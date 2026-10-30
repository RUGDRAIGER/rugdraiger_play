const crypto = require('node:crypto');

const CLIENT_NAME = 'RugdraigerPlay';
const API_VERSION = '1.16.1';

function normalizeServerUrl(value) {
  if (typeof value !== 'string' || value.length > 2048) {
    throw new TypeError('La URL del servidor no es válida');
  }

  let parsed;
  try {
    parsed = new URL(value.trim());
  } catch {
    throw new TypeError('La URL del servidor no es válida');
  }

  const isLocalHttp = parsed.protocol === 'http:' && ['localhost', '127.0.0.1', '::1'].includes(parsed.hostname);
  if (parsed.protocol !== 'https:' && !isLocalHttp) {
    throw new Error('Navidrome debe usar HTTPS (HTTP sólo se permite en localhost)');
  }
  if (parsed.username || parsed.password || parsed.search || parsed.hash) {
    throw new Error('La URL no debe incluir credenciales, parámetros ni fragmentos');
  }

  parsed.pathname = parsed.pathname.replace(/\/+$/, '');
  return parsed.toString().replace(/\/$/, '');
}

function normalizeUsername(value) {
  if (typeof value !== 'string') throw new TypeError('El usuario es obligatorio');
  const username = value.trim();
  if (!username || username.length > 256) throw new TypeError('El usuario es obligatorio');
  return username;
}

function validatePassword(value) {
  if (typeof value !== 'string' || value.length === 0 || value.length > 4096) {
    throw new TypeError('La contraseña es obligatoria');
  }
  return value;
}

function buildApiUrl(method, credentials, extraParams = {}) {
  if (!/^[A-Za-z][A-Za-z0-9]*$/.test(method)) throw new TypeError('Método Navidrome inválido');
  const serverUrl = normalizeServerUrl(credentials.serverUrl);
  const username = normalizeUsername(credentials.username);
  const password = validatePassword(credentials.password);
  const salt = crypto.randomBytes(12).toString('hex');
  const token = crypto.createHash('md5').update(password + salt, 'utf8').digest('hex');
  const url = new URL(serverUrl);
  url.pathname = `${url.pathname.replace(/\/$/, '')}/rest/${method}.view`;
  url.searchParams.set('u', username);
  url.searchParams.set('t', token);
  url.searchParams.set('s', salt);
  url.searchParams.set('v', API_VERSION);
  url.searchParams.set('c', CLIENT_NAME);
  url.searchParams.set('f', 'json');
  for (const [key, value] of Object.entries(extraParams)) {
    if (value !== undefined && value !== null) url.searchParams.set(key, String(value));
  }
  return url;
}

function parseSubsonicResponse(payload) {
  const response = payload?.['subsonic-response'];
  if (!response || typeof response !== 'object') {
    throw new Error('El servidor no devolvió una respuesta Subsonic válida');
  }
  if (response.status !== 'ok') {
    const message = response.error?.message || 'Credenciales incorrectas o acceso denegado';
    throw new Error(message);
  }
  return {
    apiVersion: String(response.version || API_VERSION),
    serverType: String(response.type || 'Navidrome'),
    serverVersion: response.serverVersion ? String(response.serverVersion) : '',
    openSubsonic: response.openSubsonic === true,
  };
}

function unwrapSubsonicResponse(payload) {
  const response = payload?.['subsonic-response'];
  if (!response || typeof response !== 'object') {
    throw new Error('El servidor no devolvió una respuesta Subsonic válida');
  }
  if (response.status !== 'ok') {
    throw new Error(response.error?.message || 'Navidrome rechazó la solicitud');
  }
  return response;
}

