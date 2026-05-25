import { create } from 'zustand'
import type { EQBand, EQProfile } from '../types'
import { audioService } from '../services/audioService'

const PRESETS: Record<string, number[]> = {
  Flat:       [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  Bass:       [6, 5, 4, 2, 0, 0, 0, 0, 0, 0],
  'Bass Boost': [8, 6, 4, 2, 0, 0, 0, 0, 0, 0],
  Treble:     [0, 0, 0, 0, 0, 0, 2, 4, 5, 6],
  Rock:       [4, 3, 2, 0, -1, 0, 2, 3, 4, 4],
  Pop:        [-1, 0, 2, 3, 3, 2, 0, -1, -1, -1],
  Jazz:       [3, 2, 1, 2, -1, -1, 0, 1, 2, 3],
  Classical:  [4, 3, 2, 1, 0, 0, 0, 1, 2, 3],
  Electronic: [4, 3, 0, -2, -1, 0, 3, 4, 4, 4],
  Vocal:      [-2, -2, 0, 2, 4, 4, 2, 0, -2, -2],
}

const PROFILES_KEY = 'rugdraiger_eq_profiles'

function loadProfiles(): EQProfile[] {
  try {
    const raw = localStorage.getItem(PROFILES_KEY)
    return raw ? JSON.parse(raw) : []
  } catch {
    return []
  }
}

function saveProfiles(profiles: EQProfile[]) {
  localStorage.setItem(PROFILES_KEY, JSON.stringify(profiles))
}

interface EQStore {
  bands: EQBand[]
  enabled: boolean
  activePreset: string
  savedProfiles: EQProfile[]

  setEnabled: (v: boolean) => void
  setBandGain: (index: number, gain: number) => void
  applyPreset: (name: string) => void
  getPresetNames: () => string[]
  saveCurrentAsProfile: (name: string) => void
  deleteProfile: (id: string) => void
  applyProfile: (profile: EQProfile) => void
}

export const useEQStore = create<EQStore>((set, get) => ({
  bands: audioService.getDefaultBands(),
  enabled: true,
  activePreset: 'Flat',
  savedProfiles: loadProfiles(),

  setEnabled: (v) => {
    if (!v) audioService.resetEQ()
    else audioService.setAllEQBands(get().bands)
    set({ enabled: v })
  },

  setBandGain: (index, gain) => {
    const bands = get().bands.map((b, i) => (i === index ? { ...b, gain } : b))
    audioService.setEQBand(index, gain)
    set({ bands, activePreset: 'Custom' })
  },

  applyPreset: (name) => {
    const gains = PRESETS[name] ?? PRESETS['Flat']
    const bands = get().bands.map((b, i) => ({ ...b, gain: gains[i] ?? 0 }))
    audioService.setAllEQBands(bands)
    set({ bands, activePreset: name })
  },

  getPresetNames: () => Object.keys(PRESETS),

  saveCurrentAsProfile: (name) => {
    const trimmed = name.trim()
    if (!trimmed) return
    const profile: EQProfile = {
      id: `profile_${Date.now()}`,
      name: trimmed,
      bands: get().bands.map((b) => b.gain),
      createdAt: Date.now(),
    }
    const savedProfiles = [...get().savedProfiles, profile]
    saveProfiles(savedProfiles)
    set({ savedProfiles, activePreset: trimmed })
  },

  deleteProfile: (id) => {
    const savedProfiles = get().savedProfiles.filter((p) => p.id !== id)
    saveProfiles(savedProfiles)
    set({ savedProfiles })
  },

  applyProfile: (profile) => {
    const bands = get().bands.map((b, i) => ({ ...b, gain: profile.bands[i] ?? 0 }))
    audioService.setAllEQBands(bands)
    set({ bands, activePreset: profile.name })
  },
}))
