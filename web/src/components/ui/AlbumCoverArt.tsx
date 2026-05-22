import { useState } from 'react'
import type { Song } from '../../types'
import type { MenuAnchorPoint } from './SongActionsMenu'
import { ArtworkDisplay } from './ArtworkDisplay'
import { SongActionsMenu } from './SongActionsMenu'

interface Props {
  artwork?: string
  title?: string
  artist?: string
  album?: string
  size?: number
  borderRadius?: number
  className?: string
  style?: React.CSSProperties
  menuSong?: Song | null
  onClick?: () => void
}

export function AlbumCoverArt({
  artwork,
  title,
  artist,
  album,
  size = 130,
  borderRadius = 10,
  className,
  style,
  menuSong,
  onClick,
}: Props) {
  const [hovered, setHovered] = useState(false)
  const [menuOpen, setMenuOpen] = useState(false)
  const [anchorPoint, setAnchorPoint] = useState<MenuAnchorPoint | null>(null)

  function openMenuAtPointer(e: React.MouseEvent) {
    e.preventDefault()
    e.stopPropagation()
    setAnchorPoint({ x: e.clientX, y: e.clientY })
    setMenuOpen(true)
  }

  function handleMenuOpenChange(open: boolean) {
    setMenuOpen(open)
    if (!open) setAnchorPoint(null)
  }

  return (
    <div
      className={className}
      style={{
        position: 'relative',
        flexShrink: 0,
        borderRadius,
        cursor: onClick ? 'pointer' : undefined,
        ...style,
      }}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      onClick={onClick}
      onContextMenu={menuSong ? openMenuAtPointer : undefined}
    >
      <div
        style={{
          width: '100%',
          height: '100%',
          borderRadius,
          overflow: 'hidden',
        }}
      >
        <ArtworkDisplay
          artwork={artwork}
          title={title}
          artist={artist}
          album={album}
          size={size}
          borderRadius={borderRadius}
          style={{ width: '100%', height: '100%', ...(style?.width ? { width: '100%', height: 'auto' } : {}) }}
        />
      </div>

      {menuSong && (
        <div
          style={{
            position: 'absolute',
            top: 4,
            right: 4,
            zIndex: 2,
            opacity: hovered || menuOpen ? 1 : 0.75,
            transition: 'opacity 0.15s',
          }}
          onClick={(e) => e.stopPropagation()}
        >
          <SongActionsMenu
            song={menuSong}
            variant="overlay"
            open={menuOpen}
            anchorPoint={anchorPoint}
            onClearAnchor={() => setAnchorPoint(null)}
            onOpenChange={handleMenuOpenChange}
          />
        </div>
      )}
    </div>
  )
}
