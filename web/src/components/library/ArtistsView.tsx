import { useState } from 'react'
import { useLibraryStore } from '../../store/libraryStore'
import { usePlayerStore } from '../../store/playerStore'
import { ArtworkDisplay } from '../ui/ArtworkDisplay'
import { PlayableArtwork } from '../ui/PlayableArtwork'
import { SongActionsMenu } from '../ui/SongActionsMenu'
import { openSongMenu, handleSongMenuOpenChange, type SongMenuState } from '../ui/songMenuUtils'
import { formatDuration } from '../../services/scannerService'
import type { Artist } from '../../types'

export function ArtistsView() {
  const { artists, getArtistSongs } = useLibraryStore()
  const { playSong } = usePlayerStore()
  const [selected, setSelected] = useState<Artist | null>(null)
  const [search, setSearch] = useState('')
  const [menuState, setMenuState] = useState<SongMenuState | null>(null)

  const filtered = artists.filter((a) =>
    !search.trim() || a.name.toLowerCase().includes(search.toLowerCase()),
  )

  if (selected) {
    const artistSongs = getArtistSongs(selected.id)
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
              Artistas
            </button>
          </div>

          <div className="album-detail-header">
            <div style={{ width: 80, height: 80, borderRadius: '50%', overflow: 'hidden', flexShrink: 0, background: 'var(--bg-surface)' }}>
              <ArtworkDisplay artwork={selected.artwork} artist={selected.name} title={selected.name} size={80} borderRadius={40} />
            </div>
            <div style={{ minWidth: 0 }}>
              <div style={{ fontSize: 'clamp(20px, 5vw, 22px)', fontWeight: 800, wordBreak: 'break-word' }}>{selected.name}</div>
              <div style={{ fontSize: 13, color: 'var(--text-secondary)', marginTop: 4 }}>{artistSongs.length} canciones</div>
              <button
                type="button"
                onClick={() => playSong(artistSongs[0], artistSongs)}
                disabled={artistSongs.length === 0}
                style={{
                  marginTop: 10, padding: '8px 16px', borderRadius: 'var(--radius-md)', background: 'var(--accent)', color: '#fff',
                  fontSize: 13, fontWeight: 600, cursor: artistSongs.length === 0 ? 'not-allowed' : 'pointer',
                  display: 'inline-flex', alignItems: 'center', gap: 6, opacity: artistSongs.length === 0 ? 0.5 : 1,
                }}
              >
                <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>
                Reproducir
              </button>
            </div>
          </div>

          <div className="album-detail-tracks">
            {artistSongs.map((song) => (
              <div
                key={song.id}
                onClick={() => playSong(song, artistSongs)}
                onContextMenu={(e) => setMenuState(openSongMenu(e, song.id))}
                style={{
                  display: 'flex', alignItems: 'center', gap: 12, padding: '8px 0',
                  borderBottom: '1px solid var(--border)', cursor: 'pointer',
                }}
              >
                <PlayableArtwork song={song} size={38} borderRadius={4} onPlay={() => playSong(song, artistSongs)} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 13, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{song.title}</div>
                  <div style={{ fontSize: 12, color: 'var(--text-secondary)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{song.album}</div>
                </div>
                <span style={{ fontSize: 12, color: 'var(--text-secondary)', flexShrink: 0 }}>{formatDuration(song.duration)}</span>
                <SongActionsMenu
                  song={song}
                  open={menuState?.songId === song.id}
                  anchorPoint={menuState?.songId === song.id ? (menuState.anchor ?? null) : null}
                  onOpenChange={(open) => handleSongMenuOpenChange(open, song.id, setMenuState)}
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
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 12 }}>Artistas</h1>
        <input
          type="text" placeholder="Buscar artistas..." value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{ width: '100%', maxWidth: 360, padding: '9px 12px', background: 'var(--bg-surface)', border: '1px solid var(--border)', borderRadius: 'var(--radius-md)', fontSize: 14, color: 'var(--text-primary)', outline: 'none' }}
        />
      </div>
      <div className="scrollable view-scroll view-list-pad">
        {filtered.length === 0 ? (
          <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-secondary)' }}>Sin artistas</div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
            {filtered.map((artist) => (
              <div
                key={artist.id}
                onClick={() => setSelected(artist)}
                style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '10px 12px', borderRadius: 'var(--radius-md)', cursor: 'pointer' }}
                onMouseEnter={(e) => { e.currentTarget.style.background = 'var(--bg-surface)' }}
                onMouseLeave={(e) => { e.currentTarget.style.background = 'transparent' }}
              >
                <div style={{ width: 46, height: 46, borderRadius: '50%', overflow: 'hidden', flexShrink: 0, background: 'var(--bg-surface2)' }}>
                  <ArtworkDisplay artwork={artist.artwork} artist={artist.name} title={artist.name} size={46} borderRadius={23} />
                </div>
                <div>
                  <div style={{ fontSize: 14, fontWeight: 600 }}>{artist.name}</div>
                  <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{artist.songIds.length} canciones</div>
                </div>
                <svg style={{ marginLeft: 'auto', color: 'var(--text-tertiary)' }} width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M8.59 16.59 13.17 12 8.59 7.41 10 6l6 6-6 6-1.41-1.41z"/></svg>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
