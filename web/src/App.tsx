import { useEffect, useState } from 'react'
import type { ViewName } from './types'
import { useLibraryStore } from './store/libraryStore'
import { usePlaylistStore } from './store/playlistStore'
import { usePlayerStore } from './store/playerStore'
import { useIsMobile } from './hooks/useIsMobile'
import { Sidebar } from './components/layout/Sidebar'
import { BottomNav } from './components/layout/BottomNav'
import { MobileNavDrawer } from './components/layout/MobileNavDrawer'
import { MiniPlayer } from './components/player/MiniPlayer'
import { FullPlayer } from './components/player/FullPlayer'
import { HomeView } from './components/home/HomeView'
import { LibraryView } from './components/library/LibraryView'
import { SongsView } from './components/library/SongsView'
import { AlbumsView } from './components/library/AlbumsView'
import { ArtistsView } from './components/library/ArtistsView'
import { PlaylistsView } from './components/playlist/PlaylistsView'
import { EqualizerView } from './components/equalizer/EqualizerView'
import { SearchView } from './components/search/SearchView'

export default function App() {
  const [activeView, setActiveView] = useState<ViewName>('home')
  const [drawerOpen, setDrawerOpen] = useState(false)
  const isMobile = useIsMobile()
  const { loadLibrary } = useLibraryStore()
  const { loadPlaylists } = usePlaylistStore()
  const { currentSong } = usePlayerStore()

  useEffect(() => {
    loadLibrary()
    loadPlaylists()
  }, [])

  useEffect(() => {
    if (!isMobile) setDrawerOpen(false)
  }, [isMobile])

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
      case 'playlists': return <PlaylistsView />
      case 'equalizer': return <EqualizerView />
      case 'search':    return <SearchView />
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
            <BottomNav
              activeView={activeView}
              onNavigate={navigate}
              onMenuOpen={() => setDrawerOpen(true)}
            />
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

      {currentSong && <FullPlayer />}
    </div>
  )
}
