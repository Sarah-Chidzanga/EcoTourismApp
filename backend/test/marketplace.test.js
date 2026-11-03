const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createApp } = require('../server');
const { randomUUID } = require('node:crypto');

test('published guides and booking lifecycle enforce ownership, dates, capacity and reservations', async () => {
    const service = await createApp(':memory:', { now: () => Date.UTC(2026, 10, 3, 12), authLimit: 100 });
    const server = await new Promise(resolve => { const s = service.app.listen(0, '127.0.0.1', () => resolve(s)); });
    const base = `http://127.0.0.1:${server.address().port}`;
    async function request(route, method = 'GET', body, token) {
        const response = await fetch(base + route, { method, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, body: body === undefined ? undefined : JSON.stringify(body) });
        return { status: response.status, body: await response.json() };
    }
    async function account(role, name) {
        const body = { name, email: `${name}@example.test`, password: 'test-password-123', role };
        const reg = await request('/register', 'POST', body);
        assert.equal(reg.status, 201);
        const login = await request('/login', 'POST', body);
        return { id: reg.body.id, token: login.body.token };
    }
    try {
        const guide = await account('guide', 'guide');
        const otherGuide = await account('guide', 'other-guide');
        const tourist = await account('tourist', 'tourist');
        const stranger = await account('tourist', 'stranger');
        assert.equal((await request('/bookings')).status, 401);
        assert.deepEqual((await request('/guides')).body, []);
        const profile = { title: 'Nature walks', location: 'Victoria Falls', bio: 'Walk with a local guide.', languages: 'English, Shona', dailyRate: 90.50, maxGuests: 4, published: true };
        assert.equal((await request('/guide-profile', 'PUT', profile, tourist.token)).status, 403);
        assert.equal((await request('/guide-profile', 'PUT', { ...profile, bio: '' }, guide.token)).status, 400);
        assert.equal((await request('/guide-profile', 'PUT', profile, guide.token)).status, 200);
        const listing = (await request('/guides')).body;
        assert.equal(listing.length, 1);
        assert.equal(listing[0].email, undefined);
        assert.equal(listing[0].dailyRate, 90.5);
        const booking = { guideId: guide.id, tourDate: '2026-11-10', guests: 2, note: 'Birdwatching', expectedPrice: 90.5, requestId: randomUUID() };
        for (const change of [{ tourDate: '2026-11-02' }, { tourDate: '2026-02-30' }, { tourDate: 'invalid' }, { guests: 5 }, { guests: -1 }]) {
            assert.equal((await request('/bookings', 'POST', { ...booking, ...change }, tourist.token)).status, 400);
        }
        assert.equal((await request('/bookings', 'POST', booking, guide.token)).status, 403);
        assert.equal((await request('/bookings', 'POST', { ...booking, expectedPrice: 80 }, tourist.token)).status, 409);
        const created = await request('/bookings', 'POST', booking, tourist.token);
        assert.equal(created.status, 201);
        assert.equal(created.body.status, 'pending');
        assert.equal(created.body.guideEmail, null);
        const id = created.body.id;
        assert.equal((await request('/bookings', 'POST', booking, tourist.token)).body.id, id);
        assert.equal((await request('/bookings', 'POST', { ...booking, guests: 3 }, tourist.token)).status, 409);
        assert.equal((await request('/bookings', 'POST', { ...booking, requestId: randomUUID() }, tourist.token)).status, 409);
        assert.equal((await request('/bookings', 'GET', undefined, stranger.token)).body.length, 0);
        assert.equal((await request('/bookings', 'GET', undefined, otherGuide.token)).body.length, 0);
        assert.equal((await request(`/bookings/${id}`, 'PATCH', { status: 'confirmed' }, tourist.token)).status, 409);
        assert.equal((await request(`/bookings/${id}`, 'PATCH', { status: 'cancelled' }, stranger.token)).status, 404);
        assert.equal((await request(`/bookings/${id}`, 'PATCH', { status: 'confirmed' }, otherGuide.token)).status, 404);
        const rival = await request('/bookings', 'POST', { ...booking, requestId: randomUUID() }, stranger.token);
        assert.equal(rival.status, 201);
        const accepted = await request(`/bookings/${id}`, 'PATCH', { status: 'confirmed' }, guide.token);
        assert.equal(accepted.status, 200);
        assert.equal(accepted.body.guideEmail, 'guide@example.test');
        assert.equal(accepted.body.touristEmail, 'tourist@example.test');
        assert.equal((await request(`/bookings/${rival.body.id}`, 'PATCH', { status: 'confirmed' }, guide.token)).status, 409);
        await request('/guide-profile', 'PUT', { ...profile, dailyRate: 120 }, guide.token);
        const saved = (await request('/bookings', 'GET', undefined, tourist.token)).body;
        assert.equal(saved[0].totalPrice, 90.5);
        assert.equal((await request(`/bookings/${id}`, 'PATCH', { status: 'cancelled' }, tourist.token)).status, 200);
        assert.equal((await request(`/bookings/${rival.body.id}`, 'PATCH', { status: 'confirmed' }, guide.token)).status, 200);
        assert.equal((await request(`/bookings/${id}`, 'PATCH', { status: 'confirmed' }, guide.token)).status, 409);
        assert.equal((await request('/guide-profile', 'PUT', { ...profile, published: false }, guide.token)).status, 200);
        assert.equal((await request('/guides')).body.length, 0);
        assert.equal((await request('/bookings', 'POST', { ...booking, tourDate: '2026-11-20', requestId: randomUUID() }, tourist.token)).status, 404);
        const cancelled = await request(`/bookings/${rival.body.id}`, 'PATCH', { status: 'cancelled' }, guide.token);
        assert.equal(cancelled.body.guideEmail, null);
    } finally {
        await new Promise(resolve => server.close(resolve));
        await service.close();
    }
});
