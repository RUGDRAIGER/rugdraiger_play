import { useEffect, useState } from 'react'
import type { ViewName } from './types'
import { useLibraryStore } from './store/libraryStore'
import { usePlaylistStore } from './store/playlistStore'
import { usePlayerStore } from './store/playerStore'
import { useSettingsStore } from './store/settingsStore'
import { useIsMobile } from './hooks/useIsMobile'
import { Sidebar } from './components/layout/Sidebar'
import { BottomNav } from './components/layout/BottomNav'
import { MobileNavDrawer } from './components/layout/MobileNavDrawer'
import { MiniPlayer } from './components/player/MiniPlayer'
import { FullPlayer } from './components/player/FullPlayer'
import { DrivingModeView } from './components/player/DrivingModeView'
import { HomeView } from './components/home/HomeView'
import { LibraryView } from './components/library/LibraryView'
import { SongsView } from './components/library/SongsView'
import { AlbumsView } from './components/library/AlbumsView'
import { ArtistsView } from './components/library/ArtistsView'
import { GenresView } from './components/library/GenresView'
import { PlaylistsView } from './components/playlist/PlaylistsView'
import { EqualizerView } from './components/equalizer/EqualizerView'
import { SearchView } from './components/search/SearchView'
import { SettingsView } from './components/settings/SettingsView'
import { SplashScreen } from './components/ui/SplashScreen'
import { mediaSessionService } from './services/mediaSessionService'
import { bindElectronNotchCommands, syncElectronPlayerState } from './services/electronBridgeService'
import { hasDesktopOverlay } from './utils/platform'
import { supportsElectronScan } from './services/electronScannerService'

