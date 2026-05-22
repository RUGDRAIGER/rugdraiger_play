import type { ViewName } from '../../types'
import { AppIcon } from '../ui/AppIcon'
import { APP_NAME } from '../../constants/appBranding'

interface NavItem {
  id: ViewName
  label: string
  icon: React.ReactNode
}

interface Props {
  activeView: ViewName
  onNavigate: (view: ViewName) => void
}

function HomeIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/></svg>
}
function LibraryIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M4 6H2v14c0 1.1.9 2 2 2h14v-2H4V6zm16-4H8c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm-1 9h-4v4h-2v-4H9V9h4V5h2v4h4v2z"/></svg>
}
function MusicNoteIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/></svg>
}
function AlbumIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 14.5c-2.49 0-4.5-2.01-4.5-4.5S9.51 7.5 12 7.5s4.5 2.01 4.5 4.5-2.01 4.5-4.5 4.5zm0-5.5c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1-.45-1-1-1z"/></svg>
}
function PersonIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/></svg>
}
function PlaylistIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M15 6H3v2h12V6zm0 4H3v2h12v-2zM3 16h8v-2H3v2zM17 6v8.18c-.31-.11-.65-.18-1-.18-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3V8h3V6h-5z"/></svg>
}
function EQIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M10 20h4V4h-4v16zm-6 0h4v-8H4v8zM16 9v11h4V9h-4z"/></svg>
}
function SearchIcon() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M15.5 14h-.79l-.28-.27C15.41 12.59 16 11.11 16 9.5 16 5.91 13.09 3 9.5 3S3 5.91 3 9.5 5.91 16 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z"/></svg>
}

const NAV_ITEMS: NavItem[] = [
  { id: 'home', label: 'Inicio', icon: <HomeIcon /> },
  { id: 'library', label: 'Biblioteca', icon: <LibraryIcon /> },
  { id: 'songs', label: 'Canciones', icon: <MusicNoteIcon /> },
  { id: 'albums', label: 'Álbumes', icon: <AlbumIcon /> },
  { id: 'artists', label: 'Artistas', icon: <PersonIcon /> },
  { id: 'playlists', label: 'Playlists', icon: <PlaylistIcon /> },
  { id: 'equalizer', label: 'Ecualizador', icon: <EQIcon /> },
  { id: 'search', label: 'Buscar', icon: <SearchIcon /> },
]

export function Sidebar({ activeView, onNavigate }: Props) {
  return (
    <aside style={{
      width: 'var(--sidebar-width)',
      height: '100%',
      background: 'var(--bg-secondary)',
      borderRight: '1px solid var(--border)',
      display: 'flex',
      flexDirection: 'column',
      flexShrink: 0,
      overflowY: 'auto',
    }}>
      <div style={{ padding: '20px 16px 16px', userSelect: 'none', display: 'flex', alignItems: 'center', gap: 10 }}>
        <AppIcon size={36} borderRadius={8} />
        <span style={{
          fontSize: 15,
          fontWeight: 800,
          letterSpacing: 0.3,
          color: 'var(--accent)',
          lineHeight: 1.2,
        }}>
          {APP_NAME}
        </span>
      </div>

      <nav style={{ flex: 1, padding: '4px 8px' }}>
        {NAV_ITEMS.map((item) => {
          const isActive = activeView === item.id || (activeView === 'playlist-detail' && item.id === 'playlists')
          return (
            <button
              key={item.id}
              onClick={() => onNavigate(item.id)}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 10,
                width: '100%',
                padding: '10px 12px',
                borderRadius: 'var(--radius-md)',
                background: isActive ? 'rgba(255, 32, 32, 0.12)' : 'transparent',
                color: isActive ? 'var(--accent)' : 'var(--text-secondary)',
                fontSize: 14,
                fontWeight: isActive ? 600 : 400,
                marginBottom: 2,
                transition: 'background 0.15s, color 0.15s',
                textAlign: 'left',
                cursor: 'pointer',
              }}
              onMouseEnter={(e) => { if (!isActive) e.currentTarget.style.background = 'rgba(255,255,255,0.05)' }}
              onMouseLeave={(e) => { if (!isActive) e.currentTarget.style.background = 'transparent' }}
            >
              {item.icon}
              <span>{item.label}</span>
              {isActive && (
                <span style={{ marginLeft: 'auto', width: 4, height: 4, borderRadius: '50%', background: 'var(--accent)' }} />
              )}
            </button>
          )
        })}
      </nav>

      <div style={{ padding: '12px 20px 20px', color: 'var(--text-tertiary)', fontSize: 11 }}>
        Rugdraiger Play v1.0
      </div>
    </aside>
  )
}
