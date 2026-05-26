import { create } from 'zustand'
import type { Song, RepeatMode } from '../types'
import { audioService, AudioLoadError } from '../services/audioService'
import { useSettingsStore } from './settingsStore'
import { useEQStore } from './eqStore'
import { useLibraryStore } from './libraryStore'

interface PlayerStore {
  currentSong: Song | null
  queue: Song[]
  queueIndex: number
  isPlaying: boolean
  progress: number
  duration: number
  volume: number
  isMuted: boolean
  repeatMode: RepeatMode
  isShuffled: boolean
  shuffledQueue: Song[]
  isFullPlayerOpen: boolean
  playbackError: string | null

  playSong: (song: Song, queue?: Song[]) => void
  playQueue: (songs: Song[], startIndex?: number) => void
  togglePlay: () => void
  next: () => void
  prev: () => void
  seekTo: (seconds: number) => void
  setVolume: (v: number) => void
  toggleMute: () => void
  toggleRepeat: () => void
  toggleShuffle: () => void
  setProgress: (p: number) => void
  setDuration: (d: number) => void
  setFullPlayer: (open: boolean) => void
  addToQueue: (song: Song) => void
  removeFromQueue: (index: number) => void
  onSongRemoved: (songId: string) => void
  getNextSong: () => Song | null
}

function shuffleArray<T>(arr: T[]): T[] {
  const a = [...arr]
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]]
  }
  return a
}

async function startPlayback(
  song: Song,
  set: (partial: Partial<PlayerStore>) => void,
): Promise<void> {
  const {
    replayGainEnabled,
    directAudioMode,
    crossfadeEnabled,
    crossfadeMs,
  } = useSettingsStore.getState()
  const { enabled: eqEnabled } = useEQStore.getState()

  audioService.setProcessingOptions({
    directMode: directAudioMode,
    eqEnabled: eqEnabled && !directAudioMode,
  })

  try {
    await audioService.loadSong(song, replayGainEnabled && !directAudioMode, {
      crossfadeMs: crossfadeEnabled ? crossfadeMs : 0,
    })
    await audioService.play()
    set({ isPlaying: true, playbackError: null })
    void useLibraryStore.getState().recordPlay(song.id)
  } catch (e) {
    const message =
      e instanceof AudioLoadError
        ? 'No hay audio guardado. Vuelve a escanear tu música.'
        : 'No se pudo reproducir la canción.'
    set({ isPlaying: false, playbackError: message })
  }
}

