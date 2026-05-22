import type { MenuAnchorPoint } from './SongActionsMenu'

export interface SongMenuState {
  songId: string
  anchor?: MenuAnchorPoint | null
}

export function openSongMenu(e: React.MouseEvent, songId: string): SongMenuState {
  e.preventDefault()
  e.stopPropagation()
  return { songId, anchor: { x: e.clientX, y: e.clientY } }
}

export function handleSongMenuOpenChange(
  open: boolean,
  songId: string,
  setMenuState: (state: SongMenuState | null) => void,
): void {
  if (open) setMenuState({ songId })
  else setMenuState(null)
}
