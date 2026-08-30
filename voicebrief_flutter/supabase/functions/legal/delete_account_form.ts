export type DeleteAccountLanguage = "ar" | "en";
export type DeleteAccountProvider = "apple" | "google" | "";

export interface DeleteAccountValues {
  email: string;
  provider: DeleteAccountProvider;
  note: string;
  confirmed: boolean;
}

export interface DeletionSubmission {
  email: string;
  category: "account";
  subject: string;
  message: string;
}

export function deleteAccountValues(form: FormData): DeleteAccountValues {
  const provider = String(form.get("provider") ?? "").trim().toLowerCase();
  return {
    email: String(form.get("email") ?? "").trim().toLowerCase(),
    provider: provider === "apple" || provider === "google" ? provider : "",
    note: String(form.get("note") ?? "").trim(),
    confirmed: String(form.get("confirm") ?? "") === "delete",
  };
}

export function deleteAccountValidationError(
  values: DeleteAccountValues,
  lang: DeleteAccountLanguage,
): string {
  const validEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(values.email);
  if (!validEmail || values.email.length > 254) {
    return lang === "ar"
      ? "أدخل البريد الإلكتروني المرتبط بحساب VoiceBrief."
      : "Enter the email address associated with your VoiceBrief account.";
  }
  if (values.provider !== "apple" && values.provider !== "google") {
    return lang === "ar"
      ? "اختر طريقة تسجيل الدخول إلى الحساب."
      : "Choose the account sign-in provider.";
  }
  if (values.note.length > 1_000) {
    return lang === "ar"
      ? "يجب ألا تتجاوز الملاحظة 1000 حرف."
      : "The optional note must be 1,000 characters or fewer.";
  }
  if (!values.confirmed) {
    return lang === "ar"
      ? "أكّد أنك تطلب حذف الحساب وبياناته نهائيًا."
      : "Confirm that you are requesting permanent account and data deletion.";
  }
  return "";
}

export function deletionSubmission(
  values: DeleteAccountValues,
  lang: DeleteAccountLanguage,
): DeletionSubmission {
  const provider = values.provider === "apple" ? "Apple" : "Google";
  const note = values.note || (lang === "ar" ? "لا توجد ملاحظة." : "No note.");
  return {
    email: values.email,
    category: "account",
    subject: lang === "ar"
      ? "طلب حذف حساب VoiceBrief"
      : "VoiceBrief account deletion request",
    message: lang === "ar"
      ? `طلب حذف الحساب نهائيًا. طريقة تسجيل الدخول: ${provider}. أكّد صاحب الطلب موافقته على حذف الحساب والبيانات الخاضعة لسيطرة VoiceBrief. ملاحظة المستخدم: ${note}`
      : `Permanent account deletion requested. Sign-in provider: ${provider}. The requester confirmed deletion of the account and data controlled by VoiceBrief. User note: ${note}`,
  };
}
