import { usePlayerStore } from '../../store/playerStore'
import { useSettingsStore } from '../../store/settingsStore'
import { ArtworkDisplay } from '../ui/ArtworkDisplay'
import { formatDuration } from '../../services/scannerService'

export function DrivingModeView() {
  const { currentSong, isPlaying, progress, duration, togglePlay, next, prev } = usePlayerStore()
  const setDrivingMode = useSettingsStore((s) => s.setDrivingMode)

  if (!currentSong) {
    return (
      <div style={{
        position: 'fixed', inset: 0, zIndex: 2000,
        background: 'var(--bg-primary)',
        display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 16,
      }}>
        <p style={{ color: 'var(--text-secondary)' }}>Reproduce una canción para usar el modo conducción</p>
        <button type="button" onClick={() => setDrivingMode(false)} style={{ color: 'var(--accent)', fontSize: 15, cursor: 'pointer' }}>
          Salir
        </button>
      </div>
    )
  }

  return (
    <div style={{
      position: 'fixed', inset: 0, zIndex: 2000,
      background: 'var(--bg-primary)',
      display: 'flex', flexDirection: 'column',
      padding: 'env(safe-area-inset-top, 24px) 24px env(safe-area-inset-bottom, 24px)',
    }}>
      <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
        <button type="button" onClick={() => setDrivingMode(false)} style={{ color: 'var(--text-secondary)', fontSize: 14, cursor: 'pointer', padding: 8 }}>
          Salir
        </button>
      </div>

      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 24 }}>
        <div style={{ width: 'min(280px, 70vw)', aspectRatio: '1', borderRadius: 20, overflow: 'hidden', boxShadow: '0 16px 48px rgba(0,0,0,0.5)' }}>
          <ArtworkDisplay song={currentSong} size={280} borderRadius={20} style={{ width: '100%', height: '100%' }} />
        </div>
        <div style={{ textAlign: 'center', maxWidth: 320 }}>
          <div style={{ fontSize: 26, fontWeight: 800, marginBottom: 6 }}>{currentSong.title}</div>
          <div style={{ fontSize: 18, color: 'var(--text-secondary)' }}>{currentSong.artist}</div>
        </div>
        <div style={{ fontSize: 16, color: 'var(--text-secondary)' }}>
          {formatDuration(progress * 1000)} / {formatDuration(duration * 1000)}
        </div>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 32, paddingBottom: 24 }}>
        <button type="button" onClick={prev} style={{ width: 72, height: 72, borderRadius: '50%', background: 'var(--bg-surface2)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <svg width="36" height="36" viewBox="0 0 24 24" fill="currentColor"><path d="M6 6h2v12H6zm3.5 6 8.5 6V6z"/></svg>
        </button>
        <button type="button" onClick={togglePlay} style={{ width: 96, height: 96, borderRadius: '50%', background: 'var(--accent)', color: '#fff', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 8px 32px var(--accent-shadow-strong)' }}>
          {isPlaying
            ? <svg width="44" height="44" viewBox="0 0 24 24" fill="currentColor"><path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/></svg>
            : <svg width="44" height="44" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>
          }
        </button>
        <button type="button" onClick={next} style={{ width: 72, height: 72, borderRadius: '50%', background: 'var(--bg-surface2)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <svg width="36" height="36" viewBox="0 0 24 24" fill="currentColor"><path d="M6 18l8.5-6L6 6v12zM16 6v12h2V6h-2z"/></svg>
        </button>
      </div>
    </div>
  )
}
