import type { Song } from '../../types'

export function MusicSourceBadge({ song, compact = false }: { song: Song; compact?: boolean }) {
  const remote = song.source === 'navidrome'
  return (
    <span
      title={remote ? 'Música transmitida desde Navidrome' : 'Archivo guardado en este dispositivo'}
      style={{
        display: 'inline-flex', alignItems: 'center', gap: 4, flexShrink: 0,
        padding: compact ? '2px 5px' : '3px 7px', borderRadius: 999,
        fontSize: compact ? 9 : 10, lineHeight: 1, fontWeight: 750, letterSpacing: 0.2,
        color: remote ? '#8ec5ff' : '#9ad8aa',
        background: remote ? 'rgba(64, 156, 255, 0.13)' : 'rgba(48, 209, 88, 0.11)',
        border: `1px solid ${remote ? 'rgba(64, 156, 255, 0.24)' : 'rgba(48, 209, 88, 0.2)'}`,
      }}
    >
      <span aria-hidden style={{ width: 5, height: 5, borderRadius: '50%', background: 'currentColor' }} />
      {remote ? 'Navidrome' : 'Local'}
    </span>
  )
}
