import { useRef, useState } from 'react'
import { useLibraryStore } from '../../store/libraryStore'
import { usePlayerStore } from '../../store/playerStore'
import { ArtworkDisplay } from '../ui/ArtworkDisplay'
import { AlbumCoverArt } from '../ui/AlbumCoverArt'
import { PlayableArtwork } from '../ui/PlayableArtwork'
import { SongActionsMenu } from '../ui/SongActionsMenu'
import { openSongMenu, handleSongMenuOpenChange, type SongMenuState } from '../ui/songMenuUtils'
import { ConfirmDialog } from '../ui/ConfirmDialog'
import { AppIcon } from '../ui/AppIcon'
import { FavoriteButton } from '../ui/FavoriteButton'
import { HorizontalScroller, HorizontalSongCard } from '../ui/HorizontalScroller'
import { APP_NAME } from '../../constants/appBranding'
import { showDownloadButtons } from '../../utils/platform'
import { DownloadAppButtons } from './DownloadAppButtons'
import { formatDuration, supportsDirectoryPicker } from '../../services/scannerService'
import { supportsElectronScan } from '../../services/electronScannerService'
import type { ViewName } from '../../types'

interface Props {
  onNavigate: (v: ViewName) => void
}

function getGreeting(): string {
  const h = new Date().getHours()
  if (h < 12) return 'Buenos días'
  if (h < 19) return 'Buenas tardes'
  return 'Buenas noches'
}

const LIBRARY_LINKS: { id: ViewName; label: string; icon: string }[] = [
  { id: 'artists', label: 'Artistas', icon: '🎤' },
  { id: 'albums', label: 'Álbumes', icon: '💿' },
  { id: 'genres', label: 'Géneros', icon: '🎵' },
  { id: 'songs', label: 'Canciones', icon: '🎶' },
]

