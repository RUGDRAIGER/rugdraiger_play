import { useEffect, useMemo, useState } from 'react'
import type { FormEvent } from 'react'
import type { NavidromeConfig, NavidromeConnectionInfo } from '../../types/electron'
import { useLibraryStore } from '../../store/libraryStore'

const DEFAULT_SERVER = ''
const EMPTY_CONFIG: NavidromeConfig = {
  connected: false,
  serverUrl: '',
  username: '',
  lastVerifiedAt: '',
  serverVersion: '',
}

const inputStyle = {
  width: '100%',
  border: '1px solid var(--border)',
  borderRadius: 'var(--radius-md)',
  background: 'var(--bg-surface2)',
  color: 'var(--text-primary)',
  padding: '11px 12px',
  fontSize: 14,
  outline: 'none',
} as const

function readableError(error: unknown): string {
  const message = error instanceof Error ? error.message : String(error)
  return message
    .replace(/^Error invoking remote method '[^']+': Error: /, '')
    .replace(/^Error: /, '')
}

function sameServer(left: string, right: string): boolean {
  return left.trim().replace(/\/+$/, '') === right.trim().replace(/\/+$/, '')
}

function describeImportedSongs(count: number): string {
  const summary = `${count} ${count === 1 ? 'canción importada' : 'canciones importadas'}`
  if (count <= 1) {
    return `${summary}. Navidrome solo está exponiendo ${count}; revisa el escaneo y los permisos de biblioteca de esa cuenta en el servidor.`
  }
  return summary
}

