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
import { APP_NAME } from '../../constants/appBranding'
import { formatDuration, supportsDirectoryPicker } from '../../services/scannerService'
import type { ViewName } from '../../types'

interface Props {
  onNavigate: (v: ViewName) => void
}

export function HomeView({ onNavigate }: Props) {
  const { songs, albums, isScanning, scanProgress, error,
    scanFromFiles, scanFromDirectory, getAlbumSongs,
  } = useLibraryStore()
  const { playSong } = usePlayerStore()
  const fileInputRef = useRef<HTMLInputElement>(null)
  const dirInputRef = useRef<HTMLInputElement>(null)
  const [menuState, setMenuState] = useState<SongMenuState | null>(null)
  const [clearStep, setClearStep] = useState<0 | 1 | 2>(0)

  const recent = [...songs].sort((a, b) => b.dateAdded - a.dateAdded).slice(0, 10)
  const hasFsPicker = supportsDirectoryPicker()

  const progressLabel = scanProgress?.phase === 'discovering'
    ? `Explorando${scanProgress.foldersScanned ? ` · ${scanProgress.foldersScanned} carpetas` : ''}`
    : 'Procesando'

  const progressPct = scanProgress
    ? scanProgress.phase === 'discovering'
      ? Math.min(95, scanProgress.total > 0 ? 30 + (scanProgress.total % 50) : 10)
      : Math.round((scanProgress.processed / Math.max(scanProgress.total, 1)) * 100)
    : 0

  return (
    <div className="scrollable mobile-page" style={{ flex: 1, padding: '24px 28px', display: 'flex', flexDirection: 'column', gap: 32 }}>
      <ConfirmDialog
        open={clearStep === 1}
        title="Limpiar biblioteca"
        message={`¿Estás seguro de que quieres eliminar todas las ${songs.length} canciones de tu biblioteca?`}
        confirmLabel="Continuar"
        onConfirm={() => setClearStep(2)}
        onCancel={() => setClearStep(0)}
      />
      <ConfirmDialog
        open={clearStep === 2}
        title="Confirmación final"
        message="Esta acción borrará toda tu biblioteca de forma permanente y no se puede deshacer. ¿Deseas continuar?"
        confirmLabel="Sí, limpiar todo"
        onConfirm={async () => {
          await useLibraryStore.getState().clearLibrary()
          setClearStep(0)
        }}
        onCancel={() => setClearStep(0)}
      />

      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
        <AppIcon size={64} borderRadius={14} />
        <div>
          <h1 style={{ fontSize: 28, fontWeight: 800, letterSpacing: 0.5, color: 'var(--accent)', marginBottom: 4 }}>
            {APP_NAME}
          </h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: 14 }}>
            {songs.length > 0 ? `${songs.length} canciones · ${albums.length} álbumes` : 'Tu biblioteca de música local'}
          </p>
        </div>
      </div>

      {/* Scan buttons */}
      <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', alignItems: 'center' }}>
        {hasFsPicker ? (
          <button
            onClick={() => scanFromDirectory()}
            disabled={isScanning}
            style={{
              padding: '12px 20px', borderRadius: 'var(--radius-md)',
              background: 'var(--accent)', color: '#fff',
              fontSize: 14, fontWeight: 600, cursor: isScanning ? 'not-allowed' : 'pointer',
              display: 'flex', alignItems: 'center', gap: 8,
              opacity: isScanning ? 0.6 : 1,
            }}
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M10 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2h-8l-2-2z"/></svg>
            Escanear disco o carpeta
          </button>
        ) : (
          <button
            onClick={() => dirInputRef.current?.click()}
            disabled={isScanning}
            style={{
              padding: '12px 20px', borderRadius: 'var(--radius-md)',
              background: 'var(--accent)', color: '#fff',
              fontSize: 14, fontWeight: 600, cursor: isScanning ? 'not-allowed' : 'pointer',
              display: 'flex', alignItems: 'center', gap: 8,
              opacity: isScanning ? 0.6 : 1,
            }}
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M10 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2h-8l-2-2z"/></svg>
            Escanear carpeta
          </button>
        )}

        <button
          onClick={() => fileInputRef.current?.click()}
          disabled={isScanning}
          style={{
            padding: '12px 20px', borderRadius: 'var(--radius-md)',
            background: 'var(--bg-surface2)', color: 'var(--text-primary)',
            fontSize: 14, fontWeight: 600, cursor: isScanning ? 'not-allowed' : 'pointer',
            display: 'flex', alignItems: 'center', gap: 8, border: '1px solid var(--border)',
            opacity: isScanning ? 0.6 : 1,
          }}
        >
          <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M9 16h6v-6h4l-7-7-7 7h4zm-4 2h14v2H5z"/></svg>
          Agregar archivos
        </button>

        {hasFsPicker && (
          <button
            onClick={() => dirInputRef.current?.click()}
            disabled={isScanning}
            style={{
              padding: '12px 20px', borderRadius: 'var(--radius-md)',
              background: 'transparent', color: 'var(--text-secondary)',
              fontSize: 14, cursor: isScanning ? 'not-allowed' : 'pointer',
              border: '1px solid var(--border)',
              opacity: isScanning ? 0.6 : 1,
            }}
          >
            Carpeta (alternativo)
          </button>
        )}

        {songs.length > 0 && (
          <button
            onClick={() => setClearStep(1)}
            style={{
              padding: '12px 20px', borderRadius: 'var(--radius-md)',
              background: 'transparent', color: 'var(--text-secondary)',
              fontSize: 14, cursor: 'pointer', border: '1px solid var(--border)',
            }}
          >
            Limpiar biblioteca
          </button>
        )}
      </div>

      <p style={{ fontSize: 12, color: 'var(--text-tertiary)', marginTop: -20, lineHeight: 1.5 }}>
        Puedes seleccionar un disco completo (por ejemplo <strong>C:\</strong> en Windows o tu carpeta Música).
        El navegador pedirá permiso de lectura; acéptalo para escanear todas las subcarpetas.
      </p>

      {/* Hidden inputs */}
      <input
        ref={fileInputRef}
        type="file"
        accept="audio/*"
        multiple
        style={{ display: 'none' }}
        onChange={(e) => {
          const files = Array.from(e.target.files ?? [])
          if (files.length) scanFromFiles(files)
          e.target.value = ''
        }}
      />
      <input
        ref={dirInputRef}
        type="file"
        // @ts-expect-error webkitdirectory no está en todos los typings
        webkitdirectory=""
        directory=""
        multiple
        style={{ display: 'none' }}
        onChange={(e) => {
          const files = Array.from(e.target.files ?? [])
          if (files.length) scanFromFiles(files)
          e.target.value = ''
        }}
      />

      {/* Error */}
      {error && !isScanning && (
        <div style={{
          padding: '12px 16px', borderRadius: 'var(--radius-md)',
          background: 'rgba(255,32,32,0.1)', border: '1px solid rgba(255,32,32,0.3)',
          color: 'var(--accent)', fontSize: 13,
        }}>
          {error}
        </div>
      )}

      {/* Scan progress */}
      {isScanning && (
        <div style={{ padding: 16, background: 'var(--bg-surface)', borderRadius: 'var(--radius-md)', border: '1px solid var(--border)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
            <span style={{ fontSize: 13, color: 'var(--text-secondary)' }}>
              {progressLabel}
              {scanProgress?.phase === 'processing' && scanProgress.total > 0
                ? ` · ${scanProgress.processed} / ${scanProgress.total}`
                : scanProgress?.total
                  ? ` · ${scanProgress.total} archivos encontrados`
                  : ''}
            </span>
            {scanProgress?.phase === 'processing' && (
              <span style={{ fontSize: 13, color: 'var(--accent)' }}>{progressPct}%</span>
            )}
          </div>
          <div style={{ height: 4, background: 'var(--bg-surface3)', borderRadius: 2 }}>
            <div style={{
              height: '100%', borderRadius: 2, background: 'var(--accent)',
              width: `${progressPct}%`,
              transition: 'width 0.2s',
            }} />
          </div>
          {scanProgress?.current && (
            <div style={{ fontSize: 11, color: 'var(--text-tertiary)', marginTop: 6, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
              {scanProgress.current}
            </div>
          )}
        </div>
      )}

      {/* Empty state */}
      {songs.length === 0 && !isScanning && (
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 16, padding: '60px 0' }}>
          <AppIcon size={80} borderRadius={18} />
          <p style={{ color: 'var(--text-secondary)', textAlign: 'center' }}>No hay música. Escanea un disco o carpeta para comenzar.</p>
        </div>
      )}

      {/* Recently added */}
      {recent.length > 0 && (
        <section>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
            <h2 style={{ fontSize: 18, fontWeight: 700 }}>Recientes</h2>
            <button onClick={() => onNavigate('songs')} style={{ fontSize: 13, color: 'var(--accent)', cursor: 'pointer' }}>Ver todo</button>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }} onClick={() => setMenuState(null)}>
            {recent.map((song) => (
              <div
                key={song.id}
                onClick={() => playSong(song, recent)}
                onContextMenu={(e) => setMenuState(openSongMenu(e, song.id))}
                style={{
                  display: 'flex', alignItems: 'center', gap: 12,
                  padding: '10px 12px', borderRadius: 'var(--radius-md)',
                  cursor: 'pointer', transition: 'background 0.15s',
                }}
                onMouseEnter={(e) => { e.currentTarget.style.background = 'var(--bg-surface)' }}
                onMouseLeave={(e) => { e.currentTarget.style.background = 'transparent' }}
              >
                <PlayableArtwork song={song} size={40} borderRadius={5} onPlay={() => playSong(song, recent)} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 13, fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{song.title}</div>
                  <div style={{ fontSize: 12, color: 'var(--text-secondary)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{song.artist} · {song.album}</div>
                </div>
                <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{formatDuration(song.duration)}</span>
                <SongActionsMenu
                  song={song}
                  open={menuState?.songId === song.id}
                  anchorPoint={menuState?.songId === song.id ? (menuState.anchor ?? null) : null}
                  onOpenChange={(open) => handleSongMenuOpenChange(open, song.id, setMenuState)}
                />
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Albums grid */}
      {albums.length > 0 && (
        <section>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
            <h2 style={{ fontSize: 18, fontWeight: 700 }}>Álbumes</h2>
            <button onClick={() => onNavigate('albums')} style={{ fontSize: 13, color: 'var(--accent)', cursor: 'pointer' }}>Ver todo</button>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(130px, 1fr))', gap: 16 }}>
            {albums.slice(0, 12).map((album) => {
              const albumSongs = getAlbumSongs(album.id)
              return (
              <div
                key={album.id}
                onClick={() => onNavigate('albums')}
                style={{ cursor: 'pointer', transition: 'transform 0.15s' }}
                onMouseEnter={(e) => { e.currentTarget.style.transform = 'translateY(-2px)' }}
                onMouseLeave={(e) => { e.currentTarget.style.transform = 'translateY(0)' }}
              >
                <AlbumCoverArt
                  artwork={album.artwork}
                  title={album.title}
                  artist={album.artist}
                  album={album.title}
                  size={130}
                  borderRadius={10}
                  menuSong={albumSongs[0] ?? null}
                  style={{ width: '100%', height: 'auto', aspectRatio: '1' }}
                />
                <div style={{ marginTop: 8 }}>
                  <div style={{ fontSize: 13, fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{album.title}</div>
                  <div style={{ fontSize: 12, color: 'var(--text-secondary)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{album.artist}</div>
                </div>
              </div>
            )})}
          </div>
        </section>
      )}
    </div>
  )
}
