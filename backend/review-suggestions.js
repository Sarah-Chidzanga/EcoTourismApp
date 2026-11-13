// Run on the backend host; never expose user feedback through a public endpoint.
const Database = require('better-sqlite3');
const path = require('node:path');
let db;
try {
    db = new Database(process.env.DATABASE_PATH || path.join(__dirname, 'ecotourism.db'), { readonly: true, fileMustExist: true });
    const rows = db.prepare(`SELECT id, user_id AS userId, category, message,
        datetime(created_at / 1000, 'unixepoch') AS createdAtUTC
        FROM suggestions ORDER BY id DESC LIMIT 200`).all();
    console.log(JSON.stringify(rows, null, 2));
} catch {
    console.error('Cannot read suggestions. Check DATABASE_PATH and apply backend migrations first.');
    process.exitCode = 1;
} finally { db?.close(); }
