import { Capacitor } from '@capacitor/core'

export const isNativeApp = Capacitor.isNativePlatform()

export const isElectronDesktop =
  typeof window !== 'undefined' &&
  window.electronAPI?.isDesktop === true

export const isMacDesktop =
  isElectronDesktop && window.electronAPI?.platform === 'darwin'

export const isWindowsDesktop =
  isElectronDesktop && window.electronAPI?.platform === 'win32'

/** Mini reproductor flotante (notch Mac / barra superior Windows) */
export const hasDesktopOverlay = isMacDesktop || isWindowsDesktop

/** Ocultar enlaces de descarga dentro de apps nativas o de escritorio empaquetadas */
export const showDownloadButtons = !isNativeApp && !isElectronDesktop
