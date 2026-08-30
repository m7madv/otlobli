import {
  normalizeSpokenDates,
  resolveExplicitDayMonth,
} from "./date_normalization.ts";

function assertEquals(actual: unknown, expected: unknown): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}

const reference = "2026-08-26T16:20:00.000Z";

Deno.test("resolves Arabic words as an upcoming day and month", () => {
  assertEquals(
    resolveExplicitDayMonth("«يوم خمسة تسعة»", reference, 180),
    "2026-09-05",
  );
});

Deno.test("resolves Arabic-Indic digits separated by a slash", () => {
  assertEquals(
    resolveExplicitDayMonth("بتاريخ ٥/٩", reference, 180),
    "2026-09-05",
  );
});

Deno.test("rolls a passed day and month into the next year", () => {
  assertEquals(
    resolveExplicitDayMonth("يوم 5 9", "2026-09-06T08:00:00.000Z", 180),
    "2027-09-05",
  );
});

Deno.test("does not treat a spoken clock time as a date", () => {
  assertEquals(
    resolveExplicitDayMonth("الساعة خمسة تسعة", reference, 180),
    null,
  );
});

Deno.test("corrects both action and calendar date without merging events", () => {
  const generated: Record<string, unknown> = {
    actionItems: [{
      title: "ضبط منبه للحصة",
      originalDatePhrase: "يوم خمسة تسعة",
      dueDateIso: "2026-08-27T17:00:00+03:00",
      confidence: 0.4,
    }],
    importantDates: [{
      label: "حصة التصوير",
      originalPhrase: "يوم خمسة تسعة",
      dateIso: null,
      confidence: 0.4,
      requiresConfirmation: true,
    }],
  };

  normalizeSpokenDates(generated, reference, 180);

  const actions = generated.actionItems as Record<string, unknown>[];
  const dates = generated.importantDates as Record<string, unknown>[];
  assertEquals(actions[0].dueDateIso, "2026-09-05");
  assertEquals(dates[0].dateIso, "2026-09-05");
  assertEquals(dates[0].requiresConfirmation, true);
  assertEquals(actions.length, 1);
  assertEquals(dates.length, 1);
});

Deno.test("recovers tomorrow appointment when the model omitted date arrays", () => {
  const generated: Record<string, unknown> = {
    title: "موعد الغد",
    actionItems: [],
    importantDates: [],
  };

  normalizeSpokenDates(
    generated,
    reference,
    180,
    "المتحدث يذكر بأن الموعد غدًا الساعة الخامسة ويطلب الاستعداد للذهاب.",
  );

  assertEquals(generated.importantDates, [{
    label: "موعد الغد",
    dateIso: "2026-08-27",
    originalPhrase:
      "المتحدث يذكر بأن الموعد غدًا الساعة الخامسة ويطلب الاستعداد للذهاب",
    confidence: 0.9,
    requiresConfirmation: true,
  }]);
});

Deno.test("recovers separate tomorrow and explicit day month appointments", () => {
  const generated: Record<string, unknown> = {
    title: "مواعيد قادمة",
    actionItems: [],
    importantDates: [],
  };

  normalizeSpokenDates(
    generated,
    reference,
    180,
    "موعدنا بكرة على الساعة خمسة. وكمان حط منبه يوم خمسة تسعة.",
  );

  const dates = generated.importantDates as Record<string, unknown>[];
  assertEquals(dates.length, 2);
  assertEquals(dates[0].dateIso, "2026-08-27");
  assertEquals(dates[1].dateIso, "2026-09-05");
  assertEquals(dates[0].requiresConfirmation, true);
  assertEquals(dates[1].requiresConfirmation, true);
});

Deno.test("does not duplicate a generated relative date with a full timestamp", () => {
  const generated: Record<string, unknown> = {
    title: "موعد الغد",
    actionItems: [],
    importantDates: [{
      label: "موعد الغد",
      dateIso: "2026-08-27T17:00:00+03:00",
      originalPhrase: "بكرة على الساعة خمسة",
      confidence: 0.9,
      requiresConfirmation: true,
    }],
  };

  normalizeSpokenDates(
    generated,
    reference,
    180,
    "موعدنا بكرة على الساعة خمسة.",
  );

  const dates = generated.importantDates as Record<string, unknown>[];
  assertEquals(dates.length, 1);
});

Deno.test("does not add a repeated explicit date as another event", () => {
  const generated: Record<string, unknown> = {
    title: "مواعيد قادمة",
    actionItems: [],
    importantDates: [{
      label: "حصة التصوير",
      dateIso: "2026-09-05",
      originalPhrase: "يوم خمسة من شهر تسعة لحصة التصوير",
      confidence: 0.9,
      requiresConfirmation: true,
    }],
  };

  normalizeSpokenDates(
    generated,
    reference,
    180,
    "وكمان عندنا موعد تاني مستقل يوم خمسة من شهر تسعة. " +
      "أكرر الموعد الثاني: يوم خمسة من شهر تسعة لحصة التصوير.",
  );

  const dates = generated.importantDates as Record<string, unknown>[];
  assertEquals(dates.length, 1);
  assertEquals(dates[0].label, "حصة التصوير");
});

Deno.test("keeps distinct same-day events when the speaker did not repeat", () => {
  const generated: Record<string, unknown> = {
    title: "مواعيد اليوم",
    actionItems: [],
    importantDates: [{
      label: "موعد الطبيب",
      dateIso: "2026-08-27T09:00:00+03:00",
      originalPhrase: "موعد الطبيب بكرة الصبح",
      confidence: 0.9,
      requiresConfirmation: true,
    }],
  };

  normalizeSpokenDates(
    generated,
    reference,
    180,
    "موعد الطبيب بكرة الصبح. وعندي تدريب بكرة بالمساء.",
  );

  const dates = generated.importantDates as Record<string, unknown>[];
  assertEquals(dates.length, 2);
});
