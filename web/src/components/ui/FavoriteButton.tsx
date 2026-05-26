import { useLibraryStore } from '../../store/libraryStore'
import type { Song } from '../../types'

const FAVORITE_RED = '#FF2020'

interface Props {
  song: Song
  size?: number
}

export function FavoriteButton({ song, size = 22 }: Props) {
  const toggleFavorite = useLibraryStore((s) => s.toggleFavorite)
  const isFavorite = useLibraryStore(
    (s) => s.songs.find((x) => x.id === song.id)?.isFavorite ?? false,
  )

  return (
    <button
      type="button"
      aria-label={isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos'}
      aria-pressed={isFavorite}
      onClick={(e) => {
        e.stopPropagation()
        e.preventDefault()
        void toggleFavorite(song.id)
      }}
      style={{
        background: 'transparent',
        border: 'none',
        cursor: 'pointer',
        color: isFavorite ? FAVORITE_RED : 'var(--text-secondary)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 4,
        transition: 'color 0.15s, transform 0.15s',
        transform: isFavorite ? 'scale(1.08)' : 'scale(1)',
      }}
    >
      <svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
        fill={isFavorite ? FAVORITE_RED : 'none'}
        stroke={isFavorite ? FAVORITE_RED : 'currentColor'}
        strokeWidth={isFavorite ? 1.5 : 2}
        style={{ filter: isFavorite ? 'drop-shadow(0 0 6px var(--accent-soft-65))' : 'none' }}
      >
        <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
      </svg>
    </button>
  )
}
