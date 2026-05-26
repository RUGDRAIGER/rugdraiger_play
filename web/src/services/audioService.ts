import type { Song, EQBand } from '../types'
import { resolveSongBlob } from './audioFileService'
import { getElectronLocalFileUrl } from './electronBridgeService'

const EQ_FREQUENCIES = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]

export class AudioLoadError extends Error {
  constructor(message = 'No hay archivo de audio disponible para esta canción.') {
    super(message)
    this.name = 'AudioLoadError'
  }
}

function delay(ms: number) {
  return new Promise<void>((resolve) => window.setTimeout(resolve, ms))
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
  private directMode = true
  private eqEnabled = false
  private graphBuilt = false

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

    this.graphBuilt = true
    this.rebuildGraph()
  }

  private rebuildGraph() {
    if (!this.source || !this.replayGainNode || !this.gainNode) return

    try { this.source.disconnect() } catch { /* first connect */ }
    for (const f of this.eqFilters) {
      try { f.disconnect() } catch { /* noop */ }
    }
    try { this.replayGainNode.disconnect() } catch { /* noop */ }
    try { this.gainNode.disconnect() } catch { /* noop */ }

    const useEq = this.eqEnabled && !this.directMode

    if (useEq) {
      this.source.connect(this.eqFilters[0])
      for (let i = 0; i < this.eqFilters.length - 1; i++) {
        this.eqFilters[i].connect(this.eqFilters[i + 1])
      }
      this.eqFilters[this.eqFilters.length - 1].connect(this.replayGainNode)
    } else {
      this.source.connect(this.replayGainNode)
    }

    this.replayGainNode.connect(this.gainNode)
    this.gainNode.connect(this.audioCtx!.destination)
    this.gainNode.gain.value = this.userVolume === 0 ? 0 : 1
  }

  setProcessingOptions(options: { directMode?: boolean; eqEnabled?: boolean }) {
    if (options.directMode !== undefined) this.directMode = options.directMode
    if (options.eqEnabled !== undefined) this.eqEnabled = options.eqEnabled
    if (this.graphBuilt) this.rebuildGraph()
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
    const allowGain = enabled && !this.directMode
    const linear = allowGain && gainDb != null ? Math.pow(10, gainDb / 20) : 1
    if (this.replayGainNode) {
      this.replayGainNode.gain.value = Math.max(0.05, Math.min(4, linear))
    }
  }

  private async assignSource(song: Song): Promise<void> {
    if (this.objectUrl) {
      URL.revokeObjectURL(this.objectUrl)
      this.objectUrl = null
    }

    let blob: Blob | null = null
    let directUrl: string | null = null

    if (song.filePath?.startsWith('/') || /^[A-Za-z]:\\/.test(song.filePath ?? '')) {
      directUrl = await getElectronLocalFileUrl(song.filePath!)
    }

    if (!directUrl) {
      if (this.preloadedSongId === song.id && this.preloadedBlob) {
        blob = this.preloadedBlob
        this.preloadedSongId = null
        this.preloadedBlob = null
      } else {
        blob = await resolveSongBlob(song)
      }
    }

    if (!directUrl && !blob) {
      this.currentSongId = null
      this.audioElement.removeAttribute('src')
      throw new AudioLoadError()
    }

    if (directUrl) {
      this.audioElement.src = directUrl
    } else if (blob) {
      this.objectUrl = URL.createObjectURL(blob)
      this.audioElement.src = this.objectUrl
    }
    this.currentSongId = song.id
  }

  private waitForMetadata(): Promise<void> {
    return new Promise<void>((resolve, reject) => {
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

  async loadSong(
    song: Song,
    replayGainEnabled = true,
    options?: { crossfadeMs?: number },
  ): Promise<void> {
    const crossfadeMs = options?.crossfadeMs ?? 0
    const isPlaying = !this.audioElement.paused && !!this.audioElement.src

    if (this.currentSongId === song.id && this.audioElement.src) {
      this.applyReplayGain(song.replayGain ?? null, replayGainEnabled)
      return
    }

    if (crossfadeMs > 0 && isPlaying) {
      await this.crossfadeLoad(song, replayGainEnabled, crossfadeMs)
      return
    }

    this.ensureContext()
    await this.assignSource(song)
    this.applyReplayGain(song.replayGain ?? null, replayGainEnabled)
    await this.waitForMetadata()
  }

  private async crossfadeLoad(song: Song, replayGainEnabled: boolean, crossfadeMs: number) {
    this.ensureContext()
    if (!this.gainNode) return

    const steps = 10
    const stepMs = Math.max(8, crossfadeMs / steps)
    const wasPlaying = !this.audioElement.paused

    for (let i = steps; i >= 0; i--) {
      this.gainNode.gain.value = (this.userVolume === 0 ? 0 : 1) * (i / steps)
      await delay(stepMs)
    }

    this.audioElement.pause()
    await this.assignSource(song)
    this.applyReplayGain(song.replayGain ?? null, replayGainEnabled)
    await this.waitForMetadata()

    if (wasPlaying) {
      await this.play()
      for (let i = 1; i <= steps; i++) {
        this.gainNode!.gain.value = (this.userVolume === 0 ? 0 : 1) * (i / steps)
        await delay(stepMs)
      }
    }
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
