const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcryptjs');
const path = require('node:path');
const { randomBytes, createHash } = require('node:crypto');
const { rateLimit } = require('express-rate-limit');

async function createApp(databasePath = path.join(__dirname, 'ecotourism.db'), options = {}) {
    const now = options.now || Date.now;
    const sessionDuration = 7 * 24 * 60 * 60 * 1000;
    const db = await new Promise((resolve, reject) => {
        const connection = new sqlite3.Database(databasePath, error => {
            if (error) reject(error);
            else resolve(connection);
        });
    });
    const run = (sql, values = []) => new Promise((resolve, reject) => {
        db.run(sql, values, function(error) {
            if (error) reject(error);
            else resolve({ id: this.lastID, changes: this.changes });
        });
    });
    const all = (sql, values = []) => new Promise((resolve, reject) => {
        db.all(sql, values, (error, rows) => error ? reject(error) : resolve(rows));
    });
    const get = (sql, values) => new Promise((resolve, reject) => {
        db.get(sql, values, (error, row) => error ? reject(error) : resolve(row));
    });
    const close = () => new Promise((resolve, reject) => {
        db.close(error => error ? reject(error) : resolve());
    });
    try {
        await run('PRAGMA foreign_keys = ON');
        await run('PRAGMA busy_timeout = 5000');
        await run(`CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT UNIQUE,
            password TEXT,
            role TEXT,
            nationality TEXT,
            bio TEXT
        )`);
        const columns = await all('PRAGMA table_info(users)');
        if (!columns.some(column => column.name === 'languages')) {
            await run('ALTER TABLE users ADD COLUMN languages TEXT');
        }
        await run('CREATE UNIQUE INDEX IF NOT EXISTS users_email_nocase ON users(email COLLATE NOCASE)');
        await run(`CREATE TABLE IF NOT EXISTS sessions (
            token_hash TEXT PRIMARY KEY,
            user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            expires_at INTEGER NOT NULL
        )`);
        await run('CREATE INDEX IF NOT EXISTS sessions_expiry ON sessions(expires_at)');
    } catch (error) {
        await close();
        throw error;
    }
    const app = express();
    app.disable('x-powered-by');
    app.use((req, res, next) => {
        res.set('Cache-Control', 'no-store');
        next();
    });
    app.use(['/register', '/login'], rateLimit({
        windowMs: 15 * 60 * 1000,
        limit: options.authLimit || 30,
        standardHeaders: true,
        legacyHeaders: false,
        message: { error: 'Too many authentication attempts. Try again later.' }
    }));
    app.use(express.json({ limit: '16kb' }));
    const hashToken = token => createHash('sha256').update(token).digest('hex');
    const dummyPasswordHash = await bcrypt.hash(randomBytes(32).toString('hex'), 10);
    async function authenticate(req, res, next) {
        const match = /^Bearer ([a-f0-9]{64})$/i.exec(req.get('Authorization') || '');
        if (!match) return res.status(401).json({ error: 'Authentication required.' });
        const tokenHash = hashToken(match[1]);
        const user = await get(`SELECT users.id, users.name, users.email, users.role, users.nationality, users.bio, users.languages
            FROM sessions JOIN users ON users.id = sessions.user_id
            WHERE sessions.token_hash = ? AND sessions.expires_at > ?`, [tokenHash, now()]);
        if (!user) return res.status(401).json({ error: 'Session expired or invalid.' });
        req.user = user;
        req.tokenHash = tokenHash;
        next();
    }
    const validText = (value, max) => typeof value === 'string' && value.trim().length > 0 && value.length <= max;
    const validEmail = value => validText(value, 254) && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim());
    // bcrypt truncates beyond 72 bytes, so reject longer passwords explicitly.
    const validPassword = value => typeof value === 'string' && value.length >= 8 && Buffer.byteLength(value, 'utf8') <= 72;

    app.get('/health', (req, res) => res.json({ status: 'ok' }));
    // The same reviewed catalogue ships with iOS for offline browsing.
    const catalog = require('../EcoTourismApp/travel-catalog.json');
    app.get('/catalog', (req, res) => res.json(catalog));
    app.post('/register', async (req, res) => {
        const { name, email, password, role, nationality, bio, languages } = req.body || {};
        if (!validText(name, 120) || !validEmail(email) || !validPassword(password) || !['tourist', 'guide'].includes(role)) {
            return res.status(400).json({ error: 'Provide a name, valid email, tourist or guide role, and a password of at least 8 characters (maximum 72 bytes).' });
        }
        if ((nationality !== undefined && (typeof nationality !== 'string' || nationality.length > 120)) ||
            (bio !== undefined && (typeof bio !== 'string' || bio.length > 2000)) ||
            (languages !== undefined && (typeof languages !== 'string' || languages.length > 500))) {
            return res.status(400).json({ error: 'Invalid nationality, bio, or languages.' });
        }
        const hashedPassword = await bcrypt.hash(password, 10);
        try {
            const result = await run(
                'INSERT INTO users (name, email, password, role, nationality, bio, languages) VALUES (?, ?, ?, ?, ?, ?, ?)',
                [name.trim(), email.trim().toLowerCase(), hashedPassword, role, nationality?.trim() || null, bio?.trim() || null, languages?.trim() || null]
            );
            res.status(201).json({ id: result.id, message: 'User registered successfully!' });
        } catch (error) {
            if (error.code === 'SQLITE_CONSTRAINT') return res.status(409).json({ error: 'Email already exists.' });
            throw error;
        }
    });
    app.post('/login', async (req, res) => {
        const { email, password } = req.body || {};
        if (!validEmail(email) || typeof password !== 'string' || !password.length || Buffer.byteLength(password, 'utf8') > 72) {
            return res.status(400).json({ error: 'Provide a valid email and password.' });
        }
        const user = await get('SELECT * FROM users WHERE email = ? COLLATE NOCASE', [email.trim()]);
        const matches = await bcrypt.compare(password, user?.password || dummyPasswordHash);
        if (!user || !matches) {
            return res.status(401).json({ error: 'Incorrect email or password.' });
        }
        const token = randomBytes(32).toString('hex');
        const expiresAt = now() + sessionDuration;
        await run('DELETE FROM sessions WHERE expires_at <= ?', [now()]);
        await run('INSERT INTO sessions (token_hash, user_id, expires_at) VALUES (?, ?, ?)', [hashToken(token), user.id, expiresAt]);
        res.json({ id: user.id, name: user.name, role: user.role, token, expiresAt: new Date(expiresAt).toISOString() });
    });
    app.get('/me', authenticate, (req, res) => res.json(req.user));
    app.post('/logout', authenticate, async (req, res) => {
        await run('DELETE FROM sessions WHERE token_hash = ?', [req.tokenHash]);
        res.json({ message: 'Logged out successfully.' });
    });
    try {
        await require('./marketplace')(app, { run, get, all, authenticate, now });
    } catch (error) {
        await close();
        throw error;
    }
    app.use((req, res) => res.status(404).json({ error: 'Route not found.' }));
    app.use((error, req, res, next) => {
        if (error.type === 'entity.parse.failed') return res.status(400).json({ error: 'Invalid JSON.' });
        if (error.type === 'entity.too.large') return res.status(413).json({ error: 'Request too large.' });
        console.error('Request failed:', error.code || error.name);
        res.status(500).json({ error: 'An internal server error occurred.' });
    });
    return { app, close };
}

if (require.main === module) {
    createApp(process.env.DATABASE_PATH).then(({ app, close }) => {
        const port = Number(process.env.PORT || 3000);
        const host = process.env.HOST || '127.0.0.1';
        const server = app.listen(port, host, () => console.log(`EcoTourism backend listening on http://${host}:${port}`));
        server.on('error', async error => {
            console.error('Server failed to start:', error.message);
            await close();
            process.exitCode = 1;
        });
        const shutdown = () => server.close(async () => { await close(); });
        process.once('SIGINT', shutdown);
        process.once('SIGTERM', shutdown);
    }).catch(error => {
        console.error('Database initialization failed:', error.message);
        process.exitCode = 1;
    });
}
module.exports = { createApp };
