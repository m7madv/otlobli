import { createHash, createPrivateKey, sign } from 'node:crypto'
import { readFile } from 'node:fs/promises'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const repositoryRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const authorizationPath = resolve(repositoryRoot, 'store-assets', 'google-play', 'CLOSED_TEST_AUTHORIZED.json')
const authorization = JSON.parse(await readFile(authorizationPath, 'utf8'))

const requiredFields = ['operation', 'packageName', 'appVersion', 'versionCode', 'bundlePath', 'sha256']
for (const field of requiredFields) {
  if (!String(authorization[field] || '').trim()) throw new Error(`Missing Google Play authorization field: ${field}`)
}
if (!['inspect', 'publish'].includes(authorization.operation)) throw new Error('Google Play operation must be inspect or publish.')
if (authorization.packageName !== 'com.otlobli.app') throw new Error('Google Play authorization targets an unexpected package.')
if (authorization.appVersion !== '86.244' || authorization.versionCode !== '1112') {
  throw new Error('Google Play authorization is not bound to Otlobli 86.244 (1112).')
}
if (!/^[A-F0-9]{64}$/.test(authorization.sha256)) throw new Error('Invalid authorized App Bundle SHA-256.')
if (authorization.operation === 'publish' && !String(authorization.track || '').trim()) {
  throw new Error('Publishing requires an exact Google Play track in the authorization record.')
}

const bundlePath = resolve(repositoryRoot, authorization.bundlePath)
if (!bundlePath.startsWith(`${repositoryRoot}\\`) && !bundlePath.startsWith(`${repositoryRoot}/`)) {
  throw new Error('Authorized App Bundle must stay inside the repository.')
}
const bundle = await readFile(bundlePath)
const bundleSha256 = createHash('sha256').update(bundle).digest('hex').toUpperCase()
if (bundleSha256 !== authorization.sha256) {
  throw new Error(`Authorized App Bundle SHA-256 mismatch: ${bundleSha256}.`)
}

const credentialsSource = process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
if (!credentialsSource) throw new Error('Missing GOOGLE_PLAY_SERVICE_ACCOUNT_JSON.')
const credentials = JSON.parse(credentialsSource)
if (credentials.type !== 'service_account' || !credentials.client_email || !credentials.private_key) {
  throw new Error('Google Play credentials are not a service account.')
}
if (credentials.token_uri !== 'https://oauth2.googleapis.com/token') {
  throw new Error('Google Play service account uses an unexpected token endpoint.')
}

const base64url = (value) => Buffer.from(value).toString('base64url')
const now = Math.floor(Date.now() / 1000)
const jwtHeader = base64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
const jwtPayload = base64url(JSON.stringify({
  iss: credentials.client_email,
  scope: 'https://www.googleapis.com/auth/androidpublisher',
  aud: credentials.token_uri,
  iat: now - 20,
  exp: now + 600,
}))
const unsignedJwt = `${jwtHeader}.${jwtPayload}`
const privateKey = createPrivateKey(credentials.private_key)
const assertion = `${unsignedJwt}.${sign('RSA-SHA256', Buffer.from(unsignedJwt), privateKey).toString('base64url')}`

const tokenResponse = await fetch(credentials.token_uri, {
  method: 'POST',
  headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  body: new URLSearchParams({
    grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    assertion,
  }),
})
const tokenPayload = await tokenResponse.json()
if (!tokenResponse.ok || !tokenPayload.access_token) {
  throw new Error(`Google OAuth token exchange failed (${tokenResponse.status}).`)
}

const apiRoot = 'https://androidpublisher.googleapis.com/androidpublisher/v3'
const uploadRoot = 'https://androidpublisher.googleapis.com/upload/androidpublisher/v3'
const packageName = encodeURIComponent(authorization.packageName)

