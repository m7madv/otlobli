import { createHash } from 'node:crypto'
import { readdir, readFile, stat } from 'node:fs/promises'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { screenshotManifest } from './app-store-screenshot-manifest.mjs'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const assetRoot = resolve(root, 'store-assets', 'app-store')
const prepareOnlyMarker = resolve(assetRoot, 'PREPARE_ONLY')
const forbiddenName = /(login|auth|otp|password)/i
const rejectedLoginHashes = new Set([
  '96739F877AF74B5020A75729CAD9883A5C382792FE9F93DEDE8836A00F4E0E26',
  '2E599C6EBC2C7D242D7B316DE43D7A334D1F98FA79B947119431B14868CE0442',
])

function pngDimensions(buffer, fileName) {
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])
  if (buffer.length < 24 || !buffer.subarray(0, 8).equals(signature)) {
    throw new Error(`${fileName} is not a valid PNG file.`)
  }
  return {
    width: buffer.readUInt32BE(16),
    height: buffer.readUInt32BE(20),
  }
}

if (screenshotManifest.length < 4) {
  throw new Error('App Store review requires feature screenshots for both iPhone and iPad.')
}

const prepareOnlyInfo = await stat(prepareOnlyMarker)
if (!prepareOnlyInfo.isFile()) {
  throw new Error('PREPARE_ONLY must remain present until physical App Review acceptance tests pass.')
}

const manifestNames = new Set()
const displayCounts = new Map()
for (const asset of screenshotManifest) {
  if (manifestNames.has(asset.fileName)) throw new Error(`Duplicate screenshot manifest entry: ${asset.fileName}`)
  manifestNames.add(asset.fileName)
  displayCounts.set(asset.displayType, (displayCounts.get(asset.displayType) || 0) + 1)
  if (forbiddenName.test(asset.fileName)) throw new Error(`Authentication screenshot is forbidden: ${asset.fileName}`)

  const assetPath = resolve(assetRoot, asset.fileName)
  const fileInfo = await stat(assetPath)
  if (!fileInfo.isFile() || fileInfo.size < 50_000) throw new Error(`Screenshot is empty or implausibly small: ${asset.fileName}`)
  const buffer = await readFile(assetPath)
  const dimensions = pngDimensions(buffer, asset.fileName)
  if (dimensions.width !== asset.width || dimensions.height !== asset.height) {
    throw new Error(
      `${asset.fileName} must be ${asset.width}x${asset.height}; found ${dimensions.width}x${dimensions.height}.`,
    )
  }
  const hash = createHash('sha256').update(buffer).digest('hex').toUpperCase()
  if (rejectedLoginHashes.has(hash)) throw new Error(`Rejected login-only screenshot is still present: ${asset.fileName}`)
}

for (const displayType of ['APP_IPHONE_65', 'APP_IPAD_PRO_3GEN_129']) {
  if ((displayCounts.get(displayType) || 0) < 2) {
    throw new Error(`At least two feature screenshots are required for ${displayType}.`)
  }
}

const unlistedPngs = (await readdir(assetRoot))
  .filter((fileName) => fileName.toLowerCase().endsWith('.png') && !manifestNames.has(fileName))
if (unlistedPngs.length) {
  throw new Error(`Remove unlisted App Store screenshots before release: ${unlistedPngs.join(', ')}`)
}

const submissionSource = await readFile(resolve(root, 'scripts', 'submit-app-store-review.mjs'), 'utf8')
if (/otlobli-(?:iphone|ipad)[^'"\n]*login\.png/i.test(submissionSource)) {
  throw new Error('App Store submission still references a login-only screenshot.')
}

console.log(`App Store screenshot assets verified (${screenshotManifest.length} feature screenshots).`)
