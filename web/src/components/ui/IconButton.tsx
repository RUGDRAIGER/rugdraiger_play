import type { ReactNode, CSSProperties } from 'react'

interface Props {
  onClick?: () => void
  children: ReactNode
  active?: boolean
  size?: number
  style?: CSSProperties
  title?: string
  disabled?: boolean
}

export function IconButton({ onClick, children, active, size = 36, style, title, disabled }: Props) {
  return (
    <button
      onClick={onClick}
      title={title}
      disabled={disabled}
      style={{
        width: size,
        height: size,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        borderRadius: '50%',
        color: active ? 'var(--accent)' : 'var(--text-primary)',
        transition: 'background 0.15s, color 0.15s, opacity 0.15s',
        opacity: disabled ? 0.35 : 1,
        cursor: disabled ? 'not-allowed' : 'pointer',
        ...style,
      }}
      onMouseEnter={(e) => { if (!disabled) (e.currentTarget.style.background = 'rgba(255,255,255,0.07)') }}
      onMouseLeave={(e) => { (e.currentTarget.style.background = 'transparent') }}
    >
      {children}
    </button>
  )
}
