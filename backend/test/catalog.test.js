const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createApp } = require('../server');
const catalog = require('../../EcoTourismApp/travel-catalog.json');

test('travel catalogue has stable unique IDs, valid references and secure source links', () => {
    assert.equal(catalog.schemaVersion, 1);
    assert.match(catalog.reviewedAt, /^\d{4}-\d{2}-\d{2}$/);
    for (const records of [catalog.destinations, catalog.activities, catalog.companies]) {
        assert.ok(records.length > 0);
        assert.equal(new Set(records.map(record => record.id)).size, records.length);
        for (const record of records) {
            assert.ok(record.id && record.name);
            const url = new URL(record.sourceURL || record.website);
            assert.equal(url.protocol, 'https:');
            assert.ok(url.hostname);
            assert.equal(url.username, '');
            assert.equal(url.password, '');
        }
    }
    const destinations = new Set(catalog.destinations.map(place => place.id));
    for (const company of catalog.companies) {
        assert.ok(company.destinationIDs.length);
        assert.ok(company.destinationIDs.every(id => destinations.has(id)));
    }
    for (const activity of catalog.activities) {
        assert.ok(destinations.has(activity.destinationID));
        assert.ok(activity.companyIDs.length);
        for (const id of activity.companyIDs) {
            const company = catalog.companies.find(company => company.id === id);
            assert.ok(company, `Missing provider for ${activity.id}`);
            assert.ok(company.destinationIDs.includes(activity.destinationID));
        }
    }
    for (const place of catalog.destinations) {
        assert.ok(catalog.activities.some(activity => activity.destinationID === place.id));
        assert.ok(place.planning && place.guideSearch && place.ecoTip);
    }
    assert.ok(catalog.destinations.some(place => place.id === 'nyanga'));
    assert.ok(catalog.destinations.find(place => place.id === 'matobo').aliases.includes('Matopo Hills'));
});

test('public catalogue endpoint matches the offline app resource without authentication', async () => {
    const service = await createApp(':memory:');
    const server = await new Promise(resolve => {
        const server = service.app.listen(0, '127.0.0.1', () => resolve(server));
    });
    try {
        const response = await fetch(`http://127.0.0.1:${server.address().port}/catalog`);
        assert.equal(response.status, 200);
        assert.deepEqual(await response.json(), catalog);
    } finally {
        await new Promise(resolve => server.close(resolve));
        await service.close();
    }
});
