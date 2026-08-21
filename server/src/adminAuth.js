import crypto from 'node:crypto'

export const WHATSAPP_ADMIN_SECRET_ENV = 'WHATSAPP_ADMIN_SECRET'
export const WHATSAPP_ADMIN_SECRET_MIN_BYTES = 32

function configuredSecret() {
  return String(process.env[WHATSAPP_ADMIN_SECRET_ENV] || '')
}

export function isWhatsappAdminSecretConfigured() {
  return Buffer.byteLength(configuredSecret(), 'utf8') >= WHATSAPP_ADMIN_SECRET_MIN_BYTES
}

function suppliedSecret(req) {
  const value = req.headers?.['x-whatsapp-admin-secret']
  return Array.isArray(value) ? String(value[0] || '') : String(value || '')
}

export function requireWhatsappAdminSecret(req, res, next) {
  res.setHeader('Cache-Control', 'no-store')
  res.setHeader('Referrer-Policy', 'no-referrer')

  const expected = configuredSecret()
  if (Buffer.byteLength(expected, 'utf8') < WHATSAPP_ADMIN_SECRET_MIN_BYTES) {
    return res.status(503).json({ error: 'whatsapp_admin_not_configured' })
  }

  const supplied = suppliedSecret(req)
  const expectedBytes = Buffer.from(expected, 'utf8')
  const suppliedBytes = Buffer.from(supplied, 'utf8')
  const authorized = expectedBytes.length === suppliedBytes.length
    && crypto.timingSafeEqual(expectedBytes, suppliedBytes)

  if (!authorized) {
    return res.status(401).json({ error: 'unauthorized' })
  }

  next()
}
