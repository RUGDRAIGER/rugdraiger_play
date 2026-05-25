import type { Song } from '../types'
import { resolveArtworkSrc } from './artworkFileService'

type Handlers = {
  onPlay: () => void
  onPause: () => void
  onNext: () => void
  onPrev: () => void
  onSeek: (time: number) => void
}

export const mediaSessionService = {
  isSupported(): boolean {
    return 'mediaSession' in navigator
  },

  async updateMetadata(song: Song | null, isPlaying: boolean) {
    if (!this.isSupported() || !song) return
    let artworkSrc: string | undefined
    if (song.artwork) {
      artworkSrc = await resolveArtworkSrc(song.artwork, song.id)
    }
    navigator.mediaSession.metadata = new MediaMetadata({
      title: song.title,
      artist: song.artist,
      album: song.album,
      artwork: artworkSrc
        ? [{ src: artworkSrc, sizes: '512x512', type: 'image/png' }]
        : [],
    })
    navigator.mediaSession.playbackState = isPlaying ? 'playing' : 'paused'
  },

  setPositionState(duration: number, position: number, rate = 1) {
    if (!this.isSupported() || !Number.isFinite(duration) || duration <= 0) return
    try {
      navigator.mediaSession.setPositionState({
        duration,
        position: Math.min(position, duration),
        playbackRate: rate,
      })
    } catch { /* ignore */ }
  },

  bindHandlers(handlers: Handlers) {
    if (!this.isSupported()) return
    navigator.mediaSession.setActionHandler('play', () => handlers.onPlay())
    navigator.mediaSession.setActionHandler('pause', () => handlers.onPause())
    navigator.mediaSession.setActionHandler('previoustrack', () => handlers.onPrev())
    navigator.mediaSession.setActionHandler('nexttrack', () => handlers.onNext())
    navigator.mediaSession.setActionHandler('seekto', (details) => {
      if (details.seekTime != null) handlers.onSeek(details.seekTime)
    })
  },
}
