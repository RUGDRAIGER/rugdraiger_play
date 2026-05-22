import type { ViewName } from '../../types'

interface Props {
  activeView: ViewName
  onNavigate: (view: ViewName) => void
}

const items = [
  {
    id: 'home' as ViewName, label: 'Inicio',
    icon: <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/></svg>,
  },
  {
    id: 'songs' as ViewName, label: 'Canciones',
    icon: <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/></svg>,
  },
  {
    id: 'playlists' as ViewName, label: 'Playlists',
    icon: <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><path d="M15 6H3v2h12V6zm0 4H3v2h12v-2zM3 16h8v-2H3v2zM17 6v8.18c-.31-.11-.65-.18-1-.18-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3V8h3V6h-5z"/></svg>,
  },
  {
    id: 'equalizer' as ViewName, label: 'EQ',
    icon: <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><path d="M10 20h4V4h-4v16zm-6 0h4v-8H4v8zM16 9v11h4V9h-4z"/></svg>,
  },
  {
    id: 'search' as ViewName, label: 'Buscar',
    icon: <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><path d="M15.5 14h-.79l-.28-.27C15.41 12.59 16 11.11 16 9.5 16 5.91 13.09 3 9.5 3S3 5.91 3 9.5 5.91 16 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z"/></svg>,
  },
]

export function BottomNav({ activeView, onNavigate }: Props) {
  return (
    <nav style={{
      display: 'flex',
      background: 'var(--bg-secondary)',
      borderTop: '1px solid var(--border)',
      height: 56,
    }}>
      {items.map((item) => {
        const isActive = activeView === item.id || (activeView === 'playlist-detail' && item.id === 'playlists')
        return (
          <button
            key={item.id}
            onClick={() => onNavigate(item.id)}
            style={{
              flex: 1,
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 2,
              color: isActive ? 'var(--accent)' : 'var(--text-tertiary)',
              fontSize: 10,
              fontWeight: isActive ? 600 : 400,
              cursor: 'pointer',
              transition: 'color 0.15s',
            }}
          >
            {item.icon}
            {item.label}
          </button>
        )
      })}
    </nav>
  )
}
