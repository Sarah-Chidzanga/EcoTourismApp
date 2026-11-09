const { randomBytes, createHash, createHmac } = require('node:crypto');
const express = require('express');

const hash = value => createHash('sha256').update(value).digest('base64url');
const random = () => randomBytes(32).toString('base64url');

module.exports = async function socialAuth(app, { run, get, now, issueSession }, options = {}) {
    const env = options.env || process.env;
    const request = options.fetch || fetch;
    const { createRemoteJWKSet, jwtVerify } = await import('jose');
    const appleKeys = options.appleKeys || createRemoteJWKSet(new URL('https://appleid.apple.com/auth/keys'));
    const origin = env.OAUTH_PUBLIC_URL?.replace(/\/$/, '');
    const validOrigin = origin && /^https:\/\/[^/?#]+$/.test(origin);
    const providers = {
        google: { id: env.GOOGLE_CLIENT_ID, secret: env.GOOGLE_CLIENT_SECRET,
            authorize: 'https://accounts.google.com/o/oauth2/v2/auth', token: 'https://oauth2.googleapis.com/token', scope: 'openid email profile' },
        facebook: { id: env.FACEBOOK_APP_ID, secret: env.FACEBOOK_APP_SECRET,
            authorize: `https://www.facebook.com/${env.FACEBOOK_GRAPH_VERSION || 'v25.0'}/dialog/oauth`,
            token: `https://graph.facebook.com/${env.FACEBOOK_GRAPH_VERSION || 'v25.0'}/oauth/access_token`, scope: 'email,public_profile' },
        apple: { id: env.APPLE_SERVICE_ID, secret: env.APPLE_CLIENT_SECRET,
            authorize: 'https://appleid.apple.com/auth/authorize', token: 'https://appleid.apple.com/auth/token', scope: 'name email' }
    };
    const enabled = name => Boolean(validOrigin && providers[name]?.id && providers[name]?.secret);
    await run(`CREATE TABLE IF NOT EXISTS social_identities (
        provider TEXT NOT NULL, subject TEXT NOT NULL, user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        PRIMARY KEY(provider, subject))`);
    await run(`CREATE TABLE IF NOT EXISTS oauth_flows (
        state TEXT PRIMARY KEY, provider TEXT NOT NULL, challenge TEXT NOT NULL, role TEXT NOT NULL,
        nonce TEXT NOT NULL, verifier TEXT NOT NULL, expires_at INTEGER NOT NULL)`);
    await run(`CREATE TABLE IF NOT EXISTS oauth_codes (
        code_hash TEXT PRIMARY KEY, user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        challenge TEXT NOT NULL, expires_at INTEGER NOT NULL)`);
    app.get('/auth/providers', (req, res) => res.json({ providers: Object.keys(providers).filter(enabled) }));
    app.post('/auth/social/start', async (req, res) => {
        const { provider, challenge, role } = req.body || {};
        if (!['google', 'facebook', 'apple'].includes(provider) || !['tourist', 'guide'].includes(role) ||
            typeof challenge !== 'string' || !/^[A-Za-z0-9_-]{43}$/.test(challenge)) {
            return res.status(400).json({ error: 'Invalid sign-in request.' });
        }
        if (!enabled(provider)) return res.status(503).json({ error: 'This sign-in provider is not available yet. Please use email.' });
        await run('DELETE FROM oauth_flows WHERE expires_at <= ?', [now()]);
        await run('DELETE FROM oauth_codes WHERE expires_at <= ?', [now()]);
        const state = random(), nonce = random(), verifier = random();
        await run('INSERT INTO oauth_flows VALUES (?, ?, ?, ?, ?, ?, ?)',
            [state, provider, challenge, role, nonce, verifier, now() + 10 * 60 * 1000]);
        const p = providers[provider];
        const url = new URL(p.authorize);
        const params = { client_id: p.id, redirect_uri: `${origin}/auth/${provider}/callback`,
            response_type: 'code', scope: p.scope, state, nonce };
        if (provider === 'google') Object.assign(params, { code_challenge: hash(verifier), code_challenge_method: 'S256' });
        if (provider === 'apple') params.response_mode = 'form_post';
        url.search = new URLSearchParams(params).toString();
        res.json({ url: url.href, state });
    });

    async function json(url, options) {
        const response = await request(url, { ...options, signal: AbortSignal.timeout(15000) });
        if (!response.ok) throw new Error('Provider request failed');
        return response.json();
    }
    const callback = async (req, res) => {
        const provider = req.params.provider;
        const values = req.method === 'POST' ? req.body : req.query;
        if (typeof values.state !== 'string') return res.status(400).send('Invalid sign-in state. Return to Shanya and try again.');
        // Atomically consume state before talking to a provider; callbacks cannot be replayed.
        const flow = await get('DELETE FROM oauth_flows WHERE state = ? AND provider = ? AND expires_at > ? RETURNING *',
            [values.state, provider, now()]);
        if (!flow || !enabled(provider)) return res.status(400).send('Sign-in expired. Return to Shanya and try again.');
        const redirect = new URL('shanya://auth');
        redirect.searchParams.set('state', flow.state);
        try {
            if (values.error || typeof values.code !== 'string') throw new Error('Sign-in cancelled');
            const p = providers[provider];
            const tokenParams = { client_id: p.id, client_secret: p.secret, code: values.code,
                grant_type: 'authorization_code', redirect_uri: `${origin}/auth/${provider}/callback` };
            if (provider === 'google') tokenParams.code_verifier = flow.verifier;
            const tokens = await json(p.token, { method: 'POST', body: new URLSearchParams(tokenParams) });
            let identity;
            if (provider === 'apple') {
                const { payload } = await jwtVerify(tokens.id_token, appleKeys, {
                    issuer: 'https://appleid.apple.com', audience: p.id, algorithms: ['RS256'],
                    requiredClaims: ['exp', 'iat', 'sub', 'nonce']
                });
                if (payload.nonce !== flow.nonce) throw new Error('Invalid nonce');
                identity = { subject: payload.sub, email: payload.email, name: 'Explorer',
                    verified: payload.email_verified === true || payload.email_verified === 'true' };
            } else if (provider === 'google') {
                const profile = await json('https://openidconnect.googleapis.com/v1/userinfo', {
                    headers: { Authorization: `Bearer ${tokens.access_token}` }
                });
                identity = { subject: profile.sub, email: profile.email, name: profile.name, verified: profile.email_verified === true };
            } else {
                const url = new URL(`https://graph.facebook.com/${env.FACEBOOK_GRAPH_VERSION || 'v25.0'}/me`);
                url.searchParams.set('fields', 'id,name,email');
                url.searchParams.set('appsecret_proof', createHmac('sha256', p.secret).update(tokens.access_token).digest('hex'));
                const profile = await json(url, { headers: { Authorization: `Bearer ${tokens.access_token}` } });
                identity = { subject: profile.id, email: profile.email, name: profile.name, verified: true };
            }
            if (typeof identity.subject !== 'string' || !identity.subject || !identity.verified) throw new Error('Invalid identity');
            let linked = await get('SELECT user_id FROM social_identities WHERE provider = ? AND subject = ?', [provider, identity.subject]);
            if (!linked) {
                if (typeof identity.email !== 'string' || identity.email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(identity.email)) {
                    throw new Error('Email required');
                }
                // Never merge accounts solely because a provider supplies a matching email.
                if (await get('SELECT id FROM users WHERE email = ? COLLATE NOCASE', [identity.email])) {
                    redirect.searchParams.set('error', 'existing_account');
                    return res.redirect(303, redirect.href);
                }
                const user = await run('INSERT INTO users (name, email, password, role) VALUES (?, ?, NULL, ?)',
                    [typeof identity.name === 'string' ? identity.name.slice(0, 120) : 'Explorer', identity.email.toLowerCase(), flow.role]);
                try {
                    await run('INSERT INTO social_identities VALUES (?, ?, ?)', [provider, identity.subject, user.id]);
                } catch (error) {
                    // Do not leave an unusable passwordless account if linking fails.
                    await run('DELETE FROM users WHERE id = ?', [user.id]);
                    throw error;
                }
                linked = { user_id: user.id };
            }
            const code = random();
            await run('INSERT INTO oauth_codes VALUES (?, ?, ?, ?)', [hash(code), linked.user_id, flow.challenge, now() + 60000]);
            redirect.searchParams.set('code', code);
        } catch {
            redirect.searchParams.set('error', 'sign_in_failed');
        }
        res.redirect(303, redirect.href);
    };
    app.get('/auth/:provider/callback', callback);
    app.post('/auth/:provider/callback', express.urlencoded({ extended: false, limit: '16kb' }), callback);
    app.post('/auth/social/exchange', async (req, res) => {
        const { code, verifier } = req.body || {};
        if (typeof code !== 'string' || typeof verifier !== 'string' || !/^[A-Za-z0-9_-]{43,128}$/.test(verifier)) {
            return res.status(400).json({ error: 'Invalid sign-in exchange.' });
        }
        const ticket = await get('DELETE FROM oauth_codes WHERE code_hash = ? AND challenge = ? AND expires_at > ? RETURNING user_id',
            [hash(code), hash(verifier), now()]);
        if (!ticket) return res.status(401).json({ error: 'Sign-in expired or invalid. Please try again.' });
        res.json(await issueSession(ticket.user_id));
    });
};
