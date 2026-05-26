import { APK_DOWNLOAD_URL, MACOS_DOWNLOAD_URL, WINDOWS_DOWNLOAD_URL } from '../../constants/appBranding'

function WindowsIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M3 5.5L10.5 4v7.5H3V5.5zm10.5 0L21 4v7.5h-7.5V5.5zM3 13.5h7.5V21L3 19.5v-6zm10.5 0H21V19.5L13.5 21v-7.5z" />
    </svg>
  )
}

function AppleIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
    </svg>
  )
}

function AndroidIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M17.18 9.37H6.82A1.82 1.82 0 0 0 5 11.19v6.37a1.82 1.82 0 0 0 1.82 1.82h10.36A1.82 1.82 0 0 0 19 17.56V11.2a1.82 1.82 0 0 0-1.82-1.83zM8.5 18.5a1 1 0 1 1 0-2 1 1 0 0 1 0 2zm7 0a1 1 0 1 1 0-2 1 1 0 0 1 0 2zM7.5 8.5l-1.5-2.6a.75.75 0 1 1 1.3-.76L8.7 8.5h6.6l1.4-2.36a.75.75 0 0 1 1.3.76L16.5 8.5h.68A3.32 3.32 0 0 1 20.5 11.82v.68h-17v-.68A3.32 3.32 0 0 1 6.82 8.5H7.5z" />
    </svg>
  )
}

export function DownloadAppButtons() {
  return (
    <div className="home-downloads">
      <a
        href={MACOS_DOWNLOAD_URL}
        download="RugdraigerPlay-macOS.zip"
        className="home-download-link"
        title="Descargar Rugdraiger Play para macOS"
      >
        <span className="home-download-icon">
          <AppleIcon />
        </span>
        <span className="home-download-text">
          <span className="home-download-label">macOS</span>
          <span className="home-download-hint">Descargar app</span>
        </span>
      </a>
      <a
        href={WINDOWS_DOWNLOAD_URL}
        download="RugdraigerPlay-Windows.zip"
        className="home-download-link"
        title="Descargar Rugdraiger Play para escritorio Windows"
      >
        <span className="home-download-icon">
          <WindowsIcon />
        </span>
        <span className="home-download-text">
          <span className="home-download-label">Escritorio Windows</span>
          <span className="home-download-hint">Descargar app</span>
        </span>
      </a>
      <a
        href={APK_DOWNLOAD_URL}
        download="rugdraiger-play.apk"
        className="home-download-link"
        title="Descargar Rugdraiger Play para dispositivos móviles Android"
      >
        <span className="home-download-icon">
          <AndroidIcon />
        </span>
        <span className="home-download-text">
          <span className="home-download-label">Android móvil</span>
          <span className="home-download-hint">Descargar app</span>
        </span>
      </a>
    </div>
  )
}
