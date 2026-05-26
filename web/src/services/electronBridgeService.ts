import type { Song } from '../types'
import type { ElectronPlayerStatePayload } from '../types/electron'
import { isMacDesktop } from '../utils/platform'
import { resolveArtworkSrc } from './artworkFileService'

export function bindElectronNotchCommands(handlers: {
  onPlayPause: () => void
  onNext: () => void
  onPrev: () => void
  onFocus?: () => void
}): (() => void) | undefined {
  if (!isMacDesktop || !window.electronAPI?.onNotchCommand) return undefined

  return window.electronAPI.onNotchCommand((command) => {
    if (command === 'play-pause') handlers.onPlayPause()
    else if (command === 'next') handlers.onNext()
    else if (command === 'prev') handlers.onPrev()
    else if (command === 'focus') handlers.onFocus?.()
  })
}

export async function syncElectronPlayerState(
  song: Song | null,
  isPlaying: boolean,
): Promise<void> {
  if (!isMacDesktop || !window.electronAPI?.sendPlayerState) return

  let artwork: string | undefined
  if (song?.artwork) {
    artwork = await resolveArtworkSrc(song.artwork, song.id)
  }

  const payload: ElectronPlayerStatePayload = {
    hasTrack: !!song,
    title: song?.title ?? '',
    artist: song?.artist ?? '',
    isPlaying,
    artwork,
  }

  window.electronAPI.sendPlayerState(payload)
}

export async function getElectronLocalFileUrl(filePath: string): Promise<string | null> {
  if (!window.electronAPI?.getLocalFileUrl) return null
  try {
    return await window.electronAPI.getLocalFileUrl(filePath)
  } catch {
    return null
  }
}
