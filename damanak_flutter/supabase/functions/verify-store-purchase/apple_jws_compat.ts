import { Buffer } from "node:buffer";
import { verify as verifyCryptoSignature, X509Certificate } from "node:crypto";

const maxJwsBytes = 32 * 1024;
const maxCertificateBytes = 12 * 1024;
const certificateDateSkewMs = 60_000;
const appleLeafSigningOid = Uint8Array.from([
  0x2a,
  0x86,
  0x48,
  0x86,
  0xf7,
  0x63,
  0x64,
  0x06,
  0x0b,
  0x01,
]);
const appleIntermediateOid = Uint8Array.from([
  0x2a,
  0x86,
  0x48,
  0x86,
  0xf7,
  0x63,
  0x64,
  0x06,
  0x02,
  0x01,
]);

type AppleEnvironment = "sandbox" | "production";

type DerElement = Readonly<{
  tag: number;
  start: number;
  valueStart: number;
  end: number;
}>;

type ParsedCertificate = Readonly<{
  issuerName: Uint8Array;
  subjectName: Uint8Array;
  validFromMs: number;
  validToMs: number;
  extensionOids: ReadonlySet<string>;
}>;

export type AppleJwsCompatibilityOptions = Readonly<{
  bundleId: string;
  environment: AppleEnvironment;
  trustedRoots: readonly Uint8Array[];
}>;

export class AppleJwsCompatibilityError extends Error {
  constructor() {
    super("APPLE_JWS_COMPATIBILITY_REJECTED");
    this.name = "AppleJwsCompatibilityError";
  }
}

function reject(): never {
  throw new AppleJwsCompatibilityError();
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function equalBytes(left: Uint8Array, right: Uint8Array) {
  if (left.byteLength !== right.byteLength) return false;
  for (let index = 0; index < left.byteLength; index += 1) {
    if (left[index] !== right[index]) return false;
  }
  return true;
}

function readDerElement(
  bytes: Uint8Array,
  start: number,
  limit: number,
): DerElement {
  if (start < 0 || limit > bytes.byteLength || start + 2 > limit) reject();
  const tag = bytes[start];
  // Every tag needed for an X.509 certificate fits in the low-tag-number form.
  if ((tag & 0x1f) === 0x1f) reject();

  const firstLengthByte = bytes[start + 1];
  let length = 0;
  let valueStart = start + 2;
  if ((firstLengthByte & 0x80) === 0) {
    length = firstLengthByte;
  } else {
    const lengthBytes = firstLengthByte & 0x7f;
    if (
      lengthBytes === 0 ||
      lengthBytes > 4 ||
      valueStart + lengthBytes > limit ||
      bytes[valueStart] === 0
    ) {
      reject();
    }
    for (let index = 0; index < lengthBytes; index += 1) {
      length = (length * 256) + bytes[valueStart + index];
    }
    if (length < 0x80 || !Number.isSafeInteger(length)) reject();
    valueStart += lengthBytes;
  }
  if (length > limit - valueStart) reject();
  return { tag, start, valueStart, end: valueStart + length };
}

function derChildren(bytes: Uint8Array, parent: DerElement) {
  const children: DerElement[] = [];
  let cursor = parent.valueStart;
  while (cursor < parent.end) {
    const child = readDerElement(bytes, cursor, parent.end);
    children.push(child);
    cursor = child.end;
  }
  if (cursor !== parent.end) reject();
  return children;
}

function elementBytes(bytes: Uint8Array, element: DerElement) {
  return bytes.subarray(element.start, element.end);
}

function oidKey(bytes: Uint8Array, element: DerElement) {
  if (element.tag !== 0x06 || element.valueStart === element.end) reject();
  return Buffer.from(bytes.subarray(element.valueStart, element.end)).toString(
    "hex",
  );
}

function parseDerTime(bytes: Uint8Array, element: DerElement) {
  if (element.tag !== 0x17 && element.tag !== 0x18) reject();
  let value = "";
  for (let index = element.valueStart; index < element.end; index += 1) {
    const byte = bytes[index];
    if (byte > 0x7f) reject();
    value += String.fromCharCode(byte);
  }
  const match = element.tag === 0x17
    ? /^(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})Z$/.exec(value)
    : /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})Z$/.exec(value);
  if (match == null) reject();

  const shortYear = Number(match[1]);
  const year = element.tag === 0x17
    ? shortYear >= 50 ? 1900 + shortYear : 2000 + shortYear
    : shortYear;
  const month = Number(match[2]);
  const day = Number(match[3]);
  const hour = Number(match[4]);
  const minute = Number(match[5]);
  const second = Number(match[6]);
  const parsed = new Date(0);
  parsed.setUTCFullYear(year, month - 1, day);
  parsed.setUTCHours(hour, minute, second, 0);
  if (
    month < 1 ||
    month > 12 ||
    day < 1 ||
    day > 31 ||
    hour > 23 ||
    minute > 59 ||
    second > 59 ||
    parsed.getUTCFullYear() !== year ||
    parsed.getUTCMonth() !== month - 1 ||
    parsed.getUTCDate() !== day ||
    parsed.getUTCHours() !== hour ||
    parsed.getUTCMinutes() !== minute ||
    parsed.getUTCSeconds() !== second
  ) {
    reject();
  }
  return parsed.getTime();
}

