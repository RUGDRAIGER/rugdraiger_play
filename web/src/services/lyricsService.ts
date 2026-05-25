export interface LyricLine {
  timeMs: number
  text: string
}

export function parseLrc(content: string): LyricLine[] {
  const lines: LyricLine[] = []
  for (const raw of content.split('\n')) {
    const line = raw.trim()
    const match = line.match(/^\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\](.*)$/)
    if (!match) continue
    const mins = parseInt(match[1], 10)
    const secs = parseInt(match[2], 10)
    const ms = match[3] ? parseInt(match[3].padEnd(3, '0').slice(0, 3), 10) : 0
    const text = match[4].trim()
    if (!text) continue
    lines.push({ timeMs: (mins * 60 + secs) * 1000 + ms, text })
  }
  return lines.sort((a, b) => a.timeMs - b.timeMs)
}

export function isLrcContent(content: string): boolean {
  return /\[\d{1,2}:\d{2}/.test(content)
}

export function getActiveLyricLine(lines: LyricLine[], timeMs: number): number {
  if (!lines.length) return -1
  let idx = -1
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].timeMs <= timeMs) idx = i
    else break
  }
  return idx
}

export function findLrcFileForSong(songPath: string, lrcFiles: File[]): File | undefined {
  const base = songPath.replace(/\.[^.]+$/, '').toLowerCase()
  return lrcFiles.find((f) => {
    const lrcBase = f.name.replace(/\.lrc$/i, '').toLowerCase()
    return lrcBase === base.split('/').pop() || base.endsWith(lrcBase)
  })
}
