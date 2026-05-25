import { useEffect, useRef } from 'react'
import { usePlayerStore } from '../../store/playerStore'
import { useSettingsStore } from '../../store/settingsStore'
import { audioService } from '../../services/audioService'
import { formatDuration } from '../../services/scannerService'
import { ArtworkDisplay } from '../ui/ArtworkDisplay'
import { IconButton } from '../ui/IconButton'
import { VolumeFader } from '../ui/VolumeFader'

export function MiniPlayer() {
  const {
    currentSong, isPlaying, progress, duration, volume, isMuted, playbackError,
    togglePlay, next, prev, seekTo, setVolume, toggleMute, setProgress, setDuration, setFullPlayer,
  } = usePlayerStore()
  const gaplessPlayback = useSettingsStore((s) => s.gaplessPlayback)

  const progressRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    const el = audioService.getElement()
    const onTime = () => {
      setProgress(el.currentTime)
      const nextSong = usePlayerStore.getState().getNextSong()
      audioService.maybePreloadGapless(el.currentTime, el.duration, nextSong, gaplessPlayback)
    }
    const onMeta = () => setDuration(el.duration || 0)
    const onEnd = () => usePlayerStore.getState().next()

    el.addEventListener('timeupdate', onTime)
    el.addEventListener('loadedmetadata', onMeta)
    el.addEventListener('ended', onEnd)
    return () => {
      el.removeEventListener('timeupdate', onTime)
      el.removeEventListener('loadedmetadata', onMeta)
      el.removeEventListener('ended', onEnd)
    }
  }, [setProgress, setDuration, gaplessPlayback])

  if (!currentSong) return null

  const pct = duration > 0 ? (progress / duration) * 100 : 0

  return (
    <div
      style={{
        height: 'var(--mini-player-height)',
        background: 'var(--bg-surface)',
        borderTop: '1px solid var(--border)',
        display: 'flex',
        flexDirection: 'column',
        flexShrink: 0,
        position: 'relative',
      }}
    >
      {/* Progress bar */}
      <div style={{ position: 'relative', height: 3, cursor: 'pointer' }}>
        <div style={{ position: 'absolute', inset: 0, background: 'var(--bg-surface3)' }} />
        <div style={{ position: 'absolute', left: 0, top: 0, bottom: 0, width: `${pct}%`, background: 'var(--accent)', transition: 'width 0.1s linear' }} />
        <input
          ref={progressRef}
          type="range"
          min={0}
          max={duration || 1}
          step={0.1}
          value={progress}
          onChange={(e) => seekTo(Number(e.target.value))}
          style={{
            position: 'absolute', inset: 0, width: '100%', height: '100%',
            opacity: 0, cursor: 'pointer',
          }}
        />
      </div>

      <div style={{
        flex: 1,
        display: 'flex',
        alignItems: 'center',
        padding: '0 16px',
        gap: 12,
      }}>
        {/* Artwork + Info */}
        <div
          style={{ display: 'flex', alignItems: 'center', gap: 10, flex: 1, minWidth: 0, cursor: 'pointer' }}
          onClick={() => setFullPlayer(true)}
        >
          <ArtworkDisplay song={currentSong} size={44} borderRadius={6} />
          <div style={{ minWidth: 0 }}>
            <div style={{ fontSize: 13, fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
              {currentSong.title}
            </div>
            <div style={{
              fontSize: 12,
              color: playbackError ? '#f87171' : 'var(--text-secondary)',
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              whiteSpace: 'nowrap',
            }}>
              {playbackError ?? currentSong.artist}
            </div>
          </div>
        </div>

        {/* Time */}
        <div style={{ fontSize: 11, color: 'var(--text-secondary)', whiteSpace: 'nowrap', display: 'flex', gap: 4 }}>
          <span>{formatDuration(progress * 1000)}</span>
          <span>/</span>
          <span>{formatDuration(duration * 1000)}</span>
        </div>

        {/* Controls */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
          <IconButton onClick={prev} size={32}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M6 6h2v12H6zm3.5 6 8.5 6V6z"/></svg>
          </IconButton>
          <button
            onClick={togglePlay}
            style={{
              width: 40, height: 40, borderRadius: '50%',
              background: 'var(--accent)', color: '#fff',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              cursor: 'pointer', transition: 'background 0.15s',
              flexShrink: 0,
            }}
          >
            {isPlaying
              ? <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/></svg>
              : <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>
            }
          </button>
          <IconButton onClick={next} size={32}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M6 18l8.5-6L6 6v12zM16 6v12h2V6h-2z"/></svg>
          </IconButton>
        </div>

        {/* Volume: línea horizontal + fader vertical */}
        <VolumeFader
          volume={volume}
          isMuted={isMuted}
          onVolumeChange={setVolume}
          onToggleMute={toggleMute}
          width={120}
        />
      </div>
    </div>
  )
}