async function fetchJson(method, credentials, params = {}, options = {}) {
  const fetchImpl = options.fetchImpl || globalThis.fetch;
  if (typeof fetchImpl !== 'function') throw new Error('Este sistema no permite conexiones HTTP');
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), options.timeoutMs || 15000);
  try {
    const response = await fetchImpl(buildApiUrl(method, credentials, params), {
      method: 'GET',
      signal: controller.signal,
      headers: { Accept: 'application/json' },
      redirect: 'error',
    });
    if (!response.ok) throw new Error(`El servidor respondió HTTP ${response.status}`);
    return unwrapSubsonicResponse(await response.json());
  } catch (error) {
    if (error?.name === 'AbortError') throw new Error('La conexión con Navidrome agotó el tiempo de espera');
    throw error;
  } finally {
    clearTimeout(timeout);
  }
}

function safeText(value, fallback, maxLength = 1000) {
  const text = typeof value === 'string' ? value.trim() : '';
  return (text || fallback).slice(0, maxLength);
}

function mapRemoteSong(item) {
  const remoteId = safeText(item?.id, '', 256);
  if (!remoteId) return null;
  const suffix = safeText(item.suffix, '', 16).toLowerCase();
  const coverArtId = safeText(item.coverArt || item.albumId || '', '', 256);
  const lossless = ['flac', 'alac', 'wav', 'wave', 'aiff', 'aif', 'ape', 'wv', 'dsf', 'dff'].includes(suffix);
  const createdAt = Date.parse(item.created || '');
  return {
    id: `navidrome:${remoteId}`,
    source: 'navidrome',
    remoteId,
    coverArtId: coverArtId || undefined,
    title: safeText(item.title, 'Sin título'),
    artist: safeText(item.artist || item.albumArtist, 'Artista desconocido'),
    album: safeText(item.album, 'Álbum desconocido'),
    genre: safeText(item.genre, 'Sin género'),
    // Subsonic expresa la duración en segundos; el modelo de la app usa ms.
    duration: Number.isFinite(Number(item.duration)) ? Math.max(0, Number(item.duration) * 1000) : 0,
    fileSize: Number.isFinite(Number(item.size)) ? Number(item.size) : 0,
    trackNumber: Number.isFinite(Number(item.track)) ? Number(item.track) : 0,
    format: suffix || safeText(item.contentType?.split('/').pop(), 'audio', 16),
    isLossless: lossless,
    dateAdded: Number.isFinite(createdAt) ? createdAt : 0,
    year: Number.isFinite(Number(item.year)) ? Number(item.year) : undefined,
    bitrate: Number.isFinite(Number(item.bitRate)) ? Number(item.bitRate) * 1000 : null,
    isFavorite: Boolean(item.starred),
    artwork: coverArtId ? `rugdraiger-media://cover/${encodeURIComponent(coverArtId)}?size=600` : undefined,
    streamUrl: `rugdraiger-media://stream/${encodeURIComponent(remoteId)}`,
  };
}

async function fetchNavidromeLibrary(credentials, onProgress, options = {}) {
  const pageSize = 500;
  const maxSongs = 100000;
  const songs = [];
  let offset = 0;
  while (offset < maxSongs) {
    const response = await fetchJson('search3', credentials, {
      query: '',
      artistCount: 0,
      albumCount: 0,
      songCount: pageSize,
      songOffset: offset,
    }, options);
    const page = Array.isArray(response.searchResult3?.song) ? response.searchResult3.song : [];
    for (const item of page) {
      const song = mapRemoteSong(item);
      if (song) songs.push(song);
    }
    offset += page.length;
    onProgress?.({ imported: songs.length, current: page.at(-1)?.title || '' });
    if (page.length < pageSize) break;
  }
  if (offset >= maxSongs) throw new Error('La biblioteca supera el límite de seguridad de 100.000 canciones');
  return songs;
}

async function pingNavidrome(credentials, options = {}) {
  const response = await fetchJson('ping', credentials, {}, { ...options, timeoutMs: options.timeoutMs || 10000 });
  return parseSubsonicResponse({ 'subsonic-response': response });
}

module.exports = {
  API_VERSION,
  buildApiUrl,
  fetchNavidromeLibrary,
  mapRemoteSong,
  normalizeServerUrl,
  normalizeUsername,
  parseSubsonicResponse,
  pingNavidrome,
  validatePassword,
};
