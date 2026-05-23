import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { Capacitor } from '@capacitor/core'
import { StatusBar, Style } from '@capacitor/status-bar'
import './styles/globals.css'
import App from './App'

if (Capacitor.isNativePlatform()) {
  void StatusBar.setStyle({ style: Style.Dark })
  void StatusBar.setBackgroundColor({ color: '#0A0A0A' })
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
