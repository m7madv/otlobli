export const TARGET_PACKAGE = "com.shmacash.shamcash";
export const SIGNATURE_VERSION = "v1";
export const DEFAULT_REPLAY_WINDOW_MS = 5 * 60 * 1000;
export const DEFAULT_UNMATCHED_RETRY_WINDOW_MS = 2 * 60 * 1000;

export type PaymentCurrency = "SYP" | "USD";

export type PaymentParseResult =
  | {
    ok: true;
    amount: number;
    currency: PaymentCurrency;
    notificationText: string;
  }
  | {
    ok: false;
    reason:
      | "empty_notification"
      | "otp_notification"
      | "outgoing_payment"
      | "not_incoming_payment"
      | "currency_missing"
      | "currency_ambiguous"
      | "amount_missing"
      | "amount_ambiguous";
    notificationText: string;
  };

export type ListenerPayload = {
  packageName: string;
  title: string;
  body: string;
  bigText: string;
  notificationText: string;
  sentAt: number | null;
  eventId: string;
  deviceId: string;
};

const textEncoder = new TextEncoder();
const USD_TOKEN_SOURCE =
  "(?:usd|us\\s*dollars?|\\$|دولارات?|دولار(?:\\s+امريكي)?)";
const SYP_TOKEN_SOURCE = "(?:syp|syr|ل\\s*\\.\\s*س|ل\\s+س|ليره(?:\\s+سوريه)?)";
const NUMBER_SOURCE = "[+-]?\\d(?:[\\d\\s\\u00a0.,٬٫،]*\\d)?";

const INCOMING_PATTERN = new RegExp(
  [
    "(?:تم|تمت)\\s*(?:استلام|ايداع|اضافه)",
    "استلمت",
    "استلام",
    "ايداع",
    "(?:حواله|تحويل)\\s*(?:وارده|وارد)",
    "(?:حواله|تحويل)\\s+من\\s+(?!حسابك|محفظتك)",
    "(?:وصلت|وصلتك)\\s*(?:حواله|دفعه)?",
    "حول\\s*(?:اليك|لك)",
    "الى\\s*(?:حسابك|محفظتك)",
    "وارد",
    "incoming",
    "received",
    "credit(?:ed)?",
    "deposit",
  ].join("|"),
  "iu",
);

const OUTGOING_PATTERN = new RegExp(
  [
    "(?:تم|تمت)\\s*(?:ارسال|خصم|سحب|دفع|شراء)",
    "(?:حواله|تحويل)\\s*(?:صادره|صادر)",
    "ارسلت",
    "حولت",
    "دفعت",
    "خصم",
    "سحب",
    "شراء",
    "sent(?:\\s+payment)?",
    "outgoing",
    "debited",
    "withdrawal",
    "purchase",
  ].join("|"),
  "iu",
);

const OTP_PATTERN = new RegExp(
  [
    "(?:رمز|كود)\\s*(?:التحقق|التاكيد|الامان|الدخول)",
    "كلمه\\s*(?:المرور|السر)",
    "(?:^|[^a-z])otp(?:[^a-z]|$)",
    "(?:^|[^a-z])pin(?:[^a-z]|$)",
    "one[-\\s]?time\\s+pass",
  ].join("|"),
  "iu",
);

export function toAsciiDigits(value: string): string {
  const arabicZero = "٠".charCodeAt(0);
  const persianZero = "۰".charCodeAt(0);
  return value.replace(/[٠-٩۰-۹]/g, (digit) => {
    const code = digit.charCodeAt(0);
    if (code >= arabicZero && code <= arabicZero + 9) {
      return String(code - arabicZero);
    }
    return String(code - persianZero);
  });
}

export function normalizeForMatching(value: string): string {
  return toAsciiDigits(value)
    .normalize("NFKC")
    .replace(/[ـ\u064B-\u065F\u0670]/g, "")
    .replace(/[إأآٱ]/g, "ا")
    .replace(/ى/g, "ي")
    .replace(/ة/g, "ه")
    .toLowerCase()
    .replace(/\s+/g, " ")
    .trim();
}

