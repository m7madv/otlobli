import { readFile, appendFile } from 'node:fs/promises'
import { createPrivateKey, sign } from 'node:crypto'

const API_ROOT = 'https://api.appstoreconnect.apple.com/v1'
const requiredEnvironment = [
  'ASC_API_KEY_ID',
  'ASC_ISSUER_ID',
  'ASC_API_KEY_PATH',
  'OTLOBLI_ASC_APP_ID',
  'OTLOBLI_APP_VERSION',
  'OTLOBLI_APP_BUILD',
]

for (const name of requiredEnvironment) {
  if (!process.env[name]?.trim()) throw new Error(`Missing required environment variable: ${name}`)
}

const config = {
  keyId: process.env.ASC_API_KEY_ID.trim(),
  issuerId: process.env.ASC_ISSUER_ID.trim(),
  keyPath: process.env.ASC_API_KEY_PATH.trim(),
  appId: process.env.OTLOBLI_ASC_APP_ID.trim(),
  appVersion: process.env.OTLOBLI_APP_VERSION.trim(),
  appBuild: process.env.OTLOBLI_APP_BUILD.trim(),
  waitMinutes: Number.parseInt(process.env.OTLOBLI_ASC_WAIT_MINUTES || '20', 10),
}

if (!/^[A-Z0-9]{10}$/.test(config.keyId)) throw new Error('Invalid App Store Connect key ID.')
if (!/^[0-9a-f-]{36}$/i.test(config.issuerId)) throw new Error('Invalid App Store Connect issuer ID.')
if (!/^\d+$/.test(config.appId)) throw new Error('Invalid App Store Connect app ID.')
if (!/^\d+(?:\.\d+){1,2}$/.test(config.appVersion)) throw new Error('Invalid app version.')
if (!/^\d+$/.test(config.appBuild)) throw new Error('Invalid app build number.')
if (!Number.isInteger(config.waitMinutes) || config.waitMinutes < 1 || config.waitMinutes > 30) {
  throw new Error('OTLOBLI_ASC_WAIT_MINUTES must be between 1 and 30.')
}

const privateKey = createPrivateKey(await readFile(config.keyPath, 'utf8'))
const sleep = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds))
const base64url = (value) => Buffer.from(value).toString('base64url')

function authorizationToken() {
  const issuedAt = Math.floor(Date.now() / 1000) - 20
  const header = base64url(JSON.stringify({ alg: 'ES256', kid: config.keyId, typ: 'JWT' }))
  const payload = base64url(JSON.stringify({
    iss: config.issuerId,
    iat: issuedAt,
    exp: issuedAt + 600,
    aud: 'appstoreconnect-v1',
  }))
  const unsigned = `${header}.${payload}`
  const signature = sign('sha256', Buffer.from(unsigned), {
    key: privateKey,
    dsaEncoding: 'ieee-p1363',
  })
  return `${unsigned}.${signature.toString('base64url')}`
}

function apiPath(resource, parameters = {}) {
  const query = new URLSearchParams()
  for (const [key, value] of Object.entries(parameters)) {
    if (value !== undefined && value !== null && value !== '') query.set(key, String(value))
  }
  const serialized = query.toString()
  return serialized ? `${resource}?${serialized}` : resource
}

class AppStoreConnectError extends Error {
  constructor(message, status, errors) {
    super(message)
    this.name = 'AppStoreConnectError'
    this.status = status
    this.errors = errors
  }
}

async function apiRequest(path, { method = 'GET', body } = {}) {
  for (let attempt = 1; attempt <= 5; attempt += 1) {
    const response = await fetch(`${API_ROOT}${path}`, {
      method,
      headers: {
        Authorization: `Bearer ${authorizationToken()}`,
        ...(body ? { 'Content-Type': 'application/json' } : {}),
      },
      ...(body ? { body: JSON.stringify(body) } : {}),
    })
    const responseText = await response.text()
    if (response.ok) return responseText ? JSON.parse(responseText) : null

    if ((response.status === 429 || response.status >= 500) && attempt < 5) {
      await sleep(attempt * 2_000)
      continue
    }

    let errors = []
    try {
      errors = JSON.parse(responseText).errors || []
    } catch {
      // Apple occasionally returns a plain transport error; keep it bounded.
    }
    const detail = errors.length
      ? errors.map((error) => `${error.code || response.status}: ${error.detail || error.title || 'request failed'}`).join('; ')
      : responseText.slice(0, 1_500)
    throw new AppStoreConnectError(
      `App Store Connect ${method} ${path} failed (${response.status}): ${detail}`,
      response.status,
      errors,
    )
  }
  throw new Error(`App Store Connect ${method} ${path} exhausted retries.`)
}

