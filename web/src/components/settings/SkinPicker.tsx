import { PLAYER_SKINS, SKIN_GROUPS } from '../../constants/playerSkins'
import { useSettingsStore } from '../../store/settingsStore'

export function SkinPicker() {
  const skinId = useSettingsStore((s) => s.skinId)
  const setSkinId = useSettingsStore((s) => s.setSkinId)

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
      {SKIN_GROUPS.map(({ key, label }) => {
        const skins = PLAYER_SKINS.filter((s) => s.group === key)
        if (skins.length === 0) return null

        return (
          <div key={key}>
            <div style={{
              fontSize: 11,
              color: 'var(--text-tertiary)',
              textTransform: 'uppercase',
              letterSpacing: 0.8,
              marginBottom: 10,
            }}>
              {label}
            </div>
            <div style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fill, minmax(72px, 1fr))',
              gap: 10,
            }}>
              {skins.map((skin) => {
                const selected = skinId === skin.id
                return (
                  <button
                    key={skin.id}
                    type="button"
                    onClick={() => setSkinId(skin.id)}
                    title={skin.name}
                    aria-pressed={selected}
                    style={{
                      display: 'flex',
                      flexDirection: 'column',
                      alignItems: 'center',
                      gap: 6,
                      padding: '10px 6px',
                      borderRadius: 'var(--radius-md)',
                      border: selected ? `2px solid ${skin.accent}` : '1px solid var(--border)',
                      background: selected ? 'var(--accent-soft-10)' : 'var(--bg-surface)',
                      cursor: 'pointer',
                      transition: 'border-color 0.15s, background 0.15s, transform 0.12s',
                      boxShadow: selected ? `0 0 14px ${skin.accent}55` : 'none',
                    }}
                  >
                    <span
                      style={{
                        width: 36,
                        height: 36,
                        borderRadius: '50%',
                        background: skin.accent,
                        boxShadow: `0 4px 12px ${skin.accent}66`,
                        border: '2px solid rgba(255,255,255,0.15)',
                        flexShrink: 0,
                      }}
                    />
                    <span style={{
                      fontSize: 11,
                      fontWeight: selected ? 700 : 500,
                      color: selected ? skin.accent : 'var(--text-secondary)',
                      textAlign: 'center',
                      lineHeight: 1.2,
                    }}>
                      {skin.name}
                    </span>
                  </button>
                )
              })}
            </div>
          </div>
        )
      })}
    </div>
  )
}
