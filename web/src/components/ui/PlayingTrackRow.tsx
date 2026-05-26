import type { CSSProperties, MouseEvent, ReactNode } from 'react'
import { usePlayerStore } from '../../store/playerStore'
import { StopAfterHandButton } from './StopAfterHandButton'
import type { Song } from '../../types'

interface Props {
  song: Song
  children: ReactNode
  onClick?: () => void
  onDoubleClick?: () => void
  onContextMenu?: (e: MouseEvent) => void
  className?: string
  style?: CSSProperties
  showStopHand?: boolean
}

export function PlayingTrackRow({
  song,
  children,
  onClick,
  onDoubleClick,
  onContextMenu,
  className,
  style,
  showStopHand = true,
}: Props) {
  const currentSong = usePlayerStore((s) => s.currentSong)
  const progress = usePlayerStore((s) => s.progress)
  const duration = usePlayerStore((s) => s.duration)

  const isCurrent = currentSong?.id === song.id
  const pct = isCurrent && duration > 0 ? Math.min(100, (progress / duration) * 100) : 0

  return (
    <div
      className={`track-row${isCurrent ? ' track-row--active' : ''}${className ? ` ${className}` : ''}`}
      onClick={onClick}
      onDoubleClick={onDoubleClick}
      onContextMenu={onContextMenu}
      style={style}
      aria-current={isCurrent ? 'true' : undefined}
    >
      <div className="track-row-progress" style={{ width: `${pct}%` }} aria-hidden />
      <div className="track-row-inner">{children}</div>
      {showStopHand && (
        <StopAfterHandButton songId={song.id} size={16} className="track-row-hand" />
      )}
    </div>
  )
}

export function TrackPlayingIcon({ size = 14 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="var(--accent)" aria-hidden>
      <path d="M4 10h3v4H4zm5 0h3v4H9zm5 0h3v4h-3z" />
    </svg>
  )
}

export function TrackPausedIcon({ size = 14 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="var(--accent)" aria-hidden>
      <path d="M8 5v14l11-7z" />
    </svg>
  )
}

export function useIsCurrentTrack(songId: string) {
  const currentSong = usePlayerStore((s) => s.currentSong)
  const isPlaying = usePlayerStore((s) => s.isPlaying)
  const isCurrent = currentSong?.id === songId
  return { isCurrent, isPlaying: isCurrent && isPlaying }
}
