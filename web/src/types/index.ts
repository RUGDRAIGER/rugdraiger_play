export interface Song {
  id: string
  title: string
  artist: string
  album: string
  genre: string
  duration: number
  fileSize: number
  trackNumber: number
  format: string
  isLossless: boolean
  dateAdded: number
  filePath?: string
  artwork?: string
  file?: File
}

export interface Album {
  id: string
  title: string
  artist: string
  artwork?: string
  year?: number
  songIds: string[]
}

export interface Artist {
  id: string
  name: string
  artwork?: string
  albumIds: string[]
  songIds: string[]
}

export interface Playlist {
  id: string
  name: string
  description?: string
  artwork?: string
  songIds: string[]
  createdAt: number
  updatedAt: number
}

export type RepeatMode = 'none' | 'one' | 'all'

export interface PlayerState {
  currentSong: Song | null
  queue: Song[]
  queueIndex: number
  isPlaying: boolean
  progress: number
  duration: number
  volume: number
  isMuted: boolean
  repeatMode: RepeatMode
  isShuffled: boolean
  isFullPlayerOpen: boolean
}

export interface EQBand {
  frequency: number
  gain: number
  label: string
}

export type ViewName = 'home' | 'library' | 'songs' | 'albums' | 'artists' | 'playlists' | 'playlist-detail' | 'equalizer' | 'search'

export interface ScanProgress {
  total: number
  processed: number
  current: string
  phase?: 'discovering' | 'processing'
  foldersScanned?: number
}