function parseExtensions(bytes: Uint8Array, wrapper: DerElement) {
  if (wrapper.tag !== 0xa3) reject();
  const wrapped = derChildren(bytes, wrapper);
  if (wrapped.length !== 1 || wrapped[0].tag !== 0x30) reject();

  const extensionOids = new Set<string>();
  for (const extension of derChildren(bytes, wrapped[0])) {
    if (extension.tag !== 0x30) reject();
    const fields = derChildren(bytes, extension);
    if (fields.length !== 2 && fields.length !== 3) reject();
    const key = oidKey(bytes, fields[0]);
    if (extensionOids.has(key)) reject();
    extensionOids.add(key);
    let valueIndex = 1;
    if (fields.length === 3) {
      const critical = fields[1];
      if (
        critical.tag !== 0x01 ||
        critical.end - critical.valueStart !== 1 ||
        (bytes[critical.valueStart] !== 0x00 &&
          bytes[critical.valueStart] !== 0xff)
      ) {
        reject();
      }
      valueIndex = 2;
    }
    if (fields[valueIndex].tag !== 0x04) reject();
  }
  return extensionOids;
}

function parseCertificateDer(bytes: Uint8Array): ParsedCertificate {
  const certificate = readDerElement(bytes, 0, bytes.byteLength);
  if (certificate.tag !== 0x30 || certificate.end !== bytes.byteLength) {
    reject();
  }
  const certificateFields = derChildren(bytes, certificate);
  if (certificateFields.length !== 3 || certificateFields[0].tag !== 0x30) {
    reject();
  }

  const tbsFields = derChildren(bytes, certificateFields[0]);
  let index = tbsFields[0]?.tag === 0xa0 ? 1 : 0;
  if (
    tbsFields.length < index + 7 ||
    tbsFields[index].tag !== 0x02 ||
    tbsFields[index + 1].tag !== 0x30 ||
    tbsFields[index + 2].tag !== 0x30 ||
    tbsFields[index + 3].tag !== 0x30 ||
    tbsFields[index + 4].tag !== 0x30 ||
    tbsFields[index + 5].tag !== 0x30
  ) {
    reject();
  }
  const issuer = tbsFields[index + 2];
  const validity = derChildren(bytes, tbsFields[index + 3]);
  const subject = tbsFields[index + 4];
  if (validity.length !== 2) reject();

  const extensionWrappers = tbsFields.filter((field) => field.tag === 0xa3);
  if (
    extensionWrappers.length !== 1 ||
    extensionWrappers[0].end !== certificateFields[0].end
  ) {
    reject();
  }
  return {
    issuerName: elementBytes(bytes, issuer),
    subjectName: elementBytes(bytes, subject),
    validFromMs: parseDerTime(bytes, validity[0]),
    validToMs: parseDerTime(bytes, validity[1]),
    extensionOids: parseExtensions(bytes, extensionWrappers[0]),
  };
}

function certificateValidAt(
  certificate: ParsedCertificate,
  signedDate: number,
) {
  return certificate.validFromMs <= signedDate + certificateDateSkewMs &&
    certificate.validToMs >= signedDate - certificateDateSkewMs;
}

function strictBase64Url(value: unknown, maximumBytes: number) {
  if (
    typeof value !== "string" ||
    value.length === 0 ||
    value.length % 4 === 1 ||
    !/^[A-Za-z0-9_-]+$/.test(value)
  ) {
    reject();
  }
  const decoded = Buffer.from(value, "base64url");
  if (
    decoded.byteLength > maximumBytes ||
    decoded.toString("base64url") !== value
  ) {
    reject();
  }
  return decoded;
}

function strictBase64(value: unknown, maximumBytes: number) {
  if (
    typeof value !== "string" ||
    value.length === 0 ||
    value.length % 4 !== 0 ||
    !/^[A-Za-z0-9+/]+={0,2}$/.test(value)
  ) {
    reject();
  }
  const decoded = Buffer.from(value, "base64");
  if (
    decoded.byteLength > maximumBytes || decoded.toString("base64") !== value
  ) {
    reject();
  }
  return decoded;
}