function includedResource(response, relationship) {
  const id = relationship?.data?.id
  const type = relationship?.data?.type
  return response.included?.find((resource) => resource.id === id && resource.type === type)
}

async function findProcessedBuild() {
  const deadline = Date.now() + config.waitMinutes * 60_000
  let lastState = 'NOT_VISIBLE'

  while (Date.now() <= deadline) {
    const response = await apiRequest(apiPath('/builds', {
      'filter[app]': config.appId,
      'filter[version]': config.appBuild,
      include: 'preReleaseVersion',
      'fields[builds]': 'version,uploadedDate,processingState,expired,preReleaseVersion',
      'fields[preReleaseVersions]': 'version,platform',
      limit: 10,
    }))
    const candidates = response.data
      .map((build) => ({ build, release: includedResource(response, build.relationships?.preReleaseVersion) }))
      .filter(({ build, release }) =>
        build.attributes?.version === config.appBuild &&
        release?.attributes?.version === config.appVersion &&
        release?.attributes?.platform === 'IOS')
      .sort((left, right) => String(right.build.attributes?.uploadedDate).localeCompare(String(left.build.attributes?.uploadedDate)))

    const match = candidates[0]?.build
    if (match) {
      lastState = match.attributes.processingState
      if (lastState === 'VALID' && match.attributes.expired !== true) return match
      if (lastState === 'FAILED' || lastState === 'INVALID') {
        throw new Error(`App Store Connect rejected ${config.appVersion} (${config.appBuild}): ${lastState}.`)
      }
    }
    if (Date.now() + 30_000 > deadline) break
    console.log(`Waiting for App Store Connect processing before review: ${lastState}.`)
    await sleep(30_000)
  }

  throw new Error(`Timed out waiting for ${config.appVersion} (${config.appBuild}); last state: ${lastState}.`)
}

async function findOrCreateVersion() {
  const response = await apiRequest(apiPath(`/apps/${encodeURIComponent(config.appId)}/appStoreVersions`, {
    'filter[platform]': 'IOS',
    'fields[appStoreVersions]': 'platform,versionString,appStoreState,releaseType,usesIdfa,build',
    limit: 200,
  }))
  const iosVersions = response.data.filter((version) => version.attributes?.platform === 'IOS')
  const versionSummary = iosVersions
    .map((version) => `${version.attributes?.versionString || 'UNKNOWN'}:${version.attributes?.appStoreState || 'UNKNOWN'}`)
    .join(', ')
  console.log(`Current iOS App Store versions: ${versionSummary || 'none'}.`)

  const matches = iosVersions.filter((version) => version.attributes?.versionString === config.appVersion)
  if (matches.length > 1) throw new Error(`Found multiple iOS App Store versions named ${config.appVersion}.`)
  if (matches.length === 1) return matches[0]

  // App Store Connect permits only one editable version per platform. Reuse that
  // draft so its localized metadata, screenshots, review details, and phased
  // release settings survive; never delete or guess at customer-owned metadata.
  const editableDrafts = iosVersions.filter((version) =>
    version.attributes?.appStoreState === 'PREPARE_FOR_SUBMISSION')
  if (editableDrafts.length > 1) {
    throw new Error('Multiple editable iOS App Store versions exist; refusing to choose one implicitly.')
  }
  if (editableDrafts.length === 1) {
    const draft = editableDrafts[0]
    const previousVersion = draft.attributes?.versionString || 'UNKNOWN'
    const updated = await apiRequest(`/appStoreVersions/${encodeURIComponent(draft.id)}`, {
      method: 'PATCH',
      body: {
        data: {
          type: 'appStoreVersions',
          id: draft.id,
          attributes: { versionString: config.appVersion },
        },
      },
    })
    console.log(`Reused editable App Store version ${previousVersion} as ${config.appVersion}; existing store metadata was preserved.`)
    return updated.data
  }

  try {
    const created = await apiRequest('/appStoreVersions', {
      method: 'POST',
      body: {
        data: {
          type: 'appStoreVersions',
          attributes: {
            platform: 'IOS',
            versionString: config.appVersion,
            releaseType: 'AFTER_APPROVAL',
            usesIdfa: false,
          },
          relationships: {
            app: { data: { type: 'apps', id: config.appId } },
          },
        },
      },
    })
    console.log(`Created App Store version ${config.appVersion}.`)
    return created.data
  } catch (error) {
    if (error instanceof AppStoreConnectError && error.status === 409) {
      throw new Error(
        `Apple will not create ${config.appVersion} and no PREPARE_FOR_SUBMISSION draft can be safely reused. ` +
        `Current iOS versions: ${versionSummary || 'none'}. Original error: ${error.message}`,
        { cause: error },
      )
    }
    throw error
  }
}

