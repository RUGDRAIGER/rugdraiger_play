import type { Song, ScanProgress } from '../types'

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

const AUDIO_EXTENSIONS = ['mp3', 'flac', 'aac', 'm4a', 'ogg', 'wav', 'opus', 'wma', 'aiff', 'alac']
const LOSSLESS_FORMATS = ['flac', 'wav', 'aiff', 'alac']

// Carpetas del sistema que se omiten en escaneos profundos (p. ej. disco C:)
const SKIP_DIR_NAMES = new Set([
  'windows', 'program files', 'program files (x86)', 'programdata',
  '$recycle.bin', 'system volume information', 'recovery', 'appdata',
  'node_modules', '.git', '.Trash', 'library', 'applications',
  'private', 'dev', 'proc', 'sys', 'tmp', 'temp', 'cache',
])

interface CollectState {
  foldersScanned: number
  audioFound: number
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type DirHandle = any

function generateId(file: File): string {
  return `${file.name}-${file.size}-${file.lastModified}`
    .replace(/[^a-zA-Z0-9]/g, '_')
    .substring(0, 64)
}

function getExtension(filename: string): string {
  return filename.split('.').pop()?.toLowerCase() ?? ''
}

function isAudioFile(file: File): boolean {
  return AUDIO_EXTENSIONS.includes(getExtension(file.name))
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
          resolve({
            title: tags.title as string | undefined,
            artist: tags.artist as string | undefined,
            album: tags.album as string | undefined,
            genre: tags.genre as string | undefined,
            track: parseInt(String(tags.track ?? ''), 10) || undefined,
            year: parseInt(String(tags.year ?? ''), 10) || undefined,
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

function nameFromFile(filename: string): string {
  return filename.replace(/\.[^.]+$/, '').replace(/[-_]/g, ' ')
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

    const title = tags.title || nameFromFile(file.name)
    const artist = tags.artist || 'Unknown Artist'
    const album = tags.album || 'Unknown Album'

    songs.push({
      id: generateId(file),
      title,
      artist,
      album,
      genre: tags.genre || '',
      duration,
      fileSize: file.size,
      trackNumber: tags.track || 0,
      format: ext,
      isLossless: LOSSLESS_FORMATS.includes(ext),
      dateAdded: Date.now(),
      artwork: tags.picture,
      file,
      filePath: (file as File & { webkitRelativePath?: string }).webkitRelativePath || file.name,
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
