import { APK_DOWNLOAD_URL, WINDOWS_DOWNLOAD_URL } from '../../constants/appBranding'

function WindowsIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M3 5.5L10.5 4v7.5H3V5.5zm10.5 0L21 4v7.5h-7.5V5.5zM3 13.5h7.5V21L3 19.5v-6zm10.5 0H21V19.5L13.5 21v-7.5z" />
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
