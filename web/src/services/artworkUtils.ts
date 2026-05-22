export function isLocalArtworkRef(artwork?: string): boolean {
  return Boolean(artwork?.startsWith('local://'))
}

export function localArtworkRef(songId: string): string {
  return `local://${songId}`
}

export function dataUrlToBlob(dataUrl: string): Blob | null {
  try {
    const [header, base64] = dataUrl.split(',')
    if (!base64) return null
    const mime = header.match(/:(.*?);/)?.[1] ?? 'image/jpeg'
    const binary = atob(base64)
    const bytes = new Uint8Array(binary.length)
    for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i)
    return new Blob([bytes], { type: mime })
  } catch {
    return null
  }
}
