import type { Song } from '../types'
import { dbService } from './dbService'
import { getElectronLocalFileUrl } from './electronBridgeService'

const blobCache = new Map<string, Blob>()

export function cacheSongFile(song: Song): void {
  if (song.file) blobCache.set(song.id, song.file)
}

export function cacheSongFiles(songs: Song[]): void {
  for (const song of songs) cacheSongFile(song)
}

export async function resolveSongBlob(song: Song): Promise<Blob | null> {
  if (song.file) {
    blobCache.set(song.id, song.file)
    return song.file
  }

  const cached = blobCache.get(song.id)
  if (cached) return cached

  if (song.filePath && song.filePath.startsWith('/')) {
    const url = await getElectronLocalFileUrl(song.filePath)
    if (url) {
      const response = await fetch(url)
      if (response.ok) {
        const blob = await response.blob()
        blobCache.set(song.id, blob)
        return blob
      }
    }
  }

  const blob = await dbService.getSongBlob(song.id)
  if (blob) {
    blobCache.set(song.id, blob)
    return blob
  }

  return null
}

export function clearSongBlobCache(): void {
  blobCache.clear()
}

export function removeSongFromCache(songId: string): void {
  blobCache.delete(songId)
}
