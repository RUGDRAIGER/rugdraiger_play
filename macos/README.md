# Rugdraiger Play — macOS Apple Silicon

App de escritorio para MacBook Air/Pro con chips M1, M2, M3 y M4. La
compilación predeterminada usa Electron `arm64`, comparte la UI React de la web
y mantiene el acceso a archivos detrás de una API aislada y validada.

**[Descargar la última versión publicada](https://github.com/RUGDRAIGER/rugdraiger_play/releases/latest/download/RugdraigerPlay-macOS.zip)**

## Requisitos

- macOS 13 o posterior.
- Mac Apple Silicon (`arm64`).
- Node.js 22 o posterior y npm.
- Espacio temporal libre para Electron y el ZIP final.

Xcode no es necesario para la compilación predeterminada. Sólo hace falta para
la variante Flutter opcional.

## Generar la app

```bash
cd macos
./build-macos.sh
```

El script ejecuta una instalación reproducible con `npm ci`, compila el frontend
en modo escritorio, crea el `.app`, aplica firma local ad-hoc, verifica que el
ejecutable incluya `arm64` y genera:

- `RugdraigerPlay/Rugdraiger Play.app`
- `RugdraigerPlay-macOS.zip` (para distribución)
- `RugdraigerPlay-macOS.zip.sha256`

Probar la app:

```bash
open "RugdraigerPlay/Rugdraiger Play.app"
```

El ZIP público versionado no se reemplaza accidentalmente. Para copiar de forma
explícita el artefacto nuevo a `web/public/macos/`, usa:

```bash
./build-macos.sh --publish-artifact
```

## Validaciones de desarrollo

```bash
cd macos/desktop-shell
npm ci
npm run check
npm audit --audit-level=high

cd ../../web
npm ci
npm run build:desktop
npm audit --audit-level=high
```

## Conectar Navidrome

En la app abre **Ajustes → Biblioteca remota**. Introduce la dirección HTTPS de
tu servidor, tu usuario y contraseña, y pulsa **Conectar y guardar**.

La contraseña nunca se escribe en el repositorio ni en `localStorage`. El
proceso principal la protege mediante `safeStorage` y el Llavero de macOS, y la
API Subsonic recibe un token MD5 salado distinto en cada solicitud sobre HTTPS.
Después de guardarla, la app importa el catálogo remoto y obtiene carátulas con
`getCoverArt` y audio con `stream`, sin exponer credenciales al proceso visual.

Las vistas Inicio y Canciones muestran contadores, filtros e insignias para
distinguir archivos **Local** de pistas **Navidrome**. Puedes actualizar el
catálogo o eliminar las credenciales desde Ajustes sin volver a escribir la
clave.

Para que el Llavero reconozca futuras versiones como la misma aplicación sin
volver a pedir autorización, los paquetes públicos deben conservar una firma
Developer ID estable. Las compilaciones locales usan firma ad-hoc.

## Variante Flutter opcional

Con Xcode completo instalado y seleccionado:

```bash
cd macos
./build-macos.sh --flutter
```

## Características

Igual que APK/web: biblioteca, playlists, favoritos, ecualizador, búsqueda, ajustes, modo conducción, carátulas iTunes, etc.

Las carpetas elegidas por el usuario se recuerdan entre sesiones. Las rutas se
normalizan y validan antes de escanear o leer archivos, y el proceso visual no
recibe acceso directo a Node.js.

Ver `COMO-INSTALAR-EN-MAC.txt` para instrucciones de instalación.