export function HomeView({ onNavigate }: Props) {
  const store = useLibraryStore()
  const {
    songs, albums, isScanning, scanProgress, error,
    scanFromFiles, scanFromDirectory, scanFromElectronDefaults, scanFromElectronFolder, getAlbumSongs,
    getFavorites, getMostPlayedThisMonth, getRecentlyPlayed, getRecentlyAdded,
  } = store
  const { playSong } = usePlayerStore()
  const fileInputRef = useRef<HTMLInputElement>(null)
  const dirInputRef = useRef<HTMLInputElement>(null)
  const [menuState, setMenuState] = useState<SongMenuState | null>(null)
  const [clearStep, setClearStep] = useState<0 | 1 | 2>(0)

  const favorites = getFavorites()
  const mostPlayed = getMostPlayedThisMonth()
  const recentlyPlayed = getRecentlyPlayed()
  const recentlyAdded = getRecentlyAdded()
  const hasFsPicker = supportsDirectoryPicker()
  const hasElectronScan = supportsElectronScan()

  const handleScanMusic = () => {
    if (hasElectronScan) {
      void scanFromElectronDefaults()
      return
    }
    if (hasFsPicker) {
      void scanFromDirectory()
      return
    }
    dirInputRef.current?.click()
  }

  const handlePickFolder = () => {
    if (hasElectronScan) {
      void scanFromElectronFolder()
      return
    }
    dirInputRef.current?.click()
  }

  const progressPct = scanProgress
    ? scanProgress.phase === 'discovering'
      ? scanProgress.foldersScanned != null
        ? Math.min(92, 8 + (scanProgress.foldersScanned % 120))
        : Math.min(95, scanProgress.total > 0 ? 30 + (scanProgress.total % 50) : 10)
      : Math.round((scanProgress.processed / Math.max(scanProgress.total, 1)) * 100)
    : 0

  const progressLabel = scanProgress
    ? scanProgress.phase === 'discovering'
      ? scanProgress.foldersScanned != null
        ? `${scanProgress.current}${scanProgress.total ? ` · ${scanProgress.total} archivos` : ''}`
        : scanProgress.current
      : `Procesando ${scanProgress.processed}/${scanProgress.total}: ${scanProgress.current}`
    : ''

  return (
    <div className="scrollable mobile-page" style={{ flex: 1, padding: '24px 28px', display: 'flex', flexDirection: 'column', gap: 28 }}>
      <ConfirmDialog open={clearStep === 1} title="Limpiar biblioteca" message={`¿Eliminar las ${songs.length} canciones?`} confirmLabel="Continuar" onConfirm={() => setClearStep(2)} onCancel={() => setClearStep(0)} />
      <ConfirmDialog open={clearStep === 2} title="Confirmación final" message="Esta acción no se puede deshacer." confirmLabel="Sí, limpiar todo" onConfirm={async () => { await useLibraryStore.getState().clearLibrary(); setClearStep(0) }} onCancel={() => setClearStep(0)} />

      {/* Header */}
      <header className="home-header">
        <div className="home-header-brand">
          <p style={{ fontSize: 14, color: 'var(--text-secondary)', marginBottom: 4 }}>{getGreeting()}</p>
          <h1 style={{ fontSize: 28, fontWeight: 800, letterSpacing: 0.5, color: 'var(--accent)', lineHeight: 1.15 }}>
            {APP_NAME}
          </h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: 13, marginTop: 4 }}>
            {songs.length > 0 ? `${songs.length} canciones · ${albums.length} álbumes` : 'Tu biblioteca de música local'}
          </p>
        </div>
        <div className="home-header-aside">
          {showDownloadButtons && <DownloadAppButtons />}
          <button
            type="button"
            onClick={() => onNavigate('search')}
            aria-label="Buscar"
            className="home-search-btn"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="var(--text-secondary)"><path d="M15.5 14h-.79l-.28-.27C15.41 12.59 16 11.11 16 9.5 16 5.91 13.09 3 9.5 3S3 5.91 3 9.5 5.91 16 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z"/></svg>
          </button>
        </div>
      </header>

      {/* Scan */}
      <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
        <button type="button" onClick={handleScanMusic} disabled={isScanning}
          style={{ padding: '10px 16px', borderRadius: 'var(--radius-md)', background: 'var(--accent)', color: '#fff', fontSize: 13, fontWeight: 600, cursor: 'pointer', opacity: isScanning ? 0.6 : 1 }}>
          {hasElectronScan ? 'Escanear dispositivo' : 'Escanear música'}
        </button>
        <button type="button" onClick={hasElectronScan ? handlePickFolder : () => fileInputRef.current?.click()} disabled={isScanning}
          style={{ padding: '10px 16px', borderRadius: 'var(--radius-md)', background: 'var(--bg-surface)', border: '1px solid var(--border)', fontSize: 13, cursor: 'pointer' }}>
          {hasElectronScan ? 'Elegir carpeta…' : 'Agregar archivos'}
        </button>
        {songs.length > 0 && (
          <button type="button" onClick={() => setClearStep(1)} style={{ padding: '10px 16px', borderRadius: 'var(--radius-md)', border: '1px solid var(--border)', fontSize: 13, color: 'var(--text-secondary)', cursor: 'pointer' }}>
            Limpiar
          </button>
        )}
      </div>

      <input ref={fileInputRef} type="file" accept="audio/*,.lrc" multiple hidden onChange={(e) => { const f = Array.from(e.target.files ?? []); if (f.length) scanFromFiles(f); e.target.value = '' }} />
      <input ref={dirInputRef} type="file" // @ts-expect-error webkitdirectory
        webkitdirectory="" directory="" multiple hidden onChange={(e) => { const f = Array.from(e.target.files ?? []); if (f.length) scanFromFiles(f); e.target.value = '' }} />

      {error && !isScanning && <div style={{ padding: 12, borderRadius: 'var(--radius-md)', background: 'var(--accent-soft-10)', color: 'var(--accent)', fontSize: 13 }}>{error}</div>}
      {isScanning && (
        <div style={{ padding: 14, background: 'var(--bg-surface)', borderRadius: 'var(--radius-md)', border: '1px solid var(--border)' }}>
          <p style={{ fontSize: 12, color: 'var(--text-secondary)', marginBottom: 8, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
            {progressLabel}
          </p>
          <div style={{ height: 4, background: 'var(--bg-surface3)', borderRadius: 2 }}>
            <div style={{ height: '100%', width: `${progressPct}%`, background: 'var(--accent)', borderRadius: 2, transition: 'width 0.2s' }} />
          </div>
        </div>
      )}

      {songs.length === 0 && !isScanning && (
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 12, padding: '40px 0' }}>
          <AppIcon size={72} borderRadius={16} />
          <p style={{ color: 'var(--text-secondary)', textAlign: 'center' }}>Escanea tu música para comenzar</p>
        </div>
      )}

      {/* Tu Actividad */}
      {songs.length > 0 && (
        <>
          {favorites.length > 0 && (
            <HorizontalScroller title="Favoritas" actionLabel="Ver todo" onAction={() => onNavigate('songs')}>
              {favorites.slice(0, 12).map((song) => (
                <HorizontalSongCard
                  key={song.id}
                  title={song.title}
                  subtitle={song.artist}
                  onClick={() => playSong(song, favorites)}
                  artwork={<ArtworkDisplay song={song} size={120} borderRadius={12} style={{ width: '100%', height: '100%' }} />}
                  badge={<div style={{ position: 'absolute', top: 6, right: 6 }}><FavoriteButton song={song} size={18} /></div>}
                />
              ))}
            </HorizontalScroller>
          )}

          {mostPlayed.length > 0 && (
            <HorizontalScroller title="Lo más escuchado del mes">
              {mostPlayed.map((song) => (
                <HorizontalSongCard
                  key={song.id}
                  title={song.title}
                  subtitle={`${song.playCount ?? 0} reproducciones`}
                  onClick={() => playSong(song, mostPlayed)}
                  artwork={<ArtworkDisplay song={song} size={120} borderRadius={12} style={{ width: '100%', height: '100%' }} />}
                />
              ))}
            </HorizontalScroller>
          )}

          {recentlyPlayed.length > 0 && (
            <HorizontalScroller title="Recientes">
              {recentlyPlayed.map((song) => (
                <HorizontalSongCard
                  key={song.id}
                  title={song.title}
                  subtitle={song.artist}
                  onClick={() => playSong(song, recentlyPlayed)}
                  artwork={<ArtworkDisplay song={song} size={120} borderRadius={12} style={{ width: '100%', height: '100%' }} />}
                />
              ))}
            </HorizontalScroller>
          )}

          {/* Biblioteca */}
          <section>
            <h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 12 }}>Biblioteca</h2>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 10 }}>
              {LIBRARY_LINKS.map((link) => (
                <button
                  key={link.id}
                  type="button"
                  onClick={() => onNavigate(link.id)}
                  style={{
                    padding: '16px 14px', borderRadius: 'var(--radius-md)',
                    background: 'var(--bg-surface)', border: '1px solid var(--border)',
                    textAlign: 'left', cursor: 'pointer',
                    display: 'flex', alignItems: 'center', gap: 10,
                  }}
                >
                  <span style={{ fontSize: 22 }}>{link.icon}</span>
                  <span style={{ fontSize: 14, fontWeight: 600 }}>{link.label}</span>
                </button>
              ))}
            </div>
          </section>

          {recentlyAdded.length > 0 && (
            <section>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12 }}>
                <h2 style={{ fontSize: 18, fontWeight: 700 }}>Recién añadidas</h2>
                <button type="button" onClick={() => onNavigate('songs')} style={{ fontSize: 13, color: 'var(--accent)', cursor: 'pointer' }}>Ver todo</button>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }} onClick={() => setMenuState(null)}>
                {recentlyAdded.slice(0, 8).map((song) => (
                  <div key={song.id} onClick={() => playSong(song, recentlyAdded)} onContextMenu={(e) => setMenuState(openSongMenu(e, song.id))}
                    style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 12px', borderRadius: 'var(--radius-md)', cursor: 'pointer' }}
                    onMouseEnter={(e) => { e.currentTarget.style.background = 'var(--bg-surface)' }}
                    onMouseLeave={(e) => { e.currentTarget.style.background = 'transparent' }}>
                    <PlayableArtwork song={song} size={40} borderRadius={5} onPlay={() => playSong(song, recentlyAdded)} />
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 13, fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{song.title}</div>
                      <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{song.artist}</div>
                    </div>
                    <FavoriteButton song={song} size={18} />
                    <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{formatDuration(song.duration)}</span>
                    <SongActionsMenu song={song} open={menuState?.songId === song.id} anchorPoint={menuState?.songId === song.id ? (menuState.anchor ?? null) : null} onOpenChange={(open) => handleSongMenuOpenChange(open, song.id, setMenuState)} />
                  </div>
                ))}
              </div>
            </section>
          )}

          {albums.length > 0 && (
            <section>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12 }}>
                <h2 style={{ fontSize: 18, fontWeight: 700 }}>Álbumes destacados</h2>
                <button type="button" onClick={() => onNavigate('albums')} style={{ fontSize: 13, color: 'var(--accent)', cursor: 'pointer' }}>Ver todo</button>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(120px, 1fr))', gap: 14 }}>
                {albums.slice(0, 8).map((album) => {
                  const albumSongs = getAlbumSongs(album.id)
                  return (
                    <div key={album.id} onClick={() => onNavigate('albums')} style={{ cursor: 'pointer' }}>
                      <AlbumCoverArt
                        artwork={album.artwork}
                        title={album.title}
                        artist={album.artist}
                        album={album.title}
                        size={120}
                        borderRadius={10}
                        menuSong={albumSongs[0] ?? null}
                        albumMenu={{
                          id: album.id,
                          title: album.title,
                          artist: album.artist,
                          songIds: albumSongs.map((s) => s.id),
                        }}
                        style={{ width: '100%', aspectRatio: '1' }}
                      />
                      <div style={{ marginTop: 6, fontSize: 12, fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{album.title}</div>
                    </div>
                  )
                })}
              </div>
            </section>
          )}
        </>
      )}
    </div>
  )
}
