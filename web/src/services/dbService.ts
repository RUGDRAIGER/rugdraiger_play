import Dexie, { type Table } from 'dexie'
import type { Song, Playlist } from '../types'
import { dataUrlToBlob, localArtworkRef } from './artworkUtils'

interface SongBlobRecord {
  id: string
  blob: Blob
}

interface SongArtworkRecord {
  id: string
  blob: Blob
}

class RugdraigerDB extends Dexie {
  songs!: Table<Song, string>
  playlists!: Table<Playlist, string>
  songBlobs!: Table<SongBlobRecord, string>
  songArtworks!: Table<SongArtworkRecord, string>

  constructor() {
    super('RugdraigerPlayerDB')
    this.version(1).stores({
      songs: 'id, title, artist, album, genre, dateAdded',
      playlists: 'id, name, createdAt',
    })
    this.version(2).stores({
      songs: 'id, title, artist, album, genre, dateAdded',
      playlists: 'id, name, createdAt',
      songBlobs: 'id',
    })
    this.version(3).stores({
      songs: 'id, title, artist, album, genre, dateAdded',
      playlists: 'id, name, createdAt',
      songBlobs: 'id',
      songArtworks: 'id',
    })
  }
}

export const db = new RugdraigerDB()

export const dbService = {
  async getAllSongs(): Promise<Song[]> {
    return db.songs.orderBy('title').toArray()
  },

  async getSongById(id: string): Promise<Song | undefined> {
    return db.songs.get(id)
  },

  async addSongs(songs: Song[]): Promise<void> {
    const storable: Song[] = []

    for (const { file, ...song } of songs) {
      const existing = await db.songs.get(song.id)
      if (existing?.artwork && !song.artwork) {
        song.artwork = existing.artwork
      }

      if (song.artwork?.startsWith('data:')) {
        const blob = dataUrlToBlob(song.artwork)
        if (blob) {
          await db.songArtworks.put({ id: song.id, blob })
          song.artwork = localArtworkRef(song.id)
        }
      }

      storable.push(song)
    }

    await db.songs.bulkPut(storable)

    const blobRecords = songs
      .filter((s) => s.file)
      .map((s) => ({ id: s.id, blob: s.file as Blob }))

    if (blobRecords.length > 0) {
      await db.songBlobs.bulkPut(blobRecords)
    }
  },

  async getSongArtworkBlob(id: string): Promise<Blob | undefined> {
    const record = await db.songArtworks.get(id)
    return record?.blob
  },

  async saveSongArtwork(id: string, artwork: string): Promise<void> {
    if (artwork.startsWith('data:')) {
      const blob = dataUrlToBlob(artwork)
      if (blob) {
        await db.songArtworks.put({ id, blob })
        await db.songs.update(id, { artwork: localArtworkRef(id) })
        return
      }
    }
    await db.songs.update(id, { artwork })
  },

  async getSongBlob(id: string): Promise<Blob | undefined> {
    const record = await db.songBlobs.get(id)
    return record?.blob
  },

  async updateSongArtwork(id: string, artwork: string): Promise<void> {
    await this.saveSongArtwork(id, artwork)
  },

  async deleteSong(id: string): Promise<void> {
    await db.songs.delete(id)
    await db.songBlobs.delete(id)
    await db.songArtworks.delete(id)
    const playlists = await db.playlists.toArray()
    for (const pl of playlists) {
      if (pl.songIds.includes(id)) {
        pl.songIds = pl.songIds.filter((sid) => sid !== id)
        pl.updatedAt = Date.now()
        await db.playlists.put(pl)
      }
    }
  },

  async clearSongs(): Promise<void> {
    await db.songs.clear()
    await db.songBlobs.clear()
    await db.songArtworks.clear()
  },

  async searchSongs(query: string): Promise<Song[]> {
    const q = query.toLowerCase()
    return db.songs
      .filter(
        (s) =>
          s.title.toLowerCase().includes(q) ||
          s.artist.toLowerCase().includes(q) ||
          s.album.toLowerCase().includes(q),
      )
      .toArray()
  },

  async getAllPlaylists(): Promise<Playlist[]> {
    return db.playlists.orderBy('name').toArray()
  },

  async getPlaylistById(id: string): Promise<Playlist | undefined> {
    return db.playlists.get(id)
  },

  async savePlaylist(playlist: Playlist): Promise<void> {
    await db.playlists.put(playlist)
  },

  async deletePlaylist(id: string): Promise<void> {
    await db.playlists.delete(id)
  },

  async addSongToPlaylist(playlistId: string, songId: string): Promise<void> {
    const pl = await db.playlists.get(playlistId)
    if (!pl) return
    if (!pl.songIds.includes(songId)) {
      pl.songIds.push(songId)
      pl.updatedAt = Date.now()
      await db.playlists.put(pl)
    }
  },

  async removeSongFromPlaylist(playlistId: string, songId: string): Promise<void> {
    const pl = await db.playlists.get(playlistId)
    if (!pl) return
    pl.songIds = pl.songIds.filter((id) => id !== songId)
    pl.updatedAt = Date.now()
    await db.playlists.put(pl)
  },
}
