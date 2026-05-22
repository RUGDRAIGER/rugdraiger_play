import type { ViewName } from '../../types'
import { AppIcon } from '../ui/AppIcon'
import { APP_NAME } from '../../constants/appBranding'
import { NAV_ITEMS } from './navItems'

interface Props {
  activeView: ViewName
  onNavigate: (view: ViewName) => void
}

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
