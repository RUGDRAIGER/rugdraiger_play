import type { Song, ScanProgress } from '../types'
import {
  AUDIO_EXTENSION_SET,
  LOSSLESS_FORMATS,
} from '../constants/audioFormats'
import { getElectronPathFromFile, generateSongIdForFile } from './electronPathUtils'
import type { ElectronLocalFileEntry } from '../types/electron'
import { getAudioMimeType } from '../constants/audioFormats'

interface JsMediaTags {
  read: (file: File, callbacks: {
    onSuccess: (tag: { tags: Record<string, unknown> }) => void
    onError: () => void
  }) => void
}

function getJsmediatags(): JsMediaTags | null {
  const lib = (window as Window & { jsmediatags?: JsMediaTags }).jsmediatags
  return lib ?? null
}

const AUDIO_EXTENSIONS = Array.from(AUDIO_EXTENSION_SET)

// Carpetas del sistema que se omiten en escaneos profundos
const SKIP_DIR_NAMES = new Set([
  'windows', 'program files', 'program files (x86)', 'programdata',
  '$recycle.bin', 'system volume information', 'recovery',
  'node_modules', '.git', '.trash', '.trashes',
  'applications', 'system', 'private', 'dev', 'proc', 'sys',
  'tmp', 'temp', 'cache', 'caches', 'logs',
  '.spotlight-v100', '.fseventsd', '.documentrevisions-v100',
  'photos library.photoslibrary', 'photolibary', 'mail', 'containers',
])

