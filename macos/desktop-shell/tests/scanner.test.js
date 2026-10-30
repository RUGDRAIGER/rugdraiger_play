const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');

const { dedupePaths, scanMusicPaths } = require('../scanner');

test('descubre audio, evita duplicados y omite carpetas pesadas', async (t) => {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'rugdraiger-scan-'));
  t.after(() => fs.rmSync(temp, { recursive: true, force: true }));
  fs.mkdirSync(path.join(temp, 'album'));
  fs.mkdirSync(path.join(temp, 'node_modules'));
  fs.writeFileSync(path.join(temp, 'album', 'song.flac'), 'audio');
  fs.writeFileSync(path.join(temp, 'album', 'cover.jpg'), 'image');
  fs.writeFileSync(path.join(temp, 'node_modules', 'hidden.mp3'), 'audio');

  assert.deepEqual(dedupePaths([temp, temp]), [temp]);
  const files = await scanMusicPaths([temp]);
  assert.equal(files.length, 1);
  assert.equal(files[0].name, 'song.flac');
});