export default function App() {
  const [activeView, setActiveView] = useState<ViewName>('home')
  const [navTick, setNavTick] = useState(0)
  const [drawerOpen, setDrawerOpen] = useState(false)
  const [bootDone, setBootDone] = useState(false)
  const [bootProgress, setBootProgress] = useState(0)
  const [bootStatus, setBootStatus] = useState('Inicializando...')
  const isMobile = useIsMobile()
  const { loadLibrary } = useLibraryStore()
  const { loadPlaylists } = usePlaylistStore()
  const { currentSong, isPlaying, togglePlay, next, prev, seekTo, progress, duration } = usePlayerStore()
  const drivingMode = useSettingsStore((s) => s.drivingMode)
  const mediaKeysEnabled = useSettingsStore((s) => s.mediaKeysEnabled)

  useEffect(() => {
    let cancelled = false

    async function boot() {
      setBootStatus('Inicializando sistema...')
      setBootProgress(8)
      await delay(120)
      if (cancelled) return

      setBootStatus('Cargando biblioteca...')
      setBootProgress(18)
      await loadLibrary()
      if (cancelled) return
      setBootProgress(42)

      setBootStatus('Cargando playlists...')
      await loadPlaylists()
      if (cancelled) return
      setBootProgress(58)

      if (supportsElectronScan()) {
        const { songs, isScanning } = useLibraryStore.getState()
        if (songs.length === 0 && !isScanning) {
          setBootStatus('Escaneando tu música...')
          setBootProgress(62)

          const unsub = useLibraryStore.subscribe((state) => {
            const p = state.scanProgress
            if (!p || p.total <= 0) return
            const ratio = Math.min(1, p.processed / p.total)
            const scanPct = 62 + ratio * 33
            setBootProgress(Math.round(scanPct))
            if (p.phase === 'discovering') {
              setBootStatus(`Buscando archivos... ${p.processed}/${p.total}`)
            } else {
              setBootStatus(`Procesando: ${p.current || '...'}`)
            }
          })

          try {
            await useLibraryStore.getState().scanFromElectronDefaults()
          } finally {
            unsub()
          }
          if (cancelled) return
        }
      }

      setBootStatus('Sincronizando interfaz...')
      setBootProgress(96)
      await delay(280)
      if (cancelled) return

      setBootProgress(100)
      setBootStatus('Listo')
      await delay(420)
      if (!cancelled) setBootDone(true)
    }

    void boot()
    return () => { cancelled = true }
  }, [])

  useEffect(() => {
    if (!isMobile) setDrawerOpen(false)
  }, [isMobile])

  useEffect(() => {
    if (!mediaKeysEnabled) return
    mediaSessionService.bindHandlers({
      onPlay: () => void togglePlay(),
      onPause: () => void togglePlay(),
      onNext: () => void next(),
      onPrev: () => void prev(),
      onSeek: (time) => seekTo(time),
    })
  }, [mediaKeysEnabled])

  useEffect(() => {
    if (!mediaKeysEnabled || !currentSong) return
    void mediaSessionService.updateMetadata(currentSong, isPlaying)
  }, [currentSong?.id, isPlaying, mediaKeysEnabled])

  useEffect(() => {
    if (!mediaKeysEnabled) return
    mediaSessionService.setPositionState(duration, progress)
  }, [progress, duration, mediaKeysEnabled])

  useEffect(() => {
    if (!hasDesktopOverlay) return
    return bindElectronNotchCommands({
      onPlayPause: () => void togglePlay(),
      onNext: () => void next(),
      onPrev: () => void prev(),
      onFocus: () => {
        usePlayerStore.getState().setFullPlayer(true)
      },
    })
  }, [hasDesktopOverlay])

  useEffect(() => {
    if (!hasDesktopOverlay) return
    void syncElectronPlayerState(currentSong, isPlaying)
  }, [currentSong?.id, currentSong?.title, currentSong?.artist, currentSong?.artwork, isPlaying, hasDesktopOverlay])

  function navigate(view: ViewName) {
    setNavTick((t) => t + 1)
    setActiveView(view)
    setDrawerOpen(false)
  }

  const view = (() => {
    switch (activeView) {
      case 'home':      return <HomeView onNavigate={navigate} />
      case 'library':   return <LibraryView onNavigate={navigate} />
      case 'songs':     return <SongsView key={`songs-${navTick}`} />
      case 'albums':    return <AlbumsView key={`albums-${navTick}`} />
      case 'artists':   return <ArtistsView key={`artists-${navTick}`} />
      case 'genres':    return <GenresView key={`genres-${navTick}`} />
      case 'playlists': return <PlaylistsView key={`playlists-${navTick}`} />
      case 'equalizer': return <EqualizerView />
      case 'search':    return <SearchView />
      case 'settings':  return <SettingsView onNavigateEqualizer={() => navigate('equalizer')} />
      default:          return <HomeView onNavigate={navigate} />
    }
  })()

  return (
    <div className="app-shell">
      <SplashScreen progress={bootProgress} status={bootStatus} visible={!bootDone} />

      {!isMobile && bootDone && (
        <Sidebar activeView={activeView} onNavigate={navigate} />
      )}

      <div className={`app-main${isMobile && currentSong ? ' has-mini-player' : ''}${!bootDone ? ' app-main--booting' : ''}`}>
        <main className={`app-content${bootDone ? ' fade-in' : ''}`} key={activeView}>
          {bootDone ? view : null}
        </main>

        <div className="app-dock">
          {bootDone && <MiniPlayer />}
          {isMobile && bootDone && (
            <BottomNav activeView={activeView} onNavigate={navigate} />
          )}
        </div>
      </div>

      {isMobile && bootDone && (
        <MobileNavDrawer
          open={drawerOpen}
          activeView={activeView}
          onNavigate={navigate}
          onClose={() => setDrawerOpen(false)}
        />
      )}

      {bootDone && currentSong && !drivingMode && <FullPlayer />}
      {bootDone && drivingMode && <DrivingModeView />}
    </div>
  )
}

function delay(ms: number) {
  return new Promise<void>((resolve) => window.setTimeout(resolve, ms))
}