interface CollectState {
  foldersScanned: number
  audioFound: number
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type DirHandle = any

function generateId(file: File): string {
  const electronPath = getElectronPathFromFile(file)
  if (electronPath) return generateSongIdForFile(file, electronPath)
  return generateSongIdForFile(file)
}

function getExtension(filename: string): string {
  return filename.split('.').pop()?.toLowerCase() ?? ''
}

function isAudioFile(file: File): boolean {
  const ext = getExtension(file.name)
  if (AUDIO_EXTENSION_SET.has(ext)) return true
  if (file.type.startsWith('audio/')) return true
  return false
}

function shouldSkipDirectory(name: string): boolean {
  return SKIP_DIR_NAMES.has(name.toLowerCase())
}

function getScanErrorMessage(error: unknown): string {
  if (error instanceof DOMException) {
    if (error.name === 'AbortError') return ''
    if (error.name === 'NotAllowedError') {
      return 'Permiso denegado. Acepta el acceso de lectura cuando el navegador lo solicite.'
    }
    if (error.name === 'SecurityError') {
      return 'No se puede acceder a esa ubicación por restricciones del navegador.'
    }
  }
  if (error instanceof Error) {
    if (error.name === 'AbortError') return ''
    return error.message
  }
  return String(error)
}

async function ensureReadPermission(handle: DirHandle): Promise<boolean> {
  if (typeof handle.queryPermission !== 'function') return true

  let permission = await handle.queryPermission({ mode: 'read' })
  if (permission === 'granted') return true

  if (permission === 'prompt' && typeof handle.requestPermission === 'function') {
    permission = await handle.requestPermission({ mode: 'read' })
  }

  return permission === 'granted'
}

function getAudioDuration(file: File): Promise<number> {
  return new Promise((resolve) => {
    const url = URL.createObjectURL(file)
    const audio = new Audio()
    audio.addEventListener('loadedmetadata', () => {
      URL.revokeObjectURL(url)
      resolve(Math.round(audio.duration * 1000))
    })
    audio.addEventListener('error', () => {
      URL.revokeObjectURL(url)
      resolve(0)
    })
    audio.src = url
  })
}

function normalizeImageData(data: unknown): Uint8Array | null {
  if (!data) return null
  if (data instanceof Uint8Array) return data
  if (data instanceof ArrayBuffer) return new Uint8Array(data)
  if (Array.isArray(data)) return new Uint8Array(data)
  if (typeof data === 'object' && data !== null && 'length' in data) {
    const length = (data as { length: number }).length
    if (typeof length === 'number' && length > 0) {
      try {
        return Uint8Array.from(data as ArrayLike<number>)
      } catch {
        return null
      }
    }
  }
  if (typeof data === 'object' && data !== null && 'buffer' in data) {
    const view = data as { buffer: ArrayBuffer; byteOffset?: number; byteLength?: number; length?: number }
    if (view.buffer instanceof ArrayBuffer) {
      const length = view.byteLength ?? view.length ?? view.buffer.byteLength
      return new Uint8Array(view.buffer, view.byteOffset ?? 0, length)
    }
  }
  return null
}

function bytesToDataUrl(data: number[] | Uint8Array, format: string): string {
  const bytes = normalizeImageData(data)
  if (!bytes?.length) throw new Error('empty image data')

  let binary = ''
  const chunk = 8192
  for (let i = 0; i < bytes.length; i += chunk) {
    binary += String.fromCharCode(...bytes.subarray(i, i + chunk))
  }
  const mime = format.includes('/') ? format : `image/${format.replace(/^image\//, '')}`
  return `data:${mime};base64,${btoa(binary)}`
}

function extractPicture(tags: Record<string, unknown>): string | undefined {
  const picture = tags.picture ?? tags.APIC ?? tags.image
  if (!picture) return undefined

  const frame = Array.isArray(picture) ? picture[0] : picture
  if (!frame || typeof frame !== 'object') return undefined

  const { data, format } = frame as { data?: unknown; format?: string }
  if (!format) return undefined

  try {
    return bytesToDataUrl(data as number[] | Uint8Array, format)
  } catch {
    return undefined
  }
}

function readTagsFromFile(file: File): Promise<{
  title?: string
  artist?: string
  album?: string
  genre?: string
  track?: number
  year?: number
  composer?: string
  replayGain?: number | null
  lyrics?: string
  picture?: string
}> {
  return new Promise((resolve) => {
    try {
      const jsmediatags = getJsmediatags()
      if (!jsmediatags) {
        resolve({})
        return
      }
      jsmediatags.read(file, {
        onSuccess: (tag: { tags: Record<string, unknown> }) => {
          const tags = tag.tags
          const lyricsRaw = tags.unsynchronisedLyrics ?? tags.lyrics ?? tags.USLT
          let lyrics = ''
          if (typeof lyricsRaw === 'string') lyrics = lyricsRaw
          else if (lyricsRaw && typeof lyricsRaw === 'object' && 'lyrics' in lyricsRaw) {
            lyrics = String((lyricsRaw as { lyrics: string }).lyrics ?? '')
          }
          resolve({
            title: tags.title as string | undefined,
            artist: tags.artist as string | undefined,
            album: tags.album as string | undefined,
            genre: tags.genre as string | undefined,
            track: parseInt(String(tags.track ?? ''), 10) || undefined,
            year: parseInt(String(tags.year ?? ''), 10) || undefined,
            composer: (tags.composer ?? tags.TPE3) as string | undefined,
            replayGain: parseReplayGain(tags),
            lyrics: lyrics || undefined,
            picture: extractPicture(tags),
          })
        },
        onError: () => resolve({}),
      })
    } catch {
      resolve({})
    }
  })
}

function parseReplayGain(tags: Record<string, unknown>): number | null {
  const candidates = [
    tags.REPLAYGAIN_TRACK_GAIN,
    tags.replaygain_track_gain,
    tags['TXXX:REPLAYGAIN_TRACK_GAIN'],
  ]
  for (const raw of candidates) {
    if (raw == null) continue
    const str = String(raw)
    const match = str.match(/(-?\d+(?:\.\d+)?)\s*dB/i)
    if (match) return parseFloat(match[1])
  }
  return null
}

function nameFromFile(filename: string): string {
  return filename.replace(/\.[^.]+$/, '').replace(/[-_]/g, ' ')
}

const GENERIC_FOLDER_NAMES = new Set([
  'music', 'música', 'musica', 'downloads', 'descargas', 'audio', 'songs', 'canciones',
  'albums', 'álbumes', 'albumes', 'mp3', 'flac', 'media', 'my music', 'mi musica',
  'telegram', 'whatsapp', 'documents', 'dcim', 'misc', 'ringtones', 'notifications',
])

function cleanSegment(value: string): string {
  return value.replace(/[-_]+/g, ' ').replace(/\s+/g, ' ').trim()
}

function isGenericFolder(name: string): boolean {
  const normalized = cleanSegment(name).toLowerCase()
  return !normalized || GENERIC_FOLDER_NAMES.has(normalized)
}

function stripTrackPrefix(name: string): { track?: number; rest: string } {
  const match = name.match(/^(\d{1,3})[\s.\-_]+(.+)$/)
  if (match) return { track: parseInt(match[1], 10), rest: match[2].trim() }
  return { rest: name.trim() }
}

function parseFilenameMetadata(
  nameWithoutExt: string,
  parentFolder?: string,
): { title?: string; artist?: string; album?: string; track?: number } {
  const { track: leadingTrack, rest: withoutLeadingTrack } = stripTrackPrefix(nameWithoutExt)
  let track = leadingTrack
  let rest = withoutLeadingTrack

  const bracketMatch = rest.match(/^(.+?)\s*[\[\(]([^\]\)]+)[\]\)]\s*(.+)$/)
  if (bracketMatch) {
    return {
      artist: cleanSegment(bracketMatch[1]),
      album: cleanSegment(bracketMatch[2]),
      title: cleanSegment(bracketMatch[3]),
      track,
    }
  }

  if (rest.includes(' - ')) {
    const parts = rest.split(' - ').map((p) => cleanSegment(p)).filter(Boolean)
    if (parts.length >= 3) {
      return {
        artist: parts[0],
        album: parts[1],
        title: parts.slice(2).join(' - '),
        track,
      }
    }
    if (parts.length === 2) {
      const [first, second] = parts
      const secondParsed = stripTrackPrefix(second)
      if (secondParsed.track !== undefined) {
        track = track ?? secondParsed.track
        return { album: first, title: secondParsed.rest, track }
      }
      if (parentFolder && cleanSegment(parentFolder).toLowerCase() === first.toLowerCase()) {
        return { album: first, title: second, track }
      }
      return { artist: first, title: second, track }
    }
  }

  const underscoreParts = rest.split('_').map((p) => cleanSegment(p)).filter(Boolean)
  if (underscoreParts.length >= 3 && /^\d{1,2}$/.test(underscoreParts[1])) {
    return {
      album: underscoreParts[0],
      title: underscoreParts.slice(2).join(' '),
      track: track ?? parseInt(underscoreParts[1], 10),
    }
  }

  return { title: cleanSegment(rest), track }
}

