import { create } from 'zustand'
import type { Song, Album, Artist, ScanProgress } from '../types'
import { dbService } from '../services/dbService'
import { scanFiles, scanDirectory, getScanErrorMessage, filterAudioFiles } from '../services/scannerService'
import { enrichSongsArtwork, canShareArtworkByAlbum } from '../services/artworkService'
import { cacheSongFiles, clearSongBlobCache, removeSongFromCache } from '../services/audioFileService'
import { clearArtworkUrlCache, revokeArtworkUrl } from '../services/artworkFileService'

interface LibraryStore {
  songs: Song[]
  albums: Album[]
  artists: Artist[]
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
  applyArtworkToAlbum: (artist: string, album: string, artwork: string) => Promise<void>
  getAlbumSongs: (albumId: string) => Song[]
  getArtistSongs: (artistId: string) => Song[]
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
        songIds: [],
      })
    }
    const album = map.get(key)!
    album.songIds.push(song.id)
    if (!album.artwork && song.artwork) album.artwork = song.artwork
  }
  return Array.from(map.values()).sort((a, b) => a.title.localeCompare(b.title))
}

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
  isLoading: false,
  isScanning: false,
  scanProgress: null,
  error: null,

  loadLibrary: async () => {
    set({ isLoading: true, error: null })
    try {
      const songs = await dbService.getAllSongs()
      set({ songs, albums: buildAlbums(songs), artists: buildArtists(songs) })

      if (songs.some((s) => !s.artwork)) {
        void backfillArtworks(songs, (id, artwork) => {
          void dbService.updateSongArtwork(id, artwork)
        }).then((updated) => {
          set({ songs: updated, albums: buildAlbums(updated), artists: buildArtists(updated) })
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
      set({ songs: all, albums: buildAlbums(all), artists: buildArtists(all) })

      all = await backfillArtworks(all, (id, artwork) => {
        void dbService.updateSongArtwork(id, artwork)
      })
      set({ songs: all, albums: buildAlbums(all), artists: buildArtists(all) })
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
      set({ songs: all, albums: buildAlbums(all), artists: buildArtists(all) })

      all = await backfillArtworks(all, (id, artwork) => {
        void dbService.updateSongArtwork(id, artwork)
      })
      set({ songs: all, albums: buildAlbums(all), artists: buildArtists(all) })
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
    set({ songs: [], albums: [], artists: [] })
  },

  deleteSong: async (id) => {
    await dbService.deleteSong(id)
    removeSongFromCache(id)
    revokeArtworkUrl(id)
    const songs = await dbService.getAllSongs()
    set({ songs, albums: buildAlbums(songs), artists: buildArtists(songs) })
  },

  updateSongArtwork: async (id, artwork) => {
    await dbService.updateSongArtwork(id, artwork)
    const songs = get().songs.map((s) => (s.id === id ? { ...s, artwork } : s))
    set({ songs, albums: buildAlbums(songs), artists: buildArtists(songs) })
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
    set({ songs: updated, albums: buildAlbums(updated), artists: buildArtists(updated) })
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
}))
