import {
  deleteAccountValidationError,
  deleteAccountValues,
  deletionSubmission,
} from "./delete_account_form.ts";

function assert(condition: boolean, message: string) {
  if (!condition) throw new Error(message);
}

Deno.test("account deletion form normalizes and fixes the support category", () => {
  const form = new FormData();
  form.set("email", "  Person@Example.COM ");
  form.set("provider", "apple");
  form.set("note", " Please remove my account. ");
  form.set("confirm", "delete");

  const values = deleteAccountValues(form);
  assert(values.email === "person@example.com", "email was not normalized");
  assert(values.confirmed, "confirmation was not parsed");
  assert(
    deleteAccountValidationError(values, "en") === "",
    "valid request failed",
  );

  const submission = deletionSubmission(values, "en");
  assert(submission.category === "account", "category must be account");
  assert(
    submission.subject === "VoiceBrief account deletion request",
    "subject must be fixed by the server",
  );
  assert(submission.message.includes("Apple"), "provider was not recorded");
  assert(
    submission.message.includes("Please remove my account."),
    "note was lost",
  );
});

Deno.test("account deletion form requires provider and explicit confirmation", () => {
  const form = new FormData();
  form.set("email", "person@example.com");
  const values = deleteAccountValues(form);

  assert(
    deleteAccountValidationError(values, "ar") ===
      "اختر طريقة تسجيل الدخول إلى الحساب.",
    "missing provider was not rejected",
  );

  values.provider = "google";
  assert(
    deleteAccountValidationError(values, "en") ===
      "Confirm that you are requesting permanent account and data deletion.",
    "missing confirmation was not rejected",
  );
});

Deno.test("account deletion form rejects invalid email and oversized notes", () => {
  const form = new FormData();
  form.set("email", "not-an-email");
  form.set("provider", "google");
  form.set("confirm", "delete");
  const values = deleteAccountValues(form);
  assert(
    deleteAccountValidationError(values, "en") ===
      "Enter the email address associated with your VoiceBrief account.",
    "invalid email was not rejected",
  );

  values.email = "person@example.com";
  values.note = "x".repeat(1_001);
  assert(
    deleteAccountValidationError(values, "en") ===
      "The optional note must be 1,000 characters or fewer.",
    "oversized note was not rejected",
  );
});
