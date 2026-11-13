const { randomBytes, createCipheriv, createDecipheriv } = require('node:crypto');

function keyFor(env = process.env) {
    const key = Buffer.from(env.TOKEN_ENCRYPTION_KEY || '', 'base64');
    if (key.length !== 32) throw new Error('TOKEN_ENCRYPTION_KEY must encode 32 random bytes');
    return key;
}
function seal(token, env) {
    const iv = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', keyFor(env), iv);
    const data = Buffer.concat([cipher.update(token, 'utf8'), cipher.final()]);
    return [iv, cipher.getAuthTag(), data].map(value => value.toString('base64')).join('.');
}
function unseal(value, env) {
    const parts = value.split('.').map(part => Buffer.from(part, 'base64'));
    if (parts.length !== 3) throw new Error('Invalid encrypted token');
    const decipher = createDecipheriv('aes-256-gcm', keyFor(env), parts[0]);
    decipher.setAuthTag(parts[1]);
    return Buffer.concat([decipher.update(parts[2]), decipher.final()]).toString('utf8');
}
module.exports = { keyFor, seal, unseal };
