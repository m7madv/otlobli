type JsonRecord = Record<string, unknown>;

const ARABIC_DIGITS = "٠١٢٣٤٥٦٧٨٩";
const PERSIAN_DIGITS = "۰۱۲۳۴۵۶۷۸۹";

const SIMPLE_ARABIC_NUMBERS: Record<string, number> = {
  واحد: 1,
  واحده: 1,
  اول: 1,
  اثنين: 2,
  اثنان: 2,
  اثنتين: 2,
  اتنين: 2,
  ثاني: 2,
  ثلاثه: 3,
  ثالث: 3,
  اربعه: 4,
  رابع: 4,
  خمسه: 5,
  خامس: 5,
  سته: 6,
  سادس: 6,
  سبعه: 7,
  سابع: 7,
  ثمانيه: 8,
  ثامن: 8,
  تسعه: 9,
  تاسع: 9,
  عشره: 10,
  عاشر: 10,
  احدعشر: 11,
  احدىعشر: 11,
  اثناعشر: 12,
  اثنيعشر: 12,
  اثنتاعشر: 12,
};

function normalizedArabic(value: string): string {
  return [...value]
    .map((character) => {
      const arabicIndex = ARABIC_DIGITS.indexOf(character);
      if (arabicIndex >= 0) return String(arabicIndex);
      const persianIndex = PERSIAN_DIGITS.indexOf(character);
      return persianIndex >= 0 ? String(persianIndex) : character;
    })
    .join("")
    .toLowerCase()
    .replace(/[\u064b-\u065f\u0670]/g, "")
    .replace(/[إأآٱ]/g, "ا")
    .replace(/ى/g, "ي")
    .replace(/ة/g, "ه");
}

function simpleNumber(token: string): number | null {
  if (/^\d{1,4}$/.test(token)) return Number(token);
  return SIMPLE_ARABIC_NUMBERS[token] ?? null;
}

function nextNumber(
  tokens: string[],
  start: number,
): { value: number; nextIndex: number } | null {
  for (let index = start; index < Math.min(tokens.length, start + 3); index++) {
    if (tokens[index] === "من" || tokens[index] === "شهر") continue;
    const value = simpleNumber(tokens[index]);
    if (value !== null) return { value, nextIndex: index + 1 };
    return null;
  }
  return null;
}

function daysInMonth(year: number, month: number): number {
  return new Date(Date.UTC(year, month, 0)).getUTCDate();
}

function isoDate(year: number, month: number, day: number): string {
  return `${year.toString().padStart(4, "0")}-${
    month.toString().padStart(2, "0")
  }-${day.toString().padStart(2, "0")}`;
}

/**
 * Resolves explicit Arabic day/month phrases such as "يوم خمسة تسعة" or
 * "بتاريخ ٥/٩". It intentionally requires a date marker so a spoken time such
 * as "الساعة خمسة تسعة" cannot be mistaken for a calendar date.
 */
export function resolveExplicitDayMonth(
  phrase: string,
  referenceInstant: string,
  timeZoneOffsetMinutes: number,
): string | null {
  const normalized = normalizedArabic(phrase);
  const marker = /(?:^|[^\p{L}\p{N}])(?:يوم|بتاريخ|تاريخ)\s+(.{1,60})/u
    .exec(normalized);
  if (!marker) return null;

  const tokens = marker[1].split(/[^\p{L}\p{N}]+/u).filter(Boolean);
  const dayPart = nextNumber(tokens, 0);
  if (!dayPart || dayPart.value < 1 || dayPart.value > 31) return null;
  const monthPart = nextNumber(tokens, dayPart.nextIndex);
  if (!monthPart || monthPart.value < 1 || monthPart.value > 12) return null;

  const referenceMilliseconds = Date.parse(referenceInstant);
  if (!Number.isFinite(referenceMilliseconds)) return null;
  const localReference = new Date(
    referenceMilliseconds + timeZoneOffsetMinutes * 60_000,
  );
  const referenceYear = localReference.getUTCFullYear();
  const referenceMonth = localReference.getUTCMonth() + 1;
  const referenceDay = localReference.getUTCDate();

  let year = referenceYear;
  const explicitYear = nextNumber(tokens, monthPart.nextIndex)?.value;
  if (explicitYear && explicitYear >= 1900 && explicitYear <= 2200) {
    year = explicitYear;
  } else if (
    monthPart.value < referenceMonth ||
    (monthPart.value === referenceMonth && dayPart.value < referenceDay)
  ) {
    year += 1;
  }
  if (dayPart.value > daysInMonth(year, monthPart.value)) return null;
  return isoDate(year, monthPart.value, dayPart.value);
}

function normalizeArrayDates(
  value: unknown,
  phraseKey: "originalDatePhrase" | "originalPhrase",
  dateKey: "dueDateIso" | "dateIso",
  referenceInstant: string,
  timeZoneOffsetMinutes: number,
): void {
  if (!Array.isArray(value)) return;
  for (const item of value) {
    if (!item || typeof item !== "object") continue;
    const record = item as JsonRecord;
    const phrase = record[phraseKey];
    if (typeof phrase !== "string") continue;
    const resolved = resolveExplicitDayMonth(
      phrase,
      referenceInstant,
      timeZoneOffsetMinutes,
    );
    if (!resolved) continue;
    record[dateKey] = resolved;
    if (typeof record.confidence === "number") {
      record.confidence = Math.max(record.confidence, 0.92);
    }
    if (dateKey === "dateIso") record.requiresConfirmation = true;
  }
}

export function normalizeSpokenDates(
  generated: JsonRecord,
  referenceInstant: string,
  timeZoneOffsetMinutes: number,
): JsonRecord {
  normalizeArrayDates(
    generated.actionItems,
    "originalDatePhrase",
    "dueDateIso",
    referenceInstant,
    timeZoneOffsetMinutes,
  );
  normalizeArrayDates(
    generated.importantDates,
    "originalPhrase",
    "dateIso",
    referenceInstant,
    timeZoneOffsetMinutes,
  );
  return generated;
}
