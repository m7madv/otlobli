import fs from 'node:fs'
import path from 'node:path'
import { createHash } from 'node:crypto'

const root = process.argv[2]
const output = process.argv.find((argument) => argument.startsWith('--output='))
  ?.slice('--output='.length)

if (!root || !output) {
  throw new Error('Usage: node scripts/inspect-shein-webkit-cache.mjs <NetworkCache> --output=<cache-analysis.json>')
}

const assetPattern = /https:\/\/sheinm\.ltwebstatic\.com\/pwa_dist\/assets\/[A-Za-z0-9._~%/-]+\.js/gi
const hex40Pattern = /\b[A-Fa-f0-9]{40}\b/g

function filesBelow(directory) {
  if (!fs.existsSync(directory)) return []
  const found = []
  const pending = [directory]
  while (pending.length) {
    const current = pending.pop()
    for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
      const target = path.join(current, entry.name)
      if (entry.isDirectory()) pending.push(target)
      else if (entry.isFile()) found.push(target)
    }
  }
  return found
}

function sanitizeUrl(raw) {
  try {
    const value = new URL(raw)
    return `${value.origin}${value.pathname}`
  } catch {
    return ''
  }
}

const files = filesBelow(root)
const names = new Set(files.map((file) => path.basename(file).toUpperCase()))
const records = []

for (const file of files) {
  const relativePath = path.relative(root, file).replaceAll('\\', '/')
  if (/\/Blobs\//i.test(`/${relativePath}`) || /-blob$/i.test(relativePath)) continue
  const bytes = fs.readFileSync(file)
  const text = bytes.toString('latin1')
  const urls = [...new Set((text.match(assetPattern) ?? []).map(sanitizeUrl).filter(Boolean))]
  if (!urls.length) continue

  const hashes = [...new Set(text.match(hex40Pattern) ?? [])].map((value) => value.toUpperCase())
  const referencedBlobNames = hashes.filter((value) => names.has(value) || names.has(`${value}-BLOB`))
  const companionBlob = files.find((candidate) => candidate.toUpperCase() === `${file}-BLOB`.toUpperCase())
  const mimeMatches = [...new Set([
    ...(text.match(/(?:application|text)\/(?:javascript|x-javascript|ecmascript|plain)/gi) ?? []),
  ].map((value) => value.toLowerCase()))]
  const statusCandidates = [...new Set((text.match(/\b(?:200|204|206|301|302|304|400|403|404|500)\b/g) ?? [])
    .map(Number))]
  const headerNames = [...new Set((text.match(/(?:content-type|content-length|etag|last-modified|cache-control|age|date|expires)/gi) ?? [])
    .map((value) => value.toLowerCase()))]

  records.push({
    relativePath,
    recordSize: bytes.length,
    recordSHA256: createHash('sha256').update(bytes).digest('hex'),
    canonicalSanitizedUrls: urls,
    mimeCandidates: mimeMatches,
    statusCandidates,
    headerNamesObserved: headerNames,
    companionBlob: companionBlob ? path.relative(root, companionBlob).replaceAll('\\', '/') : null,
    referencedBlobNames,
    bodyOrBlobPresence: Boolean(companionBlob || referencedBlobNames.length),
  })
}

const report = {
  generatedAt: new Date().toISOString(),
  networkCacheRoot: path.resolve(root),
  totalFilesScanned: files.length,
  matchingRecordCount: records.length,
  matchingRecordsWithBodyOrBlobEvidence: records.filter((record) => record.bodyOrBlobPresence).length,
  matchingRecordsWithoutBodyOrBlobEvidence: records.filter((record) => !record.bodyOrBlobPresence).length,
  textPlainRecordsWithoutBodyOrBlobEvidence: records.filter((record) =>
    record.mimeCandidates.includes('text/plain') && !record.bodyOrBlobPresence).length,
  records,
  limitations: [
    'Status and MIME values are conservative candidates extracted from WebKit binary record metadata.',
    'Body presence is proven only by a companion or referenced blob filename; absence is not interpreted as poisoning without matching network and runtime evidence.',
    'URLs are stored without query strings or fragments.',
  ],
}

fs.writeFileSync(output, `${JSON.stringify(report, null, 2)}\n`)
