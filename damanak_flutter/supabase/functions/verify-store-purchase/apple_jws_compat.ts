import { Buffer } from "node:buffer";
// @ts-types="npm:@types/jsrsasign@10.5.15"
import { KJUR, X509 } from "jsrsasign";

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
const basicConstraintsOidKey = "551d13";
const ecPublicKeyOidKey = "2a8648ce3d0201";
const rsaPublicKeyOidKey = "2a864886f70d010101";
const p256CurveOidKey = "2a8648ce3d030107";
const sha1WithRsaOidKey = "2a864886f70d010105";
const supportedEcCurveOidKeys = new Set([
  p256CurveOidKey,
  // secp384r1 and secp521r1 are used by pinned/trusted PKI roots.
  "2b81040022",
  "2b81040023",
]);
const supportedCertificateSignatureOidKeys = new Set([
  // sha1WithRSAEncryption is needed only to parse Apple's independently
  // pinned legacy root. Root self-signatures never establish trust here.
  sha1WithRsaOidKey,
  // ecdsa-with-SHA256/SHA384/SHA512
  "2a8648ce3d040302",
  "2a8648ce3d040303",
  "2a8648ce3d040304",
  // sha256WithRSAEncryption/sha384WithRSAEncryption/sha512WithRSAEncryption
  "2a864886f70d01010b",
  "2a864886f70d01010c",
  "2a864886f70d01010d",
]);
const rsaCertificateSignatureOidKeys = new Set([
  "2a864886f70d010105",
  "2a864886f70d01010b",
  "2a864886f70d01010c",
  "2a864886f70d01010d",
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
  isCa: boolean;
  publicKeyKind: "ec" | "rsa";
  publicKeyCurveOid: string | null;
  signatureAlgorithmOid: string;
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
  const extensionValues = new Map<string, Uint8Array>();
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
    const value = fields[valueIndex];
    if (value.tag !== 0x04) reject();
    extensionValues.set(key, bytes.subarray(value.valueStart, value.end));
  }
  return { extensionOids, extensionValues };
}

function parseBasicConstraints(
  extensionValues: ReadonlyMap<string, Uint8Array>,
) {
  const encoded = extensionValues.get(basicConstraintsOidKey);
  if (encoded == null) return false;
  const sequence = readDerElement(encoded, 0, encoded.byteLength);
  if (sequence.tag !== 0x30 || sequence.end !== encoded.byteLength) reject();
  const fields = derChildren(encoded, sequence);
  if (fields.length === 0) return false;
  if (fields.length > 2) reject();

  const ca = fields[0];
  if (
    ca.tag !== 0x01 || ca.end - ca.valueStart !== 1 ||
    encoded[ca.valueStart] !== 0xff
  ) {
    // BasicConstraints.ca has a DEFAULT of FALSE, so DER must omit it rather
    // than encoding FALSE explicitly. pathLenConstraint also requires CA.
    reject();
  }
  if (fields.length === 2) {
    const pathLength = fields[1];
    if (
      pathLength.tag !== 0x02 || pathLength.valueStart === pathLength.end ||
      (encoded[pathLength.valueStart] & 0x80) !== 0 ||
      (pathLength.end - pathLength.valueStart > 1 &&
        encoded[pathLength.valueStart] === 0x00 &&
        (encoded[pathLength.valueStart + 1] & 0x80) === 0)
    ) {
      reject();
    }
  }
  return true;
}

function parseCertificateSignatureAlgorithm(
  bytes: Uint8Array,
  algorithm: DerElement,
) {
  if (algorithm.tag !== 0x30) reject();
  const fields = derChildren(bytes, algorithm);
  if (fields.length < 1 || fields.length > 2) reject();
  const key = oidKey(bytes, fields[0]);
  if (!supportedCertificateSignatureOidKeys.has(key)) reject();
  if (rsaCertificateSignatureOidKeys.has(key)) {
    if (
      fields.length === 2 &&
      (fields[1].tag !== 0x05 || fields[1].valueStart !== fields[1].end)
    ) {
      reject();
    }
  } else if (fields.length !== 1) {
    reject();
  }
  return key;
}

