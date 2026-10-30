const assert = require('node:assert/strict');
const test = require('node:test');

const {
  buildApiUrl,
  fetchNavidromeLibrary,
  normalizeServerUrl,
  parseSubsonicResponse,
  pingNavidrome,
} = require('../navidromeClient');

const credentials = {
  serverUrl: 'https://music.example.com/',
  username: 'music-user',
  password: 'secret-value',
};

test('normaliza HTTPS y rechaza servidores inseguros', () => {
  assert.equal(normalizeServerUrl(credentials.serverUrl), 'https://music.example.com');
  assert.throws(() => normalizeServerUrl('http://example.com'), /HTTPS/);
  assert.equal(normalizeServerUrl('http://localhost:4533/'), 'http://localhost:4533');
});

test('crea autenticación Subsonic sin incluir la contraseña', () => {
  const url = buildApiUrl('ping', credentials);
  assert.equal(url.pathname, '/rest/ping.view');
  assert.equal(url.searchParams.get('u'), credentials.username);
  assert.equal(url.searchParams.get('v'), '1.16.1');
  assert.equal(url.searchParams.get('t')?.length, 32);
  assert.ok(url.searchParams.get('s'));
  assert.equal(url.href.includes(credentials.password), false);
});

test('interpreta ping correcto y errores del servidor', async () => {
  const expected = parseSubsonicResponse({
    'subsonic-response': { status: 'ok', version: '1.16.1', type: 'navidrome', serverVersion: '0.55.0' },
  });
  assert.equal(expected.serverType, 'navidrome');

  const result = await pingNavidrome(credentials, {
    fetchImpl: async () => ({
      ok: true,
      json: async () => ({ 'subsonic-response': { status: 'ok', version: '1.16.1', type: 'navidrome' } }),
    }),
  });
  assert.equal(result.apiVersion, '1.16.1');
  assert.throws(
    () => parseSubsonicResponse({ 'subsonic-response': { status: 'failed', error: { message: 'Wrong username' } } }),
    /Wrong username/,
  );
});

test('convierte el catálogo remoto en canciones reproducibles con carátula', async () => {
  const songs = await fetchNavidromeLibrary(credentials, undefined, {
    fetchImpl: async () => ({
      ok: true,
      json: async () => ({
        'subsonic-response': {
          status: 'ok',
          searchResult3: { song: [{
            id: 'track-1', title: 'Song', artist: 'Artist', album: 'Album',
            coverArt: 'cover-1', suffix: 'flac', duration: 180, size: 1234,
          }] },
        },
      }),
    }),
  });
  assert.equal(songs.length, 1);
  assert.equal(songs[0].source, 'navidrome');
  assert.equal(songs[0].streamUrl, 'rugdraiger-media://stream/track-1');
  assert.equal(songs[0].artwork, 'rugdraiger-media://cover/cover-1?size=600');
  assert.equal(songs[0].duration, 180000);
  assert.equal(songs[0].isLossless, true);
});
