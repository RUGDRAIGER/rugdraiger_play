import type { CSSProperties, MouseEvent } from 'react'
import { usePlayerStore } from '../../store/playerStore'

interface Props {
  songId: string
  size?: number
  style?: CSSProperties
  className?: string
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
        width: size + 8,
        height: size + 8,
        borderRadius: '50%',
        border: active ? '2px solid #ff1a1a' : '1px solid var(--border)',
        background: active ? 'rgba(255, 26, 26, 0.35)' : 'transparent',
        color: active ? '#ff3333' : 'var(--text-tertiary)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        cursor: 'pointer',
        flexShrink: 0,
        boxShadow: active ? '0 0 12px rgba(255, 26, 26, 0.55)' : 'none',
        transition: 'all 0.15s',
        ...style,
      }}
    >
      <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
        <path d="M18 11V9h2V4.72C20 3.62 18.94 2.5 17.82 2.5H13v2.5c0 .83-.67 1.5-1.5 1.5S10 6.83 10 6V2.5H7.82C6.7 2.5 5.64 3.4 5.64 4.5V9.5H4v6h5v7c0 1.1.9 2 2 2h6v-9.36c0-2.03 1.53-3.64 3.46-3.64 1.39 0 2.54.83 3.05 2.03.22.58.95.96 1.54.96.8 0 1.46-.65 1.46-1.45V11h-6z" />
      </svg>
    </button>
  )
}
