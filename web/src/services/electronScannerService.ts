import type { ScanProgress } from '../types'
import type { Song } from '../types'
import type { ElectronLocalFileEntry, ElectronScanProgress } from '../types/electron'
import { isElectronDesktop } from '../utils/platform'
import { scanElectronEntries } from './scannerService'

export function supportsElectronScan(): boolean {
  return isElectronDesktop && typeof window.electronAPI?.scanMusicPaths === 'function'
}

function mapDiscoverProgress(data: ElectronScanProgress): ScanProgress {
  return {
    phase: 'discovering',
    total: data.audioFound ?? 0,
    processed: 0,
    current: data.current ?? 'Escaneando…',
    foldersScanned: data.foldersScanned,
  }
}

export async function scanElectronFullDevice(
  onProgress?: (p: ScanProgress) => void,
): Promise<Song[]> {
  const api = window.electronAPI!
  const access = await api.requestFullScanAccess()
  if (!access.granted || access.paths.length === 0) return []
  return runElectronScan(access.paths, onProgress)
}

export async function scanElectronPickedFolder(
  onProgress?: (p: ScanProgress) => void,
): Promise<Song[]> {
  const api = window.electronAPI!
  const picked = await api.pickMusicFolder()
  if (!picked) return []
  return runElectronScan([picked], onProgress)
}

async function runElectronScan(
  paths: string[],
  onProgress?: (p: ScanProgress) => void,
): Promise<Song[]> {
  const api = window.electronAPI!

  onProgress?.({
    phase: 'discovering',
    total: 0,
    processed: 0,
    current: 'Preparando escaneo en Escritorio, Documentos, Descargas, Videos, Imágenes y Música…',
    foldersScanned: 0,
  })

  const entries: ElectronLocalFileEntry[] = await api.scanMusicPaths(paths, (data) => {
    onProgress?.(mapDiscoverProgress(data))
  })

  if (entries.length === 0) return []

  onProgress?.({
    phase: 'discovering',
    total: entries.length,
    processed: 0,
    current: `${entries.length} archivos encontrados — leyendo metadatos…`,
    foldersScanned: 0,
  })

  return scanElectronEntries(entries, onProgress)
}

export function openElectronFullDiskSettings(): void {
  void window.electronAPI?.openFullDiskSettings()
}
