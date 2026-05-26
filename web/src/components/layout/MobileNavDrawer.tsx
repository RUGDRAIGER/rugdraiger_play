import type { ViewName } from '../../types'
import { AppIcon } from '../ui/AppIcon'
import { APP_NAME, APK_DOWNLOAD_URL, MACOS_DOWNLOAD_URL, WINDOWS_DOWNLOAD_URL } from '../../constants/appBranding'
import { showDownloadButtons } from '../../utils/platform'
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

        {showDownloadButtons && (
          <div style={{ padding: '8px 8px 16px', borderTop: '1px solid var(--border)', display: 'flex', flexDirection: 'column', gap: 6 }}>
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
              Android
            </a>
            <a
              href={MACOS_DOWNLOAD_URL}
              download="RugdraigerPlay-macOS.zip"
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
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
              </svg>
              macOS
            </a>
            <a
              href={WINDOWS_DOWNLOAD_URL}
              download="RugdraigerPlay-Windows.zip"
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
                <path d="M3 5.5L10.5 4v7.5H3V5.5zm10.5 0L21 4v7.5h-7.5V5.5zM3 13.5h7.5V21L3 19.5v-6zm10.5 0H21V19.5L13.5 21v-7.5z" />
              </svg>
              Windows
            </a>
          </div>
        )}
      </aside>
    </>
  )
}
