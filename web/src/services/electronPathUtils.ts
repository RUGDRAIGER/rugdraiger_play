export function getElectronPathFromFile(file: File): string | undefined {
  return (file as File & { electronPath?: string }).electronPath
}

export function generateSongIdFromPath(filePath: string): string {
  return filePath.replace(/[^a-zA-Z0-9]/g, '_').substring(0, 96)
}

export function generateSongIdForFile(file: File, filePath?: string): string {
  if (filePath) return generateSongIdFromPath(filePath)
  const electronPath = getElectronPathFromFile(file)
  if (electronPath) return generateSongIdFromPath(electronPath)
  return `${file.name}-${file.size}-${file.lastModified}`
    .replace(/[^a-zA-Z0-9]/g, '_')
    .substring(0, 64)
}
