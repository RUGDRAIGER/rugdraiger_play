import { useSettingsStore } from '../../store/settingsStore'
import { useLibraryStore } from '../../store/libraryStore'
import { LOSSLESS_FORMATS } from '../../constants/audioFormats'

function Toggle({ label, description, value, onChange }: {
  label: string
  description?: string
  value: boolean
  onChange: (v: boolean) => void
}) {
  return (
    <label style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, padding: '14px 0', borderBottom: '1px solid var(--border)', cursor: 'pointer' }}>
      <div>
        <div style={{ fontSize: 15, fontWeight: 600 }}>{label}</div>
        {description && <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginTop: 2 }}>{description}</div>}
      </div>
      <div
        onClick={(e) => { e.preventDefault(); onChange(!value) }}
        style={{
          width: 44, height: 24, borderRadius: 12, flexShrink: 0,
          background: value ? 'var(--accent)' : 'var(--bg-surface3)',
          position: 'relative', transition: 'background 0.2s',
        }}
      >
        <div style={{
          position: 'absolute', width: 18, height: 18, borderRadius: '50%',
          background: '#fff', top: 3, left: value ? 23 : 3, transition: 'left 0.2s',
        }} />
      </div>
    </label>
  )
}

interface Props {
  onNavigateEqualizer: () => void
}

export function SettingsView({ onNavigateEqualizer }: Props) {
  const settings = useSettingsStore()
  const songs = useLibraryStore((s) => s.songs)
  const losslessCount = songs.filter((s) => s.isLossless || LOSSLESS_FORMATS.includes(s.format)).length

  return (
    <div className="scrollable mobile-page" style={{ flex: 1, padding: '24px 28px', display: 'flex', flexDirection: 'column', gap: 28 }}>
      <h1 style={{ fontSize: 22, fontWeight: 700 }}>Ajustes</h1>

      <section>
        <div style={{ fontSize: 12, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: 1, marginBottom: 4 }}>Reproducción</div>
        <Toggle
          label="Gapless playback"
          description="Transición sin silencios entre canciones del álbum"
          value={settings.gaplessPlayback}
          onChange={settings.setGaplessPlayback}
        />
        <Toggle
          label="ReplayGain"
          description="Normaliza el volumen entre pistas según metadatos"
          value={settings.replayGainEnabled}
          onChange={settings.setReplayGainEnabled}
        />
        <Toggle
          label="Teclas multimedia"
          description="Control desde auriculares, Bluetooth y centro de control"
          value={settings.mediaKeysEnabled}
          onChange={settings.setMediaKeysEnabled}
        />
        <Toggle
          label="Mostrar letras"
          description="Letras embebidas o archivos .lrc locales"
          value={settings.showLyrics}
          onChange={settings.setShowLyrics}
        />
      </section>

      <section>
        <div style={{ fontSize: 12, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: 1, marginBottom: 4 }}>Interfaz</div>
        <Toggle
          label="Colores dinámicos"
          description="Acentos basados en la carátula del álbum actual"
          value={settings.dynamicColors}
          onChange={settings.setDynamicColors}
        />
        <Toggle
          label="Modo conducción"
          description="Interfaz simplificada con botones grandes"
          value={settings.drivingMode}
          onChange={settings.setDrivingMode}
        />
      </section>

      <section>
        <div style={{ fontSize: 12, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: 1, marginBottom: 12 }}>Audio</div>
        <button
          type="button"
          onClick={onNavigateEqualizer}
          style={{
            width: '100%', padding: '14px 16px', borderRadius: 'var(--radius-md)',
            background: 'var(--bg-surface)', border: '1px solid var(--border)',
            color: 'var(--text-primary)', fontSize: 14, fontWeight: 600,
            cursor: 'pointer', textAlign: 'left',
          }}
        >
          Ecualizador de 10 bandas →
        </button>
        <div style={{ marginTop: 12, padding: 14, borderRadius: 'var(--radius-md)', background: 'var(--bg-surface)', border: '1px solid var(--border)' }}>
          <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 6 }}>Formatos soportados</div>
          <div style={{ fontSize: 12, color: 'var(--text-secondary)', lineHeight: 1.6 }}>
            MP3, FLAC, ALAC, WAV, AIFF, AAC, M4A, OGG, OPUS, WMA
          </div>
          <div style={{ fontSize: 12, color: 'var(--accent)', marginTop: 8 }}>
            {losslessCount} pistas lossless en tu biblioteca
          </div>
        </div>
      </section>

      <section>
        <div style={{ fontSize: 12, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: 1, marginBottom: 8 }}>Próximamente</div>
        <div style={{ padding: 14, borderRadius: 'var(--radius-md)', background: 'rgba(255,32,32,0.06)', border: '1px solid var(--border-accent)' }}>
          <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 4 }}>Sincronización en la nube</div>
          <div style={{ fontSize: 12, color: 'var(--text-secondary)', lineHeight: 1.5 }}>
            Lectura de bibliotecas desde Google Drive o Dropbox (opcional, en desarrollo).
          </div>
        </div>
      </section>
    </div>
  )
}
