const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createApp } = require('../server');
const { mkdtemp, rm } = require('node:fs/promises');
const { tmpdir } = require('node:os');
const path = require('node:path');
const sqlite3 = require('sqlite3');
const { createHash } = require('node:crypto');

test('sessions survive restart, isolate users, expire, and can be revoked', async () => {
    const folder = await mkdtemp(path.join(tmpdir(), 'ecotourism-session-'));
    const database = path.join(folder, 'test.db');
    let clock = Date.now();
    let service, server;
    async function start() {
        service = await createApp(database, { now: () => clock });
        server = await new Promise(resolve => {
            const listener = service.app.listen(0, '127.0.0.1', () => resolve(listener));
        });
    }
    async function stop() {
        await new Promise(resolve => server.close(resolve));
        await service.close();
        server = null;
    }
    async function request(route, { method = 'GET', body, token } = {}) {
        const response = await fetch(`http://127.0.0.1:${server.address().port}${route}`, {
            method,
            headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
            body: body ? JSON.stringify(body) : undefined
        });
        assert.equal(response.headers.get('cache-control'), 'no-store');
        return { status: response.status, body: await response.json() };
    }
    try {
        await start();
        const users = ['tourist', 'guide'].map(role => ({ name: role, email: `${role}@example.test`, role, languages: role === 'guide' ? 'English, Shona' : '', password: 'test-password-123' }));
        const tokens = [];
        for (const user of users) {
            assert.equal((await request('/register', { method: 'POST', body: user })).status, 201);
            const login = await request('/login', { method: 'POST', body: user });
            assert.equal(login.status, 200);
            assert.equal(login.body.password, undefined);
            tokens.push(login.body.token);
        }
        assert.notEqual(tokens[0], tokens[1]);
        assert.equal((await request('/me')).status, 401);
        assert.equal((await request('/me', { token: '0'.repeat(64) })).status, 401);
        await stop();
        const db = new sqlite3.Database(database);
        try {
            const row = await new Promise((resolve, reject) => db.get('SELECT token_hash FROM sessions WHERE user_id = 1', (error, row) => error ? reject(error) : resolve(row)));
            assert.notEqual(row.token_hash, tokens[0]);
            assert.equal(row.token_hash, createHash('sha256').update(tokens[0]).digest('hex'));
        } finally {
            await new Promise(resolve => db.close(resolve));
        }
        await start();
        for (let i = 0; i < users.length; i++) {
            const profile = await request('/me', { token: tokens[i] });
            assert.equal(profile.status, 200);
            assert.equal(profile.body.email, users[i].email);
            assert.equal(profile.body.role, users[i].role);
            assert.equal(profile.body.languages, users[i].languages || null);
            assert.equal(profile.body.password, undefined);
        }
        assert.equal((await request('/logout', { method: 'POST', token: tokens[0] })).status, 200);
        assert.equal((await request('/me', { token: tokens[0] })).status, 401);
        assert.equal((await request('/me', { token: tokens[1] })).status, 200);
        clock += 7 * 24 * 60 * 60 * 1000;
        assert.equal((await request('/me', { token: tokens[1] })).status, 401);
    } finally {
        if (server) await stop();
        await rm(folder, { recursive: true, force: true });
    }
});

test('authentication attempts are rate limited', async () => {
    const service = await createApp(':memory:', { authLimit: 2 });
    const server = await new Promise(resolve => {
        const listener = service.app.listen(0, '127.0.0.1', () => resolve(listener));
    });
    try {
        const url = `http://127.0.0.1:${server.address().port}`;
        for (let i = 0; i < 3; i++) {
            const response = await fetch(`${url}/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' });
            assert.equal(response.status, i < 2 ? 400 : 429);
            if (i === 2) assert.ok(response.headers.get('retry-after'));
            await response.json();
        }
        assert.equal((await fetch(`${url}/health`)).status, 200);
    } finally {
        await new Promise(resolve => server.close(resolve));
        await service.close();
    }
});
