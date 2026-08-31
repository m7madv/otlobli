const query = new URLSearchParams(window.location.search);
const requestedLanguage = query.get("lang");
const language =
  requestedLanguage === "ar" || requestedLanguage === "en"
    ? requestedLanguage
    : navigator.languages?.some((value) => value.toLowerCase().startsWith("ar"))
      ? "ar"
      : "en";

document.documentElement.lang = language;
document.documentElement.dir = language === "ar" ? "rtl" : "ltr";
document.title =
  language === "ar"
    ? document.title
        .replace("Delete Account", "حذف الحساب")
        .replace("Privacy", "الخصوصية")
        .replace("Terms", "الشروط")
        .replace("Support", "الدعم")
    : document.title;

const skipLink = document.querySelector(".skip");
if (skipLink && language === "ar") skipLink.href = "#content-ar";
const navigation = document.querySelector("nav");
if (navigation)
  navigation.setAttribute(
    "aria-label",
    language === "ar" ? "روابط قانونية" : "Legal navigation",
  );

for (const page of document.querySelectorAll("[data-locale]")) {
  page.hidden = page.dataset.locale !== language;
}

for (const switcher of document.querySelectorAll("[data-language-switch]")) {
  const targetLanguage = language === "ar" ? "en" : "ar";
  switcher.href = `${window.location.pathname}?lang=${targetLanguage}`;
  switcher.lang = targetLanguage;
  switcher.textContent = targetLanguage === "ar" ? "العربية" : "English";
}

for (const link of document.querySelectorAll(
  "nav a:not([data-language-switch])",
)) {
  const target = new URL(link.href);
  target.searchParams.set("lang", language);
  link.href = target.toString();
}

for (const form of document.querySelectorAll(
  "[data-support-form], [data-deletion-form]",
)) {
  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    const status = form.parentElement.querySelector("[data-form-status]");
    const button = form.querySelector("button[type='submit']");
    const isArabic = form.dataset.language === "ar";
    const isDeletion = form.hasAttribute("data-deletion-form");
    const originalLabel = button.textContent;
    status.hidden = true;
    button.disabled = true;
    button.textContent = isArabic ? "جارٍ الإرسال…" : "Sending…";

    try {
      const formData = new FormData(form);
      if (isDeletion) {
        const provider = form.querySelector("[data-provider]");
        const providerName =
          provider.selectedOptions[0]?.dataset.providerKey || "Unknown";
        const note = String(formData.get("note") || "").trim();
        const message = isArabic
          ? `طلب حذف حساب VoiceBrief نهائيًا. طريقة تسجيل الدخول: ${providerName}. أكّد صاحب الطلب حذف الحساب والبيانات الخاضعة لسيطرة VoiceBrief. ملاحظة المستخدم: ${note || "لا توجد ملاحظة."}`
          : `Permanent VoiceBrief account deletion requested. Sign-in provider: ${providerName}. The requester confirmed deletion of the account and data controlled by VoiceBrief. User note: ${note || "No note."}`;
        formData.set("message", message);
        formData.delete("note");
        formData.delete("confirm");
      }
      const response = await fetch(form.action, {
        method: "POST",
        body: formData,
        headers: { Accept: "application/json" },
      });
      const payload = await response.json();
      if (!response.ok)
        throw new Error(
          payload.error ||
            (isArabic ? "تعذر إرسال الطلب." : "Unable to send the request."),
        );
      form.reset();
      status.dataset.state = "success";
      status.textContent = isDeletion
        ? isArabic
          ? "تم استلام طلب حذف الحساب. سيدخل قائمة الدعم الخاصة، وسنتحقق من ملكية الحساب قبل تنفيذ الحذف."
          : "Account deletion request received. It entered the private support queue, and ownership will be verified before deletion."
        : isArabic
          ? "تم إرسال طلبك. سيراجع فريق VoiceBrief الرسالة من لوحة الدعم."
          : "Support request sent. The VoiceBrief team can review it in the support dashboard.";
    } catch (error) {
      status.dataset.state = "error";
      status.textContent =
        error instanceof Error
          ? error.message
          : isArabic
            ? "تعذر إرسال الطلب. حاول مرة أخرى."
            : "Unable to send the request. Try again.";
    } finally {
      status.hidden = false;
      status.focus();
      button.disabled = false;
      button.textContent = originalLabel;
    }
  });
}
