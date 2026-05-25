import { create } from 'zustand'

const STORAGE_KEY = 'rugdraiger_settings'

interface SettingsState {
  gaplessPlayback: boolean
  replayGainEnabled: boolean
  dynamicColors: boolean
  drivingMode: boolean
  mediaKeysEnabled: boolean
  showLyrics: boolean
  setGaplessPlayback: (v: boolean) => void
  setReplayGainEnabled: (v: boolean) => void
  setDynamicColors: (v: boolean) => void
  setDrivingMode: (v: boolean) => void
  setMediaKeysEnabled: (v: boolean) => void
  setShowLyrics: (v: boolean) => void
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
