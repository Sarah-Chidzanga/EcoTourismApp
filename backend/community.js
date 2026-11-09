const { rateLimit } = require('express-rate-limit');

module.exports = async function community(app, { run, get, all, authenticate, now }) {
    await run(`CREATE TABLE IF NOT EXISTS notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        booking_id INTEGER NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
        message TEXT NOT NULL, created_at INTEGER NOT NULL, read_at INTEGER
    )`);
    await run('CREATE INDEX IF NOT EXISTS notifications_user ON notifications(user_id, id)');
    // SQLite triggers keep booking changes and inbox updates in the same transaction.
    await run(`CREATE TRIGGER IF NOT EXISTS booking_request_notification AFTER INSERT ON bookings BEGIN
        INSERT INTO notifications(user_id, booking_id, message, created_at)
        VALUES (NEW.guide_id, NEW.id, 'You have a new guide request for ' || NEW.tour_date || '.', NEW.created_at);
    END`);
    await run(`CREATE TRIGGER IF NOT EXISTS booking_status_notification AFTER UPDATE OF status ON bookings
        WHEN NEW.status != OLD.status BEGIN
        INSERT INTO notifications(user_id, booking_id, message, created_at)
        VALUES (NEW.tourist_id, NEW.id, 'Your guide request for ' || NEW.tour_date || ' is now ' || NEW.status || '.', unixepoch() * 1000);
        INSERT INTO notifications(user_id, booking_id, message, created_at)
        VALUES (NEW.guide_id, NEW.id, 'The guide request for ' || NEW.tour_date || ' is now ' || NEW.status || '.', unixepoch() * 1000);
    END`);
    await run(`CREATE TABLE IF NOT EXISTS suggestions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        request_id TEXT NOT NULL, category TEXT NOT NULL, message TEXT NOT NULL,
        created_at INTEGER NOT NULL, UNIQUE(user_id, request_id)
    )`);
    app.get('/notifications', authenticate, async (req, res) => {
        res.json(await all(`SELECT id, booking_id AS bookingId, message, created_at AS createdAt,
            read_at IS NOT NULL AS isRead FROM notifications WHERE user_id = ? ORDER BY id DESC LIMIT 100`, [req.user.id]));
    });
    app.patch('/notifications/:id/read', authenticate, async (req, res) => {
        if (!/^\d+$/.test(req.params.id)) return res.status(404).json({ error: 'Notification not found.' });
        const result = await run('UPDATE notifications SET read_at = ? WHERE id = ? AND user_id = ?', [now(), req.params.id, req.user.id]);
        if (!result.changes) return res.status(404).json({ error: 'Notification not found.' });
        res.json({ message: 'Marked as read.' });
    });
    app.post('/suggestions', authenticate, rateLimit({ windowMs: 3600000, limit: 10,
        standardHeaders: true, legacyHeaders: false, message: { error: 'Please try again later. Too many suggestions were sent.' }
    }), async (req, res) => {
        const { requestId, category, message } = req.body || {};
        if (typeof requestId !== 'string' || !/^[a-zA-Z0-9-]{16,80}$/.test(requestId) ||
            !['Idea', 'Problem', 'Listing correction'].includes(category) ||
            typeof message !== 'string' || message.trim().length < 10 || message.length > 2000) {
            return res.status(400).json({ error: 'Choose a category and write between 10 and 2,000 characters.' });
        }
        const existing = await get('SELECT * FROM suggestions WHERE user_id = ? AND request_id = ?', [req.user.id, requestId]);
        if (existing) {
            if (existing.category !== category || existing.message !== message.trim()) {
                return res.status(409).json({ error: 'This submission has already been used. Start a new suggestion.' });
            }
            return res.json({ message: 'Suggestion received. Thank you!', id: existing.id });
        }
        const result = await run('INSERT INTO suggestions(user_id, request_id, category, message, created_at) VALUES (?, ?, ?, ?, ?) ON CONFLICT(user_id, request_id) DO NOTHING',
            [req.user.id, requestId, category, message.trim(), now()]);
        if (!result.changes) {
            const saved = await get('SELECT * FROM suggestions WHERE user_id = ? AND request_id = ?', [req.user.id, requestId]);
            if (saved.category !== category || saved.message !== message.trim()) {
                return res.status(409).json({ error: 'This submission has already been used. Start a new suggestion.' });
            }
            return res.json({ message: 'Suggestion received. Thank you!', id: saved.id });
        }
        res.status(201).json({ message: 'Suggestion received. Thank you!', id: result.id });
    });
};