async function apiRequest(url, { method = 'GET', body, binary = false } = {}) {
  const response = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${tokenPayload.access_token}`,
      ...(body === undefined ? {} : { 'Content-Type': binary ? 'application/octet-stream' : 'application/json' }),
    },
    ...(body === undefined ? {} : { body: binary ? body : JSON.stringify(body) }),
  })
  const responseText = await response.text()
  if (response.ok) return responseText ? JSON.parse(responseText) : null
  let detail = ''
  try {
    const parsed = JSON.parse(responseText)
    detail = parsed.error?.message || parsed.error?.status || ''
  } catch {
    detail = responseText.slice(0, 500)
  }
  throw new Error(`Google Play ${method} request failed (${response.status}): ${detail || 'request failed'}`)
}

function digestHex(value) {
  if (!value) return null
  if (/^[a-f0-9]{64}$/i.test(value)) return value.toUpperCase()
  try {
    const decoded = Buffer.from(value, 'base64')
    return decoded.length === 32 ? decoded.toString('hex').toUpperCase() : null
  } catch {
    return null
  }
}

const edit = await apiRequest(`${apiRoot}/applications/${packageName}/edits`, { method: 'POST', body: {} })
const editId = encodeURIComponent(edit.id)
let committed = false

try {
  const tracksPayload = await apiRequest(`${apiRoot}/applications/${packageName}/edits/${editId}/tracks`)
  const bundlesPayload = await apiRequest(`${apiRoot}/applications/${packageName}/edits/${editId}/bundles`)
  const tracks = tracksPayload.tracks || []
  const bundles = bundlesPayload.bundles || []

  console.log(`Google Play package ${authorization.packageName}; tracks=${tracks.length}; bundles=${bundles.length}.`)
  for (const track of tracks) {
    const releases = (track.releases || []).map((release) => ({
      status: release.status || 'UNKNOWN',
      versionCodes: release.versionCodes || [],
      name: release.name || '',
      userFraction: release.userFraction ?? null,
    }))
    let testerCount = null
    let groupCount = null
    if (!['internal', 'production'].includes(track.track)) {
      try {
        const testers = await apiRequest(
          `${apiRoot}/applications/${packageName}/edits/${editId}/testers/${encodeURIComponent(track.track)}`,
        )
        testerCount = Array.isArray(testers.googlePlayGames?.gamertags)
          ? testers.googlePlayGames.gamertags.length
          : Array.isArray(testers.testers) ? testers.testers.length : null
        groupCount = Array.isArray(testers.googleGroups) ? testers.googleGroups.length : null
      } catch {
        // Tester configuration can be managed by Play Console groups that the
        // publishing API doesn't enumerate. Keep inspection read-only.
      }
    }
    console.log(`TRACK ${JSON.stringify({ track: track.track, releases, testerCount, groupCount })}`)
  }

  if (authorization.operation === 'inspect') {
    console.log(`Google Play inspection complete for authorized ${authorization.appVersion} (${authorization.versionCode}).`)
    process.exitCode = 0
  } else {
    const targetTrack = tracks.find((track) => track.track === authorization.track)
    if (!targetTrack) throw new Error(`Authorized Google Play track does not exist: ${authorization.track}.`)

    const targetVersionCode = Number.parseInt(authorization.versionCode, 10)
    const existingBundle = bundles.find((entry) => Number(entry.versionCode) === targetVersionCode)
    if (existingBundle) {
      const existingDigest = digestHex(existingBundle.sha256)
      if (existingDigest && existingDigest !== authorization.sha256) {
        throw new Error(`Google Play already has versionCode ${targetVersionCode} with a different SHA-256.`)
      }
      console.log(`Google Play bundle ${targetVersionCode} already exists; reusing it.`)
    } else {
      const uploaded = await apiRequest(
        `${uploadRoot}/applications/${packageName}/edits/${editId}/bundles?uploadType=media`,
        { method: 'POST', body: bundle, binary: true },
      )
      if (Number(uploaded.versionCode) !== targetVersionCode) {
        throw new Error(`Google Play returned unexpected uploaded versionCode ${uploaded.versionCode}.`)
      }
      const uploadedDigest = digestHex(uploaded.sha256)
      if (uploadedDigest && uploadedDigest !== authorization.sha256) {
        throw new Error('Google Play returned an unexpected App Bundle SHA-256.')
      }
      console.log(`Uploaded exact App Bundle ${authorization.appVersion} (${authorization.versionCode}).`)
    }

    const updatedTrack = await apiRequest(
      `${apiRoot}/applications/${packageName}/edits/${editId}/tracks/${encodeURIComponent(authorization.track)}`,
      {
        method: 'PUT',
        body: {
          track: authorization.track,
          releases: [{
            name: `Otlobli ${authorization.appVersion} (${authorization.versionCode})`,
            status: 'completed',
            versionCodes: [authorization.versionCode],
          }],
        },
      },
    )
    const release = updatedTrack.releases?.[0]
    if (release?.status !== 'completed' || !release.versionCodes?.includes(authorization.versionCode)) {
      throw new Error('Google Play closed-test track did not retain the authorized completed release.')
    }

    await apiRequest(`${apiRoot}/applications/${packageName}/edits/${editId}:commit`, { method: 'POST', body: {} })
    committed = true
    console.log(
      `Published ${authorization.appVersion} (${authorization.versionCode}) to Google Play track ` +
      `${authorization.track}; status=completed.`,
    )
  }
} finally {
  if (!committed) {
    try {
      await apiRequest(`${apiRoot}/applications/${packageName}/edits/${editId}`, { method: 'DELETE' })
    } catch {
      // The edit may already be expired or committed; never obscure the main result.
    }
  }
}
