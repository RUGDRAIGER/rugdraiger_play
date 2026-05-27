import { SKIN_GROUPS, getSkinsForGroup } from '../../constants/playerSkins'
import { useSettingsStore } from '../../store/settingsStore'

export function SkinPicker() {
  const skinId = useSettingsStore((s) => s.skinId)
  const setSkinId = useSettingsStore((s) => s.setSkinId)

  return (
    <div className="skin-picker">
      {SKIN_GROUPS.map(({ key, label, hint }) => {
        const skins = getSkinsForGroup(key)
        if (skins.length === 0) return null
        const sampleAccent = skins[Math.floor(skins.length / 2)]?.accent ?? skins[0].accent

        return (
          <section key={key} className="skin-picker-group">
            <header className="skin-picker-group-header" style={{ borderLeftColor: sampleAccent }}>
              <div>
                <div className="skin-picker-group-title">{label}</div>
                <div className="skin-picker-group-hint">{hint}</div>
              </div>
              <span className="skin-picker-group-count">{skins.length}</span>
            </header>
            <div className="skin-picker-grid">
              {skins.map((skin) => {
                const selected = skinId === skin.id
                return (
                  <button
                    key={skin.id}
                    type="button"
                    className={`skin-picker-swatch${selected ? ' skin-picker-swatch--selected' : ''}`}
                    onClick={() => setSkinId(skin.id)}
                    title={skin.name}
                    aria-pressed={selected}
                    style={{
                      ['--swatch-color' as string]: skin.accent,
                    }}
                  >
                    <span className="skin-picker-swatch-dot" />
                    <span className="skin-picker-swatch-name">{skin.name}</span>
                  </button>
                )
              })}
            </div>
          </section>
        )
      })}
    </div>
  )
}
