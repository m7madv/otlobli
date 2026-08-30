import { existsSync } from 'node:fs'
import { readFile, appendFile, stat } from 'node:fs/promises'
import { createHash, createPrivateKey, sign } from 'node:crypto'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { screenshotManifest } from './app-store-screenshot-manifest.mjs'

const API_ROOT = 'https://api.appstoreconnect.apple.com/v1'
const repositoryRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const storeAssetRoot = resolve(repositoryRoot, 'store-assets', 'app-store')
const prepareOnlyMarker = resolve(storeAssetRoot, 'PREPARE_ONLY')
const submissionAuthorizedMarker = resolve(storeAssetRoot, 'SUBMISSION_AUTHORIZED.json')
const screenshotAssets = screenshotManifest.map((asset) => ({
  ...asset,
  path: resolve(storeAssetRoot, asset.fileName),
}))
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
  prepareOnly: existsSync(prepareOnlyMarker),
}

if (!/^[A-Z0-9]{10}$/.test(config.keyId)) throw new Error('Invalid App Store Connect key ID.')
if (!/^[0-9a-f-]{36}$/i.test(config.issuerId)) throw new Error('Invalid App Store Connect issuer ID.')
if (!/^\d+$/.test(config.appId)) throw new Error('Invalid App Store Connect app ID.')
if (!/^\d+(?:\.\d+){1,2}$/.test(config.appVersion)) throw new Error('Invalid app version.')
if (!/^\d+$/.test(config.appBuild)) throw new Error('Invalid app build number.')
if (!Number.isInteger(config.waitMinutes) || config.waitMinutes < 1 || config.waitMinutes > 30) {
  throw new Error('OTLOBLI_ASC_WAIT_MINUTES must be between 1 and 30.')
}

