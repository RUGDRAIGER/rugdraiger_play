import { useEffect, useLayoutEffect, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import { useLibraryStore } from '../../store/libraryStore'
import { usePlayerStore } from '../../store/playerStore'
import { usePlaylistStore } from '../../store/playlistStore'
import { ConfirmDialog } from './ConfirmDialog'
import type { Song } from '../../types'

export interface MenuAnchorPoint {
  x: number
  y: number
}

interface Props {
  song: Song
  variant?: 'inline' | 'overlay'
  playlistId?: string
  onAction?: () => void
  open?: boolean
  onOpenChange?: (open: boolean) => void
  anchorPoint?: MenuAnchorPoint | null
  onClearAnchor?: () => void
}

const MENU_WIDTH = 220
const MENU_EST_HEIGHT = 280

function clampMenuPosition(left: number, top: number) {
  const pad = 8
  let x = left
  let y = top

  if (x + MENU_WIDTH > window.innerWidth - pad) {
    x = window.innerWidth - MENU_WIDTH - pad
  }
  if (x < pad) x = pad
  if (y + MENU_EST_HEIGHT > window.innerHeight - pad) {
    y = Math.max(pad, y - MENU_EST_HEIGHT)
  }
  if (y < pad) y = pad

  return { top: y, left: x }
}

function computeMenuPositionFromButton(anchor: DOMRect) {
  return clampMenuPosition(anchor.right - MENU_WIDTH, anchor.bottom + 4)
}

function computeMenuPositionFromPoint(point: MenuAnchorPoint) {
  return clampMenuPosition(point.x, point.y)
}

export function SongActionsMenu({
  song,
  variant = 'inline',
  playlistId,
  onAction,
  open,
  onOpenChange,
  anchorPoint,
  onClearAnchor,
}: Props) {
  const [internalOpen, setInternalOpen] = useState(false)
  const isControlled = open !== undefined
  const isOpen = isControlled ? open : internalOpen
  const [confirmDelete, setConfirmDelete] = useState(false)
  const [confirmRemove, setConfirmRemove] = useState(false)
  const [menuPos, setMenuPos] = useState({ top: 0, left: 0 })
  const [usePointerAnchor, setUsePointerAnchor] = useState(false)
  const ref = useRef<HTMLDivElement>(null)
  const buttonRef = useRef<HTMLButtonElement>(null)

  const setMenuOpen = (value: boolean) => {
    if (!value) setUsePointerAnchor(false)
    if (isControlled) onOpenChange?.(value)
    else setInternalOpen(value)
  }

  useEffect(() => {
    if (isControlled && open) setInternalOpen(false)
  }, [isControlled, open])

  const { deleteSong } = useLibraryStore()
  const { addToQueue, onSongRemoved } = usePlayerStore()
  const { playlists, addSongToPlaylist, removeSongFromPlaylist, loadPlaylists } = usePlaylistStore()

  useLayoutEffect(() => {
    if (!isOpen) return

    if (anchorPoint) {
      setUsePointerAnchor(true)
      setMenuPos(computeMenuPositionFromPoint(anchorPoint))
      return
    }

    if (buttonRef.current) {
      setUsePointerAnchor(false)
      setMenuPos(computeMenuPositionFromButton(buttonRef.current.getBoundingClientRect()))
    }
  }, [isOpen, anchorPoint, playlists.length])

  useEffect(() => {
    if (!isOpen) return

    const reposition = () => {
      if (usePointerAnchor && anchorPoint) {
        setMenuPos(computeMenuPositionFromPoint(anchorPoint))
        return
      }
      if (buttonRef.current) {
        setMenuPos(computeMenuPositionFromButton(buttonRef.current.getBoundingClientRect()))
      }
    }

    window.addEventListener('resize', reposition)
    window.addEventListener('scroll', reposition, true)

    const handler = (e: MouseEvent) => {
      const target = e.target as Node
      if (ref.current?.contains(target)) return
      if (document.getElementById('song-actions-menu-portal')?.contains(target)) return
      setMenuOpen(false)
    }

    document.addEventListener('mousedown', handler)
    return () => {
      document.removeEventListener('mousedown', handler)
      window.removeEventListener('resize', reposition)
      window.removeEventListener('scroll', reposition, true)
    }
  }, [isOpen, usePointerAnchor, anchorPoint])

  function closeMenu() {
    setMenuOpen(false)
    onAction?.()
  }

  async function handleDelete() {
    await deleteSong(song.id)
    onSongRemoved(song.id)
    await loadPlaylists()
    setConfirmDelete(false)
    closeMenu()
  }

  async function handleRemoveFromPlaylist() {
    if (!playlistId) return
    await removeSongFromPlaylist(playlistId, song.id)
    setConfirmRemove(false)
    closeMenu()
  }

  const isOverlay = variant === 'overlay'
  const btnSize = isOverlay ? 26 : 28

  const menuPanel = isOpen ? (
    <div
      id="song-actions-menu-portal"
      style={{
        position: 'fixed',
        top: menuPos.top,
        left: menuPos.left,
        zIndex: 5000,
        width: MENU_WIDTH,
        maxWidth: 'calc(100vw - 16px)',
        background: 'var(--bg-surface2)',
        border: '1px solid var(--border)',
        borderRadius: 'var(--radius-md)',
        padding: 4,
        boxShadow: '0 12px 40px rgba(0,0,0,0.55)',
      }}
      onClick={(e) => e.stopPropagation()}
      onContextMenu={(e) => e.preventDefault()}
    >
      <div style={{ padding: '6px 12px', fontSize: 12, color: 'var(--text-secondary)', fontWeight: 600, borderBottom: '1px solid var(--border)', marginBottom: 4 }}>
        Agregar a playlist
      </div>
      {playlists.length === 0 ? (
        <div style={{ padding: '8px 12px', fontSize: 13, color: 'var(--text-tertiary)' }}>Sin playlists</div>
      ) : (
        <div style={{ maxHeight: 160, overflowY: 'auto' }}>
          {playlists.map((pl) => (
            <button
              key={pl.id}
              type="button"
              onClick={async () => {
                await addSongToPlaylist(pl.id, song.id)
                closeMenu()
              }}
              style={{
                display: 'block',
                width: '100%',
                textAlign: 'left',
                padding: '8px 12px',
                fontSize: 13,
                cursor: 'pointer',
                borderRadius: 6,
              }}
              onMouseEnter={(e) => { e.currentTarget.style.background = 'rgba(255,255,255,0.07)' }}
              onMouseLeave={(e) => { e.currentTarget.style.background = 'transparent' }}
            >
              {pl.name}
            </button>
          ))}
        </div>
      )}
      <div style={{ borderTop: '1px solid var(--border)', marginTop: 4, paddingTop: 4 }}>
        <button
          type="button"
          onClick={() => {
            addToQueue(song)
            closeMenu()
          }}
          style={{ display: 'block', width: '100%', textAlign: 'left', padding: '8px 12px', fontSize: 13, cursor: 'pointer', borderRadius: 6 }}
          onMouseEnter={(e) => { e.currentTarget.style.background = 'rgba(255,255,255,0.07)' }}
          onMouseLeave={(e) => { e.currentTarget.style.background = 'transparent' }}
        >
          Agregar a la cola
        </button>
        {playlistId && (
          <button
            type="button"
            onClick={() => {
              setMenuOpen(false)
              setConfirmRemove(true)
            }}
            style={{ display: 'block', width: '100%', textAlign: 'left', padding: '8px 12px', fontSize: 13, cursor: 'pointer', borderRadius: 6 }}
            onMouseEnter={(e) => { e.currentTarget.style.background = 'rgba(255,255,255,0.07)' }}
            onMouseLeave={(e) => { e.currentTarget.style.background = 'transparent' }}
          >
            Quitar de playlist
          </button>
        )}
        <button
          type="button"
          onClick={() => {
            setMenuOpen(false)
            setConfirmDelete(true)
          }}
          style={{ display: 'block', width: '100%', textAlign: 'left', padding: '8px 12px', fontSize: 13, cursor: 'pointer', borderRadius: 6, color: 'var(--accent)' }}
          onMouseEnter={(e) => { e.currentTarget.style.background = 'rgba(255,32,32,0.1)' }}
          onMouseLeave={(e) => { e.currentTarget.style.background = 'transparent' }}
        >
          Eliminar canción
        </button>
      </div>
    </div>
  ) : null

  return (
    <>
      <ConfirmDialog
        open={confirmDelete}
        title="Eliminar canción"
        message={`¿Eliminar "${song.title}" de la biblioteca? Esta acción no se puede deshacer.`}
        confirmLabel="Eliminar"
        onConfirm={handleDelete}
        onCancel={() => setConfirmDelete(false)}
      />
      <ConfirmDialog
        open={confirmRemove}
        title="Quitar canción"
        message={`¿Quitar "${song.title}" de la playlist?`}
        confirmLabel="Quitar"
        onConfirm={handleRemoveFromPlaylist}
        onCancel={() => setConfirmRemove(false)}
      />

      <div
        ref={ref}
        style={{
          position: 'relative',
          flexShrink: 0,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <button
          ref={buttonRef}
          type="button"
          aria-label="Opciones de canción"
          title="Opciones"
          onClick={(e) => {
            e.stopPropagation()
            onClearAnchor?.()
            if (isControlled) {
              onOpenChange?.(!isOpen)
            } else {
              setInternalOpen(!isOpen)
            }
          }}
          onMouseDown={(e) => e.stopPropagation()}
          style={{
            width: btnSize,
            height: btnSize,
            borderRadius: 6,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            cursor: 'pointer',
            color: isOverlay ? '#fff' : 'var(--text-secondary)',
            background: isOverlay ? 'rgba(0,0,0,0.6)' : isOpen ? 'var(--bg-surface2)' : 'transparent',
            border: isOverlay ? 'none' : '1px solid transparent',
            transition: 'background 0.15s, color 0.15s, opacity 0.15s',
            opacity: isOverlay && !isOpen ? 0.9 : 1,
          }}
          onMouseEnter={(e) => {
            if (!isOverlay) {
              e.currentTarget.style.background = 'var(--bg-surface2)'
              e.currentTarget.style.color = 'var(--text-primary)'
            }
          }}
          onMouseLeave={(e) => {
            if (!isOverlay && !isOpen) {
              e.currentTarget.style.background = 'transparent'
              e.currentTarget.style.color = 'var(--text-secondary)'
            }
          }}
        >
          <svg width={isOverlay ? 15 : 18} height={isOverlay ? 15 : 18} viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 8c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z" />
          </svg>
        </button>
      </div>

      {menuPanel && createPortal(menuPanel, document.body)}
    </>
  )
}
