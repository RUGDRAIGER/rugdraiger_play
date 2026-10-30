const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');

const { assertAllowedPath, filterAllowedDirectories } = require('../pathSecurity');

test('permite archivos dentro de una raíz autorizada', (t) => {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'rugdraiger-paths-'));
  t.after(() => fs.rmSync(temp, { recursive: true, force: true }));
  const music = path.join(temp, 'Music');
  const file = path.join(music, 'song.flac');
  fs.mkdirSync(music);
  fs.writeFileSync(file, 'audio');

  assert.equal(assertAllowedPath(file, [music]), fs.realpathSync(file));
  assert.deepEqual(filterAllowedDirectories([music], [music]), [fs.realpathSync(music)]);
});

test('rechaza rutas externas y enlaces simbólicos que escapan de la raíz', (t) => {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'rugdraiger-paths-'));
  t.after(() => fs.rmSync(temp, { recursive: true, force: true }));
  const music = path.join(temp, 'Music');
  const outside = path.join(temp, 'private.txt');
  const link = path.join(music, 'escape.txt');
  fs.mkdirSync(music);
  fs.writeFileSync(outside, 'private');
  fs.symlinkSync(outside, link);

  assert.throws(() => assertAllowedPath(outside, [music]), /Acceso denegado/);
  assert.throws(() => assertAllowedPath(link, [music]), /Acceso denegado/);
});
