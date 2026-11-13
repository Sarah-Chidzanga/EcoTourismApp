// Public guide listings are opt-in. Booking ownership comes only from the session.
module.exports = async function installMarketplace(app, { run, get, all, authenticate, now }) {
    await run(`CREATE TABLE IF NOT EXISTS guide_profiles (
        user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
        title TEXT NOT NULL DEFAULT '', location TEXT NOT NULL DEFAULT '',
        bio TEXT NOT NULL DEFAULT '', languages TEXT NOT NULL DEFAULT '',
        daily_rate INTEGER NOT NULL DEFAULT 0, max_guests INTEGER NOT NULL DEFAULT 6,
        published INTEGER NOT NULL DEFAULT 0 CHECK(published IN (0,1))
    )`);
    await run(`CREATE TABLE IF NOT EXISTS bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tourist_id INTEGER NOT NULL REFERENCES users(id), guide_id INTEGER NOT NULL REFERENCES users(id),
        tour_date TEXT NOT NULL, guests INTEGER NOT NULL, note TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','confirmed','declined','cancelled')),
        total_price INTEGER NOT NULL, client_request_id TEXT NOT NULL,
        created_at INTEGER NOT NULL, UNIQUE(tourist_id, client_request_id)
    )`);
    await run("CREATE UNIQUE INDEX IF NOT EXISTS confirmed_guide_day ON bookings(guide_id, tour_date) WHERE status = 'confirmed'");
    await run("CREATE UNIQUE INDEX IF NOT EXISTS active_tourist_request ON bookings(tourist_id, guide_id, tour_date) WHERE status IN ('pending','confirmed')");
    const requireRole = role => (req, res, next) => req.user.role === role ? next() : res.status(403).json({ error: 'This action is not available for your account.' });
    const text = (value, max) => typeof value === 'string' && value.length <= max;
    const guideFields = `u.id, u.name, p.title, p.location, p.bio, p.languages,
        p.daily_rate / 100.0 AS dailyRate, p.max_guests AS maxGuests`;
    const validID = value => /^\d+$/.test(value) && Number.isSafeInteger(Number(value)) && Number(value) > 0;
    const today = () => new Intl.DateTimeFormat('en-CA', { timeZone: 'Africa/Harare', year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date(now()));
    const validDate = value => {
        if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
        const date = new Date(value + 'T00:00:00Z');
        return !Number.isNaN(date.getTime()) && date.toISOString().slice(0, 10) === value && value >= today();
    };
    app.get('/guides', async (req, res) => {
        res.json(await all(`SELECT ${guideFields} FROM guide_profiles p JOIN users u ON u.id = p.user_id WHERE p.published = 1 AND u.role = 'guide' ORDER BY u.name, u.id`));
    });
    app.get('/guide-profile', authenticate, requireRole('guide'), async (req, res) => {
        const profile = await get(`SELECT ${guideFields}, p.published FROM guide_profiles p JOIN users u ON u.id = p.user_id WHERE u.id = ?`, [req.user.id]);
        res.json(profile ? { ...profile, published: Boolean(profile.published) } : {
            id: req.user.id, name: req.user.name, title: '', location: '', bio: req.user.bio || '',
            languages: req.user.languages || '', dailyRate: 0, maxGuests: 6, published: false
        });
    });
    app.put('/guide-profile', authenticate, requireRole('guide'), async (req, res) => {
        const { title, location, bio, languages, dailyRate, maxGuests, published } = req.body || {};
        if (!text(title, 120) || !text(location, 120) || !text(bio, 2000) || !text(languages, 500) ||
            typeof dailyRate !== 'number' || !Number.isFinite(dailyRate) || dailyRate < 0 || dailyRate > 10000 ||
            !Number.isInteger(maxGuests) || maxGuests < 1 || maxGuests > 20 || typeof published !== 'boolean') {
            return res.status(400).json({ error: 'Check your profile fields, daily price (0–10,000 USD), and group size (1–20).' });
        }
        if (published && (![title, location, bio, languages].every(v => v.trim()) || dailyRate < 1)) {
            return res.status(400).json({ error: 'Add a title, location, bio, languages, and daily price of at least 1 USD before publishing.' });
        }
        await run(`INSERT INTO guide_profiles (user_id, title, location, bio, languages, daily_rate, max_guests, published)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT(user_id) DO UPDATE SET title=excluded.title, location=excluded.location,
            bio=excluded.bio, languages=excluded.languages, daily_rate=excluded.daily_rate, max_guests=excluded.max_guests, published=excluded.published`,
            [req.user.id, title.trim(), location.trim(), bio.trim(), languages.trim(), Math.round(dailyRate * 100), maxGuests, published ? 1 : 0]);
        res.json({ message: published ? 'Your guide profile is now visible to tourists.' : 'Profile saved privately.' });
    });
    const bookingFields = `b.id, b.guide_id AS guideId, b.tourist_id AS touristId, g.name AS guideName,
        t.name AS touristName, b.tour_date AS tourDate, b.guests, b.note, b.status,
        b.total_price / 100.0 AS totalPrice,
        CASE WHEN b.status = 'confirmed' THEN g.email ELSE NULL END AS guideEmail,
        CASE WHEN b.status = 'confirmed' THEN t.email ELSE NULL END AS touristEmail`;
    const bookingJoins = 'FROM bookings b JOIN users g ON g.id = b.guide_id JOIN users t ON t.id = b.tourist_id';
    const findBooking = id => get(`SELECT ${bookingFields} ${bookingJoins} WHERE b.id = ?`, [id]);
    app.get('/bookings', authenticate, async (req, res) => {
        res.json(await all(`SELECT ${bookingFields} ${bookingJoins} WHERE b.tourist_id = ? OR b.guide_id = ? ORDER BY b.tour_date DESC, b.id DESC`, [req.user.id, req.user.id]));
    });
    app.post('/bookings', authenticate, requireRole('tourist'), async (req, res) => {
        const { guideId, tourDate, guests, note, requestId, expectedPrice } = req.body || {};
        if (!Number.isSafeInteger(guideId) || guideId < 1 || !validDate(tourDate) || !Number.isInteger(guests) || guests < 1 || guests > 20 ||
            !text(note, 2000) || typeof expectedPrice !== 'number' || !Number.isFinite(expectedPrice) || expectedPrice < 1 || typeof requestId !== 'string' || !/^[a-zA-Z0-9-]{16,80}$/.test(requestId)) {
            return res.status(400).json({ error: 'Choose a valid guide, current or future date, group size, and request.' });
        }
        // A retry after a dropped response returns the original booking, never a second request.
        const existing = await get('SELECT * FROM bookings WHERE tourist_id = ? AND client_request_id = ?', [req.user.id, requestId]);
        if (existing) {
            if (existing.guide_id !== guideId || existing.tour_date !== tourDate || existing.guests !== guests || existing.note !== note.trim()) {
                return res.status(409).json({ error: 'This request was already submitted with different details. Check My Trips.' });
            }
            return res.status(200).json(await findBooking(existing.id));
        }
        const guide = await get("SELECT p.* FROM guide_profiles p JOIN users u ON u.id=p.user_id WHERE p.user_id=? AND p.published=1 AND u.role='guide'", [guideId]);
        if (!guide) return res.status(404).json({ error: 'This guide is not accepting requests.' });
        if (Math.round(expectedPrice * 100) !== guide.daily_rate) return res.status(409).json({ error: 'The guide’s price has changed. Reload their profile before requesting.' });
        if (guests > guide.max_guests) return res.status(400).json({ error: 'Your group exceeds this guide’s maximum group size.' });
        if (await get("SELECT id FROM bookings WHERE guide_id=? AND tour_date=? AND status='confirmed'", [guideId, tourDate])) {
            return res.status(409).json({ error: 'This guide already has a confirmed booking on that date.' });
        }
        try {
            const result = await run('INSERT INTO bookings (tourist_id, guide_id, tour_date, guests, note, total_price, client_request_id, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
                [req.user.id, guideId, tourDate, guests, note.trim(), guide.daily_rate, requestId, now()]);
            res.status(201).json(await findBooking(result.id));
        } catch (error) {
            if (error.code?.startsWith('SQLITE_CONSTRAINT')) return res.status(409).json({ error: 'You already have a request for this guide and date. Check My Trips.' });
            throw error;
        }
    });
    app.patch('/bookings/:id', authenticate, async (req, res) => {
        if (!validID(req.params.id)) return res.status(404).json({ error: 'Booking not found.' });
        const booking = await get('SELECT * FROM bookings WHERE id=? AND (tourist_id=? OR guide_id=?)', [Number(req.params.id), req.user.id, req.user.id]);
        if (!booking) return res.status(404).json({ error: 'Booking not found.' });
        const status = req.body?.status;
        const isGuide = req.user.id === booking.guide_id && req.user.role === 'guide';
        const allowed = (status === 'cancelled' && ['pending', 'confirmed'].includes(booking.status)) ||
            (isGuide && booking.status === 'pending' && ['confirmed', 'declined'].includes(status));
        if (!allowed) return res.status(409).json({ error: 'This booking cannot be changed to that status.' });
        if (status === 'confirmed' && booking.tour_date < today()) return res.status(409).json({ error: 'A past booking cannot be accepted.' });
        try {
            // Compare the previous status to avoid overwriting a simultaneous cancellation.
            const result = await run('UPDATE bookings SET status=? WHERE id=? AND status=?', [status, booking.id, booking.status]);
            if (!result.changes) return res.status(409).json({ error: 'This request changed. Refresh and try again.' });
            res.json(await findBooking(booking.id));
        } catch (error) {
            if (error.code?.startsWith('SQLITE_CONSTRAINT')) return res.status(409).json({ error: 'You already have a confirmed booking on this date.' });
            throw error;
        }
    });
};
