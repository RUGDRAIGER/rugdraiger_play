const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');

const { createNavidromeStore } = require('../navidromeStore');

test('guarda la contraseña cifrada y devuelve sólo datos públicos', async (t) => {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'rugdraiger-navidrome-'));
  t.after(() => fs.rmSync(temp, { recursive: true, force: true }));
  const target = path.join(temp, 'navidrome.json');
  const safeStorage = {
    isAsyncEncryptionAvailable: async () => true,
    encryptStringAsync: async (value) => Buffer.from(`encrypted:${value}`, 'utf8'),
    decryptStringAsync: async (value) => ({ result: value.toString('utf8').replace(/^encrypted:/, ''), shouldReEncrypt: false }),
  };
  const store = createNavidromeStore({ configPath: () => target, safeStorage });
  await store.saveCredentials(
    { serverUrl: 'https://music.example', username: 'listener', password: 'never-plaintext' },
    { serverVersion: '0.55.0' },
  );

  const raw = fs.readFileSync(target, 'utf8');
  assert.equal(raw.includes('never-plaintext'), false);
  assert.deepEqual(await store.getCredentials(), {
    serverUrl: 'https://music.example',
    username: 'listener',
    password: 'never-plaintext',
  });
  const publicConfig = await store.getPublicConfig();
  assert.equal(publicConfig.connected, true);
  assert.equal('password' in publicConfig, false);
});
