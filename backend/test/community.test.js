const { test } = require('node:test');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const { createApp } = require('../server');

test('booking inbox enforces ownership and suggestions validate and deduplicate submissions', async () => {
    const service = await createApp(':memory:', { now: () => Date.UTC(2026, 10, 9, 12), authLimit: 100 });
    const server = await new Promise(resolve => { const listener = service.app.listen(0, '127.0.0.1', () => resolve(listener)); });
    const base = `http://127.0.0.1:${server.address().port}`;
    async function request(route, method = 'GET', body, token) {
        const response = await fetch(base + route, { method, headers: { 'Content-Type': 'application/json',
            ...(token ? { Authorization: `Bearer ${token}` } : {}) }, body: body === undefined ? undefined : JSON.stringify(body) });
        return { status: response.status, body: await response.json() };
    }
    async function account(role, name) {
        const body = { role, name, email: `${name}@example.test`, password: 'test-password-123' };
        const registered = await request('/register', 'POST', body);
        assert.equal(registered.status, 201);
        const login = await request('/login', 'POST', body);
        return { id: registered.body.id, token: login.body.token };
    }
    try {
        const guide = await account('guide', 'community-guide');
        const tourist = await account('tourist', 'community-tourist');
        const stranger = await account('tourist', 'community-stranger');
        assert.equal((await request('/notifications')).status, 401);
        assert.equal((await request('/suggestions', 'POST', {})).status, 401);
        await request('/guide-profile', 'PUT', { title: 'Nature walks', location: 'Harare', bio: 'Explore with a local.',
            languages: 'English', dailyRate: 50, maxGuests: 4, published: true }, guide.token);
        const body = { guideId: guide.id, tourDate: '2026-11-20', guests: 2, note: '', expectedPrice: 50, requestId: randomUUID() };
        const booking = await request('/bookings', 'POST', body, tourist.token);
        assert.equal(booking.status, 201);
        await request('/bookings', 'POST', body, tourist.token);
        const inbox = (await request('/notifications', 'GET', undefined, guide.token)).body;
        assert.equal(inbox.length, 1);
        assert.equal(inbox[0].bookingId, booking.body.id);
        assert.equal(inbox[0].isRead, 0);
        assert.deepEqual((await request('/notifications', 'GET', undefined, stranger.token)).body, []);
        assert.equal((await request(`/notifications/${inbox[0].id}/read`, 'PATCH', undefined, stranger.token)).status, 404);
        assert.equal((await request(`/notifications/${inbox[0].id}/read`, 'PATCH', undefined, guide.token)).status, 200);
        assert.equal((await request('/notifications', 'GET', undefined, guide.token)).body[0].isRead, 1);
        await request(`/bookings/${booking.body.id}`, 'PATCH', { status: 'confirmed' }, guide.token);
        let updates = (await request('/notifications', 'GET', undefined, tourist.token)).body;
        assert.equal(updates.length, 1);
        assert.match(updates[0].message, /confirmed/);
        await request(`/bookings/${booking.body.id}`, 'PATCH', { status: 'cancelled' }, tourist.token);
        updates = (await request('/notifications', 'GET', undefined, tourist.token)).body;
        assert.equal(updates.length, 2);
        assert.match(updates[0].message, /cancelled/);

        const suggestion = { requestId: randomUUID(), category: 'Idea', message: 'Please add more accessible day trips.' };
        for (const change of [{ category: 'invalid' }, { message: 'short' }, { message: 'a'.repeat(2001) }, { requestId: 'short' }]) {
            assert.equal((await request('/suggestions', 'POST', { ...suggestion, ...change }, tourist.token)).status, 400);
        }
        const submissions = await Promise.all([request('/suggestions', 'POST', suggestion, tourist.token), request('/suggestions', 'POST', suggestion, tourist.token)]);
        assert.ok(submissions.every(response => [200, 201].includes(response.status)));
        assert.equal(submissions[0].body.id, submissions[1].body.id);
        const retry = await request('/suggestions', 'POST', suggestion, tourist.token);
        assert.equal(retry.body.id, submissions[0].body.id);
        assert.equal((await request('/suggestions', 'POST', { ...suggestion, message: 'A different message about transport.' }, tourist.token)).status, 409);
        assert.equal((await request('/suggestions', 'GET', undefined, stranger.token)).status, 404);
        await request('/suggestions', 'POST', suggestion, tourist.token);
        await request('/suggestions', 'POST', suggestion, tourist.token);
        assert.equal((await request('/suggestions', 'POST', suggestion, tourist.token)).status, 429);
    } finally {
        await new Promise(resolve => server.close(resolve));
        await service.close();
    }
});
