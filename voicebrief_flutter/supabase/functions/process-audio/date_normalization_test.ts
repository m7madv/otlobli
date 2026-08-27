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
  const generated = {
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

  assertEquals(generated.actionItems[0].dueDateIso, "2026-09-05");
  assertEquals(generated.importantDates[0].dateIso, "2026-09-05");
  assertEquals(generated.importantDates[0].requiresConfirmation, true);
  assertEquals(generated.actionItems.length, 1);
  assertEquals(generated.importantDates.length, 1);
});
