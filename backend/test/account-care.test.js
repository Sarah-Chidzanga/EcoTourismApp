const { test } = require('node:test');
const assert = require('node:assert/strict');
const { mkdtemp, rm } = require('node:fs/promises');
const { tmpdir } = require('node:os');
const path = require('node:path');
const Database = require('better-sqlite3');
const { createApp } = require('../server');
const { seal, unseal } = require('../provider-tokens');

test('recovery codes expire, limit guesses, prevent replay and revoke sessions; deletion anonymises and cancels', async () => {
    const folder = await mkdtemp(path.join(tmpdir(), 'shanya-account-'));
    const file = path.join(folder, 'test.db');
    let now = Date.UTC(2026, 10, 9, 12);
    const mail = [];
    let revocationFails = false;
    const env = { AUTH_CODE_SECRET: 'test-secret-'.repeat(4), TOKEN_ENCRYPTION_KEY: Buffer.alloc(32, 7).toString('base64') };
    const service = await createApp(file, { now: () => now, authLimit: 1000,
        account: { env, limit: 100, sendMail: async message => mail.push(message), revokeApple: async token => {
            assert.equal(token, 'apple-refresh'); if (revocationFails) throw new Error('provider offline');
        } } });
    const server = await new Promise(resolve => { const listener = service.app.listen(0, '127.0.0.1', () => resolve(listener)); });
    const base = `http://127.0.0.1:${server.address().port}`;
    const db = new Database(file);
    async function request(route, method = 'GET', body, token) {
        const response = await fetch(base + route, { method, headers: { 'Content-Type': 'application/json',
            ...(token ? { Authorization: `Bearer ${token}` } : {}) }, body: body === undefined ? undefined : JSON.stringify(body) });
        return { status: response.status, body: await response.json() };
    }
    async function account(role, name) {
        const credentials = { name, role, email: `${name}@example.test`, password: 'test-password-123' };
        const registered = await request('/register', 'POST', credentials);
        const login = await request('/login', 'POST', credentials);
        return { id: registered.body.id, token: login.body.token, ...credentials };
    }
    const lastCode = () => /code is (\d{6})/.exec(mail.at(-1).text)[1];
    try {
        const tourist = await account('tourist', 'care-tourist');
        const guide = await account('guide', 'care-guide');
        assert.equal((await request('/account/features')).body.emailCodes, true);
        const unknown = await request('/account/password/request', 'POST', { email: 'missing@example.test' });
        assert.equal(unknown.status, 200);
        assert.equal(mail.length, 0);
        const start = await request('/account/password/request', 'POST', { email: tourist.email });
        assert.equal(start.body.message, unknown.body.message);
        const correct = lastCode();
        assert.notEqual(db.prepare('SELECT code_hash FROM account_codes WHERE id = ?').get(start.body.requestId).code_hash, correct);
        const invalid = correct === '111111' ? '222222' : '111111';
        for (let i = 0; i < 5; i++) {
            assert.equal((await request('/account/password/confirm', 'POST', { requestId: start.body.requestId, code: invalid, password: 'new-password-123' })).status, 400);
        }
        assert.equal((await request('/account/password/confirm', 'POST', { requestId: start.body.requestId, code: correct, password: 'new-password-123' })).status, 400);
        const fresh = await request('/account/password/request', 'POST', { email: tourist.email });
        const reset = { requestId: fresh.body.requestId, code: lastCode(), password: 'new-password-123' };
        assert.equal((await request('/account/password/confirm', 'POST', reset)).status, 200);
        assert.equal((await request('/account/password/confirm', 'POST', reset)).status, 400);
        assert.equal((await request('/me', 'GET', undefined, tourist.token)).status, 401);
        assert.equal((await request('/login', 'POST', tourist)).status, 401);
        tourist.token = (await request('/login', 'POST', { email: tourist.email, password: reset.password })).body.token;
        assert.equal((await request('/me', 'GET', undefined, tourist.token)).body.emailVerified, 1);
        const expiring = await request('/account/password/request', 'POST', { email: tourist.email });
        const expiredCode = lastCode(); now += 16 * 60 * 1000;
        assert.equal((await request('/account/password/confirm', 'POST', { requestId: expiring.body.requestId, code: expiredCode, password: reset.password })).status, 400);
        const verification = await request('/account/verification/request', 'POST', {}, guide.token);
        const verify = { requestId: verification.body.requestId, code: lastCode() };
        assert.equal((await request('/account/verification/confirm', 'POST', verify, tourist.token)).status, 400);
        assert.equal((await request('/account/verification/confirm', 'POST', verify, guide.token)).status, 200);
        await request('/guide-profile', 'PUT', { title: 'Nature', location: 'Harare', bio: 'Walk with me', languages: 'English', dailyRate: 50, maxGuests: 4, published: true }, guide.token);
        const booking = await request('/bookings', 'POST', { guideId: guide.id, tourDate: '2026-11-20', guests: 1,
            note: 'Personal travel notes', expectedPrice: 50, requestId: 'request-delete-test-123' }, tourist.token);
        assert.equal(booking.status, 201);
        assert.equal((await request('/account/delete', 'DELETE', { confirmation: 'DELETE' }, tourist.token)).status, 403);
        tourist.token = (await request('/login', 'POST', { email: tourist.email, password: reset.password })).body.token;
        assert.equal((await request('/account/delete', 'DELETE', { confirmation: 'no' }, tourist.token)).status, 400);
        assert.equal((await request('/account/delete', 'DELETE', { confirmation: 'DELETE' }, tourist.token)).status, 200);
        assert.equal((await request('/me', 'GET', undefined, tourist.token)).status, 401);
        assert.equal(db.prepare('SELECT id FROM users WHERE email = ?').get(tourist.email), undefined);
        const history = (await request('/bookings', 'GET', undefined, guide.token)).body[0];
        assert.equal(history.status, 'cancelled'); assert.equal(history.note, ''); assert.equal(history.touristName, 'Deleted account');
        assert.equal(history.touristEmail, null);

        const apple = await account('tourist', 'care-apple');
        db.prepare('INSERT INTO social_identities VALUES (?, ?, ?)').run('apple', 'apple-subject', apple.id);
        const encrypted = seal('apple-refresh', env);
        assert.notEqual(encrypted, 'apple-refresh'); assert.equal(unseal(encrypted, env), 'apple-refresh');
        db.prepare('INSERT INTO provider_tokens VALUES (?, ?)').run(apple.id, encrypted);
        revocationFails = true;
        assert.equal((await request('/account/delete', 'DELETE', { confirmation: 'DELETE' }, apple.token)).status, 503);
        assert.equal((await request('/me', 'GET', undefined, apple.token)).status, 200);
        revocationFails = false;
        assert.equal((await request('/account/delete', 'DELETE', { confirmation: 'DELETE' }, apple.token)).status, 200);
        assert.equal(db.prepare('SELECT * FROM provider_tokens WHERE user_id = ?').get(apple.id), undefined);
    } finally {
        db.close();
        await new Promise(resolve => server.close(resolve));
        await service.close();
        await rm(folder, { recursive: true, force: true });
    }
});
