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
import { mediaSessionService } from './services/mediaSessionService'

export default function App() {
  const [activeView, setActiveView] = useState<ViewName>('home')
  const [drawerOpen, setDrawerOpen] = useState(false)
  const isMobile = useIsMobile()
  const { loadLibrary } = useLibraryStore()
  const { loadPlaylists } = usePlaylistStore()
  const { currentSong, isPlaying, togglePlay, next, prev, seekTo, progress, duration } = usePlayerStore()
  const drivingMode = useSettingsStore((s) => s.drivingMode)
  const mediaKeysEnabled = useSettingsStore((s) => s.mediaKeysEnabled)

  useEffect(() => {
    loadLibrary()
    loadPlaylists()
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

  function navigate(view: ViewName) {
    setActiveView(view)
    setDrawerOpen(false)
  }

  const view = (() => {
    switch (activeView) {
      case 'home':      return <HomeView onNavigate={navigate} />
      case 'library':   return <LibraryView onNavigate={navigate} />
      case 'songs':     return <SongsView />
      case 'albums':    return <AlbumsView />
      case 'artists':   return <ArtistsView />
      case 'genres':    return <GenresView />
      case 'playlists': return <PlaylistsView />
      case 'equalizer': return <EqualizerView />
      case 'search':    return <SearchView />
      case 'settings':  return <SettingsView onNavigateEqualizer={() => navigate('equalizer')} />
      default:          return <HomeView onNavigate={navigate} />
    }
  })()

  return (
    <div className="app-shell">
      {!isMobile && (
        <Sidebar activeView={activeView} onNavigate={navigate} />
      )}

      <div className={`app-main${isMobile && currentSong ? ' has-mini-player' : ''}`}>
        <main className="app-content fade-in" key={activeView}>
          {view}
        </main>

        <div className="app-dock">
          <MiniPlayer />
          {isMobile && (
            <BottomNav activeView={activeView} onNavigate={navigate} />
          )}
        </div>
      </div>

      {isMobile && (
        <MobileNavDrawer
          open={drawerOpen}
          activeView={activeView}
          onNavigate={navigate}
          onClose={() => setDrawerOpen(false)}
        />
      )}

      {currentSong && !drivingMode && <FullPlayer />}
      {drivingMode && <DrivingModeView />}
    </div>
  )
}
