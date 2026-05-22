import { create } from 'zustand'
import type { EQBand } from '../types'
import { audioService } from '../services/audioService'

const PRESETS: Record<string, number[]> = {
  Flat:       [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  Bass:       [6, 5, 4, 2, 0, 0, 0, 0, 0, 0],
  Treble:     [0, 0, 0, 0, 0, 0, 2, 4, 5, 6],
  Rock:       [4, 3, 2, 0, -1, 0, 2, 3, 4, 4],
  Pop:        [-1, 0, 2, 3, 3, 2, 0, -1, -1, -1],
  Jazz:       [3, 2, 1, 2, -1, -1, 0, 1, 2, 3],
  Classical:  [4, 3, 2, 1, 0, 0, 0, 1, 2, 3],
  Electronic: [4, 3, 0, -2, -1, 0, 3, 4, 4, 4],
  Vocal:      [-2, -2, 0, 2, 4, 4, 2, 0, -2, -2],
}

interface EQStore {
  bands: EQBand[]
  enabled: boolean
  activePreset: string

  setEnabled: (v: boolean) => void
  setBandGain: (index: number, gain: number) => void
  applyPreset: (name: string) => void
  getPresetNames: () => string[]
}

export const useEQStore = create<EQStore>((set, get) => ({
  bands: audioService.getDefaultBands(),
  enabled: true,
  activePreset: 'Flat',

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
}))
