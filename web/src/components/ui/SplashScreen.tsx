import { useEffect, useRef } from 'react'
import { AppIcon } from './AppIcon'
import { APP_NAME } from '../../constants/appBranding'

interface Props {
  progress: number
  status: string
  visible: boolean
}

interface Particle {
  x: number
  y: number
  vx: number
  vy: number
  size: number
  alpha: number
  hue: number
}

export function SplashScreen({ progress, status, visible }: Props) {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const displayPct = Math.round(Math.min(100, Math.max(0, progress)))

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas || !visible) return

    const ctx = canvas.getContext('2d')
    if (!ctx) return

    let raf = 0
    let w = 0
    let h = 0
    const particles: Particle[] = []
    const count = 48

    function resize() {
      const dpr = Math.min(window.devicePixelRatio || 1, 2)
      w = canvas!.clientWidth
      h = canvas!.clientHeight
      canvas!.width = w * dpr
      canvas!.height = h * dpr
      ctx!.setTransform(dpr, 0, 0, dpr, 0, 0)
    }

    function seed() {
      particles.length = 0
      for (let i = 0; i < count; i++) {
        particles.push({
          x: Math.random() * w,
          y: Math.random() * h,
          vx: (Math.random() - 0.5) * 0.35,
          vy: (Math.random() - 0.5) * 0.35,
          size: Math.random() * 2.2 + 0.6,
          alpha: Math.random() * 0.55 + 0.2,
          hue: Math.random() > 0.7 ? 190 : 0,
        })
      }
    }

    function draw() {
      ctx!.clearRect(0, 0, w, h)
      const cx = w / 2
      const cy = h / 2 - 20
      const breath = 0.5 + 0.5 * Math.sin(Date.now() / 1200)

      for (const p of particles) {
        p.x += p.vx
        p.y += p.vy
        const dx = p.x - cx
        const dy = p.y - cy
        const dist = Math.hypot(dx, dy)
        const pull = dist > 1 ? (120 * breath) / dist : 0
        p.vx += (dx / dist) * pull * 0.002
        p.vy += (dy / dist) * pull * 0.002
        p.vx *= 0.985
        p.vy *= 0.985

        if (p.x < 0) p.x = w
        if (p.x > w) p.x = 0
        if (p.y < 0) p.y = h
        if (p.y > h) p.y = 0

        const color = p.hue === 190
          ? `rgba(0, 255, 255, ${p.alpha * breath})`
          : `rgba(255, 32, 32, ${p.alpha * breath})`
        ctx!.beginPath()
        ctx!.fillStyle = color
        ctx!.arc(p.x, p.y, p.size, 0, Math.PI * 2)
        ctx!.fill()
      }

      raf = requestAnimationFrame(draw)
    }

    resize()
    seed()
    draw()
    window.addEventListener('resize', () => { resize(); seed() })

    return () => {
      cancelAnimationFrame(raf)
      window.removeEventListener('resize', resize)
    }
  }, [visible])

  if (!visible) return null

  return (
    <div className="splash-screen" aria-live="polite" aria-busy="true">
      <div className="splash-grid" />
      <div className="splash-scanlines" />

      <canvas ref={canvasRef} className="splash-particles" aria-hidden />

      <div className="splash-content">
        <div className="splash-logo-wrap">
          <div className="splash-logo-glow" />
          <div className="splash-logo-breathe">
            <AppIcon size={112} borderRadius={24} />
          </div>
        </div>
        <h1 className="splash-title">{APP_NAME}</h1>
        <p className="splash-status">{status}</p>
      </div>

      <div className="splash-progress-wrap">
        <div className="splash-progress-label">
          <span>SISTEMA</span>
          <span className="splash-progress-pct">{displayPct.toString().padStart(3, '0')}%</span>
        </div>
        <div className="splash-progress-track">
          <div
            className="splash-progress-fill"
            style={{ width: `${displayPct}%` }}
          />
          <div
            className="splash-progress-glow"
            style={{ left: `${displayPct}%` }}
          />
        </div>
        <div className="splash-progress-ticks" aria-hidden>
          {Array.from({ length: 20 }).map((_, i) => (
            <span key={i} className={i * 5 <= displayPct ? 'active' : ''} />
          ))}
        </div>
      </div>
    </div>
  )
}
