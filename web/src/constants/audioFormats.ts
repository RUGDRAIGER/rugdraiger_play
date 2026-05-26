/** Extensiones de audio reconocidas al escanear bibliotecas locales */
export const AUDIO_EXTENSIONS = [
  'mp3', 'mp2', 'mpa',
  'flac', 'wav', 'wave', 'aiff', 'aif', 'aifc', 'alac', 'caf',
  'aac', 'm4a', 'm4b', 'm4p', 'mp4',
  'ogg', 'oga', 'opus',
  'wma', 'wmv',
  'ape', 'wv', 'tta', 'mpc', 'mka', 'webm',
  'mid', 'midi', 'kar',
  '3gp', 'amr', 'dsf', 'dff',
] as const

export const LOSSLESS_FORMATS = ['flac', 'wav', 'wave', 'aiff', 'aif', 'aifc', 'alac', 'caf', 'ape', 'wv', 'tta', 'dsf', 'dff']

export const AUDIO_EXTENSION_SET = new Set<string>(AUDIO_EXTENSIONS)

export function getAudioMimeType(ext: string): string {
  const map: Record<string, string> = {
    mp3: 'audio/mpeg',
    flac: 'audio/flac',
    wav: 'audio/wav',
    wave: 'audio/wav',
    aiff: 'audio/aiff',
    aif: 'audio/aiff',
    alac: 'audio/mp4',
    m4a: 'audio/mp4',
    m4b: 'audio/mp4',
    aac: 'audio/aac',
    ogg: 'audio/ogg',
    oga: 'audio/ogg',
    opus: 'audio/opus',
    wma: 'audio/x-ms-wma',
    webm: 'audio/webm',
    mid: 'audio/midi',
    midi: 'audio/midi',
  }
  return map[ext.toLowerCase()] ?? 'audio/*'
}