function safeText(value: unknown, maxLength: number): string {
  if (typeof value !== "string") return "";
  const trimmed = [...value].filter((character) => {
    const code = character.charCodeAt(0);
    return code === 9 || code === 10 || code === 13 ||
      (code >= 32 && code !== 127);
  }).join("").trim();
  return trimmed.length <= maxLength ? trimmed : trimmed.slice(0, maxLength);
}

export function parseListenerPayload(value: unknown): ListenerPayload | null {
  if (!value || typeof value !== "object" || Array.isArray(value)) return null;
  const payload = value as Record<string, unknown>;
  const rawSentAt = payload.sentAt;
  const sentAt =
    typeof rawSentAt === "number" && Number.isSafeInteger(rawSentAt) &&
      rawSentAt > 0
      ? rawSentAt
      : null;

  return {
    packageName: safeText(payload.packageName, 160),
    title: safeText(payload.title, 256),
    body: safeText(payload.body, 1024),
    bigText: safeText(payload.bigText, 1400),
    notificationText: safeText(payload.notificationText, 1600),
    sentAt,
    eventId: safeText(payload.eventId, 128),
    deviceId: safeText(payload.deviceId, 128),
  };
}

export function notificationTextFromPayload(payload: ListenerPayload): string {
  const source = payload.notificationText ||
    [payload.title, payload.body, payload.bigText]
      .filter(Boolean)
      .join("\n");
  return source.replace(/\s+/g, " ").trim().slice(0, 1200);
}

function hasCurrency(text: string, source: string): boolean {
  return new RegExp(source, "iu").test(text);
}

function normalizeGroupedInteger(value: string): string | null {
  if (!value) return null;
  if (/\s/u.test(value)) {
    if (!/^\d{1,3}(?:[\s\u00a0]+\d{3})+$/u.test(value)) return null;
    return value.replace(/[\s\u00a0]+/gu, "");
  }
  return /^\d+$/u.test(value) ? value : null;
}

function parseLocalizedAmount(
  raw: string,
  currency: PaymentCurrency,
): number | null {
  let value = toAsciiDigits(raw).trim();
  if (!value || value.startsWith("-")) return null;
  if (value.startsWith("+")) value = value.slice(1);
  if (!/^[\d\s\u00a0.,٬٫،]+$/u.test(value)) return null;

  value = value.replace(/،/g, ",");
  const explicitDecimalCount = (value.match(/٫/g) || []).length;
  const explicitThousandsCount = (value.match(/٬/g) || []).length;

  if (explicitDecimalCount > 1) return null;
  if (explicitDecimalCount === 1) {
    const [integerRaw, fractionRaw] = value.split("٫");
    if (!/^\d{1,2}$/u.test(fractionRaw)) return null;
    const integerWithSeparators = integerRaw.replace(/٬/g, ",");
    const integerDigits = normalizePunctuationInteger(integerWithSeparators);
    if (!integerDigits) return null;
    return finalizeAmount(integerDigits, fractionRaw, currency);
  }

  if (explicitThousandsCount > 0) {
    if (/[.,]/u.test(value)) return null;
    const groups = value.split("٬");
    if (!validThousandsGroups(groups)) return null;
    return finalizeAmount(groups.join(""), "", currency);
  }

  const compactWhitespace = value.replace(/[\s\u00a0]+/gu, " ");
  if (/\s/u.test(compactWhitespace) && /[.,]/u.test(compactWhitespace)) {
    return null;
  }
  if (/\s/u.test(compactWhitespace)) {
    const integerDigits = normalizeGroupedInteger(compactWhitespace);
    return integerDigits ? finalizeAmount(integerDigits, "", currency) : null;
  }

  const dots = countCharacter(value, ".");
  const commas = countCharacter(value, ",");
  if (dots && commas) {
    const decimalSeparator = value.lastIndexOf(".") > value.lastIndexOf(",")
      ? "."
      : ",";
    const decimalIndex = value.lastIndexOf(decimalSeparator);
    const integerRaw = value.slice(0, decimalIndex);
    const fractionRaw = value.slice(decimalIndex + 1);
    if (!/^\d{1,2}$/u.test(fractionRaw)) return null;
    const integerDigits = normalizePunctuationInteger(integerRaw);
    return integerDigits
      ? finalizeAmount(integerDigits, fractionRaw, currency)
      : null;
  }

  const separator = dots ? "." : commas ? "," : "";
  if (!separator) return finalizeAmount(value, "", currency);
  const groups = value.split(separator);
  if (groups.some((group) => !/^\d+$/u.test(group))) return null;
  if (groups.length > 2) {
    if (!validThousandsGroups(groups)) return null;
    return finalizeAmount(groups.join(""), "", currency);
  }

  const [integerRaw, trailing] = groups;
  if (trailing.length === 3) {
    if (!/^\d{1,3}$/u.test(integerRaw)) return null;
    return finalizeAmount(integerRaw + trailing, "", currency);
  }
  if (trailing.length >= 1 && trailing.length <= 2) {
    return finalizeAmount(integerRaw, trailing, currency);
  }
  return null;
}

