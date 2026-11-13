const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createHash } = require('node:crypto');
const { createApp } = require('../server');

test('Apple form-post callback verifies signature, audience and nonce before issuing a session', async () => {
    const { generateKeyPair, SignJWT } = await import('jose');
    const { publicKey, privateKey } = await generateKeyPair('RS256');
    let nonce;
    let audience = 'apple-service';
    const service = await createApp(':memory:', { social: {
        env: { OAUTH_PUBLIC_URL: 'https://api.example.test', TOKEN_ENCRYPTION_KEY: Buffer.alloc(32, 1).toString('base64'), APPLE_SERVICE_ID: audience, APPLE_CLIENT_SECRET: 'test-secret' },
        appleKeys: publicKey,
        fetch: async () => Response.json({ refresh_token: 'apple-refresh', id_token: await new SignJWT({ nonce, email: 'relay@privaterelay.appleid.com', email_verified: 'true' })
            .setProtectedHeader({ alg: 'RS256' }).setIssuer('https://appleid.apple.com').setAudience(audience)
            .setSubject('apple-user').setIssuedAt().setExpirationTime('5m').sign(privateKey) })
    } });
    const server = service.app.listen(0, '127.0.0.1');
    await new Promise(resolve => server.once('listening', resolve));
    const base = `http://127.0.0.1:${server.address().port}`;
    const verifier = 'c'.repeat(43);
    const challenge = createHash('sha256').update(verifier).digest('base64url');
    async function start() {
        const response = await fetch(base + '/auth/social/start', { method: 'POST', headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ provider: 'apple', role: 'tourist', challenge }) });
        const flow = await response.json();
        nonce = new URL(flow.url).searchParams.get('nonce');
        return flow;
    }
    async function callback(flow) {
        const response = await fetch(base + '/auth/apple/callback', { method: 'POST', redirect: 'manual',
            body: new URLSearchParams({ state: flow.state, code: 'apple-code' }) });
        return new URL(response.headers.get('location'));
    }
    try {
        const good = await callback(await start());
        assert.ok(good.searchParams.get('code'));
        const response = await fetch(base + '/auth/social/exchange', { method: 'POST', headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ code: good.searchParams.get('code'), verifier }) });
        assert.equal(response.status, 200);
        const wrongNonce = await start();
        nonce = 'wrong';
        assert.equal((await callback(wrongNonce)).searchParams.get('error'), 'sign_in_failed');
        const wrongAudience = await start();
        audience = 'another-app';
        assert.equal((await callback(wrongAudience)).searchParams.get('error'), 'sign_in_failed');
    } finally {
        await new Promise(resolve => server.close(resolve));
        await service.close();
    }
});

