import type { ViewName } from '../../types'
import { BOTTOM_NAV_ITEMS } from './navItems'

interface Props {
  activeView: ViewName
  onNavigate: (view: ViewName) => void
  onMenuOpen: () => void
}

export function BottomNav({ activeView, onNavigate, onMenuOpen }: Props) {
  return (
    <nav className="bottom-nav">
      {BOTTOM_NAV_ITEMS.map((item) => {
        const isActive = activeView === item.id || (activeView === 'playlist-detail' && item.id === 'playlists')
        return (
          <button
            key={item.id}
            type="button"
            onClick={() => onNavigate(item.id)}
            style={{
              flex: 1,
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 2,
              minHeight: 'var(--bottom-nav-height)',
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
      <button
        type="button"
        aria-label="Más opciones"
        onClick={onMenuOpen}
        style={{
          flex: 1,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 2,
          minHeight: 'var(--bottom-nav-height)',
          color: ['library', 'albums', 'artists'].includes(activeView) ? 'var(--accent)' : 'var(--text-tertiary)',
          fontSize: 10,
          fontWeight: ['library', 'albums', 'artists'].includes(activeView) ? 600 : 400,
          cursor: 'pointer',
        }}
      >
        <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor">
          <path d="M3 6h18v2H3V6zm0 5h18v2H3v-2zm0 5h18v2H3v-2z" />
        </svg>
        Más
      </button>
    </nav>
  )
}
