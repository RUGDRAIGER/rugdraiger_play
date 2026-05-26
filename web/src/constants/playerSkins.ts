export interface PlayerSkin {
  id: string
  name: string
  accent: string
  group: 'cálidos' | 'fríos' | 'naturales' | 'neutros'
}

export const DEFAULT_SKIN_ID = 'rojo'

export const PLAYER_SKINS: PlayerSkin[] = [
  { id: 'rojo', name: 'Rojo', accent: '#FF2020', group: 'cálidos' },
  { id: 'carmesi', name: 'Carmesí', accent: '#E8194A', group: 'cálidos' },
  { id: 'rosa', name: 'Rosa', accent: '#FF4081', group: 'cálidos' },
  { id: 'salmon', name: 'Salmón', accent: '#FF6B6B', group: 'cálidos' },
  { id: 'coral', name: 'Coral', accent: '#FF5722', group: 'cálidos' },
  { id: 'naranja', name: 'Naranja', accent: '#FF9800', group: 'cálidos' },
  { id: 'ambar', name: 'Ámbar', accent: '#FFC107', group: 'cálidos' },
  { id: 'magenta', name: 'Magenta', accent: '#E040FB', group: 'fríos' },
  { id: 'purpura', name: 'Púrpura', accent: '#9C27B0', group: 'fríos' },
  { id: 'violeta', name: 'Violeta', accent: '#7C4DFF', group: 'fríos' },
  { id: 'indigo', name: 'Índigo', accent: '#3F51B5', group: 'fríos' },
  { id: 'azul', name: 'Azul', accent: '#2196F3', group: 'fríos' },
  { id: 'cielo', name: 'Cielo', accent: '#03A9F4', group: 'fríos' },
  { id: 'cian', name: 'Cian', accent: '#00BCD4', group: 'fríos' },
  { id: 'turquesa', name: 'Turquesa', accent: '#009688', group: 'naturales' },
  { id: 'esmeralda', name: 'Esmeralda', accent: '#00C853', group: 'naturales' },
  { id: 'verde', name: 'Verde', accent: '#4CAF50', group: 'naturales' },
  { id: 'lima', name: 'Lima', accent: '#AEEA00', group: 'naturales' },
  { id: 'menta', name: 'Menta', accent: '#1DE9B6', group: 'naturales' },
  { id: 'lavanda', name: 'Lavanda', accent: '#B388FF', group: 'neutros' },
]

export function getSkinById(id: string): PlayerSkin | undefined {
  return PLAYER_SKINS.find((s) => s.id === id)
}

export const SKIN_GROUPS: { key: PlayerSkin['group']; label: string }[] = [
  { key: 'cálidos', label: 'Cálidos' },
  { key: 'fríos', label: 'Fríos' },
  { key: 'naturales', label: 'Naturales' },
  { key: 'neutros', label: 'Neutros' },
]
