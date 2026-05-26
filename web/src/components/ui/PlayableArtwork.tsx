import { useState } from 'react'
import type { Song } from '../../types'
import { ArtworkDisplay } from './ArtworkDisplay'

interface Props {
  song: Song
  size?: number
  borderRadius?: number
  onPlay: () => void
}

export function PlayableArtwork({ song, size = 36, borderRadius = 4, onPlay }: Props) {
  const [hovered, setHovered] = useState(false)

  return (
    <div
      style={{
        position: 'relative',
        width: size,
        height: size,
        flexShrink: 0,
        borderRadius,
        overflow: 'hidden',
        cursor: 'pointer',
      }}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      onClick={(e) => {
        e.stopPropagation()
        onPlay()
      }}
    >
      <ArtworkDisplay song={song} size={size} borderRadius={borderRadius} />

      <div
        style={{
          position: 'absolute',
          inset: 0,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          background: hovered ? 'rgba(0, 0, 0, 0.55)' : 'transparent',
          opacity: hovered ? 1 : 0,
          transition: 'opacity 0.15s, background 0.15s',
        }}
      >
        <div
          style={{
            width: size * 0.52,
            height: size * 0.52,
            borderRadius: '50%',
            background: '#FF2020',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: '0 2px 10px var(--accent-soft-55)',
            transform: hovered ? 'scale(1)' : 'scale(0.85)',
            transition: 'transform 0.15s',
          }}
        >
          <svg width={size * 0.26} height={size * 0.26} viewBox="0 0 24 24" fill="#fff">
            <path d="M8 5v14l11-7z" />
          </svg>
        </div>
      </div>
    </div>
  )
}
