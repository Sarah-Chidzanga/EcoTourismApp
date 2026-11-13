const { test } = require('node:test');
const assert = require('node:assert/strict');
const { mkdtemp, rm } = require('node:fs/promises');
const { tmpdir } = require('node:os');
const path = require('node:path');
const Database = require('better-sqlite3');
const { createApp } = require('../server');

test('authentication, persistence, validation, and removed reset route', async () => {
    const directory = await mkdtemp(path.join(tmpdir(), 'ecotourism-test-'));
    const database = path.join(directory, 'test.db');
    let service;
    let server;
    async function start() {
        service = await createApp(database);
        server = await new Promise(resolve => {
            const listener = service.app.listen(0, '127.0.0.1', () => resolve(listener));
        });
    }
    async function stop() {
        await new Promise((resolve, reject) => server.close(error => error ? reject(error) : resolve()));
        await service.close();
        server = null;
    }
    async function request(route, body, method = 'POST') {
        const response = await fetch(`http://127.0.0.1:${server.address().port}${route}`, {
            method,
            headers: { 'Content-Type': 'application/json' },
            body: body === undefined ? undefined : JSON.stringify(body)
        });
        return { status: response.status, body: await response.json() };
    }
    const tourist = { name: 'Test Tourist', email: 'tourist@example.test', password: 'test-password-123', role: 'tourist', nationality: 'Zimbabwe' };
    try {
        await start();
        assert.equal((await request('/health', undefined, 'GET')).status, 200);
        const registered = await request('/register', tourist);
        assert.equal(registered.status, 201);
        assert.equal(typeof registered.body.id, 'number');
        assert.equal((await request('/register', { ...tourist, email: ' TOURIST@EXAMPLE.TEST ' })).status, 409);
        for (const change of [{ role: 'admin' }, { password: 'short' }, { password: 'a'.repeat(73) }, { email: 'invalid' }, { name: '' }, { bio: 123 }]) {
            assert.equal((await request('/register', { ...tourist, ...change })).status, 400);
        }
        assert.equal((await request('/register', {})).status, 400);
        assert.equal((await request('/register', { ...tourist, email: 'guide@example.test', role: 'guide', bio: 'Nature guide' })).status, 201);
        assert.equal((await request('/login', { email: tourist.email, password: 'wrong' })).status, 401);
        assert.equal((await request('/login', { email: 'missing@example.test', password: tourist.password })).status, 401);
        assert.equal((await request('/login', { email: tourist.email, password: {} })).status, 400);
        assert.equal((await request('/api/clear-users', undefined, 'DELETE')).status, 404);
        const malformed = await fetch(`http://127.0.0.1:${server.address().port}/register`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{' });
        assert.equal(malformed.status, 400);
        await stop();
        const db = new Database(database);
        try {
            const saved = db.prepare('SELECT password FROM users WHERE email = ?').get(tourist.email);
            assert.notEqual(saved.password, tourist.password);
            assert.match(saved.password, /^\$2[aby]\$/);
        } finally {
            db.close();
        }
        await start();
        const login = await request('/login', { email: ' TOURIST@EXAMPLE.TEST ', password: tourist.password });
        assert.equal(login.status, 200);
        assert.equal(login.body.id, registered.body.id);
        assert.equal(login.body.name, tourist.name);
        assert.equal(login.body.role, tourist.role);
        assert.match(login.body.token, /^[a-f0-9]{64}$/);
    } finally {
        if (server) await stop();
        await rm(directory, { recursive: true, force: true });
    }
});
