import { useEQStore } from '../../store/eqStore'
import { useSettingsStore } from '../../store/settingsStore'
import { useState } from 'react'
import type { EQBand } from '../../types'

// Altura fija del área deslizable en píxeles
const SLIDER_H = 160

interface EQBandsProps {
  bands: EQBand[]
  enabled: boolean
  setBandGain: (index: number, gain: number) => void
}

function EQBands({ bands, enabled, setBandGain }: EQBandsProps) {
  /*
   * El range input se rota -90deg para hacerlo vertical.
   * Antes de la rotación:
   *   CSS width  = SLIDER_H  (se convierte en la longitud visual del track)
   *   CSS height = TRACK_W   (se convierte en el ancho visual del track — pequeño)
   * Para centrarlo en un contenedor de TRACK_W × SLIDER_H px:
   *   left = (TRACK_W - SLIDER_H) / 2
   *   top  = (SLIDER_H - TRACK_W) / 2
   */
  const TRACK_W = 32  // ancho visual del slider (contenedor)
  const inputLeft = (TRACK_W - SLIDER_H) / 2
  const inputTop  = (SLIDER_H - TRACK_W) / 2

  return (
    <div style={{
      background: 'var(--bg-surface)',
      borderRadius: 'var(--radius-lg)',
      padding: '20px 12px 16px',
      border: '1px solid var(--border)',
    }}>
      <div style={{ display: 'flex', alignItems: 'flex-start' }}>
        {bands.map((band, i) => {
          const fillH = Math.abs(band.gain / 12) * (SLIDER_H / 2)

          return (
            <div
              key={band.frequency}
              style={{
                flex: 1,
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: 6,
              }}
            >
              {/* Gain value */}
              <span style={{
                fontSize: 10, fontWeight: 700,
                height: 14, lineHeight: '14px',
                color: enabled
                  ? band.gain === 0 ? 'var(--text-secondary)' : '#FF2020'
                  : 'var(--text-tertiary)',
              }}>
                {band.gain > 0 ? `+${band.gain.toFixed(0)}` : band.gain.toFixed(0)}
              </span>

              {/* Slider container — tamaño fijo, sin overflow */}
              <div style={{
                width: TRACK_W,
                height: SLIDER_H,
                position: 'relative',
                flexShrink: 0,
              }}>
                {/* Rail background */}
                <div style={{
                  position: 'absolute',
                  left: (TRACK_W - 5) / 2, top: 0,
                  width: 5, height: SLIDER_H,
                  borderRadius: 3,
                  background: 'var(--bg-surface2)',
                  border: '1px solid var(--bg-surface3)',
                }} />

                {/* Center 0 dB tick */}
                <div style={{
                  position: 'absolute',
                  top: SLIDER_H / 2 - 0.5,
                  left: (TRACK_W - 12) / 2,
                  width: 12, height: 1,
                  background: 'rgba(255,255,255,0.20)',
                  pointerEvents: 'none',
                }} />

                {/* Level fill — rojo suave */}
                <div style={{
                  position: 'absolute',
                  left: (TRACK_W - 5) / 2,
                  width: 5,
                  borderRadius: 2,
                  background: enabled ? 'rgba(255, 32, 32, 0.40)' : 'rgba(130,130,130,0.2)',
                  top:    band.gain >= 0 ? SLIDER_H / 2 - fillH : SLIDER_H / 2,
                  height: Math.max(fillH, 0),
                  transition: 'height 0.08s, top 0.08s',
                  pointerEvents: 'none',
                }} />

                {/* Range input rotado — fader rectangular via CSS */}
                <input
                  type="range"
                  className="eq-band"
                  min={-12}
                  max={12}
                  step={0.5}
                  value={band.gain}
                  disabled={!enabled}
                  onChange={(e) => setBandGain(i, Number(e.target.value))}
                  style={{
                    position: 'absolute',
                    width: SLIDER_H,
                    height: TRACK_W,
                    top: inputTop,
                    left: inputLeft,
                    transform: 'rotate(-90deg)',
                    transformOrigin: 'center center',
                    margin: 0, padding: 0,
                  }}
                />
              </div>

              {/* Frequency label */}
              <span style={{
                fontSize: 9, color: 'var(--text-secondary)',
                whiteSpace: 'nowrap', letterSpacing: 0.3,
              }}>
                {band.label}
              </span>
            </div>
          )
        })}
      </div>

      {/* Scale labels */}
      <div style={{
        display: 'flex', justifyContent: 'space-between',
        marginTop: 12, paddingTop: 10,
        borderTop: '1px solid var(--border)',
        fontSize: 10, color: 'var(--text-tertiary)',
      }}>
        <span>+12 dB</span>
        <span style={{ color: 'var(--text-secondary)' }}>0 dB</span>
        <span>-12 dB</span>
      </div>
    </div>
  )
}

