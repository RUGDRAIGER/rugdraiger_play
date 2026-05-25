import { useState } from 'react'
import { useLibraryStore } from '../../store/libraryStore'
import { usePlayerStore } from '../../store/playerStore'
import { ArtworkDisplay } from '../ui/ArtworkDisplay'
import { PlayableArtwork } from '../ui/PlayableArtwork'
import { formatDuration } from '../../services/scannerService'

export function GenresView() {
  const { genres, getGenreSongs } = useLibraryStore()
  const { playSong } = usePlayerStore()
  const [selectedId, setSelectedId] = useState<string | null>(null)

  const selectedSongs = selectedId ? getGenreSongs(selectedId) : []
  const selectedGenre = genres.find((g) => g.id === selectedId)

  if (selectedId && selectedGenre) {
    return (
      <div className="scrollable mobile-page" style={{ flex: 1, padding: '24px 28px' }}>
        <button type="button" onClick={() => setSelectedId(null)} style={{ color: 'var(--accent)', fontSize: 13, marginBottom: 16, cursor: 'pointer' }}>
          ← Géneros
        </button>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 20 }}>{selectedGenre.name}</h1>
        {selectedSongs.map((song) => (
          <div
            key={song.id}
            onClick={() => playSong(song, selectedSongs)}
            style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 0', borderBottom: '1px solid var(--border)', cursor: 'pointer' }}
          >
            <PlayableArtwork song={song} size={40} borderRadius={5} onPlay={() => playSong(song, selectedSongs)} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 13, fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{song.title}</div>
              <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{song.artist}</div>
            </div>
            <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{formatDuration(song.duration)}</span>
          </div>
        ))}
      </div>
    )
  }

  return (
    <div className="scrollable mobile-page" style={{ flex: 1, padding: '24px 28px' }}>
      <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 20 }}>Géneros</h1>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(140px, 1fr))', gap: 12 }}>
        {genres.map((genre) => (
          <button
            key={genre.id}
            type="button"
            onClick={() => setSelectedId(genre.id)}
            style={{
              padding: 16, borderRadius: 'var(--radius-md)',
              background: 'var(--bg-surface)', border: '1px solid var(--border)',
              textAlign: 'left', cursor: 'pointer',
            }}
          >
            <div style={{ fontSize: 14, fontWeight: 700, marginBottom: 4 }}>{genre.name}</div>
            <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{genre.songIds.length} canciones</div>
          </button>
        ))}
      </div>
    </div>
  )
}