function getPathSegments(file: File): string[] {
  const relative = (file as File & { webkitRelativePath?: string }).webkitRelativePath || file.name
  return relative.replace(/\\/g, '/').split('/').filter(Boolean)
}

function inferMetadataFromPath(file: File): { title?: string; artist?: string; album?: string; track?: number } {
  const segments = getPathSegments(file)
  if (segments.length === 0) return {}

  const filename = segments[segments.length - 1]
  const nameWithoutExt = filename.replace(/\.[^.]+$/, '')
  const folders = segments.slice(0, -1).map(cleanSegment).filter(Boolean)
  const meaningfulFolders = folders.filter((f) => !isGenericFolder(f))

  const parentFolder = meaningfulFolders[meaningfulFolders.length - 1]
  const artistFolder = meaningfulFolders.length >= 2 ? meaningfulFolders[meaningfulFolders.length - 2] : undefined

  const fromName = parseFilenameMetadata(nameWithoutExt, parentFolder)

  return {
    title: fromName.title,
    artist: fromName.artist ?? artistFolder,
    album: fromName.album ?? parentFolder,
    track: fromName.track,
  }
}

function resolveSongMetadata(
  file: File,
  tags: { title?: string; artist?: string; album?: string; track?: number; year?: number },
) {
  const inferred = inferMetadataFromPath(file)
  const title = tags.title || inferred.title || nameFromFile(file.name)
  const artist = tags.artist || inferred.artist || 'Unknown Artist'
  const album = tags.album || inferred.album || 'Unknown Album'
  const trackNumber = tags.track || inferred.track || 0
  const year = tags.year || 0
  return { title, artist, album, trackNumber, year }
}

