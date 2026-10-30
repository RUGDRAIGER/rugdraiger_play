import type { Song } from './index'

export interface ElectronLocalFileEntry {
  path: string
  name: string
  size: number
  mtime: number
}

export interface ElectronPlayerStatePayload {
  hasTrack: boolean
  title: string
  artist: string
  isPlaying: boolean
  artwork?: string
  accentColor?: string
}

export type NotchCommand = 'play-pause' | 'next' | 'prev' | 'focus'

export interface ElectronScanProgress {
  phase: 'discovering' | 'processing'
  current: string
  foldersScanned?: number
  audioFound?: number
}

export interface ElectronScanAccessResult {
  granted: boolean
  paths: string[]
}

export interface NavidromeConfig {
  connected: boolean
  serverUrl: string
  username: string
  lastVerifiedAt: string
  serverVersion: string
}

export interface NavidromeConnectionInfo {
  apiVersion: string
  serverType: string
  serverVersion: string
  openSubsonic: boolean
}

export interface NavidromeConnectionResult {
  config: NavidromeConfig
  connectionInfo: NavidromeConnectionInfo
}

export interface NavidromeSyncProgress {
  imported: number
  current: string
}

export interface ElectronAPI {
  isDesktop: boolean
  platform: string
  getDefaultMusicPaths: () => Promise<string[]>
  requestFullScanAccess: () => Promise<ElectronScanAccessResult>
  openFullDiskSettings: () => Promise<boolean>
  pickMusicFolder: () => Promise<string | null>
  scanMusicPaths: (
    paths: string[],
    onProgress?: (progress: ElectronScanProgress) => void,
  ) => Promise<ElectronLocalFileEntry[]>
  readLocalFile: (filePath: string) => Promise<ArrayBuffer>
  getLocalFileUrl: (filePath: string) => Promise<string>
  getNavidromeConfig: () => Promise<NavidromeConfig>
  connectNavidrome: (config: { serverUrl: string; username: string; password?: string }) => Promise<NavidromeConnectionResult>
  testNavidromeConnection: () => Promise<NavidromeConnectionResult>
  disconnectNavidrome: () => Promise<NavidromeConfig>
  syncNavidromeLibrary: (onProgress?: (progress: NavidromeSyncProgress) => void) => Promise<Song[]>
  sendPlayerState: (state: ElectronPlayerStatePayload) => void
  onNotchCommand: (callback: (command: NotchCommand) => void) => () => void
}

declare global {
  interface Window {
    electronAPI?: ElectronAPI
  }
}

export {}
