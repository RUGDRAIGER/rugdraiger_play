import { useEffect, useState } from 'react'
import type { Song } from '../../types'
import { canShareArtworkByAlbum, fetchArtworkUrl } from '../../services/artworkService'
import { resolveArtworkSrc, cacheArtworkUrl } from '../../services/artworkFileService'
import { useLibraryStore } from '../../store/libraryStore'

interface Props {
  song?: Song | null
  artist?: string
  album?: string
  title?: string
  artwork?: string
  size?: number
  className?: string
  style?: React.CSSProperties
  borderRadius?: number
}

export function ArtworkDisplay({
  song,
  artist: artistProp,
  album: albumProp,
  title: titleProp,
  artwork: artworkProp,
  size = 48,
  className,
  style,
  borderRadius = 8,
}: Props) {
  const updateSongArtwork = useLibraryStore((s) => s.updateSongArtwork)
  const applyArtworkToAlbum = useLibraryStore((s) => s.applyArtworkToAlbum)

  const artist = artistProp ?? song?.artist ?? ''
  const album = albumProp ?? song?.album ?? ''
  const title = titleProp ?? song?.title
  const artworkRef = artworkProp ?? song?.artwork

  const [src, setSrc] = useState<string | undefined>()
  const [failed, setFailed] = useState(false)

  useEffect(() => {
    let cancelled = false
    setFailed(false)

    void resolveArtworkSrc(artworkRef, song?.id).then((url) => {
      if (!cancelled) setSrc(url)
    })

    return () => { cancelled = true }
  }, [song?.id, artworkRef])

  useEffect(() => {
    const hasMeta = Boolean(artist.trim() || album.trim() || title?.trim())
    if (!hasMeta || (src && !failed)) return

    let cancelled = false
    fetchArtworkUrl(artist, album, title, song?.id).then((url) => {
      if (cancelled || !url) return
      setSrc(url)
      setFailed(false)

      if (song?.id) {
        cacheArtworkUrl(song.id, url)
        void updateSongArtwork(song.id, url)
        return
      }

      if (canShareArtworkByAlbum(artist, album)) {
        void applyArtworkToAlbum(artist, album, url)
      }
    })

    return () => { cancelled = true }
  }, [song?.id, artist, album, title, src, failed, updateSongArtwork, applyArtworkToAlbum])

  const s: React.CSSProperties = {
    width: size,
    height: size,
    borderRadius,
    objectFit: 'cover',
    flexShrink: 0,
    ...style,
  }

  if (src && !failed) {
    return (
      <img
        src={src}
        alt={title ?? song?.title ?? 'Carátula'}
        style={s}
        className={className}
        onError={() => setFailed(true)}
      />
    )
  }

  return (
    <div
      className={className}
      style={{
        ...s,
        background: 'var(--bg-surface2)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: 'var(--accent)',
      }}
    >
      <svg width={size * 0.45} height={size * 0.45} viewBox="0 0 24 24" fill="currentColor">
        <path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z" />
      </svg>
    </div>
  )
}