const submissionAuthorized = existsSync(submissionAuthorizedMarker)
if (config.prepareOnly === submissionAuthorized) {
  throw new Error('Exactly one App Review gate must exist: PREPARE_ONLY or SUBMISSION_AUTHORIZED.json.')
}
if (submissionAuthorized) {
  const acceptance = JSON.parse(await readFile(submissionAuthorizedMarker, 'utf8'))
  if (acceptance.appVersion !== config.appVersion || acceptance.appBuild !== config.appBuild) {
    throw new Error(
      `Physical acceptance authorizes ${acceptance.appVersion} (${acceptance.appBuild}), not ${config.appVersion} (${config.appBuild}).`,
    )
  }
  const requiredAcceptance = [
    'iphone16SheinGuestFirstProduct',
    'loginPageDismissed',
    'socialAuthStayedInApp',
    'forceQuitColdLaunch',
    'iphoneCheckoutToShamCashCode',
    'ipadCheckoutToShamCashCode',
  ]
  if (acceptance.backgroundResumeCycles < 5 || requiredAcceptance.some((name) => acceptance[name] !== true)) {
    throw new Error('Physical acceptance record is incomplete; refusing App Review submission.')
  }
  if (acceptance.paidConfirmationPressed !== false) {
    throw new Error('Physical checkout acceptance must stop before the paid confirmation action.')
  }
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
      ? errors.map((error) => {
          const associatedErrors = error.meta?.associatedErrors
          const associatedDetail = associatedErrors
            ? `; associatedErrors=${JSON.stringify(associatedErrors)}`
            : ''
          return `${error.code || response.status}: ${error.detail || error.title || 'request failed'}${associatedDetail}`
        }).join('; ')
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
  const editableStates = new Set(['PREPARE_FOR_SUBMISSION', 'REJECTED'])
  const editableDrafts = iosVersions.filter((version) =>
    editableStates.has(version.attributes?.appStoreState))
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
    console.log(
      `Reused editable App Store version ${previousVersion} (${draft.attributes?.appStoreState}) as ` +
      `${config.appVersion}; existing store metadata was preserved.`,
    )
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
        `Apple will not create ${config.appVersion} and no PREPARE_FOR_SUBMISSION or REJECTED version can be safely reused. ` +
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

function screenshotState(screenshot) {
  return screenshot.attributes?.assetDeliveryState?.state || 'UNKNOWN'
}

async function findStoreLocalization(version) {
  const response = await apiRequest(apiPath(
    `/appStoreVersions/${encodeURIComponent(version.id)}/appStoreVersionLocalizations`,
    {
      'fields[appStoreVersionLocalizations]': 'locale,appScreenshotSets',
      limit: 50,
    },
  ))
  if (!response.data.length) throw new Error('The App Store version has no localization for screenshot upload.')

  const localized = response.data.find((entry) => /^ar(?:-|$)/i.test(entry.attributes?.locale || ''))
    || response.data[0]
  console.log(`Using App Store localization ${localized.attributes?.locale || localized.id} for screenshots.`)
  return localized
}

async function findOrCreateScreenshotSet(localization, displayType) {
  const response = await apiRequest(apiPath(
    `/appStoreVersionLocalizations/${encodeURIComponent(localization.id)}/appScreenshotSets`,
    {
      'fields[appScreenshotSets]': 'screenshotDisplayType,appScreenshots',
      limit: 50,
    },
  ))
  const matches = response.data.filter((set) => set.attributes?.screenshotDisplayType === displayType)
  if (matches.length > 1) throw new Error(`Multiple screenshot sets exist for ${displayType}.`)
  if (matches.length === 1) return matches[0]

  const created = await apiRequest('/appScreenshotSets', {
    method: 'POST',
    body: {
      data: {
        type: 'appScreenshotSets',
        attributes: { screenshotDisplayType: displayType },
        relationships: {
          appStoreVersionLocalization: {
            data: { type: 'appStoreVersionLocalizations', id: localization.id },
          },
        },
      },
    },
  })
  console.log(`Created screenshot set ${displayType}.`)
  return created.data
}

async function listScreenshots(screenshotSet) {
  const response = await apiRequest(apiPath(
    `/appScreenshotSets/${encodeURIComponent(screenshotSet.id)}/appScreenshots`,
    {
      'fields[appScreenshots]': 'fileSize,fileName,sourceFileChecksum,assetDeliveryState',
      limit: 50,
    },
  ))
  return response.data
}

async function uploadScreenshotParts(screenshot, fileBuffer) {
  const operations = screenshot.attributes?.uploadOperations || []
  if (!operations.length) throw new Error(`Apple did not return upload operations for screenshot ${screenshot.id}.`)

  for (const operation of operations) {
    const offset = Number(operation.offset)
    const length = Number(operation.length)
    if (!Number.isSafeInteger(offset) || !Number.isSafeInteger(length) || offset < 0 || length < 1) {
      throw new Error(`Apple returned an invalid upload range for screenshot ${screenshot.id}.`)
    }
    const part = fileBuffer.subarray(offset, offset + length)
    if (part.length !== length) throw new Error(`Screenshot upload range exceeds the local file for ${screenshot.id}.`)

    const headers = Object.fromEntries(
      (operation.requestHeaders || []).map((header) => [header.name, header.value]),
    )
    const response = await fetch(operation.url, {
      method: operation.method || 'PUT',
      headers,
      body: part,
    })
    if (!response.ok) {
      const responseText = await response.text()
      throw new Error(
        `Screenshot part upload failed (${response.status}) for ${screenshot.id}: ${responseText.slice(0, 1_000)}`,
      )
    }
  }
}

async function waitForScreenshot(screenshotId) {
  const deadline = Date.now() + config.waitMinutes * 60_000
  let lastState = 'UNKNOWN'
  while (Date.now() <= deadline) {
    const response = await apiRequest(apiPath(`/appScreenshots/${encodeURIComponent(screenshotId)}`, {
      'fields[appScreenshots]': 'fileSize,fileName,sourceFileChecksum,assetDeliveryState',
    }))
    lastState = screenshotState(response.data)
    if (lastState === 'COMPLETE') return response.data
    if (lastState === 'FAILED') {
      const errors = response.data.attributes?.assetDeliveryState?.errors || []
      throw new Error(`Apple failed to process screenshot ${screenshotId}: ${JSON.stringify(errors)}`)
    }
    await sleep(5_000)
  }
  throw new Error(`Timed out waiting for screenshot ${screenshotId}; last state: ${lastState}.`)
}

async function ensureScreenshot(screenshotSet, asset) {
  const fileInfo = await stat(asset.path)
  if (!fileInfo.isFile() || fileInfo.size < 1) throw new Error(`Screenshot asset is empty: ${asset.path}`)
  const fileBuffer = await readFile(asset.path)
  const fileName = asset.path.split(/[\\/]/).at(-1)
  const checksum = createHash('md5').update(fileBuffer).digest('hex')
  const existing = await listScreenshots(screenshotSet)
  const completeMatch = existing.find((screenshot) =>
    screenshot.attributes?.fileName === fileName &&
    Number(screenshot.attributes?.fileSize) === fileInfo.size &&
    String(screenshot.attributes?.sourceFileChecksum || '').toLowerCase() === checksum &&
    screenshotState(screenshot) === 'COMPLETE')
  if (completeMatch) {
    console.log(`Screenshot ${fileName} is already complete for ${asset.displayType}.`)
    return completeMatch
  }

  const reserved = await apiRequest('/appScreenshots', {
    method: 'POST',
    body: {
      data: {
        type: 'appScreenshots',
        attributes: {
          fileSize: fileInfo.size,
          fileName,
        },
        relationships: {
          appScreenshotSet: {
            data: { type: 'appScreenshotSets', id: screenshotSet.id },
          },
        },
      },
    },
  })
  await uploadScreenshotParts(reserved.data, fileBuffer)
  await apiRequest(`/appScreenshots/${encodeURIComponent(reserved.data.id)}`, {
    method: 'PATCH',
    body: {
      data: {
        type: 'appScreenshots',
        id: reserved.data.id,
        attributes: {
          uploaded: true,
          sourceFileChecksum: checksum,
        },
      },
    },
  })
  const verified = await waitForScreenshot(reserved.data.id)
  console.log(`Uploaded and verified screenshot ${fileName} for ${asset.displayType}.`)
  return verified
}

async function ensureStoreScreenshots(version) {
  const localization = await findStoreLocalization(version)
  const preparedByDisplayType = new Map()
  for (const asset of screenshotAssets) {
    const screenshotSet = await findOrCreateScreenshotSet(localization, asset.displayType)
    const screenshot = await ensureScreenshot(screenshotSet, asset)
    const prepared = preparedByDisplayType.get(asset.displayType) || { screenshotSet, screenshotIds: new Set() }
    prepared.screenshotIds.add(screenshot.id)
    preparedByDisplayType.set(asset.displayType, prepared)
  }

  // Remove stale screenshots only after every replacement is uploaded and
  // COMPLETE. This prevents a transient upload failure from leaving the store
  // listing without a usable screenshot set.
  for (const [displayType, prepared] of preparedByDisplayType) {
    const current = await listScreenshots(prepared.screenshotSet)
    const stale = current.filter((screenshot) => !prepared.screenshotIds.has(screenshot.id))
    for (const screenshot of stale) {
      await apiRequest(`/appScreenshots/${encodeURIComponent(screenshot.id)}`, { method: 'DELETE' })
      console.log(
        `Removed stale screenshot ${screenshot.attributes?.fileName || screenshot.id} from ${displayType}.`,
      )
    }
  }
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

async function listSubmissionItems(submission) {
  const response = await apiRequest(apiPath(`/reviewSubmissions/${encodeURIComponent(submission.id)}/items`, {
    'fields[reviewSubmissionItems]': 'state,appStoreVersion',
    limit: 200,
  }))
  return response.data
}

async function findVersionSubmission(version) {
  const response = await apiRequest(apiPath(`/apps/${encodeURIComponent(config.appId)}/reviewSubmissions`, {
    'fields[reviewSubmissions]': 'platform,state,items,appStoreVersionForReview',
    limit: 200,
  }))
  const editableStates = new Set(['READY_FOR_REVIEW', 'UNRESOLVED_ISSUES'])
  const matches = []

  for (const submission of response.data.filter((candidate) => editableStates.has(candidate.attributes?.state))) {
    const items = await listSubmissionItems(submission)
    const item = items.find((candidate) =>
      candidate.attributes?.state !== 'REMOVED' &&
      candidate.relationships?.appStoreVersion?.data?.id === version.id)
    if (item) matches.push({ submission, item })
  }

  if (matches.length > 1) {
    throw new Error(`App Store version ${config.appVersion} appears in multiple editable review submissions.`)
  }
  return matches[0] || null
}

async function readSubmissionContents(submissionId) {
  const response = await apiRequest(apiPath(`/reviewSubmissions/${encodeURIComponent(submissionId)}`, {
    'fields[reviewSubmissions]': 'platform,state,items,appStoreVersionForReview',
  }))
  const items = await listSubmissionItems(response.data)
  return { submission: response.data, items }
}

function owningSubmissionBlocker(error) {
  if (!(error instanceof AppStoreConnectError)) return null
  const blockers = new Map()
  for (const apiError of error.errors || []) {
    const associatedErrors = apiError.meta?.associatedErrors || {}
    for (const [resourcePath, issues] of Object.entries(associatedErrors)) {
      const resourceMatch = resourcePath.match(/^\/appStoreVersions\/([^/]+)$/)
      if (!resourceMatch) continue
      if (!Array.isArray(issues)) continue
      for (const issue of issues) {
        if (issue.code !== 'STATE_ERROR.ITEM_PART_OF_ANOTHER_SUBMISSION') continue
        const match = String(issue.detail || '').match(/reviewSubmission with id ([0-9a-f-]{36})/i)
        if (!match) continue
        const blocker = {
          appStoreVersionId: resourceMatch[1],
          submissionId: match[1],
        }
        blockers.set(`${blocker.appStoreVersionId}:${blocker.submissionId}`, blocker)
      }
    }
  }
  return blockers.size === 1 ? [...blockers.values()][0] : null
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
  const items = await listSubmissionItems(submission)
  const existing = items.find((item) => item.relationships?.appStoreVersion?.data?.id === version.id)
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

async function resolveRejectedSubmissionItem(item) {
  const state = item.attributes?.state || 'UNKNOWN'
  if (state === 'READY_FOR_REVIEW') return item
  if (state !== 'REJECTED') {
    throw new Error(`App Store review item ${item.id} cannot be resubmitted from state ${state}.`)
  }

  const response = await apiRequest(`/reviewSubmissionItems/${encodeURIComponent(item.id)}`, {
    method: 'PATCH',
    body: {
      data: {
        type: 'reviewSubmissionItems',
        id: item.id,
        attributes: { resolved: true },
      },
    },
  })
  console.log(`Marked rejected App Store version ${config.appVersion} resolved in its existing review submission.`)
  return response.data
}

async function removeRejectedLegacySubmissionItem(placement, currentVersion) {
  const submissionState = placement.submission.attributes?.state || 'UNKNOWN'
  const itemState = placement.item.attributes?.state || 'UNKNOWN'
  const legacyVersionId = placement.item.relationships?.appStoreVersion?.data?.id
  if (submissionState !== 'UNRESOLVED_ISSUES' || itemState !== 'REJECTED') {
    throw new Error(
      `Cannot remove blocking App Store version ${legacyVersionId || 'UNKNOWN'} from ` +
      `submission state ${submissionState} and item state ${itemState}.`,
    )
  }
  if (!legacyVersionId || legacyVersionId === currentVersion.id) {
    throw new Error('Legacy rejection cleanup must not remove the current App Store version item.')
  }

  await apiRequest(`/reviewSubmissionItems/${encodeURIComponent(placement.item.id)}`, {
    method: 'PATCH',
    body: {
      data: {
        type: 'reviewSubmissionItems',
        id: placement.item.id,
        attributes: { removed: true },
      },
    },
  })
  console.log(
    `Removed rejected legacy App Store version ${legacyVersionId} from unresolved review submission ` +
    `${placement.submission.id}; no app version or build was deleted.`,
  )
}

async function addSubmissionItemAfterLegacyRemoval(submission, version) {
  let lastError = null
  for (let attempt = 1; attempt <= 6; attempt += 1) {
    try {
      return await ensureSubmissionItem(submission, version)
    } catch (error) {
      lastError = error
      if (!(error instanceof AppStoreConnectError) || error.status !== 409 || attempt === 6) throw error
      await sleep(attempt * 1_000)
    }
  }
  throw lastError || new Error('Unable to add the current App Store version after legacy rejection cleanup.')
}

async function cancelLegacyVersionSubmission(contents, blocker, currentVersion) {
  const submissionState = contents.submission.attributes?.state || 'UNKNOWN'
  const legacyVersionId = contents.submission.relationships?.appStoreVersionForReview?.data?.id
  const activeItems = contents.items.filter((item) => item.attributes?.state !== 'REMOVED')
  if (submissionState !== 'UNRESOLVED_ISSUES') {
    throw new Error(`Cannot cancel legacy review submission from state ${submissionState}.`)
  }
  if (legacyVersionId !== blocker.appStoreVersionId || legacyVersionId === currentVersion.id) {
    throw new Error(
      'Legacy review submission relationship mismatch: ' +
      `relation=${legacyVersionId || 'NONE'}, blocker=${blocker.appStoreVersionId}, ` +
      `current=${currentVersion.id}, activeItems=${activeItems.length}.`,
    )
  }
  if (activeItems.length !== 0) {
    throw new Error('Legacy review submission contains other active items; refusing to cancel it implicitly.')
  }

  await apiRequest(`/reviewSubmissions/${encodeURIComponent(contents.submission.id)}`, {
    method: 'PATCH',
    body: {
      data: {
        type: 'reviewSubmissions',
        id: contents.submission.id,
        attributes: { canceled: true },
      },
    },
  })
  console.log(
    `Canceled legacy unresolved review submission ${contents.submission.id} for old App Store version ` +
    `${legacyVersionId}; no app version or build was deleted.`,
  )

  for (let attempt = 1; attempt <= 12; attempt += 1) {
    const refreshed = await readSubmissionContents(contents.submission.id)
    const state = refreshed.submission.attributes?.state || 'UNKNOWN'
    if (state === 'COMPLETE') return
    if (state !== 'CANCELING' && state !== 'UNRESOLVED_ISSUES') {
      throw new Error(`Legacy review submission moved to unexpected state ${state} after cancellation.`)
    }
    await sleep(2_000)
  }
  throw new Error('Timed out waiting for the legacy review submission cancellation to complete.')
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
await ensureStoreScreenshots(version)

await appendOutput('app_store_version_id', version.id)
if (config.prepareOnly) {
  console.log('App Store preparation completed. PREPARE_ONLY is present, so this run will not submit for review.')
  await appendOutput('app_store_state', 'PREPARED_NOT_SUBMITTED')
  process.exit(0)
}

let placement = await findVersionSubmission(version)
if (placement) {
  console.log(
    `Reusing review submission ${placement.submission.id} in state ${placement.submission.attributes?.state || 'UNKNOWN'}.`,
  )
} else {
  const submission = await findOrCreateDraftSubmission()
  try {
    const item = await ensureSubmissionItem(submission, version)
    placement = { submission, item }
  } catch (error) {
    const blocker = owningSubmissionBlocker(error)
    if (!blocker) throw error
    const blockingContents = await readSubmissionContents(blocker.submissionId)
    const blockingItem = blockingContents.items.find((candidate) =>
      candidate.attributes?.state !== 'REMOVED' &&
      candidate.relationships?.appStoreVersion?.data?.id === blocker.appStoreVersionId)
    if (blockingItem && blocker.appStoreVersionId === version.id) {
      const blockingPlacement = { submission: blockingContents.submission, item: blockingItem }
      placement = blockingPlacement
      console.log(
        `Recovered existing review submission ${blocker.submissionId} from Apple's item ownership response; ` +
        `state ${placement.submission.attributes?.state || 'UNKNOWN'}.`,
      )
    } else if (blockingItem) {
      const blockingPlacement = { submission: blockingContents.submission, item: blockingItem }
      await removeRejectedLegacySubmissionItem(blockingPlacement, version)
      const item = await addSubmissionItemAfterLegacyRemoval(submission, version)
      placement = { submission, item }
    } else {
      await cancelLegacyVersionSubmission(blockingContents, blocker, version)
      const item = await addSubmissionItemAfterLegacyRemoval(submission, version)
      placement = { submission, item }
    }
  }
}
await resolveRejectedSubmissionItem(placement.item)
const submission = placement.submission
const submissionState = await submitReview(submission)
console.log(`Submitted ${config.appVersion} (${config.appBuild}) to App Review; state: ${submissionState}.`)

await appendOutput('review_submission_id', submission.id)
await appendOutput('app_store_state', submissionState)
