import { Capacitor } from '@capacitor/core'

export const isNativeApp = Capacitor.isNativePlatform()

export const isElectronDesktop =
  typeof window !== 'undefined' &&
  window.electronAPI?.isDesktop === true

export const isMacDesktop =
  isElectronDesktop && window.electronAPI?.platform === 'darwin'

/** Ocultar enlaces de descarga dentro de apps nativas o de escritorio empaquetadas */
export const showDownloadButtons = !isNativeApp && !isElectronDesktop