function countCharacter(value: string, character: string): number {
  return value.split(character).length - 1;
}

function validThousandsGroups(groups: string[]): boolean {
  return groups.length >= 2 &&
    /^\d{1,3}$/u.test(groups[0]) &&
    groups.slice(1).every((group) => /^\d{3}$/u.test(group));
}

function normalizePunctuationInteger(value: string): string | null {
  if (/^\d+$/u.test(value)) return value;
  if (/\s/u.test(value)) return null;
  const separator = value.includes(",") ? "," : value.includes(".") ? "." : "";
  if (!separator || (value.includes(",") && value.includes("."))) return null;
  const groups = value.split(separator);
  return validThousandsGroups(groups) ? groups.join("") : null;
}

function finalizeAmount(
  integerDigits: string,
  fractionDigits: string,
  currency: PaymentCurrency,
): number | null {
  if (!/^\d+$/u.test(integerDigits)) return null;
  if (
    currency === "SYP" && fractionDigits && !/^0{1,2}$/u.test(fractionDigits)
  ) return null;
  const raw = fractionDigits
    ? `${integerDigits}.${fractionDigits}`
    : integerDigits;
  const amount = Number(raw);
  if (!Number.isFinite(amount) || amount <= 0 || amount > 99_999_999_999) {
    return null;
  }
  if (currency === "SYP") return Math.round(amount);
  return Math.round(amount * 100) / 100;
}

function collectAmounts(text: string, currency: PaymentCurrency): number[] {
  const currencySource = currency === "USD"
    ? USD_TOKEN_SOURCE
    : SYP_TOKEN_SOURCE;
  const patterns = [
    new RegExp(`(${NUMBER_SOURCE})\\s*(?:${currencySource})`, "giu"),
    new RegExp(
      `(?:${currencySource})\\s*(?:(?:مبلغ|قيمه|بقيمة|بقيمة)\\s*)?[:：-]?\\s*(${NUMBER_SOURCE})`,
      "giu",
    ),
  ];
  const candidates = new Set<number>();

  for (const pattern of patterns) {
    let match = pattern.exec(text);
    while (match) {
      const amount = parseLocalizedAmount(match[1], currency);
      if (amount !== null) candidates.add(amount);
      match = pattern.exec(text);
    }
  }
  return [...candidates];
}

