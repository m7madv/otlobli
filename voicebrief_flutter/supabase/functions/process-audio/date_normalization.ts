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

function localDate(
  referenceInstant: string,
  timeZoneOffsetMinutes: number,
  dayOffset: number,
): string | null {
  const referenceMilliseconds = Date.parse(referenceInstant);
  if (!Number.isFinite(referenceMilliseconds)) return null;
  const localReference = new Date(
    referenceMilliseconds + timeZoneOffsetMinutes * 60_000 +
      dayOffset * 86_400_000,
  );
  return isoDate(
    localReference.getUTCFullYear(),
    localReference.getUTCMonth() + 1,
    localReference.getUTCDate(),
  );
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

function transcriptClauses(transcript: string): string[] {
  return transcript
    .split(/[.!?؟،,؛;\n]+/u)
    .map((clause) => clause.trim())
    .filter((clause) => clause.length > 0 && clause.length <= 240);
}

function hasDateMarker(value: string): boolean {
  return /(?:^|[^\p{L}\p{N}])(?:اليوم|غدا|بكره|بكرا|بعد\s+(?:غد|بكره|بكرا)|يوم|بتاريخ|تاريخ)(?:$|[^\p{L}\p{N}])/u
    .test(value);
}

function resolveRelativeArabicDate(
  clause: string,
  referenceInstant: string,
  timeZoneOffsetMinutes: number,
): string | null {
  const normalized = normalizedArabic(clause);
  if (
    /(?:^|[^\p{L}\p{N}])بعد\s+(?:غد|بكره|بكرا)(?:$|[^\p{L}\p{N}])/u.test(
      normalized,
    )
  ) {
    return localDate(referenceInstant, timeZoneOffsetMinutes, 2);
  }
  if (
    /(?:^|[^\p{L}\p{N}])(?:غدا|بكره|بكرا)(?:$|[^\p{L}\p{N}])/u.test(normalized)
  ) {
    return localDate(referenceInstant, timeZoneOffsetMinutes, 1);
  }
  if (/(?:^|[^\p{L}\p{N}])اليوم(?:$|[^\p{L}\p{N}])/u.test(normalized)) {
    return localDate(referenceInstant, timeZoneOffsetMinutes, 0);
  }
  return null;
}

function importantDateRecords(generated: JsonRecord): JsonRecord[] {
  if (!Array.isArray(generated.importantDates)) generated.importantDates = [];
  return generated.importantDates as JsonRecord[];
}

function containsEquivalentDate(
  dates: JsonRecord[],
  dateIso: string,
  phrase: string,
): boolean {
  const normalizedPhrase = normalizedArabic(phrase);
  return dates.some((date) => {
    if (typeof date.originalPhrase !== "string") return false;
    const existingPhrase = normalizedArabic(date.originalPhrase);
    const samePhrase = existingPhrase.includes(normalizedPhrase) ||
      normalizedPhrase.includes(existingPhrase);
    return date.dateIso === dateIso && samePhrase;
  });
}

function ensureTranscriptDates(
  generated: JsonRecord,
  transcript: string,
  referenceInstant: string,
  timeZoneOffsetMinutes: number,
): void {
  const dates = importantDateRecords(generated);
  const fallbackLabel = typeof generated.title === "string" &&
      generated.title.trim().length > 0
    ? generated.title.trim().slice(0, 240)
    : "موعد";
  for (const clause of transcriptClauses(transcript)) {
    const normalized = normalizedArabic(clause);
    if (!hasDateMarker(normalized)) continue;
    const resolved = resolveExplicitDayMonth(
      clause,
      referenceInstant,
      timeZoneOffsetMinutes,
    ) ?? resolveRelativeArabicDate(
      clause,
      referenceInstant,
      timeZoneOffsetMinutes,
    );
    if (!resolved || containsEquivalentDate(dates, resolved, clause)) continue;
    dates.push({
      label: fallbackLabel,
      dateIso: resolved,
      originalPhrase: clause,
      confidence: 0.9,
      requiresConfirmation: true,
    });
  }
}

export function normalizeSpokenDates(
  generated: JsonRecord,
  referenceInstant: string,
  timeZoneOffsetMinutes: number,
  transcript = "",
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
  ensureTranscriptDates(
    generated,
    transcript,
    referenceInstant,
    timeZoneOffsetMinutes,
  );
  return generated;
}
