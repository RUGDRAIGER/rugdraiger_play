import { useState, useMemo } from 'react'
import { useLibraryStore } from '../../store/libraryStore'
import { usePlayerStore } from '../../store/playerStore'
import { PlayableArtwork } from '../ui/PlayableArtwork'
import { SongActionsMenu } from '../ui/SongActionsMenu'
import { openSongMenu, handleSongMenuOpenChange, type SongMenuState } from '../ui/songMenuUtils'
import { formatDuration, formatSongFormat } from '../../services/scannerService'

type SortKey = 'title' | 'artist' | 'album' | 'format' | 'duration' | 'dateAdded'

const GRID = '40px 1fr 1fr 1fr 52px 60px 36px'

export function SongsView() {
  const { songs } = useLibraryStore()
  const { playSong, currentSong, isPlaying } = usePlayerStore()
  const [search, setSearch] = useState('')
  const [sortBy, setSortBy] = useState<SortKey>('title')
  const [sortAsc, setSortAsc] = useState(true)
  const [menuState, setMenuState] = useState<SongMenuState | null>(null)

  const filtered = useMemo(() => {
    let list = songs
    if (search.trim()) {
      const q = search.toLowerCase()
      list = list.filter((s) =>
        s.title.toLowerCase().includes(q) ||
        s.artist.toLowerCase().includes(q) ||
        s.album.toLowerCase().includes(q),
      )
    }
    list = [...list].sort((a, b) => {
      const av = a[sortBy] ?? ''
      const bv = b[sortBy] ?? ''
      const cmp = String(av).localeCompare(String(bv))
      return sortAsc ? cmp : -cmp
    })
    return list
  }, [songs, search, sortBy, sortAsc])

  function toggleSort(key: SortKey) {
    if (sortBy === key) setSortAsc(!sortAsc)
    else { setSortBy(key); setSortAsc(true) }
  }

  function SortIcon({ k }: { k: SortKey }) {
    if (sortBy !== k) return null
    return <span style={{ fontSize: 10, marginLeft: 3 }}>{sortAsc ? '▲' : '▼'}</span>
  }

  return (
    <div
      style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}
      onClick={() => setMenuState(null)}
    >
      {/* Header */}
      <div style={{ padding: '20px 28px 12px', flexShrink: 0 }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 12 }}>Canciones</h1>
        <div style={{ display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap' }}>
          <div style={{ position: 'relative', flex: 1, minWidth: 180 }}>
            <svg style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-secondary)' }} width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M15.5 14h-.79l-.28-.27C15.41 12.59 16 11.11 16 9.5 16 5.91 13.09 3 9.5 3S3 5.91 3 9.5 5.91 16 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z"/></svg>
            <input
              type="text" placeholder="Buscar canciones..." value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{
                width: '100%', padding: '9px 12px 9px 34px',
                background: 'var(--bg-surface)', border: '1px solid var(--border)',
                borderRadius: 'var(--radius-md)', fontSize: 14, color: 'var(--text-primary)',
                outline: 'none',
              }}
            />
          </div>
          <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
            <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{filtered.length} canciones</span>
            <button
              onClick={() => playSong(filtered[0], filtered)}
              disabled={filtered.length === 0}
              style={{
                padding: '8px 16px', borderRadius: 'var(--radius-md)',
                background: 'var(--accent)', color: '#fff', fontSize: 13, fontWeight: 600,
                cursor: filtered.length === 0 ? 'not-allowed' : 'pointer', opacity: filtered.length === 0 ? 0.5 : 1,
                display: 'flex', alignItems: 'center', gap: 6,
              }}
            >
              <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>
              Reproducir
            </button>
          </div>
        </div>
      </div>

      {/* Column headers */}
      <div style={{
        display: 'grid', gridTemplateColumns: GRID,
        padding: '6px 28px', fontSize: 11, color: 'var(--text-secondary)',
        borderBottom: '1px solid var(--border)', flexShrink: 0, gap: 8,
        textTransform: 'uppercase', letterSpacing: 0.5,
      }}>
        <span>#</span>
        <button onClick={() => toggleSort('title')} style={{ textAlign: 'left', cursor: 'pointer', color: 'inherit', fontSize: 'inherit', letterSpacing: 'inherit', textTransform: 'inherit' }}>
          Título <SortIcon k="title" />
        </button>
        <button onClick={() => toggleSort('album')} style={{ textAlign: 'left', cursor: 'pointer', color: 'inherit', fontSize: 'inherit', letterSpacing: 'inherit', textTransform: 'inherit' }}>
          Álbum <SortIcon k="album" />
        </button>
        <button onClick={() => toggleSort('artist')} style={{ textAlign: 'left', cursor: 'pointer', color: 'inherit', fontSize: 'inherit', letterSpacing: 'inherit', textTransform: 'inherit' }}>
          Artista <SortIcon k="artist" />
        </button>
        <button onClick={() => toggleSort('format')} style={{ textAlign: 'center', cursor: 'pointer', color: 'inherit', fontSize: 'inherit', letterSpacing: 'inherit', textTransform: 'inherit' }}>
          Fmt <SortIcon k="format" />
        </button>
        <button onClick={() => toggleSort('duration')} style={{ textAlign: 'right', cursor: 'pointer', color: 'inherit', fontSize: 'inherit', letterSpacing: 'inherit', textTransform: 'inherit' }}>
          <SortIcon k="duration" /> Dur.
        </button>
        <span />
      </div>

      {/* Song list */}
      <div className="scrollable" style={{ flex: 1 }}>
        {filtered.length === 0 ? (
          <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-secondary)' }}>
            {search ? 'Sin resultados' : 'Sin canciones'}
          </div>
        ) : (
          filtered.map((song, i) => {
            const isCurrent = currentSong?.id === song.id
            return (
              <div
                key={song.id}
                onDoubleClick={() => playSong(song, filtered)}
                onContextMenu={(e) => setMenuState(openSongMenu(e, song.id))}
                style={{
                  display: 'grid', gridTemplateColumns: GRID,
                  padding: '8px 28px', gap: 8, alignItems: 'center',
                  background: isCurrent ? 'rgba(255,32,32,0.08)' : 'transparent',
                  cursor: 'pointer', transition: 'background 0.1s',
                  position: 'relative',
                }}
                onMouseEnter={(e) => { if (!isCurrent) e.currentTarget.style.background = 'var(--bg-surface)' }}
                onMouseLeave={(e) => { if (!isCurrent) e.currentTarget.style.background = 'transparent' }}
              >
                <span style={{ fontSize: 12, color: isCurrent ? 'var(--accent)' : 'var(--text-tertiary)', textAlign: 'center' }}>
                  {isCurrent && isPlaying
                    ? <svg width="14" height="14" viewBox="0 0 24 24" fill="var(--accent)"><path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/></svg>
                    : i + 1
                  }
                </span>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10, minWidth: 0 }}>
                  <PlayableArtwork
                    song={song}
                    size={36}
                    borderRadius={4}
                    onPlay={() => playSong(song, filtered)}
                  />
                  <span style={{ fontSize: 13, fontWeight: isCurrent ? 600 : 400, color: isCurrent ? 'var(--accent)' : 'var(--text-primary)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {song.title}
                  </span>
                </div>
                <span style={{ fontSize: 12, color: 'var(--text-secondary)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{song.album}</span>
                <span style={{ fontSize: 12, color: 'var(--text-secondary)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{song.artist}</span>
                <span
                  title={formatSongFormat(song.format, song.isLossless)}
                  style={{
                    fontSize: 10,
                    fontWeight: 700,
                    letterSpacing: 0.4,
                    textAlign: 'center',
                    color: song.isLossless ? 'var(--accent)' : 'var(--text-secondary)',
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                    whiteSpace: 'nowrap',
                  }}
                >
                  {song.format.toUpperCase()}
                </span>
                <span style={{ fontSize: 12, color: 'var(--text-secondary)', textAlign: 'right' }}>{formatDuration(song.duration)}</span>
                <SongActionsMenu
                  song={song}
                  open={menuState?.songId === song.id}
                  anchorPoint={menuState?.songId === song.id ? (menuState.anchor ?? null) : null}
                  onOpenChange={(open) => handleSongMenuOpenChange(open, song.id, setMenuState)}
                />
              </div>
            )
          })
        )}
      </div>
    </div>
  )
}
