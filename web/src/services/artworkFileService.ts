import { dbService } from './dbService'

const urlCache = new Map<string, string>()

export async function resolveArtworkSrc(artwork?: string, songId?: string): Promise<string | undefined> {
  if (!artwork) return undefined

  if (artwork.startsWith('local://') && songId) {
    const cached = urlCache.get(songId)
    if (cached) return cached

    const blob = await dbService.getSongArtworkBlob(songId)
    if (!blob) return undefined

    const url = URL.createObjectURL(blob)
    urlCache.set(songId, url)
    return url
  }

  return artwork
}

export function cacheArtworkUrl(songId: string, url: string): void {
  urlCache.set(songId, url)
}

export function revokeArtworkUrl(songId: string): void {
  const url = urlCache.get(songId)
  if (url?.startsWith('blob:')) URL.revokeObjectURL(url)
  urlCache.delete(songId)
}

export function clearArtworkUrlCache(): void {
  for (const id of urlCache.keys()) revokeArtworkUrl(id)
}