export function EqualizerView() {
  const { bands, enabled, activePreset, savedProfiles, setEnabled, setBandGain, applyPreset, getPresetNames, saveCurrentAsProfile, deleteProfile, applyProfile } = useEQStore()
  const directAudioMode = useSettingsStore((s) => s.directAudioMode)
  const presets = getPresetNames()
  const [profileName, setProfileName] = useState('')

  return (
    <div className="scrollable" style={{ flex: 1, padding: '24px 28px', display: 'flex', flexDirection: 'column', gap: 24 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h1 style={{ fontSize: 22, fontWeight: 700 }}>Ecualizador</h1>
        <label style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer' }}>
          <span style={{ fontSize: 14, color: 'var(--text-secondary)' }}>Activar</span>
          <div
            onClick={() => setEnabled(!enabled)}
            style={{
              width: 44, height: 24, borderRadius: 12,
              background: enabled ? 'var(--accent)' : 'var(--bg-surface3)',
              position: 'relative', cursor: 'pointer', transition: 'background 0.2s',
            }}
          >
            <div style={{
              position: 'absolute', width: 18, height: 18, borderRadius: '50%',
              background: '#fff', top: 3,
              left: enabled ? 23 : 3, transition: 'left 0.2s',
            }} />
          </div>
        </label>
      </div>

      {directAudioMode && (
        <div style={{ padding: 12, borderRadius: 'var(--radius-md)', background: 'rgba(255,32,32,0.08)', border: '1px solid var(--border-accent)', fontSize: 13, color: 'var(--text-secondary)', lineHeight: 1.5 }}>
          El modo <strong style={{ color: 'var(--text-primary)' }}>Audio directo</strong> está activo en Ajustes. El ecualizador está en bypass para máxima fidelidad. Desactívalo en Ajustes si quieres usar EQ.
        </div>
      )}

      {/* Presets */}
      <div>
        <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginBottom: 10, textTransform: 'uppercase', letterSpacing: 1 }}>Presets</div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
          {presets.map((name) => (
            <button
              key={name}
              onClick={() => applyPreset(name)}
              disabled={!enabled}
              style={{
                padding: '7px 14px', borderRadius: 20,
                background: activePreset === name ? 'var(--accent)' : 'var(--bg-surface)',
                color: activePreset === name ? '#fff' : 'var(--text-secondary)',
                border: `1px solid ${activePreset === name ? 'var(--accent)' : 'var(--border)'}`,
                fontSize: 13, cursor: enabled ? 'pointer' : 'not-allowed',
                opacity: enabled ? 1 : 0.4,
                fontWeight: activePreset === name ? 600 : 400,
                transition: 'all 0.15s',
              }}
            >
              {name}
            </button>
          ))}
        </div>
      </div>

      {savedProfiles.length > 0 && (
        <div>
          <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginBottom: 10, textTransform: 'uppercase', letterSpacing: 1 }}>Perfiles guardados</div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
            {savedProfiles.map((profile) => (
              <div key={profile.id} style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                <button type="button" onClick={() => applyProfile(profile)} disabled={!enabled}
                  style={{
                    padding: '7px 14px', borderRadius: 20,
                    background: activePreset === profile.name ? 'var(--accent)' : 'var(--bg-surface)',
                    color: activePreset === profile.name ? '#fff' : 'var(--text-secondary)',
                    border: `1px solid ${activePreset === profile.name ? 'var(--accent)' : 'var(--border)'}`,
                    fontSize: 13, cursor: enabled ? 'pointer' : 'not-allowed',
                  }}>
                  {profile.name}
                </button>
                <button type="button" onClick={() => deleteProfile(profile.id)} style={{ color: 'var(--text-tertiary)', fontSize: 16, cursor: 'pointer', padding: '0 4px' }}>×</button>
              </div>
            ))}
          </div>
        </div>
      )}

      <div style={{ display: 'flex', gap: 8 }}>
        <input type="text" placeholder="Nombre del perfil..." value={profileName} onChange={(e) => setProfileName(e.target.value)}
          style={{ flex: 1, padding: '9px 12px', borderRadius: 'var(--radius-md)', background: 'var(--bg-surface)', border: '1px solid var(--border)', color: 'var(--text-primary)', fontSize: 13 }} />
        <button type="button" onClick={() => { saveCurrentAsProfile(profileName); setProfileName('') }} disabled={!enabled || !profileName.trim()}
          style={{ padding: '9px 16px', borderRadius: 'var(--radius-md)', background: 'var(--accent)', color: '#fff', fontSize: 13, fontWeight: 600, cursor: 'pointer', opacity: !profileName.trim() ? 0.5 : 1 }}>
          Guardar perfil
        </button>
      </div>

      {/* EQ Bands */}
      <EQBands bands={bands} enabled={enabled} setBandGain={setBandGain} />

      {/* Reset */}
      <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
        <button
          onClick={() => applyPreset('Flat')}
          disabled={!enabled}
          style={{
            padding: '9px 18px', borderRadius: 'var(--radius-md)',
            background: 'var(--bg-surface)', border: '1px solid var(--border)',
            color: 'var(--text-secondary)', fontSize: 13, cursor: enabled ? 'pointer' : 'not-allowed',
            opacity: enabled ? 1 : 0.4,
          }}
        >
          Restablecer
        </button>
      </div>
    </div>
  )
}
