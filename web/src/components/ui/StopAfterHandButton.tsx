import type { CSSProperties, MouseEvent } from 'react'
import { usePlayerStore } from '../../store/playerStore'

interface Props {
  songId: string
  size?: number
  style?: CSSProperties
  className?: string
}

/** Mano extendida (palma abierta) — parar cola al terminar el tema */
export function ExtendedHandIcon({ size = 22 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M23 5.5V20c0 2.2-1.8 4-4 4h-7.3c-1.08 0-2.1-.43-2.85-1.19L1 14.83s1.26-1.23 1.3-1.25c.22-.19.49-.29.79-.29.22 0 .42.06.61.16.11.06.22.07.33.04l5.83-1.66V4.5c0-.83.67-1.5 1.5-1.5s1.5.67 1.5 1.5V8h1V3.5C13 2.67 13.67 2 14.5 2S16 2.67 16 3.5V8h1V4.5c0-.83.67-1.5 1.5-1.5s1.5.67 1.5 1.5V11h1V5.5C20 4.67 20.67 4 21.5 4S23 4.67 23 5.5z" />
    </svg>
  )
}

export function StopAfterHandButton({ songId, size = 22, style, className }: Props) {
  const active = usePlayerStore((s) => s.stopAfterSongIds.includes(songId))
  const toggleStopAfterSong = usePlayerStore((s) => s.toggleStopAfterSong)

  const handleClick = (e: MouseEvent) => {
    e.stopPropagation()
    toggleStopAfterSong(songId)
  }

  return (
    <button
      type="button"
      className={className}
      onClick={handleClick}
      title={active ? 'Parar la cola al terminar este tema' : 'Continuar con la cola al terminar'}
      aria-pressed={active}
      style={{
        width: size + 10,
        height: size + 10,
        borderRadius: '50%',
        border: active ? '2px solid var(--accent-intense)' : '1px solid var(--border)',
        background: active ? 'var(--accent-soft-35)' : 'transparent',
        color: active ? 'var(--accent-intense)' : 'var(--text-tertiary)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        cursor: 'pointer',
        flexShrink: 0,
        boxShadow: active ? '0 0 14px var(--accent-glow-strong)' : 'none',
        transition: 'all 0.15s',
        ...style,
      }}
    >
      <ExtendedHandIcon size={size} />
    </button>
  )
}
