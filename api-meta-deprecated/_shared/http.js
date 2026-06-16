export class ApiError extends Error {
  constructor(code, status, message) {
    super(message ?? code)
    this.code = code
    this.status = status
  }
}

export function sendJson(res, status, payload) {
  res.statusCode = status
  res.setHeader('Content-Type', 'application/json; charset=utf-8')
  res.end(JSON.stringify(payload))
}

export function sendError(res, error) {
  if (error instanceof ApiError) {
    sendJson(res, error.status, {
      error: error.code,
      message: error.message,
    })
    return
  }

  console.error('api_server_error', error)
  sendJson(res, 500, {
    error: 'server_error',
    message: 'حدث خطأ داخلي في الخادم.',
  })
}

export function ensurePost(req, res) {
  if (req.method === 'OPTIONS') {
    sendJson(res, 200, { ok: true })
    return false
  }

  if (req.method !== 'POST') {
    sendJson(res, 405, { error: 'method_not_allowed' })
    return false
  }

  return true
}

export async function readJsonBody(req) {
  const rawBody = await readRawBody(req)
  return parseJson(rawBody)
}

export async function readRawBody(req) {
  let body

  try {
    body = req.body
  } catch {
    throw new ApiError('invalid_json', 400, 'صيغة الطلب غير صحيحة.')
  }

  if (body && typeof body === 'object') {
    return JSON.stringify(body)
  }

  if (typeof body === 'string') {
    return body
  }

  const chunks = []

  for await (const chunk of req) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(String(chunk)))
  }

  return Buffer.concat(chunks).toString('utf8')
}

export function getString(body, key) {
  const value = body[key]
  return typeof value === 'string' ? value.trim() : ''
}

function parseJson(value) {
  if (!value.trim()) {
    return {}
  }

  let parsed

  try {
    parsed = JSON.parse(value)
  } catch {
    throw new ApiError('invalid_json', 400, 'صيغة الطلب غير صحيحة.')
  }

  if (!parsed || typeof parsed !== 'object') {
    throw new ApiError('invalid_json', 400, 'صيغة الطلب غير صحيحة.')
  }

  return parsed
}
