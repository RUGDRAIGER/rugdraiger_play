# Rugdraiger Player — Instrucciones de Compilación

## Requisitos previos

### Para Android (APK)
1. Instala **Android Studio** desde: https://developer.android.com/studio
2. Al abrirlo por primera vez instala el Android SDK (API 34 recomendada).
3. Ejecuta: `flutter config --android-sdk ~/Library/Android/sdk`
4. Verifica con: `flutter doctor`

### Para iOS (IPA)
1. Instala **Xcode** completo desde App Store.
2. Ejecuta: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
3. Ejecuta: `sudo xcodebuild -runFirstLaunch`
4. Instala CocoaPods: `sudo gem install cocoapods`
5. Instala pods: `cd ios && pod install`

---

## Compilar APK (Android)

```bash
cd rugdraiger_player

# Debug (para pruebas rápidas)
flutter build apk --debug

# Release (distribución final)
flutter build apk --release

# Split por arquitectura (APK más pequeño)
flutter build apk --release --split-per-abi
```

Los archivos se generan en:
- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (ARM 64-bit)
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (ARM 32-bit)

---

## Compilar IPA (iOS)

```bash
cd rugdraiger_player

# Instalar pods primero
cd ios && pod install && cd ..

# Build de release
flutter build ipa --release
```

O desde Xcode:
1. Abre `ios/Runner.xcworkspace` en Xcode.
2. Ve a **Signing & Capabilities** → selecciona tu Apple ID.
3. Cambia el Bundle ID si es necesario (ej: `com.tuapple.rugdraiger`).
4. Menú **Product → Archive**.
5. En **Organizer**, selecciona **Distribute App**.

---

## Instalar en dispositivo Android sin Play Store

```bash
# Conecta el cable USB y activa "Depuración USB" en tu Android
flutter install
# O instala el APK directamente
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Instalar en iPhone sin App Store (desarrollo personal)

1. Conecta el iPhone a tu Mac.
2. En Xcode: menú **Product → Run** (selecciona tu iPhone como destino).
3. Confía en el certificado en: **Ajustes → General → VPN y gestión de dispositivos**.

---

## Estructura del Proyecto

```
lib/
├── core/
│   ├── constants/     # Formatos, constantes, enums
│   ├── extensions/    # String extensions
│   ├── theme/         # AppTheme (Negro Carbón / Rojo Neón)
│   └── utils/         # DurationFormatter
├── data/
│   ├── models/        # SongModel, PlaylistModel
│   ├── repositories/  # MusicRepository (scan + CRUD)
│   └── sources/       # DatabaseHelper (SQLite)
├── presentation/
│   ├── bloc/
│   │   ├── library/   # LibraryBloc (gestión biblioteca)
│   │   └── player/    # PlayerBloc (estado del reproductor)
│   ├── screens/
│   │   ├── home/      # HomeScreen + MainScaffold
│   │   ├── player/    # PlayerScreen (fullscreen)
│   │   ├── library/   # LibraryScreen (Songs/Albums/Artists/Playlists)
│   │   ├── equalizer/ # EqualizerScreen (10 bandas)
│   │   ├── search/    # SearchScreen
│   │   └── user/      # UserScreen (perfil + favoritos)
│   └── widgets/       # AlbumCard, MiniPlayer, ArtworkWidget, etc.
└── services/
    ├── audio_service.dart      # Motor de audio (just_audio)
    └── equalizer_service.dart  # EQ 10 bandas + bass boost
```

---

## Funcionalidades Implementadas

- ✅ Escáner de biblioteca local (MP3, FLAC, AAC, WAV, OGG, M4A, ALAC, AIFF, OPUS, WMA)
- ✅ Reproducción en segundo plano con controles en pantalla de bloqueo
- ✅ Cola de reproducción (queue)
- ✅ Shuffle y modos de repetición (None / All / One)
- ✅ Ecualizador de 10 bandas con presets (Flat, Bass, Rock, Jazz, etc.)
- ✅ Bass Boost (0–100%)
- ✅ Búsqueda indexada (SQLite)
- ✅ Playlists personalizadas
- ✅ Historial de reproducción
- ✅ Favoritos
- ✅ Indicador de calidad FLAC/Lossless
- ✅ Waveform visual en el reproductor
- ✅ Animaciones fluidas (flutter_animate)
- ✅ Modo Dark absoluto (Negro Carbón #0A0A0A + Rojo Neón #FF0000)
- ✅ Bottom navigation personalizada (igual al diseño de referencia)
- ✅ MiniPlayer persistente sobre la barra de navegación