test('social login validates state, PKCE, expiry, provider identity and account ownership', async () => {
    let now = Date.now();
    let profile = { sub: 'google-1', email: 'traveller@example.test', email_verified: true, name: 'Traveller' };
    let failProvider = false;
    const calls = [];
    const service = await createApp(':memory:', { now: () => now, authLimit: 200, social: {
        env: { OAUTH_PUBLIC_URL: 'https://api.example.test', TOKEN_ENCRYPTION_KEY: Buffer.alloc(32, 1).toString('base64'), GOOGLE_CLIENT_ID: 'test-client', GOOGLE_CLIENT_SECRET: 'test-secret',
            FACEBOOK_APP_ID: 'test-facebook', FACEBOOK_APP_SECRET: 'test-facebook-secret', APPLE_SERVICE_ID: 'test-apple', APPLE_CLIENT_SECRET: 'test-apple-secret' },
        fetch: async (url, options) => {
            calls.push({ url: String(url), options });
            if (failProvider) return new Response('{}', { status: 401 });
            if (String(url).includes('/token') || String(url).includes('/access_token')) {
                return Response.json({ access_token: 'provider-token', id_token: 'invalid-token' });
            }
            if (String(url).includes('graph.facebook.com')) return Response.json({ id: 'facebook-1', name: 'Facebook Traveller', email: 'facebook@example.test' });
            return Response.json(profile);
        }
    } });
    const server = service.app.listen(0, '127.0.0.1');
    await new Promise(resolve => server.once('listening', resolve));
    const base = `http://127.0.0.1:${server.address().port}`;
    async function post(route, body) {
        return fetch(base + route, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
    }
    const verifier = 'a'.repeat(43);
    const challenge = createHash('sha256').update(verifier).digest('base64url');
    async function start(provider = 'google', role = 'tourist') {
        const response = await post('/auth/social/start', { provider, role, challenge });
        assert.equal(response.status, 200);
        return response.json();
    }
    async function callback(flow, provider = 'google', extra = 'code=provider-code') {
        const response = await fetch(`${base}/auth/${provider}/callback?state=${flow.state}&${extra}`, { redirect: 'manual' });
        return { response, url: response.headers.get('location') ? new URL(response.headers.get('location')) : null };
    }
    async function exchange(flow, provider = 'google') {
        const result = await callback(flow, provider);
        assert.equal(result.response.status, 303);
        const code = result.url.searchParams.get('code');
        assert.ok(code);
        return { code, response: await post('/auth/social/exchange', { code, verifier }) };
    }
    try {
        assert.deepEqual((await (await fetch(base + '/auth/providers')).json()).providers, ['google', 'facebook', 'apple']);
        assert.equal((await post('/auth/social/start', { provider: 'instagram', role: 'tourist', challenge })).status, 400);
        assert.equal((await post('/auth/social/start', { provider: 'google', role: 'admin', challenge })).status, 400);
        const flow = await start();
        const authorization = new URL(flow.url);
        assert.equal(authorization.searchParams.get('redirect_uri'), 'https://api.example.test/auth/google/callback');
        assert.equal(authorization.searchParams.get('code_challenge_method'), 'S256');
        assert.equal(authorization.searchParams.has('client_secret'), false);
        assert.equal((await callback({ state: 'wrong' })).response.status, 400);
        const result = await callback(flow);
        assert.equal(result.url.searchParams.get('state'), flow.state);
        const code = result.url.searchParams.get('code');
        assert.ok(code);
        assert.equal((await callback(flow)).response.status, 400);
        assert.equal((await post('/auth/social/exchange', { code, verifier: 'b'.repeat(43) })).status, 401);
        const signedIn = await post('/auth/social/exchange', { code, verifier });
        assert.equal(signedIn.status, 200);
        const first = await signedIn.json();
        const me = await fetch(base + '/me', { headers: { Authorization: `Bearer ${first.token}` } });
        assert.equal((await me.json()).email, profile.email);
        assert.equal((await post('/auth/social/exchange', { code, verifier })).status, 401);
        const returning = await exchange(await start('google', 'guide'));
        const returningUser = await returning.response.json();
        assert.equal(returningUser.id, first.id);
        assert.equal(returningUser.role, 'tourist');
        assert.ok(calls.some(call => call.options.body?.get('code_verifier')));
        profile = { ...profile, sub: 'different-provider-subject' };
        assert.equal((await callback(await start())).url.searchParams.get('error'), 'existing_account');
        profile = { ...profile, email: 'unverified@example.test', email_verified: false };
        assert.equal((await callback(await start())).url.searchParams.get('error'), 'sign_in_failed');
        const expired = await start();
        now += 11 * 60 * 1000;
        assert.equal((await callback(expired)).response.status, 400);
        assert.equal((await callback(await start(), 'google', 'error=access_denied')).url.searchParams.get('error'), 'sign_in_failed');
        failProvider = true;
        assert.equal((await callback(await start())).url.searchParams.get('error'), 'sign_in_failed');
        failProvider = false;
        assert.equal((await callback(await start('apple'), 'apple')).url.searchParams.get('error'), 'sign_in_failed');
        const facebook = await exchange(await start('facebook', 'guide'), 'facebook');
        assert.equal((await facebook.response.json()).role, 'guide');
        const ticket = await callback(await start('facebook'), 'facebook');
        now += 61000;
        assert.equal((await post('/auth/social/exchange', { code: ticket.url.searchParams.get('code'), verifier })).status, 401);
    } finally {
        await new Promise(resolve => server.close(resolve));
        await service.close();
    }
});

test('unconfigured providers stay unavailable', async () => {
    const service = await createApp(':memory:', { social: { env: {} } });
    const server = service.app.listen(0, '127.0.0.1');
    await new Promise(resolve => server.once('listening', resolve));
    try {
        const base = `http://127.0.0.1:${server.address().port}`;
        assert.deepEqual(await (await fetch(base + '/auth/providers')).json(), { providers: [] });
        const response = await fetch(base + '/auth/social/start', { method: 'POST', headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ provider: 'google', role: 'tourist', challenge: 'a'.repeat(43) }) });
        assert.equal(response.status, 503);
    } finally {
        await new Promise(resolve => server.close(resolve));
        await service.close();
    }
});
