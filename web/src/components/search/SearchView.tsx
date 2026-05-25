import { useState, useMemo } from 'react'
import { useLibraryStore } from '../../store/libraryStore'
import { usePlayerStore } from '../../store/playerStore'
import { searchLibrary } from '../../services/searchService'
import { ArtworkDisplay } from '../ui/ArtworkDisplay'
import { AlbumCoverArt } from '../ui/AlbumCoverArt'
import { PlayableArtwork } from '../ui/PlayableArtwork'
import { SongActionsMenu } from '../ui/SongActionsMenu'
import { FavoriteButton } from '../ui/FavoriteButton'
import { openSongMenu, handleSongMenuOpenChange, type SongMenuState } from '../ui/songMenuUtils'
import { formatDuration } from '../../services/scannerService'

export function SearchView() {
  const [query, setQuery] = useState('')
  const [menuState, setMenuState] = useState<SongMenuState | null>(null)
  const { songs, albums, artists, genres, getAlbumSongs } = useLibraryStore()
  const { playSong } = usePlayerStore()

  const results = useMemo(
    () => searchLibrary(query, songs, albums, artists, genres),
    [query, songs, albums, artists, genres],
  )

  const hasResults = results.songs.length + results.albums.length + results.artists.length + results.genres.length > 0

  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
      <div style={{ padding: '24px 28px 16px', flexShrink: 0 }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 16 }}>Buscar</h1>
        <div style={{ position: 'relative' }}>
          <svg style={{ position: 'absolute', left: 14, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-secondary)' }} width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
            <path d="M15.5 14h-.79l-.28-.27C15.41 12.59 16 11.11 16 9.5 16 5.91 13.09 3 9.5 3S3 5.91 3 9.5 5.91 16 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z"/>
          </svg>
          <input
            autoFocus
            type="text"
            placeholder="Título, artista, álbum, género, año, compositor..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            style={{
              width: '100%', padding: '12px 16px 12px 44px',
              background: 'var(--bg-surface)', border: '1px solid var(--border)',
              borderRadius: 'var(--radius-lg)', fontSize: 16, color: 'var(--text-primary)',
              outline: 'none',
            }}
            onFocus={(e) => { e.target.style.borderColor = 'var(--accent)' }}
            onBlur={(e) => { e.target.style.borderColor = 'var(--border)' }}
          />
        </div>
        <p style={{ fontSize: 11, color: 'var(--text-tertiary)', marginTop: 8 }}>
          Búsqueda en tiempo real por metadatos indexados
        </p>
      </div>

      <div className="scrollable" style={{ flex: 1, padding: '0 28px 24px' }} onClick={() => setMenuState(null)}>
        {!query.trim() ? (
          <div style={{ padding: '60px 0', textAlign: 'center', color: 'var(--text-secondary)' }}>
            <p>Escribe para buscar en tu biblioteca</p>
          </div>
        ) : !hasResults ? (
          <div style={{ padding: '60px 0', textAlign: 'center', color: 'var(--text-secondary)' }}>
            Sin resultados para &quot;{query}&quot;
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 28 }}>
            {results.songs.length > 0 && (
              <section>
                <div style={{ fontSize: 13, fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: 1, marginBottom: 10 }}>Canciones</div>
                {results.songs.map((song) => (
                  <div key={song.id} onClick={() => playSong(song, results.songs)} onContextMenu={(e) => setMenuState(openSongMenu(e, song.id))}
                    style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '8px 0', borderBottom: '1px solid var(--border)', cursor: 'pointer' }}>
                    <PlayableArtwork song={song} size={40} borderRadius={5} onPlay={() => playSong(song, results.songs)} />
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 13, fontWeight: 600 }}>{highlightMatch(song.title, query)}</div>
                      <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>
                        {song.artist} · {song.album}
                        {song.year ? ` · ${song.year}` : ''}
                        {song.genre ? ` · ${song.genre}` : ''}
                      </div>
                    </div>
                    <FavoriteButton song={song} size={16} />
                    <SongActionsMenu song={song} open={menuState?.songId === song.id} anchorPoint={menuState?.songId === song.id ? (menuState.anchor ?? null) : null} onOpenChange={(open) => handleSongMenuOpenChange(open, song.id, setMenuState)} />
                  </div>
                ))}
              </section>
            )}
            {results.genres.length > 0 && (
              <section>
                <div style={{ fontSize: 13, fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: 1, marginBottom: 10 }}>Géneros</div>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
                  {results.genres.map((g) => (
                    <span key={g.id} style={{ padding: '6px 12px', borderRadius: 20, background: 'var(--bg-surface)', fontSize: 13 }}>
                      {highlightMatch(g.name, query)} ({g.songIds.length})
                    </span>
                  ))}
                </div>
              </section>
            )}
            {results.artists.length > 0 && (
              <section>
                <div style={{ fontSize: 13, fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: 1, marginBottom: 10 }}>Artistas</div>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 12 }}>
                  {results.artists.map((artist) => (
                    <div key={artist.id} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 12px', background: 'var(--bg-surface)', borderRadius: 'var(--radius-md)' }}>
                      <ArtworkDisplay artwork={artist.artwork} artist={artist.name} title={artist.name} size={36} borderRadius={18} />
                      <div>
                        <div style={{ fontSize: 13, fontWeight: 600 }}>{highlightMatch(artist.name, query)}</div>
                        <div style={{ fontSize: 11, color: 'var(--text-secondary)' }}>{artist.songIds.length} canciones</div>
                      </div>
                    </div>
                  ))}
                </div>
              </section>
            )}
            {results.albums.length > 0 && (
              <section>
                <div style={{ fontSize: 13, fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: 1, marginBottom: 10 }}>Álbumes</div>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(120px, 1fr))', gap: 14 }}>
                  {results.albums.map((album) => {
                    const albumSongs = getAlbumSongs(album.id)
                    return (
                      <div key={album.id}>
                        <AlbumCoverArt artwork={album.artwork} title={album.title} artist={album.artist} album={album.title} size={120} borderRadius={8} menuSong={albumSongs[0] ?? null} style={{ width: '100%', aspectRatio: '1' }} />
                        <div style={{ fontSize: 12, fontWeight: 600, marginTop: 4 }}>{album.title}</div>
                      </div>
                    )
                  })}
                </div>
              </section>
            )}
          </div>
        )}
      </div>
    </div>
  )
}

function highlightMatch(text: string, query: string): React.ReactNode {
  const idx = text.toLowerCase().indexOf(query.toLowerCase())
  if (idx === -1) return text
  return (
    <>
      {text.slice(0, idx)}
      <span style={{ color: 'var(--accent)', fontWeight: 700 }}>{text.slice(idx, idx + query.length)}</span>
      {text.slice(idx + query.length)}
    </>
  )
}
