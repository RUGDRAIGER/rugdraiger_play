const fsp = require('node:fs/promises');
const path = require('node:path');

function createNavidromeStore({ configPath, safeStorage }) {
  async function readRecord() {
    try {
      const raw = await fsp.readFile(configPath(), 'utf8');
      const record = JSON.parse(raw);
      return record && record.version === 1 ? record : null;
    } catch (error) {
      if (error?.code === 'ENOENT') return null;
      throw new Error('No se pudo leer la configuración segura de Navidrome');
    }
  }

  async function writeRecord(record) {
    const target = configPath();
    const temporary = `${target}.tmp`;
    await fsp.mkdir(path.dirname(target), { recursive: true });
    await fsp.writeFile(temporary, JSON.stringify(record, null, 2), { encoding: 'utf8', mode: 0o600 });
    await fsp.rename(temporary, target);
    await fsp.chmod(target, 0o600);
  }

  async function decryptPassword(record) {
    const encrypted = Buffer.from(record.encryptedPassword, 'base64');
    const decrypted = await safeStorage.decryptStringAsync(encrypted);
    if (decrypted.shouldReEncrypt) {
      const refreshed = await safeStorage.encryptStringAsync(decrypted.result);
      await writeRecord({ ...record, encryptedPassword: refreshed.toString('base64') });
    }
    return decrypted.result;
  }

  async function getCredentials() {
    const record = await readRecord();
    if (!record?.serverUrl || !record?.username || !record?.encryptedPassword) return null;
    return {
      serverUrl: record.serverUrl,
      username: record.username,
      password: await decryptPassword(record),
    };
  }

  async function getPublicConfig() {
    const record = await readRecord();
    if (!record?.serverUrl || !record?.username || !record?.encryptedPassword) {
      return { connected: false, serverUrl: '', username: '', lastVerifiedAt: '', serverVersion: '' };
    }
    return {
      connected: true,
      serverUrl: record.serverUrl,
      username: record.username,
      lastVerifiedAt: record.lastVerifiedAt || '',
      serverVersion: record.serverVersion || '',
    };
  }

  async function saveCredentials(credentials, connectionInfo) {
    if (!(await safeStorage.isAsyncEncryptionAvailable())) {
      throw new Error('El llavero seguro de macOS no está disponible');
    }
    const encrypted = await safeStorage.encryptStringAsync(credentials.password);
    await writeRecord({
      version: 1,
      serverUrl: credentials.serverUrl,
      username: credentials.username,
      encryptedPassword: encrypted.toString('base64'),
      lastVerifiedAt: new Date().toISOString(),
      serverVersion: connectionInfo.serverVersion || '',
    });
    return getPublicConfig();
  }

  async function clear() {
    try {
      await fsp.rm(configPath(), { force: true });
    } catch {
      throw new Error('No se pudieron eliminar las credenciales de Navidrome');
    }
  }

  return { clear, getCredentials, getPublicConfig, saveCredentials };
}

module.exports = { createNavidromeStore };
