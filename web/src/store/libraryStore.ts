import { create } from 'zustand'
import type { Song, Album, Artist, Genre, ScanProgress, SongMetadataPatch } from '../types'
import { dbService } from '../services/dbService'
import { scanFiles, scanDirectory, getScanErrorMessage, filterAudioFiles } from '../services/scannerService'
import { enrichSongsArtwork, canShareArtworkByAlbum } from '../services/artworkService'
import { cacheSongFiles, clearSongBlobCache, removeSongFromCache } from '../services/audioFileService'
import { clearArtworkUrlCache, revokeArtworkUrl } from '../services/artworkFileService'
import { usePlayerStore } from './playerStore'

interface LibraryStore {
  songs: Song[]
  albums: Album[]
  artists: Artist[]
  genres: Genre[]
  isLoading: boolean
  isScanning: boolean
  scanProgress: ScanProgress | null
  error: string | null

  loadLibrary: () => Promise<void>
  scanFromFiles: (files: File[]) => Promise<void>
  scanFromDirectory: () => Promise<void>
  clearLibrary: () => Promise<void>
  deleteSong: (id: string) => Promise<void>
  updateSongArtwork: (id: string, artwork: string) => Promise<void>
  updateSongMetadata: (id: string, patch: SongMetadataPatch) => Promise<void>
  toggleFavorite: (id: string) => Promise<void>
  recordPlay: (id: string) => Promise<void>
  applyArtworkToAlbum: (artist: string, album: string, artwork: string) => Promise<void>
  getAlbumSongs: (albumId: string) => Song[]
  getArtistSongs: (artistId: string) => Song[]
  getGenreSongs: (genreId: string) => Song[]
  getFavorites: () => Song[]
  getMostPlayedThisMonth: () => Song[]
  getRecentlyPlayed: () => Song[]
  getRecentlyAdded: () => Song[]
}

function buildAlbums(songs: Song[]): Album[] {
  const map = new Map<string, Album>()
  for (const song of songs) {
    const key = `${song.album}||${song.artist}`
    if (!map.has(key)) {
      map.set(key, {
        id: key.replace(/[^a-zA-Z0-9]/g, '_'),
        title: song.album,
        artist: song.artist,
        artwork: song.artwork,
        year: song.year || undefined,
        songIds: [],
      })
    }
    const album = map.get(key)!
    album.songIds.push(song.id)
    if (!album.artwork && song.artwork) album.artwork = song.artwork
    if (song.year && (!album.year || song.year > album.year)) album.year = song.year
  }
  return Array.from(map.values()).sort((a, b) => a.title.localeCompare(b.title))
}

function buildGenres(songs: Song[]): Genre[] {
  const map = new Map<string, Genre>()
  for (const song of songs) {
    const name = (song.genre || 'Sin género').trim()
    const key = name.toLowerCase()
    if (!map.has(key)) {
      map.set(key, {
        id: key.replace(/[^a-zA-Z0-9]/g, '_'),
        name,
        songIds: [],
      })
    }
    map.get(key)!.songIds.push(song.id)
  }
  return Array.from(map.values()).sort((a, b) => a.name.localeCompare(b.name))
}

function rebuildLibraryState(songs: Song[]) {
  return {
    songs,
    albums: buildAlbums(songs),
    artists: buildArtists(songs),
    genres: buildGenres(songs),
  }
}

const MONTH_MS = 30 * 24 * 60 * 60 * 1000

function buildArtists(songs: Song[]): Artist[] {
  const map = new Map<string, Artist>()
  for (const song of songs) {
    const key = song.artist
    if (!map.has(key)) {
      map.set(key, {
        id: key.replace(/[^a-zA-Z0-9]/g, '_'),
        name: song.artist,
        artwork: song.artwork,
        albumIds: [],
        songIds: [],
      })
    }
    const artist = map.get(key)!
    artist.songIds.push(song.id)
    if (!artist.artwork && song.artwork) artist.artwork = song.artwork
  }
  return Array.from(map.values()).sort((a, b) => a.name.localeCompare(b.name))
}

