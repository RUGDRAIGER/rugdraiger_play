import type { CapacitorConfig } from '@capacitor/cli'

const config: CapacitorConfig = {
  appId: 'com.rugdraiger.play',
  appName: 'Rugdraiger Play',
  webDir: 'dist',
  android: {
    allowMixedContent: true,
    backgroundColor: '#0A0A0A',
  },
  server: {
    androidScheme: 'https',
  },
}

export default config
