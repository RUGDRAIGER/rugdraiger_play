import { useRef } from 'react'

interface SwipeHandlers {
  onSwipeLeft?: () => void
  onSwipeRight?: () => void
  onTap?: () => void
}

export function useSwipeGestures({ onSwipeLeft, onSwipeRight, onTap }: SwipeHandlers) {
  const startX = useRef(0)
  const startY = useRef(0)
  const startTime = useRef(0)

  return {
    onTouchStart: (e: React.TouchEvent) => {
      startX.current = e.touches[0].clientX
      startY.current = e.touches[0].clientY
      startTime.current = Date.now()
    },
    onTouchEnd: (e: React.TouchEvent) => {
      const dx = e.changedTouches[0].clientX - startX.current
      const dy = e.changedTouches[0].clientY - startY.current
      const elapsed = Date.now() - startTime.current

      if (Math.abs(dx) < 40 && Math.abs(dy) < 40 && elapsed < 300) {
        onTap?.()
        return
      }
      if (Math.abs(dx) < Math.abs(dy)) return
      if (dx > 60) onSwipeRight?.()
      else if (dx < -60) onSwipeLeft?.()
    },
  }
}
