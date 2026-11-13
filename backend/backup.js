const Database = require('better-sqlite3');
const fs = require('node:fs');
const path = require('node:path');

// SQLite's online backup API includes committed WAL transactions. Copying only
// the main .db file while the service is running can silently omit those writes.
async function backup(source, destination) {
    if (path.resolve(source) === path.resolve(destination)) throw new Error('Choose a different backup path.');
    const db = new Database(source, { readonly: true, fileMustExist: true });
    let reserved = false;
    try {
        fs.closeSync(fs.openSync(destination, 'wx', 0o600));
        reserved = true;
        await db.backup(destination);
        const copy = new Database(destination, { readonly: true, fileMustExist: true });
        try {
            if (copy.pragma('integrity_check', { simple: true }) !== 'ok') throw new Error('Backup integrity check failed.');
        } finally { copy.close(); }
    } catch (error) {
        if (reserved) fs.rmSync(destination, { force: true });
        throw error;
    } finally { db.close(); }
}

if (require.main === module) {
    const destination = process.argv[2];
    if (!destination) {
        console.error('Usage: node backup.js /private-backups/new-snapshot.db');
        process.exitCode = 1;
    } else {
        backup(process.env.DATABASE_PATH || path.join(__dirname, 'ecotourism.db'), destination)
            .then(() => console.log('Backup created and integrity checked. Store it privately off this host.'))
            .catch(error => { console.error('Backup failed:', error.message); process.exitCode = 1; });
    }
}
module.exports = { backup };
