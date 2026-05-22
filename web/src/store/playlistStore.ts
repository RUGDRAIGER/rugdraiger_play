import { create } from 'zustand'
import type { Playlist } from '../types'
import { dbService } from '../services/dbService'

interface PlaylistStore {
  playlists: Playlist[]
  activePlaylistId: string | null
  isLoading: boolean

  loadPlaylists: () => Promise<void>
  createPlaylist: (name: string, description?: string) => Promise<Playlist>
  deletePlaylist: (id: string) => Promise<void>
  renamePlaylist: (id: string, name: string) => Promise<void>
  addSongToPlaylist: (playlistId: string, songId: string) => Promise<void>
  removeSongFromPlaylist: (playlistId: string, songId: string) => Promise<void>
  setActivePlaylist: (id: string | null) => void
  getPlaylistById: (id: string) => Playlist | undefined
}

function generateId(): string {
  return `pl_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`
}

export const usePlaylistStore = create<PlaylistStore>((set, get) => ({
  playlists: [],
  activePlaylistId: null,
  isLoading: false,

  loadPlaylists: async () => {
    set({ isLoading: true })
    const playlists = await dbService.getAllPlaylists()
    set({ playlists, isLoading: false })
  },

  createPlaylist: async (name, description) => {
    const playlist: Playlist = {
      id: generateId(),
      name,
      description,
      songIds: [],
      createdAt: Date.now(),
      updatedAt: Date.now(),
    }
    await dbService.savePlaylist(playlist)
    set((s) => ({ playlists: [...s.playlists, playlist] }))
    return playlist
  },

  deletePlaylist: async (id) => {
    await dbService.deletePlaylist(id)
    set((s) => ({ playlists: s.playlists.filter((p) => p.id !== id) }))
  },

  renamePlaylist: async (id, name) => {
    const pl = get().playlists.find((p) => p.id === id)
    if (!pl) return
    const updated = { ...pl, name, updatedAt: Date.now() }
    await dbService.savePlaylist(updated)
    set((s) => ({ playlists: s.playlists.map((p) => (p.id === id ? updated : p)) }))
  },

  addSongToPlaylist: async (playlistId, songId) => {
    await dbService.addSongToPlaylist(playlistId, songId)
    set((s) => ({
      playlists: s.playlists.map((p) =>
        p.id === playlistId && !p.songIds.includes(songId)
          ? { ...p, songIds: [...p.songIds, songId], updatedAt: Date.now() }
          : p,
      ),
    }))
  },

  removeSongFromPlaylist: async (playlistId, songId) => {
    await dbService.removeSongFromPlaylist(playlistId, songId)
    set((s) => ({
      playlists: s.playlists.map((p) =>
        p.id === playlistId
          ? { ...p, songIds: p.songIds.filter((id) => id !== songId), updatedAt: Date.now() }
          : p,
      ),
    }))
  },

  setActivePlaylist: (id) => set({ activePlaylistId: id }),
  getPlaylistById: (id) => get().playlists.find((p) => p.id === id),
}))
