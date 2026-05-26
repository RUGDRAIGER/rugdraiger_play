/** Lee sample rate, bit depth y bitrate aproximado desde cabeceras de archivo. */
export interface AudioTechnicalInfo {
  sampleRate?: number
  bitDepth?: number
  bitrate?: number
}

function readU32BE(view: DataView, offset: number): number {
  return view.getUint32(offset, false)
}

function parseFlac(buffer: ArrayBuffer): AudioTechnicalInfo {
  if (buffer.byteLength < 42) return {}
  const view = new DataView(buffer)
  const sig = String.fromCharCode(view.getUint8(0), view.getUint8(1), view.getUint8(2), view.getUint8(3))
  if (sig !== 'fLaC') return {}

  const blockHeader = view.getUint32(4, false)
  const isLast = (blockHeader & 0x80) !== 0
  const blockType = (blockHeader >> 24) & 0x7f
  if (blockType !== 0) return {}

  void isLast
  const data = readU32BE(view, 8)
  void data
  if (buffer.byteLength < 26) return {}

  const srRaw =
    (view.getUint8(18) << 12) |
    (view.getUint8(19) << 4) |
    (view.getUint8(20) >> 4)
  const bitDepth = ((view.getUint8(20) & 0x0e) >> 1) + 1

  return {
    sampleRate: srRaw > 0 ? srRaw : undefined,
    bitDepth: bitDepth >= 4 && bitDepth <= 32 ? bitDepth : undefined,
  }
}

function parseWav(buffer: ArrayBuffer): AudioTechnicalInfo {
  if (buffer.byteLength < 44) return {}
  const view = new DataView(buffer)
  const riff = String.fromCharCode(view.getUint8(0), view.getUint8(1), view.getUint8(2), view.getUint8(3))
  if (riff !== 'RIFF') return {}
  const sampleRate = view.getUint32(24, true)
  const bitDepth = view.getUint16(34, true)
  const byteRate = view.getUint32(28, true)
  return {
    sampleRate: sampleRate > 0 ? sampleRate : undefined,
    bitDepth: bitDepth > 0 ? bitDepth : undefined,
    bitrate: byteRate > 0 ? Math.round((byteRate * 8) / 1000) : undefined,
  }
}

function parseMp3Bitrate(buffer: ArrayBuffer, durationSec: number, fileSize: number): AudioTechnicalInfo {
  if (durationSec <= 0 || fileSize <= 0) return {}
  const kbps = Math.round(((fileSize * 8) / durationSec) / 1000)
  return kbps > 32 && kbps < 2000 ? { bitrate: kbps } : {}
}

export async function parseAudioTechnicalInfo(
  source: Blob | ArrayBuffer,
  ext: string,
  durationSec = 0,
  fileSize = 0,
): Promise<AudioTechnicalInfo> {
  const lower = ext.toLowerCase()
  let buffer: ArrayBuffer
  if (source instanceof ArrayBuffer) {
    buffer = source.slice(0, Math.min(source.byteLength, 65536))
  } else {
    buffer = await source.slice(0, 65536).arrayBuffer()
  }

  if (['flac'].includes(lower)) return parseFlac(buffer)
  if (['wav', 'wave'].includes(lower)) return parseWav(buffer)
  if (['mp3', 'aac', 'm4a', 'ogg', 'opus'].includes(lower)) {
    return parseMp3Bitrate(buffer, durationSec, fileSize)
  }
  return {}
}

export function formatAudioQuality(song: {
  format: string
  isLossless?: boolean
  sampleRate?: number | null
  bitDepth?: number | null
  bitrate?: number | null
}): string {
  const parts: string[] = [song.format.toUpperCase()]
  if (song.sampleRate && song.sampleRate > 0) {
    const khz = song.sampleRate >= 1000 ? song.sampleRate / 1000 : song.sampleRate
    parts.push(song.sampleRate >= 1000 ? `${khz % 1 === 0 ? khz.toFixed(0) : khz.toFixed(1)} kHz` : `${song.sampleRate} Hz`)
  }
  if (song.bitDepth && song.bitDepth > 0) parts.push(`${song.bitDepth}-bit`)
  else if (song.bitrate && song.bitrate > 0) parts.push(`${song.bitrate} kbps`)
  else if (song.isLossless) parts.push('Lossless')
  return parts.join(' · ')
}
