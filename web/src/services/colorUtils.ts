export interface DominantColor {
  r: number
  g: number
  b: number
  hex: string
}

export async function extractDominantColor(imageUrl: string): Promise<DominantColor | null> {
  return new Promise((resolve) => {
    const img = new Image()
    img.crossOrigin = 'anonymous'
    img.onload = () => {
      try {
        const canvas = document.createElement('canvas')
        const size = 32
        canvas.width = size
        canvas.height = size
        const ctx = canvas.getContext('2d')
        if (!ctx) { resolve(null); return }
        ctx.drawImage(img, 0, 0, size, size)
        const data = ctx.getImageData(0, 0, size, size).data
        let r = 0, g = 0, b = 0, count = 0
        for (let i = 0; i < data.length; i += 4) {
          const alpha = data[i + 3]
          if (alpha < 128) continue
          const pr = data[i], pg = data[i + 1], pb = data[i + 2]
          const brightness = (pr + pg + pb) / 3
          if (brightness < 20 || brightness > 235) continue
          r += pr; g += pg; b += pb; count++
        }
        if (!count) { resolve(null); return }
        r = Math.round(r / count)
        g = Math.round(g / count)
        b = Math.round(b / count)
        const hex = `#${[r, g, b].map((v) => v.toString(16).padStart(2, '0')).join('')}`
        resolve({ r, g, b, hex })
      } catch {
        resolve(null)
      }
    }
    img.onerror = () => resolve(null)
    img.src = imageUrl
  })
}

export function applyDynamicAccent(color: DominantColor | null) {
  const root = document.documentElement
  if (!color) {
    root.style.removeProperty('--dynamic-accent')
    root.style.removeProperty('--dynamic-glow')
    return
  }
  root.style.setProperty('--dynamic-accent', color.hex)
  root.style.setProperty('--dynamic-glow', `rgba(${color.r}, ${color.g}, ${color.b}, 0.35)`)
}
