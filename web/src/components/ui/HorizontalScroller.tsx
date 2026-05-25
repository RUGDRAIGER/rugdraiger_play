import type { ReactNode } from 'react'

interface Props {
  title: string
  actionLabel?: string
  onAction?: () => void
  children: ReactNode
}

export function HorizontalScroller({ title, actionLabel, onAction, children }: Props) {
  return (
    <section>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12, paddingRight: 4 }}>
        <h2 style={{ fontSize: 18, fontWeight: 700 }}>{title}</h2>
        {actionLabel && onAction && (
          <button type="button" onClick={onAction} style={{ fontSize: 13, color: 'var(--accent)', cursor: 'pointer' }}>
            {actionLabel}
          </button>
        )}
      </div>
      <div className="horizontal-scroll">
        {children}
      </div>
    </section>
  )
}

interface SongCardProps {
  title: string
  subtitle: string
  artwork: ReactNode
  onClick: () => void
  badge?: ReactNode
}

export function HorizontalSongCard({ title, subtitle, artwork, onClick, badge }: SongCardProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="horizontal-card"
    >
      <div style={{ position: 'relative', width: 120, height: 120, borderRadius: 12, overflow: 'hidden', marginBottom: 8, flexShrink: 0 }}>
        {artwork}
        {badge}
      </div>
      <div style={{ fontSize: 13, fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: 120, textAlign: 'left' }}>
        {title}
      </div>
      <div style={{ fontSize: 11, color: 'var(--text-secondary)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: 120, textAlign: 'left' }}>
        {subtitle}
      </div>
    </button>
  )
}
