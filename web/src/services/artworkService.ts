const cache = new Map<string, string>()
const pending = new Map<string, Promise<string | undefined>>()

function normalizeQuery(value: string): string {
  return value
    .replace(/\([^)]*\)/g, '')
    .replace(/\[[^\]]*\]/g, '')
    .replace(/\s+/g, ' ')
    .trim()
}

function albumKey(artist: string, album: string): string {
  return `${artist.toLowerCase()}::${album.toLowerCase()}`
}

function upgradeArtworkSize(url: string): string {
  return url
    .replace(/(\d+)x\d+(bb)?\.(jpg|png)/i, '600x600$2.$3')
    .replace('100x100', '600x600')
}

interface iTunesItem {
  artworkUrl100?: string
  artworkUrl600?: string
  collectionName?: string
  artistName?: string
  trackName?: string
}

async function searchItunes(term: string, entity: 'album' | 'song'): Promise<iTunesItem[]> {
  const url = `https://itunes.apple.com/search?term=${encodeURIComponent(term)}&entity=${entity}&limit=8`
  const res = await fetch(url)
  if (!res.ok) return []
  const data = await res.json() as { results?: iTunesItem[] }
  return data.results ?? []
}

function pickBestMatch(
  results: iTunesItem[],
  artist: string,
  album: string,
  title?: string,
): iTunesItem | undefined {
  const a = artist.toLowerCase()
  const al = album.toLowerCase()
  const t = title?.toLowerCase()

  const scored = results.map((item) => {
    let score = 0
    const itemArtist = item.artistName?.toLowerCase() ?? ''
    const itemAlbum = item.collectionName?.toLowerCase() ?? ''
    const itemTitle = item.trackName?.toLowerCase() ?? ''

    if (itemArtist.includes(a) || a.includes(itemArtist)) score += 3
    if (itemAlbum.includes(al) || al.includes(itemAlbum)) score += 3
    if (t && (itemTitle.includes(t) || t.includes(itemTitle))) score += 2
    if (item.artworkUrl600 || item.artworkUrl100) score += 1
    return { item, score }
  })

  scored.sort((x, y) => y.score - x.score)
  return scored[0]?.score > 0 ? scored[0].item : results[0]
}

function artworkFromItem(item: iTunesItem): string | undefined {
  const raw = item.artworkUrl600 || item.artworkUrl100
  return raw ? upgradeArtworkSize(raw) : undefined
}

export async function fetchArtworkUrl(
  artist: string,
  album: string,
  title?: string,
): Promise<string | undefined> {
  const cleanArtist = normalizeQuery(artist)
  const cleanAlbum = normalizeQuery(album)
  const cleanTitle = title ? normalizeQuery(title) : ''

  if (!cleanArtist && !cleanAlbum && !cleanTitle) return undefined

  const key = albumKey(cleanArtist || 'unknown', cleanAlbum || cleanTitle || 'unknown')
  if (cache.has(key)) return cache.get(key)

  if (pending.has(key)) return pending.get(key)

  const task = (async () => {
    const unknownAlbum = !cleanAlbum || cleanAlbum.toLowerCase() === 'unknown album'

    if (cleanTitle && unknownAlbum) {
      const songResults = await searchItunes(`${cleanArtist} ${cleanTitle}`, 'song')
      const match = pickBestMatch(songResults, cleanArtist, cleanAlbum, cleanTitle)
      const url = match ? artworkFromItem(match) : undefined
      if (url) {
        cache.set(key, url)
        return url
      }
    }

    if (cleanAlbum && !unknownAlbum) {
      const albumResults = await searchItunes(`${cleanArtist} ${cleanAlbum}`, 'album')
      const match = pickBestMatch(albumResults, cleanArtist, cleanAlbum, cleanTitle)
      const url = match ? artworkFromItem(match) : undefined
      if (url) {
        cache.set(key, url)
        return url
      }
    }

    if (cleanTitle) {
      const songResults = await searchItunes(`${cleanArtist} ${cleanTitle}`, 'song')
      const match = pickBestMatch(songResults, cleanArtist, cleanAlbum, cleanTitle)
      const url = match ? artworkFromItem(match) : undefined
      if (url) {
        cache.set(key, url)
        return url
      }
    }

    return undefined
  })()

  pending.set(key, task)
  try {
    return await task
  } finally {
    pending.delete(key)
  }
}

export async function enrichSongsArtwork(
  songs: Array<{ id: string; artist: string; album: string; title: string; artwork?: string }>,
  onArtworkFound: (songId: string, artwork: string) => void,
): Promise<void> {
  const albumArt = new Map<string, string>()

  for (const song of songs) {
    if (song.artwork) continue

    const key = albumKey(song.artist, song.album)
    if (albumArt.has(key)) {
      const artwork = albumArt.get(key)!
      onArtworkFound(song.id, artwork)
      continue
    }

    const url = await fetchArtworkUrl(song.artist, song.album, song.title)
    if (url) {
      albumArt.set(key, url)
      onArtworkFound(song.id, url)
    }

    await new Promise((r) => setTimeout(r, 120))
  }
}
