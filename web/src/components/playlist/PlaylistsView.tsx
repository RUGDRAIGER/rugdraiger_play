import { useState } from 'react'
import { usePlaylistStore } from '../../store/playlistStore'
import { useLibraryStore } from '../../store/libraryStore'
import { usePlayerStore } from '../../store/playerStore'
import { ArtworkDisplay } from '../ui/ArtworkDisplay'
import { PlayableArtwork } from '../ui/PlayableArtwork'
import { SongActionsMenu } from '../ui/SongActionsMenu'
import { openSongMenu, handleSongMenuOpenChange, type SongMenuState } from '../ui/songMenuUtils'
import { ConfirmDialog } from '../ui/ConfirmDialog'
import { formatDuration } from '../../services/scannerService'
import type { Playlist } from '../../types'

export function PlaylistsView() {
  const { playlists, createPlaylist, deletePlaylist } = usePlaylistStore()
  const { songs } = useLibraryStore()
  const { playSong } = usePlayerStore()
  const [selectedPlaylistId, setSelectedPlaylistId] = useState<string | null>(null)
  const [creating, setCreating] = useState(false)
  const [newName, setNewName] = useState('')
  const [playlistToDelete, setPlaylistToDelete] = useState<Playlist | null>(null)
  const [menuState, setMenuState] = useState<SongMenuState | null>(null)

  const songMap = new Map(songs.map((s) => [s.id, s]))

  const activePlaylist = playlists.find((p) => p.id === selectedPlaylistId)

  async function handleCreate() {
    if (!newName.trim()) return
    const pl = await createPlaylist(newName.trim())
    setNewName('')
    setCreating(false)
    setSelectedPlaylistId(pl.id)
  }

  async function handleConfirmDeletePlaylist() {
    if (!playlistToDelete) return
    await deletePlaylist(playlistToDelete.id)
    if (selectedPlaylistId === playlistToDelete.id) setSelectedPlaylistId(null)
    setPlaylistToDelete(null)
  }

  const deletePlaylistDialog = (
    <ConfirmDialog
      open={!!playlistToDelete}
      title="Eliminar playlist"
      message={playlistToDelete ? `¿Eliminar la playlist "${playlistToDelete.name}"? Esta acción no se puede deshacer.` : ''}
      confirmLabel="Eliminar"
      onConfirm={handleConfirmDeletePlaylist}
      onCancel={() => setPlaylistToDelete(null)}
    />
  )

  if (activePlaylist) {
    const plSongs = activePlaylist.songIds.map((id) => songMap.get(id)).filter(Boolean) as ReturnType<typeof songMap.get>[]
    const validSongs = plSongs.filter(Boolean) as NonNullable<typeof plSongs[0]>[]

    return (
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        {deletePlaylistDialog}
        <div style={{ padding: '20px 28px 16px', flexShrink: 0 }}>
          <button onClick={() => setSelectedPlaylistId(null)} style={{ color: 'var(--text-secondary)', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 4, fontSize: 14, marginBottom: 16 }}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z"/></svg>
            Playlists
          </button>
          <div style={{ display: 'flex', alignItems: 'center', gap: 16, flexWrap: 'wrap' }}>
            <div style={{ width: 100, height: 100, borderRadius: 12, overflow: 'hidden', background: 'var(--bg-surface)', flexShrink: 0, display: 'grid', gridTemplateColumns: '1fr 1fr', gridTemplateRows: '1fr 1fr' }}>
              {validSongs.slice(0, 4).map((s, i) => (
                <ArtworkDisplay key={i} song={s} size={50} borderRadius={0} style={{ width: '100%', height: '100%' }} />
              ))}
              {validSongs.length === 0 && (
                <div style={{ gridColumn: '1/-1', gridRow: '1/-1', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <svg width="40" height="40" viewBox="0 0 24 24" fill="var(--text-tertiary)"><path d="M15 6H3v2h12V6zm0 4H3v2h12v-2zM3 16h8v-2H3v2zM17 6v8.18c-.31-.11-.65-.18-1-.18-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3V8h3V6h-5z"/></svg>
                </div>
              )}
            </div>
            <div>
              <div style={{ fontSize: 22, fontWeight: 800 }}>{activePlaylist.name}</div>
              {activePlaylist.description && <div style={{ fontSize: 13, color: 'var(--text-secondary)', marginTop: 4 }}>{activePlaylist.description}</div>}
              <div style={{ fontSize: 13, color: 'var(--text-tertiary)', marginTop: 4 }}>{validSongs.length} canciones</div>
              <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
                {validSongs.length > 0 && (
                  <button
                    onClick={() => playSong(validSongs[0], validSongs)}
                    style={{ padding: '8px 16px', borderRadius: 'var(--radius-md)', background: 'var(--accent)', color: '#fff', fontSize: 13, fontWeight: 600, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6 }}
                  >
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>
                    Reproducir
                  </button>
                )}
                <button
                  onClick={() => setPlaylistToDelete(activePlaylist)}
                  style={{ padding: '8px 14px', borderRadius: 'var(--radius-md)', background: 'transparent', color: 'var(--text-secondary)', border: '1px solid var(--border)', fontSize: 13, cursor: 'pointer' }}
                >
                  Eliminar
                </button>
              </div>
            </div>
          </div>
        </div>

        <div className="scrollable" style={{ flex: 1, padding: '0 28px' }} onClick={() => setMenuState(null)}>
          {validSongs.length === 0 ? (
            <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-secondary)' }}>
              Agrega canciones desde el menú ⋮ o clic derecho en la lista de canciones
            </div>
          ) : validSongs.map((song) => (
            <div
              key={song.id}
              onDoubleClick={() => playSong(song, validSongs)}
              onContextMenu={(e) => setMenuState(openSongMenu(e, song.id))}
              style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '8px 0', borderBottom: '1px solid var(--border)', cursor: 'pointer' }}
            >
              <PlayableArtwork song={song} size={38} borderRadius={4} onPlay={() => playSong(song, validSongs)} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13, fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{song.title}</div>
                <div style={{ fontSize: 12, color: 'var(--text-secondary)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{song.artist}</div>
              </div>
              <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{formatDuration(song.duration)}</span>
              <SongActionsMenu
                song={song}
                playlistId={activePlaylist.id}
                open={menuState?.songId === song.id}
                anchorPoint={menuState?.songId === song.id ? (menuState.anchor ?? null) : null}
                onOpenChange={(open) => handleSongMenuOpenChange(open, song.id, setMenuState)}
              />
            </div>
          ))}
        </div>
      </div>
    )
  }

  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
      {deletePlaylistDialog}
      <div style={{ padding: '20px 28px 16px', flexShrink: 0 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <h1 style={{ fontSize: 22, fontWeight: 700 }}>Playlists</h1>
          <button
            onClick={() => setCreating(true)}
            style={{ padding: '8px 16px', borderRadius: 'var(--radius-md)', background: 'var(--accent)', color: '#fff', fontSize: 13, fontWeight: 600, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6 }}
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z"/></svg>
            Nueva playlist
          </button>
        </div>

        {creating && (
          <div style={{ display: 'flex', gap: 10, marginBottom: 16 }}>
            <input
              autoFocus
              type="text"
              placeholder="Nombre de la playlist"
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
              onKeyDown={(e) => { if (e.key === 'Enter') handleCreate(); if (e.key === 'Escape') { setCreating(false); setNewName('') } }}
              style={{ flex: 1, padding: '9px 12px', background: 'var(--bg-surface)', border: '1px solid var(--border-accent)', borderRadius: 'var(--radius-md)', fontSize: 14, color: 'var(--text-primary)', outline: 'none' }}
            />
            <button onClick={handleCreate} style={{ padding: '8px 16px', borderRadius: 'var(--radius-md)', background: 'var(--accent)', color: '#fff', fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>Crear</button>
            <button onClick={() => { setCreating(false); setNewName('') }} style={{ padding: '8px 14px', borderRadius: 'var(--radius-md)', background: 'var(--bg-surface)', color: 'var(--text-secondary)', border: '1px solid var(--border)', fontSize: 13, cursor: 'pointer' }}>Cancelar</button>
          </div>
        )}
      </div>

      <div className="scrollable" style={{ flex: 1, padding: '0 28px 24px' }}>
        {playlists.length === 0 ? (
          <div style={{ padding: 60, textAlign: 'center' }}>
            <div style={{ width: 64, height: 64, borderRadius: '50%', background: 'var(--bg-surface)', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 16px', border: '2px solid var(--border)' }}>
              <svg width="32" height="32" viewBox="0 0 24 24" fill="var(--text-tertiary)"><path d="M15 6H3v2h12V6zm0 4H3v2h12v-2zM3 16h8v-2H3v2zM17 6v8.18c-.31-.11-.65-.18-1-.18-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3V8h3V6h-5z"/></svg>
            </div>
            <p style={{ color: 'var(--text-secondary)' }}>No hay playlists. ¡Crea una!</p>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
            {playlists.map((pl) => {
              const plSongs = pl.songIds.slice(0, 4).map((id) => songMap.get(id)).filter(Boolean) as NonNullable<ReturnType<typeof songMap.get>>[]
              return (
                <PlaylistCard
                  key={pl.id}
                  playlist={pl}
                  songs={plSongs}
                  count={pl.songIds.length}
                  onClick={() => setSelectedPlaylistId(pl.id)}
                  onDelete={() => setPlaylistToDelete(pl)}
                />
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}

function PlaylistCard({ playlist, songs, count, onClick, onDelete }: { playlist: Playlist; songs: { artwork?: string }[]; count: number; onClick: () => void; onDelete: () => void }) {
  return (
    <div
      onClick={onClick}
      style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '10px 12px', borderRadius: 'var(--radius-md)', cursor: 'pointer' }}
      onMouseEnter={(e) => e.currentTarget.style.background = 'var(--bg-surface)'}
      onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
    >
      <div style={{ width: 48, height: 48, borderRadius: 8, overflow: 'hidden', background: 'var(--bg-surface2)', display: 'grid', gridTemplateColumns: '1fr 1fr', gridTemplateRows: '1fr 1fr', flexShrink: 0 }}>
        {songs.length > 0
          ? songs.slice(0, 4).map((s, i) => (
            <ArtworkDisplay key={i} song={s as never} size={24} borderRadius={0} style={{ width: '100%', height: '100%' }} />
          ))
          : <div style={{ gridColumn: '1/-1', gridRow: '1/-1', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="var(--text-tertiary)"><path d="M15 6H3v2h12V6zm0 4H3v2h12v-2zM3 16h8v-2H3v2zM17 6v8.18c-.31-.11-.65-.18-1-.18-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3V8h3V6h-5z"/></svg>
          </div>
        }
      </div>
      <div>
        <div style={{ fontSize: 14, fontWeight: 600 }}>{playlist.name}</div>
        <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{count} canciones</div>
      </div>
      <button
        onClick={(e) => { e.stopPropagation(); onDelete() }}
        title="Eliminar playlist"
        style={{ marginLeft: 'auto', color: 'var(--text-tertiary)', cursor: 'pointer', padding: 6, borderRadius: 4, flexShrink: 0 }}
        onMouseEnter={(e) => e.currentTarget.style.color = 'var(--accent)'}
        onMouseLeave={(e) => e.currentTarget.style.color = 'var(--text-tertiary)'}
      >
        <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/></svg>
      </button>
      <svg style={{ color: 'var(--text-tertiary)', flexShrink: 0 }} width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M8.59 16.59 13.17 12 8.59 7.41 10 6l6 6-6 6-1.41-1.41z"/></svg>
    </div>
  )
}