function parseJsonObject(bytes: Uint8Array) {
  let parsed: unknown;
  try {
    parsed = JSON.parse(
      new TextDecoder("utf-8", { fatal: true }).decode(bytes),
    );
  } catch {
    reject();
  }
  if (!isRecord(parsed)) reject();
  return parsed;
}

function appleOidKey(oid: Uint8Array) {
  return Buffer.from(oid).toString("hex");
}

/**
 * Deno-compatible, fail-closed verification for an Apple transaction JWS.
 *
 * The caller must supply independently pinned Apple roots and must still bind
 * the returned payload to trusted App Store Server API transaction facts.
 * x5c[2] is intentionally ignored, matching Apple's official verifier: trust
 * comes only from the separately pinned roots, never from the JWS header.
 */
export function verifyAppleTransactionJwsCompatibility(
  signedTransaction: string,
  options: AppleJwsCompatibilityOptions,
): Record<string, unknown> {
  try {
    if (
      typeof signedTransaction !== "string" ||
      Buffer.byteLength(signedTransaction, "utf8") > maxJwsBytes ||
      options.trustedRoots.length === 0
    ) {
      reject();
    }
    const segments = signedTransaction.split(".");
    if (
      segments.length !== 3 || segments.some((segment) => segment.length === 0)
    ) {
      reject();
    }
    const header = parseJsonObject(strictBase64Url(segments[0], 16 * 1024));
    const payload = parseJsonObject(strictBase64Url(segments[1], 16 * 1024));
    const signature = strictBase64Url(segments[2], 128);
    if (
      header.alg !== "ES256" ||
      (header.typ !== undefined && header.typ !== "JWT") ||
      header.crit !== undefined ||
      header.b64 !== undefined ||
      !Array.isArray(header.x5c) ||
      header.x5c.length !== 3 ||
      header.x5c.some((value) => typeof value !== "string") ||
      signature.byteLength !== 64 ||
      payload.bundleId !== options.bundleId ||
      payload.environment !==
        (options.environment === "sandbox" ? "Sandbox" : "Production") ||
      !Number.isSafeInteger(payload.signedDate) ||
      (payload.signedDate as number) <= 0
    ) {
      reject();
    }

    const leafDer = strictBase64(header.x5c[0], maxCertificateBytes);
    const intermediateDer = strictBase64(header.x5c[1], maxCertificateBytes);
    // Validate the third entry's encoding and size, but never use it for trust.
    strictBase64(header.x5c[2], maxCertificateBytes);
    const leaf = new X509Certificate(leafDer);
    const intermediate = new X509Certificate(intermediateDer);
    const parsedLeaf = parseCertificateDer(leaf.raw);
    const parsedIntermediate = parseCertificateDer(intermediate.raw);
    const signedDate = payload.signedDate as number;

    if (
      leaf.ca ||
      !intermediate.ca ||
      !equalBytes(parsedLeaf.issuerName, parsedIntermediate.subjectName) ||
      !leaf.verify(intermediate.publicKey) ||
      !parsedLeaf.extensionOids.has(appleOidKey(appleLeafSigningOid)) ||
      !parsedIntermediate.extensionOids.has(
        appleOidKey(appleIntermediateOid),
      ) ||
      !certificateValidAt(parsedLeaf, signedDate) ||
      !certificateValidAt(parsedIntermediate, signedDate)
    ) {
      reject();
    }

    let matchedRoot = false;
    for (const trustedRootDer of options.trustedRoots) {
      try {
        if (trustedRootDer.byteLength > maxCertificateBytes) continue;
        const root = new X509Certificate(trustedRootDer);
        const parsedRoot = parseCertificateDer(root.raw);
        if (
          root.ca &&
          equalBytes(parsedIntermediate.issuerName, parsedRoot.subjectName) &&
          intermediate.verify(root.publicKey) &&
          certificateValidAt(parsedRoot, signedDate)
        ) {
          matchedRoot = true;
          break;
        }
      } catch {
        // A malformed or unrelated configured root can never establish trust.
      }
    }
    if (!matchedRoot) reject();

    const leafJwk = leaf.publicKey.export({ format: "jwk" });
    if (leafJwk.kty !== "EC" || leafJwk.crv !== "P-256") reject();
    const verified = verifyCryptoSignature(
      "sha256",
      Buffer.from(`${segments[0]}.${segments[1]}`, "ascii"),
      { key: leaf.publicKey, dsaEncoding: "ieee-p1363" },
      signature,
    );
    if (!verified) reject();
    return payload;
  } catch (error) {
    if (error instanceof AppleJwsCompatibilityError) throw error;
    throw new AppleJwsCompatibilityError();
  }
}
