// Run on the backend host. This is intentionally not a public HTTP endpoint.
const sqlite3 = require('sqlite3');
const path = require('node:path');
const database = process.env.DATABASE_PATH || path.join(__dirname, 'ecotourism.db');
const db = new sqlite3.Database(database, sqlite3.OPEN_READONLY, error => {
    if (error) {
        console.error('Cannot open the suggestions database. Check DATABASE_PATH.');
        process.exitCode = 1;
        return;
    }
    db.all(`SELECT id, user_id AS userId, category, message,
        datetime(created_at / 1000, 'unixepoch') AS createdAtUTC
        FROM suggestions ORDER BY id DESC LIMIT 200`, [], (error, rows) => {
        if (error) {
            console.error('Cannot read suggestions. Start the updated backend to apply migrations first.');
            process.exitCode = 1;
        } else {
            console.log(JSON.stringify(rows, null, 2));
        }
        db.close();
    });
});
