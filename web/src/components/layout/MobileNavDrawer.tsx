import type { ViewName } from '../../types'
import { AppIcon } from '../ui/AppIcon'
import { APP_NAME, APK_DOWNLOAD_URL } from '../../constants/appBranding'
import { isNativeApp } from '../../utils/platform'
import { NAV_ITEMS } from './navItems'

interface Props {
  open: boolean
  activeView: ViewName
  onNavigate: (view: ViewName) => void
  onClose: () => void
}

export function MobileNavDrawer({ open, activeView, onNavigate, onClose }: Props) {
  if (!open) return null

  return (
    <>
      <button
        type="button"
        aria-label="Cerrar menú"
        onClick={onClose}
        style={{
          position: 'fixed',
          inset: 0,
          zIndex: 300,
          background: 'rgba(0, 0, 0, 0.55)',
          border: 'none',
          cursor: 'pointer',
        }}
      />
      <aside
        className="slide-up"
        style={{
          position: 'fixed',
          top: 0,
          left: 0,
          bottom: 0,
          width: 'min(280px, 86vw)',
          zIndex: 301,
          background: 'var(--bg-secondary)',
          borderRight: '1px solid var(--border)',
          display: 'flex',
          flexDirection: 'column',
          paddingTop: 'env(safe-area-inset-top, 0px)',
          paddingBottom: 'env(safe-area-inset-bottom, 0px)',
          boxShadow: '8px 0 32px rgba(0, 0, 0, 0.45)',
        }}
      >
        <div style={{ padding: '16px 16px 12px', display: 'flex', alignItems: 'center', gap: 10 }}>
          <AppIcon size={36} borderRadius={8} />
          <span style={{ fontSize: 15, fontWeight: 800, letterSpacing: 0.3, color: 'var(--accent)' }}>
            {APP_NAME}
          </span>
        </div>

        <nav style={{ flex: 1, overflowY: 'auto', padding: '4px 8px' }}>
          {NAV_ITEMS.map((item) => {
            const isActive = activeView === item.id || (activeView === 'playlist-detail' && item.id === 'playlists')
            return (
              <button
                key={item.id}
                type="button"
                onClick={() => {
                  onNavigate(item.id)
                  onClose()
                }}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 10,
                  width: '100%',
                  padding: '12px 12px',
                  borderRadius: 'var(--radius-md)',
                  background: isActive ? 'rgba(255, 32, 32, 0.12)' : 'transparent',
                  color: isActive ? 'var(--accent)' : 'var(--text-secondary)',
                  fontSize: 15,
                  fontWeight: isActive ? 600 : 400,
                  marginBottom: 2,
                  textAlign: 'left',
                  cursor: 'pointer',
                }}
              >
                {item.icon}
                <span>{item.label}</span>
              </button>
            )
          })}
        </nav>

        {!isNativeApp && (
          <div style={{ padding: '8px 8px 16px', borderTop: '1px solid var(--border)' }}>
            <a
              href={APK_DOWNLOAD_URL}
              download="rugdraiger-play.apk"
              onClick={onClose}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 10,
                width: '100%',
                padding: '12px 12px',
                borderRadius: 'var(--radius-md)',
                background: 'rgba(255, 32, 32, 0.12)',
                color: 'var(--accent)',
                fontSize: 15,
                fontWeight: 600,
                textDecoration: 'none',
              }}
            >
              <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                <path d="M19 9h-4V3H9v6H5l7 7 7-7zM5 18v2h14v-2H5z" />
              </svg>
              Download
            </a>
          </div>
        )}
      </aside>
    </>
  )
}
