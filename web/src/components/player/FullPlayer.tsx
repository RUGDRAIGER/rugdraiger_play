import { useEffect, useRef, useState } from 'react'
import { usePlayerStore } from '../../store/playerStore'
import { useSettingsStore } from '../../store/settingsStore'
import { audioService } from '../../services/audioService'
import { formatDuration } from '../../services/scannerService'
import { resolveArtworkSrc } from '../../services/artworkFileService'
import { extractDominantColor, applyDynamicAccent } from '../../services/colorUtils'
import { parseLrc, isLrcContent, getActiveLyricLine } from '../../services/lyricsService'
import { useSwipeGestures } from '../../hooks/useSwipeGestures'
import { ArtworkDisplay } from '../ui/ArtworkDisplay'
import { FavoriteButton } from '../ui/FavoriteButton'
import { IconButton } from '../ui/IconButton'
import { VolumeFader } from '../ui/VolumeFader'

export function FullPlayer() {
  const {
    currentSong, isPlaying, progress, duration, volume, isMuted,
    repeatMode, isShuffled, isFullPlayerOpen,
    togglePlay, next, prev, seekTo, setVolume, toggleMute,
    toggleRepeat, toggleShuffle, setFullPlayer,
  } = usePlayerStore()

  const [showQueue, setShowQueue] = useState(false)
  const [showLyrics, setShowLyrics] = useState(false)
  const [blurArtwork, setBlurArtwork] = useState<string | undefined>()
  const [accentColor, setAccentColor] = useState<string | undefined>()
  const lyricsRef = useRef<HTMLDivElement>(null)
  const { queue, queueIndex } = usePlayerStore()
  const dynamicColors = useSettingsStore((s) => s.dynamicColors)
  const showLyricsSetting = useSettingsStore((s) => s.showLyrics)

  const swipeHandlers = useSwipeGestures({
    onSwipeLeft: next,
    onSwipeRight: prev,
    onTap: togglePlay,
  })

  const lyricLines = currentSong?.lyrics && isLrcContent(currentSong.lyrics)
    ? parseLrc(currentSong.lyrics)
    : []
  const activeLyricIdx = getActiveLyricLine(lyricLines, progress * 1000)

  useEffect(() => {
    if (activeLyricIdx >= 0 && lyricsRef.current) {
      const el = lyricsRef.current.children[activeLyricIdx] as HTMLElement | undefined
      el?.scrollIntoView({ block: 'center', behavior: 'smooth' })
    }
  }, [activeLyricIdx])

  useEffect(() => {
    if (!currentSong?.artwork) {
      setBlurArtwork(undefined)
      setAccentColor(undefined)
      applyDynamicAccent(null)
      return
    }
    let cancelled = false
    void resolveArtworkSrc(currentSong.artwork, currentSong.id).then(async (url) => {
      if (cancelled) return
      setBlurArtwork(url)
      if (dynamicColors && url) {
        const color = await extractDominantColor(url)
        if (!cancelled && color) {
          setAccentColor(color.hex)
          applyDynamicAccent(color)
        }
      }
    })
    return () => {
      cancelled = true
      applyDynamicAccent(null)
    }
  }, [currentSong?.id, currentSong?.artwork, dynamicColors])

  if (!isFullPlayerOpen || !currentSong) return null

  const pct = duration > 0 ? (progress / duration) * 100 : 0
  const accent = accentColor ?? 'var(--accent)'

  return (
    <div
      className="slide-up"
      style={{
        position: 'fixed', inset: 0, zIndex: 1000,
        background: 'var(--bg-primary)',
        display: 'flex', flexDirection: 'column',
      }}
    >
      {/* Blurred background */}
      {blurArtwork && (
        <div style={{
          position: 'absolute', inset: 0, zIndex: 0,
          backgroundImage: `url(${blurArtwork})`,
          backgroundSize: 'cover', backgroundPosition: 'center',
          filter: 'blur(60px) brightness(0.25)',
          transform: 'scale(1.2)',
        }} />
      )}

      <div style={{ position: 'relative', zIndex: 1, flex: 1, display: 'flex', flexDirection: 'column' }}>
        {/* Header */}
        <div style={{ display: 'flex', alignItems: 'center', padding: '16px 20px', gap: 12 }}>
          <IconButton onClick={() => setFullPlayer(false)}>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z"/></svg>
          </IconButton>
          <div style={{ flex: 1, textAlign: 'center' }}>
            <div style={{ fontSize: 11, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: 1 }}>Reproduciendo</div>
          </div>
          {showLyricsSetting && (
            <IconButton onClick={() => { setShowLyrics(!showLyrics); setShowQueue(false) }} active={showLyrics}>
              <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/></svg>
            </IconButton>
          )}
          <IconButton onClick={() => { setShowQueue(!showQueue); setShowLyrics(false) }} active={showQueue}>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><path d="M3 18h13v-2H3v2zm0-5h10v-2H3v2zm0-7v2h13V6H3zm18 9.59L17.42 12 21 8.41 19.59 7l-5 5 5 5L21 15.59z"/></svg>
          </IconButton>
        </div>

        {showQueue ? (
          /* Queue panel */
          <div style={{ flex: 1, overflowY: 'auto', padding: '0 20px' }}>
            <div style={{ fontSize: 13, fontWeight: 700, color: 'var(--text-secondary)', marginBottom: 12, textTransform: 'uppercase', letterSpacing: 1 }}>
              Cola de reproducción
            </div>
            {queue.map((song, i) => (
              <div
                key={`${song.id}-${i}`}
                onClick={() => usePlayerStore.getState().playQueue(queue, i)}
                style={{
                  display: 'flex', alignItems: 'center', gap: 12,
                  padding: '10px 12px', borderRadius: 'var(--radius-md)',
                  background: i === queueIndex ? 'rgba(255,32,32,0.1)' : 'transparent',
                  cursor: 'pointer', marginBottom: 2,
                }}
              >
                <ArtworkDisplay song={song} size={38} borderRadius={4} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 13, fontWeight: i === queueIndex ? 600 : 400, color: i === queueIndex ? 'var(--accent)' : 'var(--text-primary)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {song.title}
                  </div>
                  <div style={{ fontSize: 12, color: 'var(--text-secondary)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {song.artist}
                  </div>
                </div>
                <span style={{ fontSize: 11, color: 'var(--text-secondary)' }}>{formatDuration(song.duration)}</span>
              </div>
            ))}
          </div>
        ) : showLyrics ? (
          <div style={{ flex: 1, overflowY: 'auto', padding: '0 28px 24px' }} ref={lyricsRef}>
            <div style={{ fontSize: 13, fontWeight: 700, color: 'var(--text-secondary)', marginBottom: 16, textTransform: 'uppercase', letterSpacing: 1 }}>
              Letras
            </div>
            {lyricLines.length > 0 ? (
              lyricLines.map((line, i) => (
                <p key={`${line.timeMs}-${i}`} style={{
                  fontSize: i === activeLyricIdx ? 20 : 16,
                  fontWeight: i === activeLyricIdx ? 700 : 400,
                  color: i === activeLyricIdx ? accent : 'var(--text-secondary)',
                  marginBottom: 12,
                  transition: 'all 0.2s',
                  lineHeight: 1.4,
                }}>
                  {line.text}
                </p>
              ))
            ) : currentSong.lyrics ? (
              <p style={{ fontSize: 16, lineHeight: 1.6, color: 'var(--text-primary)', whiteSpace: 'pre-wrap' }}>{currentSong.lyrics}</p>
            ) : (
              <p style={{ color: 'var(--text-secondary)', textAlign: 'center', padding: '40px 0' }}>
                No hay letras disponibles. Escanea un archivo .lrc junto a la canción o usa tags embebidos.
              </p>
            )}
          </div>
        ) : (
          /* Player UI */
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '20px 40px', gap: 24 }}>
            <div
              style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', width: '100%', touchAction: 'pan-y' }}
              {...swipeHandlers}
            >
              <div style={{
                maxWidth: 340, width: '100%', aspectRatio: '1',
                borderRadius: 'var(--radius-xl)',
                overflow: 'hidden',
                boxShadow: `0 24px 80px ${accentColor ? 'var(--dynamic-glow, rgba(0,0,0,0.6))' : 'rgba(0,0,0,0.6)'}`,
                border: accentColor ? `2px solid ${accent}` : 'none',
              }}>
                <ArtworkDisplay song={currentSong} size={340} borderRadius={22} style={{ width: '100%', height: '100%' }} />
              </div>
            </div>

            <div style={{ width: '100%', textAlign: 'center', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 22, fontWeight: 700, marginBottom: 4, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                  {currentSong.title}
                </div>
                <div style={{ fontSize: 16, color: 'var(--text-secondary)' }}>{currentSong.artist}</div>
                <div style={{ fontSize: 13, color: 'var(--text-tertiary)', marginTop: 2 }}>{currentSong.album}</div>
              </div>
              <FavoriteButton song={currentSong} size={26} />
            </div>

            <div style={{ width: '100%' }}>
              <div style={{ position: 'relative', height: 4, borderRadius: 2, background: 'var(--bg-surface3)', marginBottom: 8 }}>
                <div style={{ position: 'absolute', left: 0, top: 0, bottom: 0, width: `${pct}%`, background: accent, borderRadius: 2 }} />
                <input type="range" min={0} max={duration || 1} step={0.1} value={progress} onChange={(e) => seekTo(Number(e.target.value))}
                  style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', opacity: 0, cursor: 'pointer' }} />
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, color: 'var(--text-secondary)' }}>
                <span>{formatDuration(progress * 1000)}</span>
                <span>{formatDuration(duration * 1000)}</span>
              </div>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: 24, width: '100%', justifyContent: 'center' }}>
              <IconButton onClick={toggleShuffle} active={isShuffled} size={40}>
                <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><path d="M10.59 9.17 5.41 4 4 5.41l5.17 5.17 1.42-1.41zM14.5 4l2.04 2.04L4 18.59 5.41 20 17.96 7.46 20 9.5V4h-5.5zm.33 9.41-1.41 1.41 3.13 3.13L14.5 20H20v-5.5l-2.04 2.04-3.13-3.13z"/></svg>
              </IconButton>
              <IconButton onClick={prev} size={44}>
                <svg width="26" height="26" viewBox="0 0 24 24" fill="currentColor"><path d="M6 6h2v12H6zm3.5 6 8.5 6V6z"/></svg>
              </IconButton>
              <button onClick={togglePlay} style={{
                width: 64, height: 64, borderRadius: '50%', background: accent, color: '#fff',
                display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', flexShrink: 0,
                boxShadow: `0 8px 24px ${accentColor ? 'var(--dynamic-glow)' : 'rgba(255,32,32,0.4)'}`,
              }}>
                {isPlaying
                  ? <svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor"><path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/></svg>
                  : <svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>
                }
              </button>
              <IconButton onClick={next} size={44}>
                <svg width="26" height="26" viewBox="0 0 24 24" fill="currentColor"><path d="M6 18l8.5-6L6 6v12zM16 6v12h2V6h-2z"/></svg>
              </IconButton>
              <IconButton onClick={toggleRepeat} active={repeatMode !== 'none'} size={40}>
                <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><path d="M7 7h10v3l4-4-4-4v3H5v6h2V7zm10 10H7v-3l-4 4 4 4v-3h12v-6h-2v4z"/></svg>
              </IconButton>
            </div>

            <p style={{ fontSize: 11, color: 'var(--text-tertiary)', textAlign: 'center' }}>
              Desliza ← → para cambiar · Toca la carátula para pausar
            </p>

            <div style={{ display: 'flex', justifyContent: 'center', width: '100%', padding: '0 40px' }}>
              <VolumeFader volume={volume} isMuted={isMuted} onVolumeChange={setVolume} onToggleMute={toggleMute} width="100%" />
            </div>

            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', justifyContent: 'center' }}>
              {currentSong.format && (
                <span style={{ fontSize: 11, padding: '3px 8px', borderRadius: 20, background: 'rgba(255,32,32,0.15)', color: accent, fontWeight: 600, textTransform: 'uppercase' }}>
                  {currentSong.format}
                </span>
              )}
              {currentSong.isLossless && (
                <span style={{ fontSize: 11, padding: '3px 8px', borderRadius: 20, background: 'rgba(255,32,32,0.08)', color: accent, border: '1px solid var(--border-accent)' }}>
                  LOSSLESS
                </span>
              )}
              {currentSong.replayGain != null && (
                <span style={{ fontSize: 11, padding: '3px 8px', borderRadius: 20, background: 'var(--bg-surface)', color: 'var(--text-secondary)' }}>
                  RG {currentSong.replayGain > 0 ? '+' : ''}{currentSong.replayGain.toFixed(1)} dB
                </span>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
