import { useState } from 'react'
import { useLibraryStore } from '../../store/libraryStore'
import { usePlayerStore } from '../../store/playerStore'
import { AlbumCoverArt } from '../ui/AlbumCoverArt'
import { PlayableArtwork } from '../ui/PlayableArtwork'
import { SongActionsMenu } from '../ui/SongActionsMenu'
import { openSongMenu, handleSongMenuOpenChange, type SongMenuState } from '../ui/songMenuUtils'
import { formatDuration } from '../../services/scannerService'
import type { Album } from '../../types'

export function AlbumsView() {
  const { albums, getAlbumSongs } = useLibraryStore()
  const { playSong } = usePlayerStore()
  const [selected, setSelected] = useState<Album | null>(null)
  const [search, setSearch] = useState('')
  const [menuState, setMenuState] = useState<SongMenuState | null>(null)

  const filtered = albums.filter((a) =>
    !search.trim() || a.title.toLowerCase().includes(search.toLowerCase()) || a.artist.toLowerCase().includes(search.toLowerCase()),
  )

  if (selected) {
    const albumSongs = getAlbumSongs(selected.id)
    const albumMenu = {
      id: selected.id,
      title: selected.title,
      artist: selected.artist,
      songIds: albumSongs.map((s) => s.id),
    }

    const handleSongDeletedFromAlbum = () => {
      const remaining = useLibraryStore.getState().getAlbumSongs(selected.id)
      if (remaining.length === 0) setSelected(null)
    }

    return (
      <div className="view-panel">
        <div className="scrollable view-scroll" onClick={() => setMenuState(null)}>
          <div className="view-back">
            <button
              type="button"
              onClick={() => setSelected(null)}
              style={{ color: 'var(--text-secondary)', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 4, fontSize: 14 }}
            >
              <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z"/></svg>
              Álbumes
            </button>
          </div>

          <div className="album-detail-header">
            <AlbumCoverArt
              artwork={selected.artwork}
              title={selected.title}
              artist={selected.artist}
              album={selected.title}
              size={140}
              borderRadius={12}
              menuSong={albumSongs[0] ?? null}
              albumMenu={albumMenu}
              onAlbumDeleted={() => setSelected(null)}
              style={{ width: 140, height: 140, flexShrink: 0 }}
            />
            <div style={{ minWidth: 0 }}>
              <div style={{ fontSize: 'clamp(20px, 5vw, 24px)', fontWeight: 800, marginBottom: 4, wordBreak: 'break-word' }}>{selected.title}</div>
              <div style={{ fontSize: 16, color: 'var(--text-secondary)', marginBottom: 8 }}>{selected.artist}</div>
              <div style={{ fontSize: 13, color: 'var(--text-tertiary)', marginBottom: 16 }}>{albumSongs.length} canciones</div>
              <button
                type="button"
                onClick={() => playSong(albumSongs[0], albumSongs)}
                disabled={albumSongs.length === 0}
                style={{
                  padding: '10px 20px', borderRadius: 'var(--radius-md)', background: 'var(--accent)', color: '#fff',
                  fontSize: 14, fontWeight: 600, cursor: albumSongs.length === 0 ? 'not-allowed' : 'pointer',
                  display: 'inline-flex', alignItems: 'center', gap: 6, opacity: albumSongs.length === 0 ? 0.5 : 1,
                }}
              >
                <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>
                Reproducir álbum
              </button>
            </div>
          </div>

          <div className="album-detail-tracks">
            {albumSongs.map((song, i) => (
              <div
                key={song.id}
                onClick={() => playSong(song, albumSongs)}
                onContextMenu={(e) => setMenuState(openSongMenu(e, song.id))}
                style={{
                  display: 'flex', alignItems: 'center', gap: 12, padding: '10px 0',
                  borderBottom: '1px solid var(--border)', cursor: 'pointer',
                }}
              >
                <span style={{ width: 28, textAlign: 'center', fontSize: 12, color: 'var(--text-tertiary)', flexShrink: 0 }}>
                  {song.trackNumber || i + 1}
                </span>
                <PlayableArtwork song={song} size={38} borderRadius={4} onPlay={() => playSong(song, albumSongs)} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 14, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{song.title}</div>
                </div>
                <span style={{ fontSize: 12, color: 'var(--text-secondary)', flexShrink: 0 }}>{formatDuration(song.duration)}</span>
                <SongActionsMenu
                  song={song}
                  open={menuState?.songId === song.id}
                  anchorPoint={menuState?.songId === song.id ? (menuState.anchor ?? null) : null}
                  onOpenChange={(open) => handleSongMenuOpenChange(open, song.id, setMenuState)}
                  onAfterDelete={handleSongDeletedFromAlbum}
                />
              </div>
            ))}
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="view-panel">
      <div className="view-header">
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 12 }}>Álbumes</h1>
        <input
          type="text" placeholder="Buscar álbumes..." value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{ width: '100%', maxWidth: 360, padding: '9px 12px', background: 'var(--bg-surface)', border: '1px solid var(--border)', borderRadius: 'var(--radius-md)', fontSize: 14, color: 'var(--text-primary)', outline: 'none' }}
        />
      </div>
      <div className="scrollable view-scroll view-list-pad">
        {filtered.length === 0 ? (
          <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-secondary)' }}>Sin álbumes</div>
        ) : (
          <div className="albums-grid" style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(150px, 1fr))', gap: 20 }}>
            {filtered.map((album) => {
              const albumSongs = getAlbumSongs(album.id)
              return (
                <div
                  key={album.id}
                  onClick={() => setSelected(album)}
                  style={{ cursor: 'pointer', transition: 'transform 0.15s' }}
                  onMouseEnter={(e) => { e.currentTarget.style.transform = 'translateY(-3px)' }}
                  onMouseLeave={(e) => { e.currentTarget.style.transform = 'translateY(0)' }}
                >
                  <div style={{ width: '100%', aspectRatio: '1', borderRadius: 10, background: 'var(--bg-surface)', marginBottom: 8 }}>
                    <AlbumCoverArt
                      artwork={album.artwork}
                      title={album.title}
                      artist={album.artist}
                      album={album.title}
                      size={150}
                      borderRadius={10}
                      menuSong={albumSongs[0] ?? null}
                      albumMenu={{
                        id: album.id,
                        title: album.title,
                        artist: album.artist,
                        songIds: albumSongs.map((s) => s.id),
                      }}
                      style={{ width: '100%', height: '100%' }}
                    />
                  </div>
                  <div style={{ fontSize: 13, fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{album.title}</div>
                  <div style={{ fontSize: 12, color: 'var(--text-secondary)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{album.artist}</div>
                </div>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}
