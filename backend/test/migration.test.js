const { test } = require('node:test');
const assert = require('node:assert/strict');
const { mkdtemp, rm } = require('node:fs/promises');
const { tmpdir } = require('node:os');
const path = require('node:path');
const Database = require('better-sqlite3');
const { createApp } = require('../server');

test('original users schema migrates without losing accounts and is restart-safe', async () => {
    const folder = await mkdtemp(path.join(tmpdir(), 'ecotourism-migration-'));
    const file = path.join(folder, 'original.db');
    const db = new Database(file);
    const run = async sql => db.prepare(sql).run();
    try {
        await run('CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, email TEXT UNIQUE, password TEXT, role TEXT, nationality TEXT, bio TEXT)');
        await run("INSERT INTO users (name, email, role) VALUES ('Existing Guide', 'existing@example.test', 'guide')");
    } finally {
        db.close();
    }
    try {
        for (let i = 0; i < 2; i++) {
            const service = await createApp(file);
            await service.close();
        }
        const migrated = new Database(file);
        try {
            const row = migrated.prepare('SELECT id, name, languages FROM users').get();
            assert.deepEqual(row, { id: 1, name: 'Existing Guide', languages: null });
        } finally {
            migrated.close();
        }
    } finally {
        await rm(folder, { recursive: true, force: true });
    }
});