export function parseIncomingPayment(rawText: string): PaymentParseResult {
  const notificationText = rawText.replace(/\s+/g, " ").trim().slice(0, 1200);
  const text = normalizeForMatching(notificationText);
  if (!text) {
    return { ok: false, reason: "empty_notification", notificationText };
  }
  if (OTP_PATTERN.test(text)) {
    return { ok: false, reason: "otp_notification", notificationText };
  }
  if (OUTGOING_PATTERN.test(text)) {
    return { ok: false, reason: "outgoing_payment", notificationText };
  }
  if (!INCOMING_PATTERN.test(text)) {
    return { ok: false, reason: "not_incoming_payment", notificationText };
  }

  const hasUsd = hasCurrency(text, USD_TOKEN_SOURCE);
  const hasSyp = hasCurrency(text, SYP_TOKEN_SOURCE);
  if (!hasUsd && !hasSyp) {
    return { ok: false, reason: "currency_missing", notificationText };
  }
  if (hasUsd && hasSyp) {
    return { ok: false, reason: "currency_ambiguous", notificationText };
  }

  const currency: PaymentCurrency = hasUsd ? "USD" : "SYP";
  const amounts = collectAmounts(text, currency);
  if (!amounts.length) {
    return { ok: false, reason: "amount_missing", notificationText };
  }
  if (amounts.length > 1) {
    return { ok: false, reason: "amount_ambiguous", notificationText };
  }
  return { ok: true, amount: amounts[0], currency, notificationText };
}

export function isValidEventId(value: string): boolean {
  return /^[0-9a-f]{64}$/u.test(value);
}

export function isValidDeviceId(value: string): boolean {
  return /^[A-Za-z0-9._:-]{8,128}$/u.test(value);
}

export function parseSignatureHeader(value: string): Uint8Array | null {
  const match = /^v1=([0-9a-f]{64})$/iu.exec(value.trim());
  if (!match) return null;
  const bytes = new Uint8Array(32);
  for (let index = 0; index < bytes.length; index += 1) {
    bytes[index] = Number.parseInt(
      match[1].slice(index * 2, index * 2 + 2),
      16,
    );
  }
  return bytes;
}

export function isFreshTimestamp(
  timestamp: number,
  now = Date.now(),
  replayWindowMs = DEFAULT_REPLAY_WINDOW_MS,
): boolean {
  return Number.isSafeInteger(timestamp) &&
    timestamp >= 1_000_000_000_000 &&
    Math.abs(now - timestamp) <= replayWindowMs;
}

export function isRetryableUnmatchedTimestamp(
  receivedAt: string | null | undefined,
  now = Date.now(),
  retryWindowMs = DEFAULT_UNMATCHED_RETRY_WINDOW_MS,
): boolean {
  if (!receivedAt) return false;
  const receivedAtMs = Date.parse(receivedAt);
  if (!Number.isFinite(receivedAtMs)) return false;
  const ageMs = now - receivedAtMs;
  return ageMs >= 0 && ageMs <= retryWindowMs;
}

export function buildSignedMessage(
  deviceId: string,
  eventId: string,
  timestamp: number,
  rawBody: Uint8Array,
): Uint8Array {
  const prefix = textEncoder.encode(`${deviceId}\n${eventId}\n${timestamp}\n`);
  const message = new Uint8Array(prefix.length + rawBody.length);
  message.set(prefix, 0);
  message.set(rawBody, prefix.length);
  return message;
}

export async function sha256Hex(value: Uint8Array): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new Uint8Array(value).buffer,
  );
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

export async function verifyHmacSignature(
  secret: string,
  deviceId: string,
  eventId: string,
  timestamp: number,
  rawBody: Uint8Array,
  signatureHeader: string,
): Promise<boolean> {
  if (!secret) return false;
  const signature = parseSignatureHeader(signatureHeader);
  if (!signature) return false;
  const key = await crypto.subtle.importKey(
    "raw",
    textEncoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["verify"],
  );
  const signatureBuffer = new Uint8Array(signature).buffer;
  const messageBuffer = new Uint8Array(
    buildSignedMessage(deviceId, eventId, timestamp, rawBody),
  ).buffer;
  return crypto.subtle.verify(
    "HMAC",
    key,
    signatureBuffer,
    messageBuffer,
  );
}
