import { create } from 'zustand'
import { audioService } from '../services/audioService'

const STORAGE_KEY = 'rugdraiger_settings'

interface SettingsState {
  gaplessPlayback: boolean
  replayGainEnabled: boolean
  directAudioMode: boolean
  crossfadeEnabled: boolean
  crossfadeMs: number
  dynamicColors: boolean
  drivingMode: boolean
  mediaKeysEnabled: boolean
  showLyrics: boolean
  setGaplessPlayback: (v: boolean) => void
  setReplayGainEnabled: (v: boolean) => void
  setDirectAudioMode: (v: boolean) => void
  setCrossfadeEnabled: (v: boolean) => void
  setCrossfadeMs: (v: number) => void
  setDynamicColors: (v: boolean) => void
  setDrivingMode: (v: boolean) => void
  setMediaKeysEnabled: (v: boolean) => void
  setShowLyrics: (v: boolean) => void
}

function syncDirectMode(directAudioMode: boolean) {
  audioService.setProcessingOptions({ directMode: directAudioMode })
}

function loadSettings(): Partial<SettingsState> {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    return raw ? JSON.parse(raw) : {}
  } catch {
    return {}
  }
}

function persistSettings(state: SettingsState) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify({
    gaplessPlayback: state.gaplessPlayback,
    replayGainEnabled: state.replayGainEnabled,
    directAudioMode: state.directAudioMode,
    crossfadeEnabled: state.crossfadeEnabled,
    crossfadeMs: state.crossfadeMs,
    dynamicColors: state.dynamicColors,
    drivingMode: state.drivingMode,
    mediaKeysEnabled: state.mediaKeysEnabled,
    showLyrics: state.showLyrics,
  }))
}

const saved = loadSettings()

export const useSettingsStore = create<SettingsState>((set, get) => ({
  gaplessPlayback: saved.gaplessPlayback ?? true,
  replayGainEnabled: saved.replayGainEnabled ?? true,
  directAudioMode: saved.directAudioMode ?? true,
  crossfadeEnabled: saved.crossfadeEnabled ?? false,
  crossfadeMs: saved.crossfadeMs ?? 120,
  dynamicColors: saved.dynamicColors ?? true,
  drivingMode: saved.drivingMode ?? false,
  mediaKeysEnabled: saved.mediaKeysEnabled ?? true,
  showLyrics: saved.showLyrics ?? true,

  setGaplessPlayback: (v) => {
    set({ gaplessPlayback: v })
    persistSettings(get())
  },
  setReplayGainEnabled: (v) => {
    set({ replayGainEnabled: v })
    persistSettings(get())
  },
  setDirectAudioMode: (v) => {
    set({ directAudioMode: v })
    persistSettings(get())
    syncDirectMode(v)
  },
  setCrossfadeEnabled: (v) => {
    set({ crossfadeEnabled: v })
    persistSettings(get())
  },
  setCrossfadeMs: (v) => {
    set({ crossfadeMs: Math.max(50, Math.min(500, v)) })
    persistSettings(get())
  },
  setDynamicColors: (v) => {
    set({ dynamicColors: v })
    persistSettings(get())
  },
  setDrivingMode: (v) => {
    set({ drivingMode: v })
    persistSettings(get())
  },
  setMediaKeysEnabled: (v) => {
    set({ mediaKeysEnabled: v })
    persistSettings(get())
  },
  setShowLyrics: (v) => {
    set({ showLyrics: v })
    persistSettings(get())
  },
}))

syncDirectMode(useSettingsStore.getState().directAudioMode)
