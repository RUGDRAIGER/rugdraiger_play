import type { ViewName } from '../../types'
import { BOTTOM_NAV_ITEMS } from './navItems'

interface Props {
  activeView: ViewName
  onNavigate: (view: ViewName) => void
}

export function BottomNav({ activeView, onNavigate }: Props) {
  return (
    <nav className="bottom-nav">
      {BOTTOM_NAV_ITEMS.map((item) => {
        const isActive = activeView === item.id ||
          (activeView === 'playlist-detail' && item.id === 'playlists') ||
          (['songs', 'albums', 'artists', 'genres'].includes(activeView) && item.id === 'library')
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
    </nav>
  )
}