export function supportsDirectoryPicker(): boolean {
  return 'showDirectoryPicker' in window
}

export function filterAudioFiles(files: File[] | FileList): File[] {
  return Array.from(files).filter(isAudioFile)
}

export async function scanFiles(
  files: File[],
  onProgress?: (p: ScanProgress) => void,
): Promise<Song[]> {
  const audioFiles = files.filter(isAudioFile)
  const songs: Song[] = []

  for (let i = 0; i < audioFiles.length; i++) {
    const file = audioFiles[i]
    onProgress?.({
      total: audioFiles.length,
      processed: i,
      current: file.name,
      phase: 'processing',
    })

    const ext = getExtension(file.name)
    const [tags, duration] = await Promise.all([readTagsFromFile(file), getAudioDuration(file)])
    const { title, artist, album, trackNumber, year } = resolveSongMetadata(file, tags)

    const electronPath = getElectronPathFromFile(file)
    songs.push({
      id: generateId(file),
      title,
      artist,
      album,
      genre: tags.genre || '',
      duration,
      fileSize: file.size,
      trackNumber,
      format: ext,
      isLossless: LOSSLESS_FORMATS.includes(ext),
      dateAdded: Date.now(),
      year,
      composer: tags.composer || '',
      isFavorite: false,
      playCount: 0,
      lastPlayed: 0,
      replayGain: tags.replayGain ?? null,
      lyrics: tags.lyrics || '',
      artwork: tags.picture,
      file,
      filePath: electronPath || (file as File & { webkitRelativePath?: string }).webkitRelativePath || file.name,
    })
  }

  onProgress?.({
    total: audioFiles.length,
    processed: audioFiles.length,
    current: '',
    phase: 'processing',
  })
  return songs
}

async function collectFiles(
  handle: DirHandle,
  files: File[],
  onProgress?: (p: ScanProgress) => void,
  state: CollectState = { foldersScanned: 0, audioFound: 0 },
  path = '',
): Promise<void> {
  const granted = await ensureReadPermission(handle)
  if (!granted) return

  state.foldersScanned += 1
  const folderLabel = path || handle.name || 'Raíz'

  onProgress?.({
    total: state.audioFound,
    processed: 0,
    current: folderLabel,
    phase: 'discovering',
    foldersScanned: state.foldersScanned,
  })

  try {
    for await (const entry of handle.values()) {
      if (entry.kind === 'file') {
        try {
          const file = await entry.getFile()
          if (isAudioFile(file)) {
            files.push(file)
            state.audioFound += 1
            onProgress?.({
              total: state.audioFound,
              processed: 0,
              current: `${folderLabel} · ${file.name}`,
              phase: 'discovering',
              foldersScanned: state.foldersScanned,
            })
          }
        } catch {
          // Archivo protegido o inaccesible — continuar
        }
      } else if (entry.kind === 'directory') {
        if (shouldSkipDirectory(entry.name)) continue
        try {
          const subPath = path ? `${path}/${entry.name}` : entry.name
          await collectFiles(entry, files, onProgress, state, subPath)
        } catch {
          // Carpeta protegida — continuar con el resto del disco
        }
      }
    }
  } catch {
    // Carpeta no legible
  }
}