export function NavidromeSettings() {
  const api = window.electronAPI
  const available = typeof api?.getNavidromeConfig === 'function'
  const [config, setConfig] = useState<NavidromeConfig>(EMPTY_CONFIG)
  const [serverUrl, setServerUrl] = useState(DEFAULT_SERVER)
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState('')
  const [isError, setIsError] = useState(false)
  const syncNavidrome = useLibraryStore((state) => state.syncNavidrome)
  const removeNavidromeSongs = useLibraryStore((state) => state.removeNavidromeSongs)

  useEffect(() => {
    if (!available || !api) return
    let active = true
    setBusy(true)
    void api.getNavidromeConfig()
      .then((saved) => {
        if (!active) return
        setConfig(saved)
        if (saved.serverUrl) setServerUrl(saved.serverUrl)
        if (saved.username) setUsername(saved.username)
      })
      .catch((error) => {
        if (!active) return
        setIsError(true)
        setMessage(readableError(error))
      })
      .finally(() => { if (active) setBusy(false) })
    return () => { active = false }
  }, [api, available])

  const savedIdentity = useMemo(
    () => config.connected && sameServer(serverUrl, config.serverUrl) && username.trim() === config.username,
    [config, serverUrl, username],
  )
  const needsPassword = !savedIdentity
  const canConnect = Boolean(serverUrl.trim() && username.trim() && (password || !needsPassword) && !busy)

  function describeConnection(info: NavidromeConnectionInfo): string {
    const version = info.serverVersion || config.serverVersion
    return `Conexión correcta${version ? ` · Navidrome ${version}` : ''} · API ${info.apiVersion}`
  }

  async function handleConnect(event: FormEvent) {
    event.preventDefault()
    if (!api || !canConnect) return
    setBusy(true)
    setMessage('Comprobando credenciales…')
    setIsError(false)
    try {
      const result = await api.connectNavidrome({
        serverUrl: serverUrl.trim(),
        username: username.trim(),
        ...(password ? { password } : {}),
      })
      setConfig(result.config)
      setServerUrl(result.config.serverUrl)
      setUsername(result.config.username)
      setPassword('')
      try {
        const count = await syncNavidrome()
        setMessage(`${describeConnection(result.connectionInfo)} · ${describeImportedSongs(count)}`)
      } catch (syncError) {
        setIsError(true)
        setMessage(`Conexión guardada, pero la biblioteca no pudo importarse: ${readableError(syncError)}`)
      }
    } catch (error) {
      setIsError(true)
      setMessage(readableError(error))
    } finally {
      setBusy(false)
    }
  }

  async function handleTest() {
    if (!api || busy) return
    setBusy(true)
    setMessage('Probando la conexión guardada…')
    setIsError(false)
    try {
      const result = await api.testNavidromeConnection()
      setConfig(result.config)
      setMessage(describeConnection(result.connectionInfo))
    } catch (error) {
      setIsError(true)
      setMessage(readableError(error))
    } finally {
      setBusy(false)
    }
  }

  async function handleDisconnect() {
    if (!api || busy || !window.confirm('¿Eliminar del llavero las credenciales de Navidrome?')) return
    setBusy(true)
    try {
      setConfig(await api.disconnectNavidrome())
      await removeNavidromeSongs()
      setServerUrl(DEFAULT_SERVER)
      setUsername('')
      setPassword('')
      setIsError(false)
      setMessage('Credenciales eliminadas de este Mac')
    } catch (error) {
      setIsError(true)
      setMessage(readableError(error))
    } finally {
      setBusy(false)
    }
  }

  async function handleSync() {
    if (busy) return
    setBusy(true)
    setIsError(false)
    setMessage('Importando catálogo, carátulas y rutas de reproducción…')
    try {
      const count = await syncNavidrome()
      setMessage(`Biblioteca actualizada · ${describeImportedSongs(count)}`)
    } catch (error) {
      setIsError(true)
      setMessage(readableError(error))
    } finally {
      setBusy(false)
    }
  }

  if (!available) {
    return (
      <div style={{ padding: 14, borderRadius: 'var(--radius-md)', background: 'var(--bg-surface)', border: '1px solid var(--border)' }}>
        <div style={{ fontSize: 14, fontWeight: 650 }}>Navidrome</div>
        <div style={{ marginTop: 5, color: 'var(--text-secondary)', fontSize: 12, lineHeight: 1.5 }}>
          La conexión segura está disponible en la aplicación de escritorio para macOS.
        </div>
      </div>
    )
  }

  return (
    <form onSubmit={handleConnect} style={{ padding: 16, borderRadius: 'var(--radius-md)', background: 'var(--bg-surface)', border: '1px solid var(--border)' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12, marginBottom: 14 }}>
        <div>
          <div style={{ fontSize: 15, fontWeight: 700 }}>Servidor Navidrome</div>
          <div style={{ marginTop: 3, color: 'var(--text-secondary)', fontSize: 12 }}>
            {config.connected ? `Cuenta guardada: ${config.username}` : 'Conecta tu biblioteca musical privada'}
          </div>
        </div>
        <span style={{
          flexShrink: 0, padding: '5px 9px', borderRadius: 999, fontSize: 11, fontWeight: 700,
          color: config.connected ? '#78e08f' : 'var(--text-secondary)',
          background: config.connected ? 'rgba(48, 209, 88, 0.12)' : 'var(--bg-surface3)',
        }}>
          {config.connected ? '● Guardado' : 'Sin conectar'}
        </span>
      </div>

      <div style={{ display: 'grid', gap: 12 }}>
        <label style={{ display: 'grid', gap: 6, fontSize: 12, color: 'var(--text-secondary)' }}>
          Servidor HTTPS
          <input
            type="url"
            value={serverUrl}
            onChange={(event) => setServerUrl(event.target.value)}
            placeholder="https://musica.ejemplo.com"
            autoComplete="url"
            spellCheck={false}
            required
            disabled={busy}
            style={inputStyle}
          />
        </label>
        <label style={{ display: 'grid', gap: 6, fontSize: 12, color: 'var(--text-secondary)' }}>
          Usuario
          <input
            type="text"
            value={username}
            onChange={(event) => setUsername(event.target.value)}
            placeholder="Tu usuario de Navidrome"
            autoComplete="username"
            required
            disabled={busy}
            style={inputStyle}
          />
        </label>
        <label style={{ display: 'grid', gap: 6, fontSize: 12, color: 'var(--text-secondary)' }}>
          Contraseña
          <input
            type="password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            placeholder={savedIdentity ? 'Guardada en el llavero · deja vacío para conservarla' : 'Tu contraseña de Navidrome'}
            autoComplete="current-password"
            required={needsPassword}
            disabled={busy}
            style={inputStyle}
          />
        </label>
      </div>

      <div style={{ marginTop: 13, color: 'var(--text-secondary)', fontSize: 11, lineHeight: 1.5 }}>
        La contraseña se cifra con el Llavero de macOS. Rugdraiger Play usa un token salado distinto en cada solicitud y no guarda la clave en texto plano.
      </div>

      {message && (
        <div role="status" style={{
          marginTop: 12, padding: '9px 11px', borderRadius: 9, fontSize: 12,
          color: isError ? '#ff8a8a' : '#78e08f',
          background: isError ? 'rgba(255, 69, 58, 0.1)' : 'rgba(48, 209, 88, 0.1)',
        }}>
          {message}
        </div>
      )}

      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginTop: 14 }}>
        <button type="submit" disabled={!canConnect} style={{
          border: 0, borderRadius: 10, padding: '10px 14px', fontWeight: 700, fontSize: 12,
          color: '#fff', background: 'var(--accent)', cursor: canConnect ? 'pointer' : 'not-allowed', opacity: canConnect ? 1 : 0.5,
        }}>
          {busy ? 'Conectando…' : config.connected ? 'Actualizar conexión' : 'Conectar y guardar'}
        </button>
        {config.connected && (
          <>
            <button type="button" onClick={handleTest} disabled={busy} style={{
              border: '1px solid var(--border)', borderRadius: 10, padding: '9px 13px', fontWeight: 650, fontSize: 12,
              color: 'var(--text-primary)', background: 'var(--bg-surface2)', cursor: busy ? 'not-allowed' : 'pointer',
            }}>
              Probar conexión
            </button>
            <button type="button" onClick={handleSync} disabled={busy} style={{
              border: '1px solid rgba(64, 156, 255, 0.3)', borderRadius: 10, padding: '9px 13px', fontWeight: 650, fontSize: 12,
              color: '#8ec5ff', background: 'rgba(64, 156, 255, 0.1)', cursor: busy ? 'not-allowed' : 'pointer',
            }}>
              Sincronizar biblioteca
            </button>
            <button type="button" onClick={handleDisconnect} disabled={busy} style={{
              border: 0, padding: '9px 8px', fontWeight: 600, fontSize: 12,
              color: '#ff8a8a', background: 'transparent', cursor: busy ? 'not-allowed' : 'pointer',
            }}>
              Olvidar credenciales
            </button>
          </>
        )}
      </div>
    </form>
  )
}