function parseSubjectPublicKeyInfo(bytes: Uint8Array, spki: DerElement) {
  if (spki.tag !== 0x30) reject();
  const fields = derChildren(bytes, spki);
  if (fields.length !== 2 || fields[0].tag !== 0x30 || fields[1].tag !== 0x03) {
    reject();
  }
  const keyBits = fields[1];
  if (
    keyBits.end - keyBits.valueStart < 2 || bytes[keyBits.valueStart] !== 0x00
  ) {
    reject();
  }

  const algorithm = derChildren(bytes, fields[0]);
  if (algorithm.length < 1 || algorithm.length > 2) reject();
  const keyOid = oidKey(bytes, algorithm[0]);
  if (keyOid === ecPublicKeyOidKey) {
    if (algorithm.length !== 2 || algorithm[1].tag !== 0x06) reject();
    const curveOid = oidKey(bytes, algorithm[1]);
    if (!supportedEcCurveOidKeys.has(curveOid)) reject();
    const expectedPointBytes = curveOid === p256CurveOidKey
      ? 65
      : curveOid === "2b81040022"
      ? 97
      : 133;
    if (
      keyBits.end - keyBits.valueStart - 1 !== expectedPointBytes ||
      bytes[keyBits.valueStart + 1] !== 0x04
    ) {
      reject();
    }
    return { publicKeyKind: "ec" as const, publicKeyCurveOid: curveOid };
  }
  if (keyOid !== rsaPublicKeyOidKey) reject();
  if (
    algorithm.length === 2 &&
    (algorithm[1].tag !== 0x05 || algorithm[1].valueStart !== algorithm[1].end)
  ) {
    reject();
  }
  const rsaStart = keyBits.valueStart + 1;
  const rsaKey = readDerElement(bytes, rsaStart, keyBits.end);
  if (rsaKey.tag !== 0x30 || rsaKey.end !== keyBits.end) reject();
  const rsaFields = derChildren(bytes, rsaKey);
  if (
    rsaFields.length !== 2 || rsaFields[0].tag !== 0x02 ||
    rsaFields[1].tag !== 0x02
  ) {
    reject();
  }
  for (const integer of rsaFields) {
    if (
      integer.valueStart === integer.end ||
      (bytes[integer.valueStart] & 0x80) !== 0 ||
      (integer.end - integer.valueStart > 1 &&
        bytes[integer.valueStart] === 0x00 &&
        (bytes[integer.valueStart + 1] & 0x80) === 0)
    ) {
      reject();
    }
  }
  return { publicKeyKind: "rsa" as const, publicKeyCurveOid: null };
}

function parseCertificateDer(bytes: Uint8Array): ParsedCertificate {
  const certificate = readDerElement(bytes, 0, bytes.byteLength);
  if (certificate.tag !== 0x30 || certificate.end !== bytes.byteLength) {
    reject();
  }
  const certificateFields = derChildren(bytes, certificate);
  if (
    certificateFields.length !== 3 || certificateFields[0].tag !== 0x30 ||
    certificateFields[1].tag !== 0x30 || certificateFields[2].tag !== 0x03
  ) {
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

  if (
    !equalBytes(
      elementBytes(bytes, tbsFields[index + 1]),
      elementBytes(bytes, certificateFields[1]),
    )
  ) {
    reject();
  }
  const signatureAlgorithmOid = parseCertificateSignatureAlgorithm(
    bytes,
    certificateFields[1],
  );
  const certificateSignature = certificateFields[2];
  if (
    certificateSignature.end - certificateSignature.valueStart < 2 ||
    bytes[certificateSignature.valueStart] !== 0x00
  ) {
    reject();
  }
  const publicKey = parseSubjectPublicKeyInfo(bytes, tbsFields[index + 5]);

  const extensionWrappers = tbsFields.filter((field) => field.tag === 0xa3);
  if (
    extensionWrappers.length !== 1 ||
    extensionWrappers[0].end !== certificateFields[0].end
  ) {
    reject();
  }
  const { extensionOids, extensionValues } = parseExtensions(
    bytes,
    extensionWrappers[0],
  );
  return {
    issuerName: elementBytes(bytes, issuer),
    subjectName: elementBytes(bytes, subject),
    validFromMs: parseDerTime(bytes, validity[0]),
    validToMs: parseDerTime(bytes, validity[1]),
    extensionOids,
    isCa: parseBasicConstraints(extensionValues),
    publicKeyKind: publicKey.publicKeyKind,
    publicKeyCurveOid: publicKey.publicKeyCurveOid,
    signatureAlgorithmOid,
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

function parseJsrsasignCertificate(der: Uint8Array) {
  const certificate = new X509();
  certificate.readCertHex(Buffer.from(der).toString("hex"));
  return certificate;
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
    const parsedLeaf = parseCertificateDer(leafDer);
    const parsedIntermediate = parseCertificateDer(intermediateDer);
    const leaf = parseJsrsasignCertificate(leafDer);
    const intermediate = parseJsrsasignCertificate(intermediateDer);
    const signedDate = payload.signedDate as number;

    if (
      parsedLeaf.isCa ||
      !parsedIntermediate.isCa ||
      parsedLeaf.signatureAlgorithmOid === sha1WithRsaOidKey ||
      parsedIntermediate.signatureAlgorithmOid === sha1WithRsaOidKey ||
      !equalBytes(parsedLeaf.issuerName, parsedIntermediate.subjectName) ||
      !leaf.verifySignature(intermediate.getPublicKey()) ||
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
        const parsedRoot = parseCertificateDer(trustedRootDer);
        const root = parseJsrsasignCertificate(trustedRootDer);
        if (
          parsedRoot.isCa &&
          equalBytes(parsedIntermediate.issuerName, parsedRoot.subjectName) &&
          intermediate.verifySignature(root.getPublicKey()) &&
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

    if (
      parsedLeaf.publicKeyKind !== "ec" ||
      parsedLeaf.publicKeyCurveOid !== p256CurveOidKey
    ) {
      reject();
    }
    const verified = KJUR.jws.JWS.verify(
      signedTransaction,
      leaf.getPublicKey() as Parameters<typeof KJUR.jws.JWS.verify>[1],
      ["ES256"],
    );
    if (!verified) reject();
    return payload;
  } catch (error) {
    if (error instanceof AppleJwsCompatibilityError) throw error;
    throw new AppleJwsCompatibilityError();
  }
}