export async function scanDirectory(
  onProgress?: (p: ScanProgress) => void,
): Promise<File[]> {
  if (!supportsDirectoryPicker()) {
    throw new Error('Usa Chrome o Edge, o el botón "Escanear carpeta" con selección de directorio.')
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const win = window as any
  const dirHandle: DirHandle = await win.showDirectoryPicker({
    mode: 'read',
    startIn: 'music',
  })

  const granted = await ensureReadPermission(dirHandle)
  if (!granted) {
    throw new Error('Se necesita permiso de lectura para escanear el disco o carpeta seleccionada.')
  }

  onProgress?.({
    total: 0,
    processed: 0,
    current: dirHandle.name || 'Iniciando escaneo...',
    phase: 'discovering',
    foldersScanned: 0,
  })

  const files: File[] = []
  await collectFiles(dirHandle, files, onProgress)

  onProgress?.({
    total: files.length,
    processed: 0,
    current: `${files.length} archivos de audio encontrados`,
    phase: 'discovering',
  })

  return files
}

function getExtensionFromName(filename: string): string {
  return filename.split('.').pop()?.toLowerCase() ?? ''
}

async function getAudioDurationFromUrl(fileUrl: string): Promise<number> {
  return new Promise((resolve) => {
    const audio = new Audio()
    const cleanup = () => {
      audio.removeEventListener('loadedmetadata', onReady)
      audio.removeEventListener('error', onError)
    }
    const onReady = () => {
      cleanup()
      resolve(Math.round(audio.duration * 1000))
    }
    const onError = () => {
      cleanup()
      resolve(0)
    }
    audio.addEventListener('loadedmetadata', onReady)
    audio.addEventListener('error', onError)
    audio.src = fileUrl
  })
}

/** Procesa entradas del escaneo nativo (solo metadatos; reproducción por ruta local). */
export async function scanElectronEntries(
  entries: ElectronLocalFileEntry[],
  onProgress?: (p: ScanProgress) => void,
): Promise<Song[]> {
  const api = window.electronAPI
  if (!api) return []

  const songs: Song[] = []

  for (let i = 0; i < entries.length; i++) {
    const entry = entries[i]
    onProgress?.({
      total: entries.length,
      processed: i,
      current: entry.name,
      phase: 'processing',
    })

    const ext = getExtensionFromName(entry.name)
    let tags: Awaited<ReturnType<typeof readTagsFromFile>> = {}
    let duration = 0

    try {
      const fileUrl = await api.getLocalFileUrl(entry.path)
      duration = await getAudioDurationFromUrl(fileUrl)

      const buffer = await api.readLocalFile(entry.path)
      const pseudoFile = new File([buffer], entry.name, {
        type: getAudioMimeType(ext),
        lastModified: entry.mtime,
      })
      Object.defineProperty(pseudoFile, 'webkitRelativePath', {
        value: entry.path,
        configurable: true,
      })
      tags = await readTagsFromFile(pseudoFile)
    } catch {
      // Sin permiso o formato ilegible — usar metadatos mínimos desde la ruta
    }

    const pseudoForMeta = { name: entry.name } as File
    Object.defineProperty(pseudoForMeta, 'webkitRelativePath', {
      value: entry.path,
      configurable: true,
    })
    const inferred = inferMetadataFromPath(pseudoForMeta)
    const { title, artist, album, trackNumber, year } = resolveSongMetadata(
      pseudoForMeta,
      { ...tags, ...inferred },
    )

    songs.push({
      id: generateSongIdForFile(pseudoForMeta, entry.path),
      title,
      artist,
      album,
      genre: tags.genre || '',
      duration,
      fileSize: entry.size,
      trackNumber,
      format: ext,
      isLossless: LOSSLESS_FORMATS.includes(ext),
      dateAdded: Date.now(),
      year,
      composer: tags.composer || '',
      isFavorite: false,
      playCount: 0,
      lastPlayed: 0,
      replayGain: tags.replayGain ?? null,
      lyrics: tags.lyrics || '',
      artwork: tags.picture,
      filePath: entry.path,
    })

    if (i > 0 && i % 8 === 0) {
      await new Promise((r) => setTimeout(r, 0))
    }
  }

  onProgress?.({
    total: entries.length,
    processed: entries.length,
    current: '',
    phase: 'processing',
  })

  return songs
}

export function formatDuration(ms: number): string {
  if (!ms || isNaN(ms)) return '0:00'
  const totalSeconds = Math.floor(ms / 1000)
  const minutes = Math.floor(totalSeconds / 60)
  const seconds = totalSeconds % 60
  return `${minutes}:${seconds.toString().padStart(2, '0')}`
}

export function formatFileSize(bytes: number): string {
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

export function formatSongFormat(format: string, isLossless?: boolean): string {
  const ext = format.trim().toUpperCase()
  if (!ext) return '—'
  return isLossless ? `${ext} · LOSSLESS` : ext
}

export { getScanErrorMessage }
