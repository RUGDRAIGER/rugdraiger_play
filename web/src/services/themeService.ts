import { DEFAULT_SKIN_ID, getSkinById, type PlayerSkin } from '../constants/playerSkins'

function hexToRgb(hex: string): { r: number; g: number; b: number } {
  const h = hex.replace('#', '')
  return {
    r: parseInt(h.slice(0, 2), 16),
    g: parseInt(h.slice(2, 4), 16),
    b: parseInt(h.slice(4, 6), 16),
  }
}

function rgbToHex(r: number, g: number, b: number): string {
  const clamp = (n: number) => Math.max(0, Math.min(255, Math.round(n)))
  return `#${[clamp(r), clamp(g), clamp(b)].map((v) => v.toString(16).padStart(2, '0')).join('')}`
}

function mix(hex: string, target: 'black' | 'white', amount: number): string {
  const { r, g, b } = hexToRgb(hex)
  const t = target === 'black' ? 0 : 255
  return rgbToHex(r + (t - r) * amount, g + (t - g) * amount, b + (t - b) * amount)
}

function rgba(hex: string, alpha: number): string {
  const { r, g, b } = hexToRgb(hex)
  return `rgba(${r}, ${g}, ${b}, ${alpha})`
}

export function applyPlayerSkin(skinId: string): PlayerSkin {
  const skin = getSkinById(skinId) ?? getSkinById(DEFAULT_SKIN_ID)!
  const root = document.documentElement
  const accent = skin.accent
  const accentDim = mix(accent, 'black', 0.22)
  const accentBright = mix(accent, 'white', 0.28)
  const accentIntense = mix(accent, 'white', 0.12)

  root.style.setProperty('--accent', accent)
  root.style.setProperty('--accent-dim', accentDim)
  root.style.setProperty('--accent-bright', accentBright)
  root.style.setProperty('--accent-intense', accentIntense)
  root.style.setProperty('--accent-glow', rgba(accent, 0.25))
  root.style.setProperty('--accent-glow-strong', rgba(accent, 0.55))
  root.style.setProperty('--border-accent', rgba(accent, 0.4))

  const softLevels: Record<string, number> = {
    '06': 0.06,
    '08': 0.08,
    '10': 0.10,
    '12': 0.12,
    '15': 0.15,
    '18': 0.18,
    '20': 0.20,
    '35': 0.35,
    '40': 0.40,
    '45': 0.45,
    '55': 0.55,
    '65': 0.65,
    '75': 0.75,
    '80': 0.80,
  }

  for (const [suffix, alpha] of Object.entries(softLevels)) {
    root.style.setProperty(`--accent-soft-${suffix}`, rgba(accent, alpha))
  }

  root.style.setProperty('--accent-gradient', `linear-gradient(90deg, ${accentDim}, ${accent}, ${accentBright})`)
  root.style.setProperty('--accent-progress', `linear-gradient(90deg, ${rgba(accent, 0.2)}, ${rgba(accent, 0.07)})`)
  root.style.setProperty('--accent-nav-active', rgba(accent, 0.12))
  root.style.setProperty('--accent-shadow', rgba(accent, 0.4))
  root.style.setProperty('--accent-shadow-strong', rgba(accent, 0.45))

  return skin
}

export function getAccentForSkin(skinId: string): string {
  return getSkinById(skinId)?.accent ?? getSkinById(DEFAULT_SKIN_ID)!.accent
}

export function initPlayerSkin(skinId: string) {
  applyPlayerSkin(skinId)
}