export const usePlayerStore = create<PlayerStore>((set, get) => ({
  currentSong: null,
  queue: [],
  queueIndex: 0,
  isPlaying: false,
  progress: 0,
  duration: 0,
  volume: 1,
  isMuted: false,
  repeatMode: 'none',
  isShuffled: false,
  shuffledQueue: [],
  isFullPlayerOpen: false,
  playbackError: null,

  playSong: async (song, queue) => {
    const q = queue ?? [song]
    const idx = q.findIndex((s) => s.id === song.id)
    set({
      currentSong: song,
      queue: q,
      queueIndex: idx < 0 ? 0 : idx,
      isPlaying: false,
      playbackError: null,
    })
    await startPlayback(song, set)
  },

  playQueue: async (songs, startIndex = 0) => {
    if (!songs.length) return
    const song = songs[startIndex]
    set({
      currentSong: song,
      queue: songs,
      queueIndex: startIndex,
      isPlaying: false,
      playbackError: null,
    })
    await startPlayback(song, set)
  },

  togglePlay: async () => {
    const { isPlaying, currentSong } = get()
    if (isPlaying) {
      audioService.pause()
      set({ isPlaying: false })
      return
    }
    if (!currentSong) return
    if (!audioService.getElement().src) {
      await startPlayback(currentSong, set)
      return
    }
    try {
      await audioService.play()
      set({ isPlaying: true, playbackError: null })
    } catch {
      set({ isPlaying: false, playbackError: 'No se pudo reproducir la canción.' })
    }
  },

  next: async () => {
    const { queue, queueIndex, repeatMode, isShuffled, shuffledQueue } = get()
    const activeQueue = isShuffled && shuffledQueue.length ? shuffledQueue : queue
    let nextIdx = queueIndex + 1
    if (nextIdx >= activeQueue.length) {
      if (repeatMode === 'all') nextIdx = 0
      else { audioService.pause(); set({ isPlaying: false }); return }
    }
    const song = activeQueue[nextIdx]
    set({ currentSong: song, queueIndex: nextIdx, isPlaying: false, playbackError: null })
    await startPlayback(song, set)
  },

  prev: async () => {
    const { queue, queueIndex, isShuffled, shuffledQueue } = get()
    const activeQueue = isShuffled && shuffledQueue.length ? shuffledQueue : queue
    const el = audioService.getElement()
    if (el.currentTime > 3) {
      audioService.seek(0)
      return
    }
    const prevIdx = Math.max(0, queueIndex - 1)
    const song = activeQueue[prevIdx]
    set({ currentSong: song, queueIndex: prevIdx, isPlaying: false, playbackError: null })
    await startPlayback(song, set)
  },

  seekTo: (seconds) => {
    audioService.seek(seconds)
    set({ progress: seconds })
  },

  setVolume: (v) => {
    audioService.setVolume(v)
    set({ volume: v, isMuted: v === 0 })
  },

  toggleMute: () => {
    const { isMuted, volume } = get()
    const muted = !isMuted
    audioService.setMuted(muted)
    audioService.setVolume(muted ? 0 : volume)
    set({ isMuted: muted })
  },

  toggleRepeat: () => {
    const modes: RepeatMode[] = ['none', 'all', 'one']
    const { repeatMode } = get()
    const next = modes[(modes.indexOf(repeatMode) + 1) % modes.length]
    audioService.getElement().loop = next === 'one'
    set({ repeatMode: next })
  },

  toggleShuffle: () => {
    const { isShuffled, queue } = get()
    if (!isShuffled) {
      set({ isShuffled: true, shuffledQueue: shuffleArray(queue) })
    } else {
      set({ isShuffled: false, shuffledQueue: [] })
    }
  },

  setProgress: (p) => set({ progress: p }),
  setDuration: (d) => set({ duration: d }),
  setFullPlayer: (open) => set({ isFullPlayerOpen: open }),

  addToQueue: (song) => {
    const { queue } = get()
    set({ queue: [...queue, song] })
  },

  removeFromQueue: (index) => {
    const { queue, queueIndex } = get()
    const newQueue = queue.filter((_, i) => i !== index)
    const newIdx = index < queueIndex ? queueIndex - 1 : queueIndex
    set({ queue: newQueue, queueIndex: Math.min(newIdx, newQueue.length - 1) })
  },

  onSongRemoved: (songId) => {
    const { currentSong, queue, queueIndex } = get()
    const newQueue = queue.filter((s) => s.id !== songId)
    if (currentSong?.id === songId) {
      audioService.pause()
      set({
        currentSong: null,
        queue: newQueue,
        queueIndex: 0,
        isPlaying: false,
        progress: 0,
        isFullPlayerOpen: false,
      })
      return
    }
    const idx = newQueue.findIndex((s) => s.id === currentSong?.id)
    set({ queue: newQueue, queueIndex: idx >= 0 ? idx : 0 })
  },

  getNextSong: () => {
    const { queue, queueIndex, repeatMode, isShuffled, shuffledQueue } = get()
    const activeQueue = isShuffled && shuffledQueue.length ? shuffledQueue : queue
    let nextIdx = queueIndex + 1
    if (nextIdx >= activeQueue.length) {
      if (repeatMode === 'all') nextIdx = 0
      else return null
    }
    return activeQueue[nextIdx] ?? null
  },
}))
