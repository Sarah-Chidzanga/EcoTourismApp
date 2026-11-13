const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const Database = require('better-sqlite3');
const { backup } = require('../backup');

test('online backup includes WAL writes, restores independently, and refuses to overwrite', async () => {
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'shanya-backup-'));
    const source = path.join(directory, 'source.db');
    const destination = path.join(directory, 'snapshot.db');
    const live = new Database(source);
    try {
        live.pragma('journal_mode = WAL');
        live.exec("CREATE TABLE sample(id INTEGER PRIMARY KEY, value TEXT); INSERT INTO sample VALUES(1, 'before backup')");
        await backup(source, destination);
        live.exec("UPDATE sample SET value = 'after backup'");
        const restored = new Database(destination);
        try {
            assert.equal(restored.prepare('SELECT value FROM sample').get().value, 'before backup');
            assert.equal(restored.pragma('integrity_check', { simple: true }), 'ok');
        } finally { restored.close(); }
        await assert.rejects(backup(source, destination), { code: 'EEXIST' });
        await assert.rejects(backup(source, source), /different backup path/);
        assert.equal(live.prepare('SELECT value FROM sample').get().value, 'after backup');
        assert.equal(fs.statSync(destination).mode & 0o777, 0o600);
    } finally { live.close(); fs.rmSync(directory, { recursive: true, force: true }); }
});