async function ensureVersionBuild(version, build) {
  const relationshipPath = `/appStoreVersions/${encodeURIComponent(version.id)}/relationships/build`
  const existing = await apiRequest(relationshipPath)
  if (existing.data?.id === build.id) return 'already-linked'
  const previousBuildId = existing.data?.id || null
  await apiRequest(relationshipPath, {
    method: 'PATCH',
    body: { data: { type: 'builds', id: build.id } },
  })
  const verified = await apiRequest(relationshipPath)
  if (verified.data?.id !== build.id) throw new Error('The App Store version/build relationship was not visible after assignment.')
  return previousBuildId ? `replaced-${previousBuildId}` : 'linked-now'
}

async function findDraftSubmission() {
  const response = await apiRequest(apiPath(`/apps/${encodeURIComponent(config.appId)}/reviewSubmissions`, {
    'filter[platform]': 'IOS',
    'filter[state]': 'READY_FOR_REVIEW',
    'fields[reviewSubmissions]': 'platform,state,items,appStoreVersionForReview',
    limit: 20,
  }))
  if (response.data.length > 1) throw new Error('Multiple editable iOS review submissions exist; refusing to choose one implicitly.')
  return response.data[0] || null
}

async function findOrCreateDraftSubmission() {
  const existing = await findDraftSubmission()
  if (existing) return existing
  const created = await apiRequest('/reviewSubmissions', {
    method: 'POST',
    body: {
      data: {
        type: 'reviewSubmissions',
        relationships: { app: { data: { type: 'apps', id: config.appId } } },
      },
    },
  })
  console.log(`Created review submission ${created.data.id}.`)
  return created.data
}

async function ensureSubmissionItem(submission, version) {
  const response = await apiRequest(apiPath(`/reviewSubmissions/${encodeURIComponent(submission.id)}/items`, {
    'fields[reviewSubmissionItems]': 'state,appStoreVersion',
    limit: 50,
  }))
  const existing = response.data.find((item) => item.relationships?.appStoreVersion?.data?.id === version.id)
  if (existing) return existing

  const created = await apiRequest('/reviewSubmissionItems', {
    method: 'POST',
    body: {
      data: {
        type: 'reviewSubmissionItems',
        relationships: {
          reviewSubmission: { data: { type: 'reviewSubmissions', id: submission.id } },
          appStoreVersion: { data: { type: 'appStoreVersions', id: version.id } },
        },
      },
    },
  })
  console.log(`Added App Store version ${config.appVersion} to review submission ${submission.id}.`)
  return created.data
}

async function submitReview(submission) {
  const response = await apiRequest(`/reviewSubmissions/${encodeURIComponent(submission.id)}`, {
    method: 'PATCH',
    body: {
      data: {
        type: 'reviewSubmissions',
        id: submission.id,
        attributes: { submitted: true },
      },
    },
  })
  return response.data?.attributes?.state || 'SUBMITTED'
}

async function appendOutput(name, value) {
  if (!process.env.GITHUB_OUTPUT) return
  await appendFile(process.env.GITHUB_OUTPUT, `${name}=${value}\n`, 'utf8')
}

const build = await findProcessedBuild()
const version = await findOrCreateVersion()
const appStoreState = version.attributes?.appStoreState || 'UNKNOWN'
const alreadySubmittedStates = new Set([
  'WAITING_FOR_REVIEW',
  'IN_REVIEW',
  'PENDING_APPLE_RELEASE',
  'PENDING_DEVELOPER_RELEASE',
  'PROCESSING_FOR_APP_STORE',
  'READY_FOR_SALE',
])

if (alreadySubmittedStates.has(appStoreState)) {
  console.log(`App Store version ${config.appVersion} is already ${appStoreState}.`)
  await appendOutput('app_store_state', appStoreState)
  process.exit(0)
}

const buildLink = await ensureVersionBuild(version, build)
console.log(`Verified App Store build ${config.appVersion} (${config.appBuild}); build link: ${buildLink}.`)
const submission = await findOrCreateDraftSubmission()
await ensureSubmissionItem(submission, version)
const submissionState = await submitReview(submission)
console.log(`Submitted ${config.appVersion} (${config.appBuild}) to App Review; state: ${submissionState}.`)

await appendOutput('app_store_version_id', version.id)
await appendOutput('review_submission_id', submission.id)
await appendOutput('app_store_state', submissionState)
