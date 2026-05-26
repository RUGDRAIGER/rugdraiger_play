export const APP_NAME = 'Rugdraiger Play'

const base = import.meta.env.BASE_URL

export const APK_DOWNLOAD_URL = `${base}apk/rugdraiger-play.apk`

/** ZIP ~157 MB en LFS; GitHub Pages sirve el puntero, no el binario. */
export const WINDOWS_DOWNLOAD_URL =
  'https://github.com/RUGDRAIGER/rugdraiger_play/raw/gh-pages/windows/RugdraigerPlay-Windows.zip'

/** ZIP ~289 MB en LFS; GitHub Pages sirve el puntero, no el binario. */
export const MACOS_DOWNLOAD_URL =
  'https://github.com/RUGDRAIGER/rugdraiger_play/raw/gh-pages/macos/RugdraigerPlay-macOS.zip'

export const APP_ICONS = {
  /** Icono principal (1024×1024) */
  app: `${base}icons/app-icon.png`,
  /** PWA / tiendas — 512×512 */
  pwa512: `${base}icons/icon-512.png`,
  /** PWA — 192×192 */
  pwa192: `${base}icons/icon-192.png`,
  /** Favicon pestaña */
  favicon32: `${base}icons/favicon-32.png`,
  /** iOS / Add to Home Screen */
  appleTouch: `${base}icons/apple-touch-icon.png`,
} as const
