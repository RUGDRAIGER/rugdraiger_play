import { AppIcon } from '../ui/AppIcon'
import { APP_NAME } from '../../constants/appBranding'

interface Props {
  onMenuOpen: () => void
}

export function MobileHeader({ onMenuOpen }: Props) {
  return (
    <header
      className="mobile-header"
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        padding: '10px 14px',
        paddingTop: 'calc(10px + env(safe-area-inset-top, 0px))',
        background: 'var(--bg-secondary)',
        borderBottom: '1px solid var(--border)',
        flexShrink: 0,
      }}
    >
      <button
        type="button"
        aria-label="Abrir menú"
        onClick={onMenuOpen}
        style={{
          width: 40,
          height: 40,
          borderRadius: 'var(--radius-md)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          color: 'var(--text-primary)',
          background: 'var(--bg-surface)',
          border: '1px solid var(--border)',
          cursor: 'pointer',
          flexShrink: 0,
        }}
      >
        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
          <path d="M3 6h18v2H3V6zm0 5h18v2H3v-2zm0 5h18v2H3v-2z" />
        </svg>
      </button>
      <AppIcon size={28} borderRadius={6} />
      <span style={{ fontSize: 16, fontWeight: 800, color: 'var(--accent)', letterSpacing: 0.2 }}>
        {APP_NAME}
      </span>
    </header>
  )
}
