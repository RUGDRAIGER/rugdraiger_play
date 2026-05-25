import type { Song, Album, Artist, Genre } from '../types'

export interface SearchResults {
  songs: Song[]
  albums: Album[]
  artists: Artist[]
  genres: Genre[]
}

function matchesQuery(text: string | number | undefined | null, q: string): boolean {
  if (text === undefined || text === null) return false
  return String(text).toLowerCase().includes(q)
}

export function searchLibrary(
  query: string,
  songs: Song[],
  albums: Album[],
  artists: Artist[],
  genres: Genre[],
): SearchResults {
  const q = query.trim().toLowerCase()
  if (!q) return { songs: [], albums: [], artists: [], genres: [] }

  const matchedSongs = songs.filter((s) =>
    matchesQuery(s.title, q) ||
    matchesQuery(s.artist, q) ||
    matchesQuery(s.album, q) ||
    matchesQuery(s.genre, q) ||
    matchesQuery(s.composer, q) ||
    matchesQuery(s.year, q) ||
    matchesQuery(s.format, q),
  )

  return {
    songs: matchedSongs.slice(0, 30),
    albums: albums.filter((a) =>
      matchesQuery(a.title, q) || matchesQuery(a.artist, q) || matchesQuery(a.year, q),
    ).slice(0, 10),
    artists: artists.filter((a) => matchesQuery(a.name, q)).slice(0, 8),
    genres: genres.filter((g) => matchesQuery(g.name, q)).slice(0, 6),
  }
}
