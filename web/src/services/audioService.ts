import type { Song, EQBand } from '../types'
import { resolveSongBlob } from './audioFileService'

const EQ_FREQUENCIES = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]

export class AudioLoadError extends Error {
  constructor(message = 'No hay archivo de audio disponible para esta canción.') {
    super(message)
    this.name = 'AudioLoadError'
  }
}

class AudioService {
  private audioCtx: AudioContext | null = null
  private source: MediaElementAudioSourceNode | null = null
  private replayGainNode: GainNode | null = null
  private gainNode: GainNode | null = null
  private eqFilters: BiquadFilterNode[] = []
  private audioElement: HTMLAudioElement
  private objectUrl: string | null = null
  private currentSongId: string | null = null
  private preloadedSongId: string | null = null
  private preloadedBlob: Blob | null = null
  private userVolume = 1

  constructor() {
    this.audioElement = new Audio()
    this.audioElement.preload = 'auto'
  }

  private ensureContext() {
    if (this.audioCtx) return

    this.audioCtx = new AudioContext()
    this.source = this.audioCtx.createMediaElementSource(this.audioElement)
    this.replayGainNode = this.audioCtx.createGain()
    this.gainNode = this.audioCtx.createGain()

    this.eqFilters = EQ_FREQUENCIES.map((freq, i) => {
      const filter = this.audioCtx!.createBiquadFilter()
      filter.type = i === 0 ? 'lowshelf' : i === EQ_FREQUENCIES.length - 1 ? 'highshelf' : 'peaking'
      filter.frequency.value = freq
      filter.gain.value = 0
      filter.Q.value = 1.4
      return filter
    })

    this.source.connect(this.eqFilters[0])
    for (let i = 0; i < this.eqFilters.length - 1; i++) {
      this.eqFilters[i].connect(this.eqFilters[i + 1])
    }
    this.eqFilters[this.eqFilters.length - 1].connect(this.replayGainNode)
    this.replayGainNode.connect(this.gainNode)
    this.gainNode.connect(this.audioCtx.destination)
  }

  getElement(): HTMLAudioElement {
    return this.audioElement
  }

  async preloadNext(song: Song): Promise<void> {
    if (this.preloadedSongId === song.id && this.preloadedBlob) return
    const blob = await resolveSongBlob(song)
    if (!blob) return
    this.preloadedSongId = song.id
    this.preloadedBlob = blob
  }

  maybePreloadGapless(currentTime: number, duration: number, nextSong: Song | null, enabled: boolean) {
    if (!enabled || !nextSong || !Number.isFinite(duration) || duration <= 0) return
    if (duration - currentTime <= 3) {
      void this.preloadNext(nextSong)
    }
  }

  applyReplayGain(gainDb: number | null, enabled: boolean) {
    this.ensureContext()
    const linear = enabled && gainDb != null ? Math.pow(10, gainDb / 20) : 1
    if (this.replayGainNode) {
      this.replayGainNode.gain.value = Math.max(0.05, Math.min(4, linear))
    }
  }

  async loadSong(song: Song, replayGainEnabled = true): Promise<void> {
    if (this.currentSongId === song.id && this.audioElement.src) {
      this.applyReplayGain(song.replayGain ?? null, replayGainEnabled)
      return
    }

    if (this.objectUrl) {
      URL.revokeObjectURL(this.objectUrl)
      this.objectUrl = null
    }

    let blob: Blob | null = null
    if (this.preloadedSongId === song.id && this.preloadedBlob) {
      blob = this.preloadedBlob
      this.preloadedSongId = null
      this.preloadedBlob = null
    } else {
      blob = await resolveSongBlob(song)
    }

    if (!blob) {
      this.currentSongId = null
      this.audioElement.removeAttribute('src')
      throw new AudioLoadError()
    }

    this.objectUrl = URL.createObjectURL(blob)
    this.audioElement.src = this.objectUrl
    this.currentSongId = song.id
    this.applyReplayGain(song.replayGain ?? null, replayGainEnabled)

    await new Promise<void>((resolve, reject) => {
      const onReady = () => {
        cleanup()
        resolve()
      }
      const onError = () => {
        cleanup()
        reject(new AudioLoadError('No se pudo cargar el archivo de audio.'))
      }
      const cleanup = () => {
        this.audioElement.removeEventListener('loadedmetadata', onReady)
        this.audioElement.removeEventListener('error', onError)
      }
      this.audioElement.addEventListener('loadedmetadata', onReady)
      this.audioElement.addEventListener('error', onError)
      this.audioElement.load()
    })
  }

  async play(): Promise<void> {
    this.ensureContext()
    if (this.audioCtx?.state === 'suspended') {
      await this.audioCtx.resume()
    }
    await this.audioElement.play()
  }

  pause(): void {
    this.audioElement.pause()
  }

  seek(seconds: number): void {
    this.audioElement.currentTime = seconds
  }

  setVolume(value: number): void {
    this.userVolume = Math.max(0, Math.min(1, value))
    this.audioElement.volume = this.userVolume
    if (this.gainNode) {
      this.gainNode.gain.value = this.userVolume === 0 ? 0 : 1
    }
  }

  setMuted(muted: boolean): void {
    this.audioElement.muted = muted
  }

  setEQBand(index: number, gainDb: number): void {
    if (this.eqFilters[index]) {
      this.eqFilters[index].gain.value = gainDb
    }
  }

  setAllEQBands(bands: EQBand[]): void {
    this.ensureContext()
    bands.forEach((band, i) => {
      if (this.eqFilters[i]) {
        this.eqFilters[i].gain.value = band.gain
      }
    })
  }

  resetEQ(): void {
    this.eqFilters.forEach((f) => { f.gain.value = 0 })
  }

  getDefaultBands(): EQBand[] {
    return EQ_FREQUENCIES.map((freq) => ({
      frequency: freq,
      gain: 0,
      label: freq >= 1000 ? `${freq / 1000}k` : `${freq}`,
    }))
  }

  destroy(): void {
    this.audioElement.pause()
    if (this.objectUrl) URL.revokeObjectURL(this.objectUrl)
    this.audioCtx?.close()
  }
}

export const audioService = new AudioService()