async function backfillArtworks(
  songs: Song[],
  apply: (id: string, artwork: string) => void,
): Promise<Song[]> {
  const updated = new Map(songs.map((s) => [s.id, { ...s }]))
  await enrichSongsArtwork(songs, (songId, artwork) => {
    const song = updated.get(songId)
    if (!song) return
    song.artwork = artwork
    updated.set(songId, song)
    apply(songId, artwork)
  })
  return Array.from(updated.values())
}

export const useLibraryStore = create<LibraryStore>((set, get) => ({
  songs: [],
  albums: [],
  artists: [],
  genres: [],
  isLoading: false,
  isScanning: false,
  scanProgress: null,
  error: null,

  loadLibrary: async () => {
    set({ isLoading: true, error: null })
    try {
      const songs = await dbService.getAllSongs()
      set(rebuildLibraryState(songs))

      if (songs.some((s) => !s.artwork)) {
        void backfillArtworks(songs, (id, artwork) => {
          void dbService.updateSongArtwork(id, artwork)
        }).then((updated) => {
          set(rebuildLibraryState(updated))
        })
      }
    } catch (e) {
      set({ error: String(e) })
    } finally {
      set({ isLoading: false })
    }
  },

  scanFromFiles: async (files) => {
    set({ isScanning: true, error: null, scanProgress: null })
    try {
      const audioFiles = filterAudioFiles(files)
      if (audioFiles.length === 0) {
        set({ error: 'No se encontraron archivos de audio en la selección.' })
        return
      }
      const songs = await scanFiles(audioFiles, (p) => set({ scanProgress: p }))
      const artworkFromScan = new Map(songs.map((s) => [s.id, s.artwork]))
      cacheSongFiles(songs)
      await dbService.addSongs(songs)
      let all = await dbService.getAllSongs()
      all = all.map((s) => ({ ...s, artwork: s.artwork ?? artworkFromScan.get(s.id) }))
      set(rebuildLibraryState(all))

      all = await backfillArtworks(all, (id, artwork) => {
        void dbService.updateSongArtwork(id, artwork)
      })
      set(rebuildLibraryState(all))
    } catch (e) {
      const msg = getScanErrorMessage(e)
      if (msg) set({ error: msg })
    } finally {
      set({ isScanning: false, scanProgress: null })
    }
  },

  scanFromDirectory: async () => {
    set({ isScanning: true, error: null, scanProgress: null })
    try {
      const files = await scanDirectory((p) => set({ scanProgress: p }))
      if (files.length === 0) {
        set({ error: 'No se encontró música en la carpeta o disco seleccionado.' })
        return
      }
      const songs = await scanFiles(files, (p) => set({ scanProgress: p }))
      const artworkFromScan = new Map(songs.map((s) => [s.id, s.artwork]))
      cacheSongFiles(songs)
      await dbService.addSongs(songs)
      let all = await dbService.getAllSongs()
      all = all.map((s) => ({ ...s, artwork: s.artwork ?? artworkFromScan.get(s.id) }))
      set(rebuildLibraryState(all))

      all = await backfillArtworks(all, (id, artwork) => {
        void dbService.updateSongArtwork(id, artwork)
      })
      set(rebuildLibraryState(all))
    } catch (e) {
      const msg = getScanErrorMessage(e)
      if (msg) set({ error: msg })
    } finally {
      set({ isScanning: false, scanProgress: null })
    }
  },

  clearLibrary: async () => {
    await dbService.clearSongs()
    clearSongBlobCache()
    clearArtworkUrlCache()
    set({ songs: [], albums: [], artists: [], genres: [] })
  },

  deleteSong: async (id) => {
    await dbService.deleteSong(id)
    removeSongFromCache(id)
    revokeArtworkUrl(id)
    const songs = await dbService.getAllSongs()
    set(rebuildLibraryState(songs))
  },

  updateSongArtwork: async (id, artwork) => {
    await dbService.updateSongArtwork(id, artwork)
    const songs = get().songs.map((s) => (s.id === id ? { ...s, artwork } : s))
    set(rebuildLibraryState(songs))
  },

  updateSongMetadata: async (id, patch) => {
    await dbService.updateSong(id, patch)
    const songs = get().songs.map((s) => (s.id === id ? { ...s, ...patch } : s))
    set(rebuildLibraryState(songs))
  },

  toggleFavorite: async (id) => {
    const isFavorite = await dbService.toggleFavorite(id)
    const songs = get().songs.map((s) => (s.id === id ? { ...s, isFavorite } : s))
    set(rebuildLibraryState(songs))

    const player = usePlayerStore.getState()
    if (player.currentSong?.id === id) {
      usePlayerStore.setState({
        currentSong: { ...player.currentSong, isFavorite },
      })
    }
    if (player.queue.some((s) => s.id === id)) {
      usePlayerStore.setState({
        queue: player.queue.map((s) => (s.id === id ? { ...s, isFavorite } : s)),
        shuffledQueue: player.shuffledQueue.map((s) => (s.id === id ? { ...s, isFavorite } : s)),
      })
    }
  },

  recordPlay: async (id) => {
    await dbService.recordPlay(id)
    const songs = get().songs.map((s) =>
      s.id === id
        ? { ...s, playCount: (s.playCount ?? 0) + 1, lastPlayed: Date.now() }
        : s,
    )
    set(rebuildLibraryState(songs))
  },

  applyArtworkToAlbum: async (artist, album, artwork) => {
    if (!canShareArtworkByAlbum(artist, album)) return

    const songs = get().songs
    const targets = songs.filter(
      (s) => s.artist === artist && s.album === album && s.artwork !== artwork,
    )
    if (!targets.length) return

    await Promise.all(targets.map((s) => dbService.updateSongArtwork(s.id, artwork)))
    const updated = songs.map((s) =>
      s.artist === artist && s.album === album ? { ...s, artwork } : s,
    )
    set(rebuildLibraryState(updated))
  },

  getAlbumSongs: (albumId) => {
    const album = get().albums.find((a) => a.id === albumId)
    if (!album) return []
    const songMap = new Map(get().songs.map((s) => [s.id, s]))
    return album.songIds.map((id) => songMap.get(id)).filter(Boolean) as Song[]
  },

  getArtistSongs: (artistId) => {
    const artist = get().artists.find((a) => a.id === artistId)
    if (!artist) return []
    const songMap = new Map(get().songs.map((s) => [s.id, s]))
    return artist.songIds.map((id) => songMap.get(id)).filter(Boolean) as Song[]
  },

  getGenreSongs: (genreId) => {
    const genre = get().genres.find((g) => g.id === genreId)
    if (!genre) return []
    const songMap = new Map(get().songs.map((s) => [s.id, s]))
    return genre.songIds.map((id) => songMap.get(id)).filter(Boolean) as Song[]
  },

  getFavorites: () => get().songs.filter((s) => s.isFavorite),

  getMostPlayedThisMonth: () => {
    const cutoff = Date.now() - MONTH_MS
    return [...get().songs]
      .filter((s) => (s.lastPlayed ?? 0) >= cutoff && (s.playCount ?? 0) > 0)
      .sort((a, b) => (b.playCount ?? 0) - (a.playCount ?? 0))
      .slice(0, 15)
  },

  getRecentlyPlayed: () =>
    [...get().songs]
      .filter((s) => (s.lastPlayed ?? 0) > 0)
      .sort((a, b) => (b.lastPlayed ?? 0) - (a.lastPlayed ?? 0))
      .slice(0, 15),

  getRecentlyAdded: () =>
    [...get().songs].sort((a, b) => b.dateAdded - a.dateAdded).slice(0, 15),
}))
