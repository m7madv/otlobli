const APP_CALLBACK = 'otlobli://apple-auth'
const MAX_BODY_BYTES = 16 * 1024

const responseHeaders = {
  'Cache-Control': 'no-store, max-age=0',
  Pragma: 'no-cache',
  'Referrer-Policy': 'no-referrer',
  'X-Content-Type-Options': 'nosniff',
}

function text(message: string, status: number): Response {
  return new Response(message, {
    status,
    headers: { ...responseHeaders, 'content-type': 'text/plain; charset=utf-8' },
  })
}

function bounded(value: FormDataEntryValue | string | null, maxLength: number): string {
  return typeof value === 'string' ? value.trim().slice(0, maxLength) : ''
}

function safeState(value: string): boolean {
  return value.length >= 16 && value.length <= 512 && /^[A-Za-z0-9._~-]+$/.test(value)
}

function redirectToApp(params: URLSearchParams): Response {
  const target = `${APP_CALLBACK}?${params.toString()}`
  return new Response(null, {
    status: 303,
    headers: { ...responseHeaders, Location: target },
  })
}

Deno.serve(async (req) => {
  if (req.method !== 'POST' && req.method !== 'GET') {
    return text('Method not allowed', 405)
  }

  const contentLength = Number(req.headers.get('content-length') ?? 0)
  if (Number.isFinite(contentLength) && contentLength > MAX_BODY_BYTES) {
    return text('Request too large', 413)
  }

  let input: URLSearchParams
  try {
    if (req.method === 'POST') {
      const contentType = req.headers.get('content-type')?.toLowerCase() ?? ''
      if (!contentType.startsWith('application/x-www-form-urlencoded')) {
        return text('Unsupported content type', 415)
      }
      const rawBody = await req.text()
      if (new TextEncoder().encode(rawBody).byteLength > MAX_BODY_BYTES) {
        return text('Request too large', 413)
      }
      input = new URLSearchParams(rawBody)
    } else {
      input = new URL(req.url).searchParams
    }
  } catch {
    return text('Invalid authorization response', 400)
  }

  const state = bounded(input.get('state'), 512)
  if (!safeState(state)) {
    return text('Invalid authorization state', 400)
  }

  const error = bounded(input.get('error'), 128)
  if (error) {
    const output = new URLSearchParams({
      error: /^[A-Za-z0-9._~-]+$/.test(error) ? error : 'apple_authorization_failed',
      state,
    })
    const description = bounded(input.get('error_description'), 512)
    if (description) output.set('error_description', description)
    return redirectToApp(output)
  }

  const code = bounded(input.get('code'), 4096)
  if (!code) {
    return redirectToApp(new URLSearchParams({ error: 'missing_authorization_code', state }))
  }

  return redirectToApp(new URLSearchParams({ success: 'true', code, state }))
})
