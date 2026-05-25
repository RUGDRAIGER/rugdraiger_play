import { useState } from 'react'
import type { Song, SongMetadataPatch } from '../../types'
import { useLibraryStore } from '../../store/libraryStore'

interface Props {
  song: Song
  open: boolean
  onClose: () => void
}

export function MetadataEditor({ song, open, onClose }: Props) {
  const updateSongMetadata = useLibraryStore((s) => s.updateSongMetadata)
  const updateSongArtwork = useLibraryStore((s) => s.updateSongArtwork)
  const [form, setForm] = useState<SongMetadataPatch>({
    title: song.title,
    artist: song.artist,
    album: song.album,
    genre: song.genre,
    year: song.year || undefined,
    composer: song.composer || '',
  })

  if (!open) return null

  async function handleSave() {
    await updateSongMetadata(song.id, {
      title: form.title?.trim() || song.title,
      artist: form.artist?.trim() || song.artist,
      album: form.album?.trim() || song.album,
      genre: form.genre?.trim() || '',
      year: form.year ? Number(form.year) : 0,
      composer: form.composer?.trim() || '',
    })
    onClose()
  }

  async function handleArtwork(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    const reader = new FileReader()
    reader.onload = async () => {
      const dataUrl = reader.result as string
      await updateSongArtwork(song.id, dataUrl)
    }
    reader.readAsDataURL(file)
  }

  const fieldStyle: React.CSSProperties = {
    width: '100%',
    padding: '10px 12px',
    background: 'var(--bg-surface2)',
    border: '1px solid var(--border)',
    borderRadius: 'var(--radius-md)',
    color: 'var(--text-primary)',
    fontSize: 14,
  }

  return (
    <div
      style={{
        position: 'fixed', inset: 0, zIndex: 6000,
        background: 'rgba(0,0,0,0.65)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        padding: 20,
      }}
      onClick={onClose}
    >
      <div
        className="slide-up"
        style={{
          width: 'min(420px, 100%)',
          background: 'var(--bg-secondary)',
          borderRadius: 'var(--radius-lg)',
          border: '1px solid var(--border)',
          padding: 24,
          display: 'flex', flexDirection: 'column', gap: 14,
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <h2 style={{ fontSize: 18, fontWeight: 700 }}>Editar metadatos</h2>
        <p style={{ fontSize: 12, color: 'var(--text-secondary)', marginTop: -8 }}>
          Los cambios se guardan en la biblioteca local (no modifican el archivo original).
        </p>

        {(['title', 'artist', 'album', 'genre', 'composer'] as const).map((key) => (
          <label key={key} style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
            <span style={{ fontSize: 12, color: 'var(--text-secondary)', textTransform: 'capitalize' }}>
              {key === 'title' ? 'Título' : key === 'artist' ? 'Artista' : key === 'album' ? 'Álbum' : key === 'genre' ? 'Género' : 'Compositor'}
            </span>
            <input
              type="text"
              value={form[key] ?? ''}
              onChange={(e) => setForm({ ...form, [key]: e.target.value })}
              style={fieldStyle}
            />
          </label>
        ))}

        <label style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
          <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>Año</span>
          <input
            type="number"
            value={form.year ?? ''}
            onChange={(e) => setForm({ ...form, year: e.target.value ? Number(e.target.value) : undefined })}
            style={fieldStyle}
          />
        </label>

        <label style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
          <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>Carátula</span>
          <input type="file" accept="image/*" onChange={handleArtwork} style={{ fontSize: 13, color: 'var(--text-secondary)' }} />
        </label>

        <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end', marginTop: 8 }}>
          <button type="button" onClick={onClose} style={{ padding: '10px 16px', borderRadius: 'var(--radius-md)', border: '1px solid var(--border)', color: 'var(--text-secondary)', cursor: 'pointer' }}>
            Cancelar
          </button>
          <button type="button" onClick={() => void handleSave()} style={{ padding: '10px 16px', borderRadius: 'var(--radius-md)', background: 'var(--accent)', color: '#fff', fontWeight: 600, cursor: 'pointer' }}>
            Guardar
          </button>
        </div>
      </div>
    </div>
  )
}
