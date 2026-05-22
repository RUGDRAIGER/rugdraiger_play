import { useLibraryStore } from '../../store/libraryStore'
import type { ViewName } from '../../types'

interface Props {
  onNavigate: (v: ViewName) => void
}

const sections = [
  { id: 'songs' as ViewName, label: 'Canciones', desc: 'Toda tu música', icon: <svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/></svg> },
  { id: 'albums' as ViewName, label: 'Álbumes', desc: 'Por álbum', icon: <svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 14.5c-2.49 0-4.5-2.01-4.5-4.5S9.51 7.5 12 7.5s4.5 2.01 4.5 4.5-2.01 4.5-4.5 4.5zm0-5.5c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1-.45-1-1-1z"/></svg> },
  { id: 'artists' as ViewName, label: 'Artistas', desc: 'Por artista', icon: <svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor"><path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/></svg> },
  { id: 'playlists' as ViewName, label: 'Playlists', desc: 'Tus listas', icon: <svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor"><path d="M15 6H3v2h12V6zm0 4H3v2h12v-2zM3 16h8v-2H3v2zM17 6v8.18c-.31-.11-.65-.18-1-.18-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3V8h3V6h-5z"/></svg> },
]

export function LibraryView({ onNavigate }: Props) {
  const { songs, albums, artists } = useLibraryStore()
  const counts: Record<string, number> = { songs: songs.length, albums: albums.length, artists: artists.length, playlists: 0 }

  return (
    <div className="scrollable" style={{ flex: 1, padding: '24px 28px' }}>
      <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 24 }}>Biblioteca</h1>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: 16 }}>
        {sections.map((s) => (
          <button
            key={s.id}
            onClick={() => onNavigate(s.id)}
            style={{
              padding: 20, borderRadius: 'var(--radius-lg)',
              background: 'var(--bg-surface)',
              border: '1px solid var(--border)',
              textAlign: 'left', cursor: 'pointer',
              display: 'flex', flexDirection: 'column', gap: 12,
              transition: 'border-color 0.15s, transform 0.15s',
            }}
            onMouseEnter={(e) => { e.currentTarget.style.borderColor = 'var(--border-accent)'; e.currentTarget.style.transform = 'translateY(-2px)' }}
            onMouseLeave={(e) => { e.currentTarget.style.borderColor = 'var(--border)'; e.currentTarget.style.transform = 'translateY(0)' }}
          >
            <div style={{ color: 'var(--accent)' }}>{s.icon}</div>
            <div>
              <div style={{ fontSize: 16, fontWeight: 700 }}>{s.label}</div>
              <div style={{ fontSize: 13, color: 'var(--text-secondary)' }}>{s.desc}</div>
            </div>
            <div style={{ fontSize: 24, fontWeight: 800, color: 'var(--text-tertiary)' }}>
              {counts[s.id] ?? 0}
            </div>
          </button>
        ))}
      </div>
    </div>
  )
}
