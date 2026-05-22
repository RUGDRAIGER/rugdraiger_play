import { useEffect, useState } from 'react'
import type { ViewName } from './types'
import { useLibraryStore } from './store/libraryStore'
import { usePlaylistStore } from './store/playlistStore'
import { usePlayerStore } from './store/playerStore'
import { Sidebar } from './components/layout/Sidebar'
import { BottomNav } from './components/layout/BottomNav'
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
  const [isMobile, setIsMobile] = useState(window.innerWidth < 768)
  const { loadLibrary } = useLibraryStore()
  const { loadPlaylists } = usePlaylistStore()
  const { currentSong } = usePlayerStore()

  useEffect(() => {
    loadLibrary()
    loadPlaylists()
  }, [])

  useEffect(() => {
    const handler = () => setIsMobile(window.innerWidth < 768)
    window.addEventListener('resize', handler)
    return () => window.removeEventListener('resize', handler)
  }, [])

  function navigate(view: ViewName) {
    setActiveView(view)
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
    <div style={{ display: 'flex', height: '100vh', overflow: 'hidden' }}>
      {/* Desktop sidebar */}
      {!isMobile && (
        <Sidebar activeView={activeView} onNavigate={navigate} />
      )}

      {/* Main content */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden', minWidth: 0 }}>
        <main style={{ flex: 1, display: 'flex', overflow: 'hidden' }} className="fade-in" key={activeView}>
          {view}
        </main>

        {/* Mini player */}
        <MiniPlayer />

        {/* Mobile bottom nav */}
        {isMobile && (
          <BottomNav activeView={activeView} onNavigate={navigate} />
        )}
      </div>

      {/* Full player overlay */}
      {currentSong && <FullPlayer />}
    </div>
  )
}
