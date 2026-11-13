const { randomInt, randomUUID, createHmac, timingSafeEqual } = require('node:crypto');
const bcrypt = require('bcryptjs');
const nodemailer = require('nodemailer');
const { unseal } = require('./provider-tokens');
const { rateLimit } = require('express-rate-limit');

module.exports = async function accountCare(app, { db, authenticate, now }, options = {}) {
    const env = options.env || process.env;
    const secret = env.AUTH_CODE_SECRET || '';
    const smtpReady = env.SMTP_HOST && env.SMTP_USER && env.SMTP_PASSWORD && env.MAIL_FROM;
    const transport = smtpReady ? nodemailer.createTransport({ host: env.SMTP_HOST,
        port: Number(env.SMTP_PORT || 465), secure: Number(env.SMTP_PORT || 465) === 465,
        requireTLS: true, auth: { user: env.SMTP_USER, pass: env.SMTP_PASSWORD },
        connectionTimeout: 10000, socketTimeout: 15000 }) : null;
    const send = options.sendMail || (transport ? message => transport.sendMail({ from: env.MAIL_FROM, ...message }) : null);
    const enabled = Boolean(send && secret.length >= 32);
    db.exec(`CREATE TABLE IF NOT EXISTS account_codes (
        id TEXT PRIMARY KEY, user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        purpose TEXT NOT NULL, code_hash TEXT NOT NULL, expires_at INTEGER NOT NULL, attempts INTEGER NOT NULL DEFAULT 0
    )`);
    const columns = db.prepare('PRAGMA table_info(users)').all();
    if (!columns.some(column => column.name === 'email_verified')) db.exec('ALTER TABLE users ADD COLUMN email_verified INTEGER NOT NULL DEFAULT 0');
    if (!columns.some(column => column.name === 'deleted_at')) db.exec('ALTER TABLE users ADD COLUMN deleted_at INTEGER');
    const hash = (id, code) => createHmac('sha256', secret).update(id + ':' + code).digest('hex');
    const validEmail = value => typeof value === 'string' && value.length <= 254 && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim());
    const limiter = rateLimit({ windowMs: 15 * 60 * 1000, limit: options.limit || 15,
        standardHeaders: true, legacyHeaders: false, message: { error: 'Too many attempts. Please try again later.' } });
    app.get('/account/features', (req, res) => res.json({ emailCodes: enabled }));
    app.use(['/account/password', '/account/verification', '/account/delete'], limiter);
    async function sendCode(user, purpose) {
        db.prepare('DELETE FROM account_codes WHERE expires_at <= ?').run(now());
        const id = randomUUID();
        const code = String(randomInt(100000, 1000000));
        // Invalidate older codes for this purpose; a newer request always wins.
        if (user) db.prepare('DELETE FROM account_codes WHERE user_id = ? AND purpose = ?').run(user.id, purpose);
        db.prepare('INSERT INTO account_codes(id, user_id, purpose, code_hash, expires_at) VALUES (?, ?, ?, ?, ?)')
            .run(id, user?.id ?? null, purpose, hash(id, code), now() + 15 * 60 * 1000);
        let delivered = !user;
        if (user) {
            try {
                await send({ to: user.email, subject: purpose === 'reset' ? 'Reset your Shanya password' : 'Verify your Shanya email',
                    text: `Your Shanya code is ${code}. It expires in 15 minutes. If you did not request this, ignore this message. Do not share this code.` });
                delivered = true;
            } catch {
                db.prepare('DELETE FROM account_codes WHERE id = ?').run(id);
                console.error('Account email delivery failed. Check mail service configuration.');
            }
        }
        return { requestId: id, delivered };
    }
    // Validation and consumption run synchronously inside the caller's SQLite transaction.
    function consume(id, code, purpose, userID) {
        if (typeof id !== 'string' || typeof code !== 'string' || !/^\d{6}$/.test(code)) return null;
        const row = db.prepare('SELECT * FROM account_codes WHERE id = ? AND purpose = ? AND expires_at > ? AND attempts < 5').get(id, purpose, now());
        if (!row || (userID !== undefined && row.user_id !== userID)) return null;
        db.prepare('UPDATE account_codes SET attempts = attempts + 1 WHERE id = ?').run(id);
        if (!timingSafeEqual(Buffer.from(row.code_hash, 'hex'), Buffer.from(hash(id, code), 'hex')) || !row.user_id) return null;
        db.prepare('DELETE FROM account_codes WHERE id = ?').run(id);
        return row.user_id;
    }
    app.post('/account/password/request', async (req, res) => {
        if (!enabled) return res.status(503).json({ error: 'Email recovery is not configured yet.' });
        if (!validEmail(req.body?.email)) return res.status(400).json({ error: 'Enter a valid email address.' });
        const user = db.prepare('SELECT id, email FROM users WHERE email = ? COLLATE NOCASE AND password IS NOT NULL AND deleted_at IS NULL').get(req.body.email.trim());
        const { requestId } = await sendCode(user, 'reset');
        res.json({ requestId, message: 'If this email has a password account, a code has been sent. For social accounts, use your original sign-in provider.' });
    });
    app.post('/account/password/confirm', async (req, res) => {
        if (!enabled) return res.status(503).json({ error: 'Email recovery is not configured yet.' });
        const { requestId, code, password } = req.body || {};
        if (typeof password !== 'string' || password.length < 8 || Buffer.byteLength(password, 'utf8') > 72) {
            return res.status(400).json({ error: 'Use at least 8 characters and at most 72 bytes for your password.' });
        }
        const passwordHash = await bcrypt.hash(password, 10);
        const reset = db.transaction(() => {
            const userID = consume(requestId, code, 'reset');
            if (!userID) return false;
            db.prepare('UPDATE users SET password = ?, email_verified = 1 WHERE id = ? AND deleted_at IS NULL').run(passwordHash, userID);
            db.prepare('DELETE FROM sessions WHERE user_id = ?').run(userID);
            db.prepare('DELETE FROM account_codes WHERE user_id = ?').run(userID);
            return true;
        })();
        if (!reset) return res.status(400).json({ error: 'Code invalid or expired. Request a new code.' });
        res.json({ message: 'Password updated. Sign in again on your devices.' });
    });
    app.post('/account/verification/request', authenticate, async (req, res) => {
        if (!enabled) return res.status(503).json({ error: 'Email verification is not configured yet.' });
        const result = await sendCode(req.user, 'verify');
        if (!result.delivered) return res.status(503).json({ error: 'We could not send the code. Please try again later.' });
        res.json({ requestId: result.requestId, message: 'Check your account email for a verification code.' });
    });
    app.post('/account/verification/confirm', authenticate, (req, res) => {
        if (!enabled) return res.status(503).json({ error: 'Email verification is not configured yet.' });
        const verified = db.transaction(() => {
            const userID = consume(req.body?.requestId, req.body?.code, 'verify', req.user.id);
            if (!userID) return false;
            db.prepare('UPDATE users SET email_verified = 1 WHERE id = ?').run(userID);
            return true;
        })();
        if (!verified) return res.status(400).json({ error: 'Code invalid or expired. Request a new code.' });
        res.json({ message: 'Email verified.' });
    });
    app.delete('/account/delete', authenticate, async (req, res) => {
        if (req.body?.confirmation !== 'DELETE') return res.status(400).json({ error: 'Type DELETE to confirm account deletion.' });
        // Recent authentication protects accounts on shared/unlocked devices.
        const session = db.prepare('SELECT expires_at FROM sessions WHERE token_hash = ?').get(req.tokenHash);
        const issuedAt = session?.expires_at - 7 * 24 * 60 * 60 * 1000;
        if (!issuedAt || now() - issuedAt > 10 * 60 * 1000) {
            return res.status(403).json({ error: 'For security, log out and sign in again before deleting your account.' });
        }
        const apple = db.prepare("SELECT subject FROM social_identities WHERE provider = 'apple' AND user_id = ?").get(req.user.id);
        if (apple) {
            const saved = db.prepare('SELECT encrypted_token FROM provider_tokens WHERE user_id = ?').get(req.user.id);
            if (!saved) return res.status(409).json({ error: 'Please log out and sign in with Apple again, then retry deletion so we can revoke access.' });
            try {
                const token = unseal(saved.encrypted_token, env);
                if (options.revokeApple) await options.revokeApple(token);
                else {
                    if (!env.APPLE_SERVICE_ID || !env.APPLE_CLIENT_SECRET) throw new Error('Apple not configured');
                    const response = await fetch('https://appleid.apple.com/auth/revoke', {
                        method: 'POST', signal: AbortSignal.timeout(15000),
                        body: new URLSearchParams({ client_id: env.APPLE_SERVICE_ID, client_secret: env.APPLE_CLIENT_SECRET,
                            token, token_type_hint: 'refresh_token' })
                    });
                    if (!response.ok) throw new Error('Revocation failed');
                }
            } catch { return res.status(503).json({ error: 'Could not revoke Apple access. Your account has not been deleted. Please try again.' }); }
        }

        db.transaction(() => {
            const id = req.user.id;
            db.prepare("UPDATE bookings SET status = 'cancelled', note = '' WHERE (tourist_id = ? OR guide_id = ?) AND status IN ('pending','confirmed')").run(id, id);
            db.prepare("UPDATE bookings SET note = '' WHERE tourist_id = ? OR guide_id = ?").run(id, id);
            for (const table of ['sessions', 'provider_tokens', 'social_identities', 'oauth_codes', 'account_codes', 'guide_profiles', 'notifications', 'suggestions']) {
                db.prepare(`DELETE FROM ${table} WHERE user_id = ?`).run(id);
            }
            // Preserve the other participant's itinerary history without retaining this account's personal fields.
            db.prepare('UPDATE users SET name = ?, email = ?, password = NULL, nationality = NULL, bio = NULL, languages = NULL, email_verified = 0, deleted_at = ? WHERE id = ?')
                .run('Deleted account', `deleted-${randomUUID()}@deleted.invalid`, now(), id);
        })();
        res.json({ message: 'Account deleted. Active guide requests were cancelled.' });
    });
};
