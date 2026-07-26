import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { VitePWA } from 'vite-plugin-pwa'

const isCapacitor = process.env.VITE_CAPACITOR === 'true'
const base = process.env.VITE_BASE_PATH ?? (isCapacitor ? './' : '/')

export default defineConfig({
  base,
  plugins: [
    react(),
    ...(isCapacitor ? [] : [VitePWA({
      registerType: 'autoUpdate',
      injectRegister: 'auto',
      includeAssets: ['icons/**/*', 'vendor/**/*'],
      manifestFilename: 'manifest.json',
      manifest: {
        id: base,
        name: 'Rugdraiger Play',
        short_name: 'Rugdraiger',
        description: 'Reproductor de música local con biblioteca, playlists y ecualizador.',
        theme_color: '#0A0A0A',
        background_color: '#0A0A0A',
        display: 'standalone',
        orientation: 'any',
        scope: base,
        start_url: base,
        lang: 'es',
        dir: 'ltr',
        categories: ['music', 'entertainment'],
        icons: [
          {
            src: `${base}icons/icon-192.png`,
            sizes: '192x192',
            type: 'image/png',
            purpose: 'any',
          },
          {
            src: `${base}icons/icon-512.png`,
            sizes: '512x512',
            type: 'image/png',
            purpose: 'any',
          },
          {
            src: `${base}icons/icon-512.png`,
            sizes: '512x512',
            type: 'image/png',
            purpose: 'maskable',
          },
          {
            src: `${base}icons/app-icon.png`,
            sizes: '1024x1024',
            type: 'image/png',
            purpose: 'any',
          },
        ],
        shortcuts: [
          {
            name: 'Abrir biblioteca',
            short_name: 'Biblioteca',
            url: base,
            icons: [{ src: `${base}icons/icon-192.png`, sizes: '192x192', type: 'image/png' }],
          },
        ],
      },
      workbox: {
        globPatterns: ['**/*.{js,css,html,ico,png,svg,webmanifest,json,wasm}'],
        navigateFallback: `${base}index.html`.replace(/\/{2,}/g, '/'),
      },
      devOptions: {
        enabled: true,
      },
    })]),
  ],
  resolve: {
    alias: {
      '@': '/src',
    },
  },
  server: {
    port: 5199,
    strictPort: true,
  },
  preview: {
    port: 5198,
    strictPort: true,
  },
})
