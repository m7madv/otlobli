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

for (const form of document.querySelectorAll("[data-support-form]")) {
  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    const status = form.parentElement.querySelector("[data-form-status]");
    const button = form.querySelector("button[type='submit']");
    const isArabic = form.dataset.language === "ar";
    const originalLabel = button.textContent;
    status.hidden = true;
    button.disabled = true;
    button.textContent = isArabic ? "جارٍ الإرسال…" : "Sending…";

    try {
      const response = await fetch(form.action, {
        method: "POST",
        body: new FormData(form),
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
      status.textContent = isArabic
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
