import { createClient } from "@supabase/supabase-js";
import { BoundedBodyError, boundedFormData } from "./bounded_form.ts";
import {
  deleteAccountValidationError,
  type DeleteAccountValues,
  deleteAccountValues,
  deletionSubmission,
} from "./delete_account_form.ts";

type Language = "en" | "ar";
type LegalRoute = "privacy" | "terms" | "support" | "delete-account";

const policyDate = "2026-08-30";
const maxBodyBytes = 32_768;

const securityHeaders = {
  "access-control-allow-headers": "content-type",
  "access-control-allow-methods": "GET, HEAD, POST, OPTIONS",
  "access-control-allow-origin": "*",
  "cache-control": "public, max-age=300",
  "content-security-policy":
    "default-src 'none'; style-src 'unsafe-inline'; form-action 'self'; base-uri 'none'; frame-ancestors 'none'",
  "cross-origin-opener-policy": "same-origin",
  "referrer-policy": "no-referrer",
  "x-content-type-options": "nosniff",
  "x-frame-options": "DENY",
};

function htmlResponse(body: string, status = 200, extraHeaders = {}) {
  return new Response(body, {
    status,
    headers: {
      ...securityHeaders,
      "content-type": "text/html; charset=utf-8",
      ...extraHeaders,
    },
  });
}

function jsonResponse(
  status: number,
  body: Record<string, unknown>,
  extraHeaders = {},
) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "access-control-allow-headers": "content-type",
      "access-control-allow-methods": "POST, OPTIONS",
      "access-control-allow-origin": "*",
      "cache-control": "no-store",
      "content-type": "application/json; charset=utf-8",
      "x-content-type-options": "nosniff",
      ...extraHeaders,
    },
  });
}

function escapeHtml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function languageFor(request: Request, url: URL): Language {
  const requested = url.searchParams.get("lang");
  if (requested === "ar" || requested === "en") return requested;
  return (request.headers.get("accept-language") ?? "")
      .toLowerCase()
      .startsWith("ar")
    ? "ar"
    : "en";
}

function routeFor(url: URL): LegalRoute | null {
  const route = url.pathname.split("/").filter(Boolean).at(-1);
  if (
    route === "privacy" || route === "terms" || route === "support" ||
    route === "delete-account"
  ) {
    return route;
  }
  return null;
}

function routeLabel(route: LegalRoute, lang: Language) {
  const labels = {
    en: {
      privacy: "Privacy",
      terms: "Terms",
      support: "Support",
      "delete-account": "Delete Account",
    },
    ar: {
      privacy: "الخصوصية",
      terms: "الشروط",
      support: "الدعم",
      "delete-account": "حذف الحساب",
    },
  } as const;
  return labels[lang][route];
}

function shell(
  route: LegalRoute,
  lang: Language,
  title: string,
  description: string,
  content: string,
) {
  const direction = lang === "ar" ? "rtl" : "ltr";
  const otherLanguage = lang === "ar" ? "en" : "ar";
  const otherLabel = lang === "ar" ? "English" : "العربية";
  const skipLabel = lang === "ar" ? "انتقل إلى المحتوى" : "Skip to content";
  const updatedLabel = lang === "ar" ? "آخر تحديث" : "Last updated";
  const updatedText = lang === "ar" ? "30 أغسطس 2026" : "August 30, 2026";
  const footerText = lang === "ar"
    ? "VoiceBrief — رسائلك الصوتية، واضحة."
    : "VoiceBrief — Voice messages, made clear.";

  const nav = ([
    "privacy",
    "terms",
    "support",
    "delete-account",
  ] as LegalRoute[])
    .map(
      (item) =>
        `<a href="./${item}?lang=${lang}"${
          item === route ? ' aria-current="page"' : ""
        }>${routeLabel(item, lang)}</a>`,
    )
    .join("");

  return `<!doctype html>
<html lang="${lang}" dir="${direction}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="theme-color" content="#ffffff" media="(prefers-color-scheme: light)">
  <meta name="theme-color" content="#000000" media="(prefers-color-scheme: dark)">
  <meta name="description" content="${escapeHtml(description)}">
  <title>${escapeHtml(title)} — VoiceBrief</title>
  <style>
    :root { color-scheme: light dark; --bg:#fff; --surface:#f5f5f7; --elevated:#fff; --text:#090909; --muted:#636366; --border:#d1d1d6; --accent:#0066cc; --focus:#004a99; --success:#248a3d; }
    * { box-sizing: border-box; }
    html { background: var(--bg); scroll-behavior: smooth; }
    body { margin:0; background:var(--bg); color:var(--text); font: 17px/1.58 -apple-system, BlinkMacSystemFont, "Segoe UI", Arial, sans-serif; text-rendering:optimizeLegibility; }
    a { color:var(--accent); text-underline-offset:.18em; text-decoration-thickness:.08em; }
    a:hover { text-decoration-thickness:.13em; }
    a:focus-visible, button:focus-visible, input:focus-visible, select:focus-visible, textarea:focus-visible { outline:3px solid var(--focus); outline-offset:3px; }
    .skip { position:fixed; inset-block-start:10px; inset-inline-start:10px; transform:translateY(-160%); z-index:10; padding:10px 14px; border-radius:10px; background:var(--text); color:var(--bg); }
    .skip:focus { transform:translateY(0); }
    header { border-bottom:1px solid var(--border); background:color-mix(in srgb, var(--bg) 92%, transparent); }
    .topbar { width:min(100% - 32px, 920px); min-height:72px; margin:auto; display:flex; align-items:center; justify-content:space-between; gap:20px; }
    .brand { color:var(--text); font-size:19px; font-weight:750; text-decoration:none; letter-spacing:-.02em; }
    nav { display:flex; align-items:center; gap:4px; }
    nav a, .language { min-height:44px; display:inline-flex; align-items:center; padding:8px 12px; border-radius:10px; color:var(--muted); font-size:15px; font-weight:650; text-decoration:none; }
    nav a:hover, .language:hover { background:var(--surface); color:var(--text); }
    nav a[aria-current="page"] { color:var(--accent); background:var(--surface); }
    .language { border-inline-start:1px solid var(--border); border-radius:0; margin-inline-start:6px; color:var(--accent); }
    main { width:min(100% - 40px, 760px); margin:0 auto; padding:clamp(48px, 8vw, 88px) 0 72px; }
    .wave { height:44px; display:flex; align-items:center; gap:6px; margin-bottom:26px; color:var(--accent); }
    .wave span { display:block; width:5px; border-radius:999px; background:currentColor; }
    .wave span:nth-child(1), .wave span:nth-child(7) { height:10px; opacity:.45; }
    .wave span:nth-child(2), .wave span:nth-child(6) { height:22px; opacity:.62; }
    .wave span:nth-child(3), .wave span:nth-child(5) { height:34px; opacity:.8; }
    .wave span:nth-child(4) { height:44px; }
    h1 { margin:0; max-width:15ch; font-size:clamp(38px, 8vw, 68px); line-height:1.02; letter-spacing:-.045em; text-wrap:balance; }
    .lede { max-width:62ch; margin:24px 0 12px; color:var(--muted); font-size:20px; line-height:1.5; text-wrap:pretty; }
    .updated { margin:0 0 52px; color:var(--muted); font-size:14px; }
    section { padding:30px 0; border-top:1px solid var(--border); }
    section:first-of-type { border-top:0; }
    h2 { margin:0 0 14px; font-size:25px; line-height:1.2; letter-spacing:-.025em; scroll-margin-top:24px; text-wrap:balance; }
    h3 { margin:24px 0 8px; font-size:18px; }
    p { margin:0 0 14px; }
    ul { margin:12px 0 0; padding-inline-start:24px; }
    li { margin:8px 0; }
    .notice { margin:8px 0 28px; padding:18px 20px; border:1px solid var(--border); border-inline-start:4px solid var(--accent); border-radius:12px; background:var(--surface); }
    .success { border-inline-start-color:var(--success); }
    .error { border-inline-start-color:#d70015; }
    form { display:grid; gap:18px; margin-top:26px; }
    label { display:grid; gap:8px; font-weight:650; }
    .check { grid-template-columns:auto 1fr; align-items:start; font-weight:500; }
    .check input { width:22px; min-height:22px; margin-top:3px; }
    input, select, textarea { width:100%; min-height:48px; border:1px solid var(--border); border-radius:12px; padding:12px 14px; background:var(--elevated); color:var(--text); font:inherit; }
    textarea { min-height:170px; resize:vertical; }
    .hint { color:var(--muted); font-size:14px; font-weight:400; }
    button { min-height:48px; justify-self:start; border:0; border-radius:12px; padding:12px 20px; background:var(--accent); color:#fff; font:700 16px/1.2 inherit; cursor:pointer; touch-action:manipulation; }
    button:hover { filter:brightness(.9); }
    .trap { position:absolute; inline-size:1px; block-size:1px; overflow:hidden; clip-path:inset(50%); white-space:nowrap; }
    footer { border-top:1px solid var(--border); color:var(--muted); font-size:14px; }
    .footer-inner { width:min(100% - 40px, 760px); margin:auto; padding:28px 0 42px; }
    @media (max-width:680px) { .topbar { min-height:auto; padding:14px 0; align-items:flex-start; flex-direction:column; gap:8px; } nav { width:100%; overflow-x:auto; padding-bottom:2px; } nav a, .language { padding-inline:10px; white-space:nowrap; } main { padding-top:50px; } }
    @media (prefers-color-scheme:dark) { :root { --bg:#000; --surface:#1c1c1e; --elevated:#1c1c1e; --text:#f5f5f7; --muted:#b0b0b5; --border:#3a3a3c; --accent:#4aa3ff; --focus:#64b5ff; --success:#30d158; } header { background:color-mix(in srgb, var(--bg) 92%, transparent); } }
    @media (prefers-reduced-motion:reduce) { html { scroll-behavior:auto; } }
  </style>
</head>
<body>
  <a class="skip" href="#content">${skipLabel}</a>
  <header>
    <div class="topbar">
      <a class="brand" href="./privacy?lang=${lang}" translate="no">VoiceBrief</a>
      <nav aria-label="${
    lang === "ar" ? "روابط قانونية" : "Legal navigation"
  }">${nav}<a class="language" lang="${otherLanguage}" href="./${route}?lang=${otherLanguage}">${otherLabel}</a></nav>
    </div>
  </header>
  <main id="content">
    <div class="wave" aria-hidden="true"><span></span><span></span><span></span><span></span><span></span><span></span><span></span></div>
    <h1>${escapeHtml(title)}</h1>
    <p class="lede">${escapeHtml(description)}</p>
    <p class="updated">${updatedLabel}: <time datetime="${policyDate}">${updatedText}</time></p>
    ${content}
  </main>
  <footer><div class="footer-inner">${footerText}</div></footer>
</body>
</html>`;
}

function privacyContent(lang: Language) {
  if (lang === "ar") {
    return `
<section><h2>نطاق هذه السياسة</h2><p>توضح هذه السياسة طريقة تعامل VoiceBrief مع البيانات عند إنشاء حساب أو مشاركة تسجيل صوتي أو شراء اشتراك أو التواصل مع الدعم.</p></section>
<section><h2>البيانات التي نعالجها</h2><ul><li><strong>بيانات الحساب:</strong> البريد الإلكتروني، معرّف الحساب، مزود تسجيل الدخول، والاسم أو صورة الملف الشخصي إذا وفرهما مزود تسجيل الدخول.</li><li><strong>المحتوى الصوتي:</strong> الملف الذي تختار مشاركته أو استيراده أو تسجيله لمعالجته.</li><li><strong>النتائج:</strong> النص المكتوب والملخص والنقاط والمهام والمواعيد والردود المقترحة التي ينشئها التطبيق.</li><li><strong>الاشتراك والاستخدام:</strong> المنتج وحالة الاستحقاق ومدة الاشتراك وسجل الشراء وحالة انتهاء الصلاحية والدقائق المستخدمة.</li><li><strong>الدعم والتشخيص:</strong> المعلومات التي ترسلها في نماذج الدعم أو حذف الحساب، ورموز أخطاء تشغيلية منقحة ومعرّفات مجزأة لمكافحة الإساءة.</li></ul></section>
<section><h2>طريقة معالجة الصوت والنتائج</h2><p>لا يبدأ الرفع إلا بعد أن تختار ملفًا أو تسجيلًا. يُرفع الصوت إلى مساحة خاصة مؤقتة في Supabase، ثم يُرسل إلى OpenAI لتحويله إلى نص وإنشاء النتيجة. يحاول مسار المعالجة الطبيعي حذف النسخة المؤقتة عند اكتمال المعالجة أو فشلها. إذا منع انقطاعٌ الحذف الفوري، فقد تبقى النسخة في التخزين الخاص إلى أن تزيلها عملية تنظيف تشغيلية أو حذف الحساب؛ ولا يعرضها VoiceBrief كسجل صوتي دائم.</p><p>في المسار العادي داخل التطبيق، لا تُكتب النتيجة في السجل المحلي إلا عندما تختار «حفظ». أما نتيجة Share Extension فتُحفظ تلقائيًا ومحليًا على جهازك بعد استيرادها كي يستطيع إشعار الاكتمال فتحها. يمكنك حذف النتائج المحلية من التطبيق.</p><p>قد يحتوي سجل <code>processing_jobs.result</code> في Supabase على النتيجة المولدة كاملة، بما فيها النص والملخص والمهام والمواعيد والردود، لمدة تصل إلى 24 ساعة لدعم إعادة المحاولة ومنع احتساب الطلب نفسه مرتين.</p></section>
<section><h2>معالجة OpenAI</h2><p>ترسل VoiceBrief طلبات OpenAI مع <code>store: false</code> حتى لا تُحفظ النتيجة كبيانات تطبيق مخزنة لدى واجهة Responses. رغم ذلك، قد تحتفظ OpenAI بمدخلات ومخرجات واجهة API في سجلات مراقبة إساءة الاستخدام لمدة تصل إلى 30 يومًا، ما لم يكن حساب VoiceBrief معتمدًا ومضبوطًا على Zero Data Retention أو Modified Abuse Monitoring. لا ندّعي حاليًا أن Zero Data Retention مفعّل.</p></section>
<section><h2>الخدمات التي نعتمد عليها</h2><ul><li><strong>Supabase:</strong> الحساب، قاعدة البيانات، التخزين المؤقت، وتشغيل المعالجة.</li><li><strong>OpenAI:</strong> تحويل الصوت إلى نص وإنشاء الملخص والمهام والمواعيد والردود.</li><li><strong>RevenueCat ومتجرا Apple وGoogle:</strong> إدارة الاشتراك وحالة الشراء. يستخدم VoiceBrief معرّف حساب Supabase كمعرّف مستخدم RevenueCat، وقد يعالج هؤلاء المزودون المنتج والاستحقاق وتاريخ الشراء والانتهاء وسجل المعاملة وفق سياساتهم.</li><li><strong>Apple أو Google:</strong> تسجيل الدخول عندما تختار أحدهما، بما في ذلك بيانات الملف الشخصي التي يشاركها المزود.</li></ul><p>يُفتح حدث التقويم في محرر النظام لتراجعه قبل الحفظ؛ لا يحفظ VoiceBrief تقويمك على خوادمه.</p></section>
<section><h2>ما لا نفعله</h2><p>لا نبيع بياناتك، ولا نستخدم شبكة إعلانات، ولا نضيف أدوات تتبع إعلاني. لا يصل VoiceBrief إلى صوت لم تختر مشاركته أو تسجيله.</p></section>
<section><h2>الاحتفاظ والحذف</h2><p>تبقى بيانات الحساب والاستخدام اللازمة لتقديم الخدمة حتى حذف الحساب أو انتهاء الحاجة التشغيلية إليها. يمكنك حذف حساب VoiceBrief من الإعدادات أو إرسال طلب عبر <a href="./delete-account?lang=ar">صفحة حذف الحساب</a>. إلغاء اشتراك App Store أو Google Play إجراء منفصل لا ينفذه حذف حساب VoiceBrief، وقد تبقى سجلات المعاملة لدى المتجر أو RevenueCat وفق متطلبات قانونية وتشغيلية. وقد يحتاج مستخدم «تسجيل الدخول باستخدام Apple» إلى سحب وصول VoiceBrief يدويًا من إعدادات حساب Apple بعد الحذف.</p><p>لا نحدد حاليًا مدة ثابتة لطلبات الدعم وطلبات الحذف؛ نحتفظ بها حسب الحاجة للرد، والتحقق من الملكية، والتحقيق في الإساءة، وحماية الخدمة، والوفاء بالالتزامات القانونية.</p></section>
<section><h2>اختياراتك وأمان البيانات</h2><p>يمكنك الامتناع عن رفع الصوت، حذف النتائج المحلية، تسجيل الخروج، إلغاء أذونات النظام، وحذف الحساب. نستخدم اتصالًا مشفرًا وصلاحيات وصول مقيدة، لكن لا توجد خدمة إلكترونية خالية تمامًا من المخاطر.</p></section>
<section><h2>التغييرات والتواصل</h2><p>قد نحدّث هذه السياسة عندما تتغير الخدمة أو المتطلبات. سنحدّث التاريخ أعلى الصفحة عند إجراء تغيير جوهري. لأسئلة الخصوصية أو طلبات البيانات، استخدم <a href="./support?lang=ar">صفحة الدعم</a>، ولحذف الحساب استخدم <a href="./delete-account?lang=ar">صفحة حذف الحساب</a>.</p></section>`;
  }
  return `
<section><h2>Scope</h2><p>This policy explains how VoiceBrief handles data when you create an account, share audio, purchase a subscription, or contact support.</p></section>
<section><h2>Data We Process</h2><ul><li><strong>Account data:</strong> email address, account identifier, sign-in provider, and a name or profile image when supplied by that provider.</li><li><strong>Audio content:</strong> the file you choose to share, import, or record for processing.</li><li><strong>Generated results:</strong> transcript, summary, key points, tasks, dates, and suggested replies.</li><li><strong>Subscription and usage:</strong> product, entitlement status, subscription period, purchase history, expiration status, and processing minutes used.</li><li><strong>Support and diagnostics:</strong> information submitted through support or deletion forms, redacted operational error codes, and hashed identifiers used to prevent abuse.</li></ul></section>
<section><h2>How Audio and Results Are Processed</h2><p>Uploading starts only after you select or record audio. The audio is uploaded to private temporary storage in Supabase, then sent to OpenAI for transcription and result generation. The normal processing path attempts to delete the temporary copy when processing succeeds or fails. If an interruption prevents immediate deletion, the copy may remain in private storage until operational cleanup or account deletion removes it; VoiceBrief does not present it as permanent audio history.</p><p>In the ordinary in-app flow, a result is written to local history only when you choose Save. A Share Extension result is automatically saved locally on your device after import so the completion notification can open it. You can delete local results in the app.</p><p>The Supabase <code>processing_jobs.result</code> record may contain the complete generated result—including transcript, summary, tasks, dates, and replies—for up to 24 hours to support safe retries and prevent duplicate charging.</p></section>
<section><h2>OpenAI Processing</h2><p>VoiceBrief sends OpenAI requests with <code>store: false</code>, so Responses output is not retained as stored application data through that API feature. OpenAI may nevertheless retain API inputs and outputs in abuse-monitoring logs for up to 30 days unless the VoiceBrief account has been approved and configured for Zero Data Retention or Modified Abuse Monitoring. We do not currently claim that Zero Data Retention is enabled.</p></section>
<section><h2>Service Providers</h2><ul><li><strong>Supabase:</strong> authentication, database, temporary storage, and server processing.</li><li><strong>OpenAI:</strong> audio transcription and generation of summaries, tasks, dates, and suggested replies.</li><li><strong>RevenueCat, Apple, and Google:</strong> subscription and purchase status. VoiceBrief uses the Supabase account ID as the RevenueCat App User ID, and these providers may process product, entitlement, purchase date, expiration, and transaction history under their policies.</li><li><strong>Apple or Google:</strong> sign-in when you choose that option, including profile data shared by the provider.</li></ul><p>Calendar events open in your device’s system editor for review before saving. VoiceBrief does not store your calendar on its servers.</p></section>
<section><h2>What We Do Not Do</h2><p>We do not sell your data, use an advertising network, or include advertising-tracking tools. VoiceBrief cannot access audio you did not choose to share or record.</p></section>
<section><h2>Retention and Deletion</h2><p>Account and usage data needed to provide the service remains until account deletion or until it is no longer operationally required. You can delete a VoiceBrief account in Settings or submit a request on the <a href="./delete-account?lang=en">Delete Account page</a>. Canceling an App Store or Google Play subscription is a separate action and is not performed by deleting the VoiceBrief account. Transaction records may remain with the store or RevenueCat for legal or operational reasons. A Sign in with Apple user may also need to revoke VoiceBrief access manually in Apple Account settings after deletion.</p><p>We do not currently promise a fixed retention period for support and deletion requests. They are kept as needed to respond, verify account ownership, investigate abuse, protect the service, and satisfy legal obligations.</p></section>
<section><h2>Your Choices and Data Security</h2><p>You can choose not to upload audio, delete local results, sign out, revoke system permissions, and delete your account. We use encrypted transport and restricted access, but no online service is completely risk-free.</p></section>
<section><h2>Changes and Contact</h2><p>This policy may change when the service or requirements change. The date at the top will be updated for material changes. For privacy questions or data requests, use the <a href="./support?lang=en">Support page</a>. To delete an account, use the <a href="./delete-account?lang=en">Delete Account page</a>.</p></section>`;
}

function termsContent(lang: Language) {
  if (lang === "ar") {
    return `
<div class="notice">باستخدام VoiceBrief، فإنك توافق على هذه الشروط وسياسة الخصوصية. إذا لم توافق، فلا تستخدم الخدمة.</div>
<section><h2>الخدمة</h2><p>يحوّل VoiceBrief التسجيلات الصوتية التي تختارها إلى نصوص وملخصات ومهام وتواريخ وردود مقترحة. الخدمة أداة مساعدة وليست بديلًا عن مراجعتك البشرية.</p></section>
<section><h2>الحساب والاستخدام المقبول</h2><p>أنت مسؤول عن صحة معلومات حسابك وحماية وسيلة تسجيل الدخول. لا ترفع صوتًا لا تملك حق معالجته، ولا تستخدم الخدمة لانتهاك الخصوصية أو القانون أو حقوق الآخرين، أو لمحاولة تعطيل الخدمة أو تجاوز حدودها.</p></section>
<section><h2>دقة النتائج</h2><p>قد يخطئ الذكاء الاصطناعي في الكلمات أو الأسماء أو المواعيد أو المقصود. راجع النص والملخص والمهام بعناية، وأكّد أي موعد في محرر التقويم قبل حفظه. لا تعتمد على VoiceBrief وحده في قرارات طبية أو قانونية أو مالية أو طارئة.</p></section>
<section><h2>المحتوى</h2><p>تحتفظ بحقوقك في المحتوى الذي ترسله. تمنح VoiceBrief الإذن المحدود اللازم لمعالجة المحتوى وإرجاع النتيجة إليك وتشغيل الخدمة بأمان. أنت مسؤول عن امتلاك الموافقات والحقوق اللازمة.</p></section>
<section><h2>الاشتراكات والدفع</h2><p>تعرض المتاجر السعر والعملة والمدة الفعلية قبل الشراء. تُدار الفوترة والتجديد والإلغاء والاسترداد عبر متجر Apple أو Google وفق شروطه. حذف الحساب لا يلغي اشتراك المتجر تلقائيًا. تبقى المزايا المدفوعة متاحة عادةً حتى نهاية الفترة المدفوعة ما لم يقرر المتجر خلاف ذلك.</p></section>
<section><h2>التوفر وإنهاء الاستخدام</h2><p>قد تتوقف الخدمة مؤقتًا للصيانة أو بسبب مزود خارجي. يمكن تقييد الحساب عند إساءة الاستخدام أو وجود خطر أمني. يمكنك التوقف عن الاستخدام وحذف حسابك في أي وقت.</p></section>
<section><h2>حدود المسؤولية والتغييرات</h2><p>تُقدم الخدمة بالقدر المتاح وضمن الحدود التي يسمح بها القانون. لا نضمن أن تكون كل نتيجة كاملة أو خالية من الأخطاء. قد نحدّث هذه الشروط عند تغير الخدمة أو القانون؛ سيظهر تاريخ التحديث أعلى الصفحة.</p></section>
<section><h2>التواصل</h2><p>للاستفسارات عن هذه الشروط، استخدم <a href="./support?lang=ar">صفحة الدعم</a>.</p></section>`;
  }
  return `
<div class="notice">By using VoiceBrief, you agree to these Terms and the Privacy Policy. If you do not agree, do not use the service.</div>
<section><h2>The Service</h2><p>VoiceBrief turns audio you choose into transcripts, summaries, tasks, dates, and suggested replies. It is an assistive tool, not a replacement for your own review.</p></section>
<section><h2>Accounts and Acceptable Use</h2><p>You are responsible for accurate account information and for protecting your sign-in method. Do not upload audio you lack permission to process. Do not use the service to violate privacy, law, or another person’s rights, or to disrupt the service or bypass its limits.</p></section>
<section><h2>Result Accuracy</h2><p>AI can misunderstand words, names, dates, or intent. Review every transcript, brief, task, and date. Confirm calendar details in the system editor before saving. Do not rely on VoiceBrief alone for medical, legal, financial, emergency, or other high-stakes decisions.</p></section>
<section><h2>Your Content</h2><p>You keep your rights in content you submit. You grant VoiceBrief the limited permission needed to process it, return results to you, and operate the service safely. You are responsible for having all necessary rights and consents.</p></section>
<section><h2>Subscriptions and Billing</h2><p>The store displays the actual localized price, currency, and billing period before purchase. Apple or Google manages billing, renewal, cancellation, and refunds under its rules. Deleting a VoiceBrief account does not automatically cancel a store subscription. Paid access normally continues through the paid period unless the store determines otherwise.</p></section>
<section><h2>Availability and Ending Use</h2><p>The service may be temporarily unavailable for maintenance or because of a provider. Access may be limited for abuse or security risk. You can stop using VoiceBrief and delete your account at any time.</p></section>
<section><h2>Disclaimers, Liability, and Changes</h2><p>The service is provided as available and to the extent permitted by applicable law. We do not promise that every result is complete or error-free. These Terms may change when the service or law changes; the date at the top will show the latest material update.</p></section>
<section><h2>Contact</h2><p>For questions about these Terms, use the <a href="./support?lang=en">Support page</a>.</p></section>`;
}

function deleteAccountContent(
  lang: Language,
  url: URL,
  values: DeleteAccountValues = {
    email: "",
    provider: "",
    note: "",
    confirmed: false,
  },
  error = "",
) {
  const sent = url.searchParams.get("sent") === "1";
  const action = `${url.pathname}?lang=${lang}`;
  const appleSelected = values.provider === "apple" ? " selected" : "";
  const googleSelected = values.provider === "google" ? " selected" : "";
  const confirmed = values.confirmed ? " checked" : "";

  if (lang === "ar") {
    return `
${
      sent
        ? '<div class="notice success" role="status"><strong>تم استلام طلب حذف الحساب.</strong><br>لم يُحذف الحساب تلقائيًا من إرسال النموذج وحده. دخل الطلب قائمة الدعم الخاصة، وسيُتحقق من ملكية الحساب قبل تنفيذ الحذف.</div>'
        : ""
    }
${
      error
        ? `<div class="notice error" role="alert">${escapeHtml(error)}</div>`
        : ""
    }
<section><h2>الحذف من داخل التطبيق</h2><p>إذا كان بإمكانك تسجيل الدخول، فالطريقة الأسرع هي فتح «الإعدادات» في VoiceBrief ثم اختيار «حذف الحساب». هذا يحذف حساب VoiceBrief والبيانات الخاضعة لسيطرته، ويحذف النتائج المحلية على ذلك الجهاز.</p></section>
<section><h2>طلب حذف مباشر</h2><p>إذا تعذر عليك دخول التطبيق، أرسل الطلب أدناه باستخدام البريد المرتبط بحساب VoiceBrief. إذا استخدمت «إخفاء بريدي الإلكتروني» مع Apple، فاكتب عنوان الترحيل الظاهر لحساب VoiceBrief، إن أمكن.</p>
<form method="post" action="${escapeHtml(action)}">
  <label>البريد المرتبط بالحساب<input type="email" name="email" autocomplete="email" inputmode="email" spellcheck="false" maxlength="254" required value="${
      escapeHtml(values.email)
    }"><span class="hint">لا ترسل كلمة المرور أو رمز تسجيل الدخول.</span></label>
  <label>طريقة تسجيل الدخول<select name="provider" required><option value="">اختر</option><option value="apple"${appleSelected}>Apple</option><option value="google"${googleSelected}>Google</option></select></label>
  <label>ملاحظة اختيارية<textarea name="note" autocomplete="off" maxlength="1000">${
      escapeHtml(values.note)
    }</textarea><span class="hint">يمكنك ذكر معلومة غير سرية تساعد على تمييز الحساب. لا ترسل تسجيلات أو بيانات دفع.</span></label>
  <label class="check"><input type="checkbox" name="confirm" value="delete" required${confirmed}><span>أؤكد أنني أطلب حذف حساب VoiceBrief والبيانات المرتبطة به نهائيًا.</span></label>
  <label class="trap" aria-hidden="true">الموقع<input type="text" name="website" autocomplete="off" tabindex="-1"></label>
  <button type="submit">إرسال طلب الحذف</button>
</form></section>
<section><h2>كيف نتحقق من الطلب</h2><ol><li>يدخل الطلب قائمة الدعم الخاصة، ولا يؤدي إرسال النموذج وحده إلى حذف فوري.</li><li>يطابق المراجع البريد ومزود تسجيل الدخول مع سجل الحساب. إذا لم تكفِ المطابقة، يرسل طلب تحقق إلى البريد نفسه؛ لن نطلب كلمة مرور أو رمز دخول.</li><li>بعد التحقق، يُنفذ حذف البيانات الخاضعة لسيطرة VoiceBrief، وتُتابع معرّفات المعالجين المرتبطة بالحساب حيث ينطبق. قد نحتفظ بسجل محدود للطلب حسب الحاجة للأمان أو الالتزامات القانونية.</li></ol></section>
<section><h2>الاشتراك والوصول عبر Apple</h2><p><strong>إلغاء اشتراك المتجر منفصل عن حذف الحساب.</strong> احذف أو ألغِ اشتراك App Store أو Google Play من إعدادات المتجر؛ حذف حساب VoiceBrief لا يوقف الفوترة تلقائيًا.</p><p>قد يبقى تفويض «تسجيل الدخول باستخدام Apple» بعد حذف بيانات VoiceBrief. إذا بقي، يمكنك سحب الوصول يدويًا من إعدادات حساب Apple ضمن التطبيقات التي تستخدم Apple ID.</p></section>`;
  }

  return `
${
    sent
      ? '<div class="notice success" role="status"><strong>Account deletion request received.</strong><br>Submitting this form did not delete the account automatically. The request entered the private support queue, and ownership will be verified before deletion.</div>'
      : ""
  }
${
    error
      ? `<div class="notice error" role="alert">${escapeHtml(error)}</div>`
      : ""
  }
<section><h2>Delete in the App</h2><p>If you can sign in, the fastest path is VoiceBrief Settings → Delete Account. This removes the VoiceBrief account and data controlled by VoiceBrief, and clears local results on that device.</p></section>
<section><h2>Submit a Direct Deletion Request</h2><p>If you cannot access the app, submit this form using the email associated with your VoiceBrief account. If you used Apple Hide My Email, enter the relay address shown for VoiceBrief when possible.</p>
<form method="post" action="${escapeHtml(action)}">
  <label>Account Email<input type="email" name="email" autocomplete="email" inputmode="email" spellcheck="false" maxlength="254" required value="${
    escapeHtml(values.email)
  }"><span class="hint">Never send a password or sign-in code.</span></label>
  <label>Sign-in Provider<select name="provider" required><option value="">Choose one</option><option value="apple"${appleSelected}>Apple</option><option value="google"${googleSelected}>Google</option></select></label>
  <label>Optional Note<textarea name="note" autocomplete="off" maxlength="1000">${
    escapeHtml(values.note)
  }</textarea><span class="hint">You may include non-secret information that helps identify the account. Do not send audio or payment details.</span></label>
  <label class="check"><input type="checkbox" name="confirm" value="delete" required${confirmed}><span>I confirm that I am requesting permanent deletion of my VoiceBrief account and associated data.</span></label>
  <label class="trap" aria-hidden="true">Website<input type="text" name="website" autocomplete="off" tabindex="-1"></label>
  <button type="submit">Submit Deletion Request</button>
</form></section>
<section><h2>How We Verify the Request</h2><ol><li>The request enters the private support queue; submitting the form alone does not trigger immediate deletion.</li><li>A reviewer matches the email and sign-in provider against the account record. If that is insufficient, a verification request is sent to the same address. We will not ask for a password or sign-in code.</li><li>After verification, data controlled by VoiceBrief is deleted and associated processor identifiers are addressed where applicable. A limited request record may remain as needed for security or legal obligations.</li></ol></section>
<section><h2>Store Subscription and Apple Access</h2><p><strong>Canceling a store subscription is separate from deleting the account.</strong> Manage or cancel an App Store or Google Play subscription in the store settings; deleting a VoiceBrief account does not stop store billing automatically.</p><p>Sign in with Apple authorization may remain after VoiceBrief data is deleted. If it does, revoke VoiceBrief manually in Apple Account settings under apps using your Apple ID.</p></section>`;
}

interface SupportValues {
  email: string;
  category: string;
  subject: string;
  message: string;
}

function supportContent(
  lang: Language,
  url: URL,
  values: SupportValues = {
    email: "",
    category: "other",
    subject: "",
    message: "",
  },
  error = "",
) {
  const sent = url.searchParams.get("sent") === "1";
  const categories = lang === "ar"
    ? {
      account: "الحساب",
      audio: "معالجة الصوت",
      billing: "الاشتراك والدفع",
      privacy: "الخصوصية والبيانات",
      other: "أخرى",
    }
    : {
      account: "Account",
      audio: "Audio processing",
      billing: "Subscription and billing",
      privacy: "Privacy and data",
      other: "Other",
    };
  const options = Object.entries(categories)
    .map(
      ([value, label]) =>
        `<option value="${value}"${
          values.category === value ? " selected" : ""
        }>${label}</option>`,
    )
    .join("");
  const action = `${url.pathname}?lang=${lang}`;

  if (lang === "ar") {
    return `
${
      sent
        ? '<div class="notice success" role="status"><strong>تم إرسال طلبك.</strong><br>احتفظ بهذه الصفحة، وسيراجع فريق VoiceBrief الرسالة من لوحة الدعم.</div>'
        : ""
    }
${
      error
        ? `<div class="notice error" role="alert">${escapeHtml(error)}</div>`
        : ""
    }
<section><h2>مساعدة سريعة</h2><ul><li><strong>لم تتم معالجة الصوت:</strong> تأكد أن الاتصال مستقر وأن الملف مدعوم، ثم أعد المحاولة.</li><li><strong>لم يظهر الاشتراك:</strong> استخدم «استعادة المشتريات» بالحساب نفسه الذي اشترى الاشتراك.</li><li><strong>حذف الحساب:</strong> افتح الإعدادات ثم اختر حذف الحساب، أو استخدم <a href="./delete-account?lang=ar">صفحة حذف الحساب</a> إذا تعذر الدخول. ألغِ اشتراك المتجر بصورة منفصلة إذا كان نشطًا.</li></ul></section>
<section><h2>أرسل طلب دعم</h2><p>اكتب التفاصيل اللازمة فقط. لا ترسل كلمة مرور أو مفتاح API أو رقم بطاقة أو تسجيلًا صوتيًا حساسًا.</p>
<form method="post" action="${escapeHtml(action)}">
  <label>البريد الإلكتروني<input type="email" name="email" autocomplete="email" inputmode="email" spellcheck="false" maxlength="254" required value="${
      escapeHtml(values.email)
    }"><span class="hint">سنستخدمه للرد على هذا الطلب فقط.</span></label>
  <label>نوع المشكلة<select name="category" required>${options}</select></label>
  <label>العنوان<input type="text" name="subject" autocomplete="off" minlength="3" maxlength="120" required value="${
      escapeHtml(values.subject)
    }"></label>
  <label>التفاصيل<textarea name="message" autocomplete="off" minlength="20" maxlength="4000" required>${
      escapeHtml(values.message)
    }</textarea><span class="hint">اشرح ما حدث وما الذي كنت تتوقعه، من دون بيانات سرية.</span></label>
  <label class="trap" aria-hidden="true">الموقع<input type="text" name="website" autocomplete="off" tabindex="-1"></label>
  <button type="submit">إرسال طلب الدعم</button>
</form></section>
<section><h2>الخصوصية في الدعم</h2><p>نحفظ بريدك ورسالتك وبيانات محدودة لمنع الإغراق بالطلبات، ونستخدمها للرد وحماية الخدمة. راجع <a href="./privacy?lang=ar">سياسة الخصوصية</a>.</p></section>`;
  }
  return `
${
    sent
      ? '<div class="notice success" role="status"><strong>Support request sent.</strong><br>Keep this page for reference. The VoiceBrief team can review your message in the support dashboard.</div>'
      : ""
  }
${
    error
      ? `<div class="notice error" role="alert">${escapeHtml(error)}</div>`
      : ""
  }
<section><h2>Quick Help</h2><ul><li><strong>Audio did not process:</strong> Check that your connection is stable and the file type is supported, then try again.</li><li><strong>Subscription is missing:</strong> Use Restore Purchases with the same store account that made the purchase.</li><li><strong>Delete your account:</strong> Open Settings and choose Delete Account, or use the <a href="./delete-account?lang=en">Delete Account page</a> if you cannot sign in. Cancel an active store subscription separately.</li></ul></section>
<section><h2>Send a Support Request</h2><p>Include only the details needed to help. Never send a password, API key, payment-card number, or sensitive audio.</p>
<form method="post" action="${escapeHtml(action)}">
  <label>Email Address<input type="email" name="email" autocomplete="email" inputmode="email" spellcheck="false" maxlength="254" required value="${
    escapeHtml(values.email)
  }"><span class="hint">Used only to reply to this request.</span></label>
  <label>Issue Type<select name="category" required>${options}</select></label>
  <label>Subject<input type="text" name="subject" autocomplete="off" minlength="3" maxlength="120" required value="${
    escapeHtml(values.subject)
  }"></label>
  <label>Details<textarea name="message" autocomplete="off" minlength="20" maxlength="4000" required>${
    escapeHtml(values.message)
  }</textarea><span class="hint">Describe what happened and what you expected, without including secrets.</span></label>
  <label class="trap" aria-hidden="true">Website<input type="text" name="website" autocomplete="off" tabindex="-1"></label>
  <button type="submit">Send Support Request</button>
</form></section>
<section><h2>Support Privacy</h2><p>Your email, message, and limited anti-abuse data are kept to respond and protect the service. See the <a href="./privacy?lang=en">Privacy Policy</a>.</p></section>`;
}

function supportValues(form: FormData): SupportValues {
  return {
    email: String(form.get("email") ?? "")
      .trim()
      .toLowerCase(),
    category: String(form.get("category") ?? "other").trim(),
    subject: String(form.get("subject") ?? "").trim(),
    message: String(form.get("message") ?? "").trim(),
  };
}

function validationError(values: SupportValues, lang: Language) {
  const validEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(values.email);
  const validCategories = new Set([
    "account",
    "audio",
    "billing",
    "privacy",
    "other",
  ]);
  if (!validEmail || values.email.length > 254) {
    return lang === "ar"
      ? "أدخل بريدًا إلكترونيًا صالحًا."
      : "Enter a valid email address.";
  }
  if (!validCategories.has(values.category)) {
    return lang === "ar"
      ? "اختر نوعًا صالحًا للمشكلة."
      : "Choose a valid issue type.";
  }
  if (values.subject.length < 3 || values.subject.length > 120) {
    return lang === "ar"
      ? "اكتب عنوانًا من 3 إلى 120 حرفًا."
      : "Use a subject between 3 and 120 characters.";
  }
  if (values.message.length < 20 || values.message.length > 4000) {
    return lang === "ar"
      ? "اكتب تفاصيل من 20 إلى 4000 حرف."
      : "Enter between 20 and 4,000 characters of detail.";
  }
  return "";
}

async function sha256(value: string) {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

type StoredRequestResult =
  | "accepted"
  | "rate_limited"
  | "unavailable"
  | "failed";

async function storeSupportRequest(
  request: Request,
  lang: Language,
  values: SupportValues,
): Promise<StoredRequestResult> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const hashSecret = Deno.env.get("SUPPORT_HASH_SECRET") ?? "";
  if (!supabaseUrl || !serviceKey || !hashSecret) return "unavailable";

  const forwarded =
    request.headers.get("x-forwarded-for")?.split(",")[0].trim() ?? "unknown";
  const fingerprint = await sha256(`${hashSecret}:${forwarded}`);
  const client = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false },
  });
  const { data: submission, error } = await client.rpc(
    "submit_voicebrief_support_request",
    {
      p_request_key_hash: fingerprint,
      p_email: values.email,
      p_category: values.category,
      p_subject: values.subject,
      p_message: values.message,
      p_language: lang,
    },
  );
  if (error) return "unavailable";
  if (submission === "rate_limited") return "rate_limited";
  return submission === "accepted" ? "accepted" : "failed";
}

async function submitSupport(request: Request, url: URL, lang: Language) {
  const wantsJson =
    request.headers.get("accept")?.includes("application/json") ?? false;
  const failure = (
    status: number,
    message: string,
    values: SupportValues = {
      email: "",
      category: "other",
      subject: "",
      message: "",
    },
    extraHeaders = {},
  ) =>
    wantsJson
      ? jsonResponse(status, { error: message }, extraHeaders)
      : htmlResponse(
        shell(
          "support",
          lang,
          routeLabel("support", lang),
          message,
          supportContent(lang, url, values, message),
        ),
        status,
        { "cache-control": "no-store", ...extraHeaders },
      );
  let form: FormData;
  try {
    form = await boundedFormData(request, maxBodyBytes);
  } catch (error) {
    const status = error instanceof BoundedBodyError ? error.status : 400;
    const message = status === 413
      ? lang === "ar"
        ? "الطلب أكبر من الحد المسموح."
        : "The request is larger than allowed."
      : status === 415
      ? lang === "ar"
        ? "نوع الطلب غير مدعوم."
        : "The request type is not supported."
      : lang === "ar"
      ? "تعذر قراءة الطلب. أعد المحاولة."
      : "Unable to read the request. Try again.";
    return failure(status, message);
  }
  const values = supportValues(form);
  if (String(form.get("website") ?? "").trim().length > 0) {
    return wantsJson ? jsonResponse(201, { ok: true }) : new Response(null, {
      status: 303,
      headers: {
        "cache-control": "no-store",
        location: `${url.pathname}?sent=1&lang=${lang}`,
      },
    });
  }
  const invalid = validationError(values, lang);
  if (invalid) {
    return failure(400, invalid, values);
  }

  const submission = await storeSupportRequest(request, lang, values);
  if (submission === "unavailable") {
    const message = lang === "ar"
      ? "الدعم غير متاح مؤقتًا. حاول لاحقًا."
      : "Support is temporarily unavailable. Try again later.";
    return failure(503, message, values);
  }
  if (submission === "rate_limited") {
    const message = lang === "ar"
      ? "وصلت إلى حد طلبات الدعم اليومي. حاول بعد 24 ساعة."
      : "The daily support-request limit has been reached. Try again in 24 hours.";
    return failure(429, message, values, { "retry-after": "86400" });
  }

  if (submission !== "accepted") {
    const message = lang === "ar"
      ? "تعذر إرسال الطلب. حاول مرة أخرى."
      : "Unable to send the request. Try again.";
    return failure(500, message, values);
  }
  return wantsJson ? jsonResponse(201, { ok: true }) : new Response(null, {
    status: 303,
    headers: {
      "cache-control": "no-store",
      location: `${url.pathname}?sent=1&lang=${lang}`,
    },
  });
}

async function submitDeleteAccount(
  request: Request,
  url: URL,
  lang: Language,
) {
  const wantsJson =
    request.headers.get("accept")?.includes("application/json") ?? false;
  const failure = (
    status: number,
    message: string,
    values: DeleteAccountValues = {
      email: "",
      provider: "",
      note: "",
      confirmed: false,
    },
    extraHeaders = {},
  ) =>
    wantsJson
      ? jsonResponse(status, { error: message }, extraHeaders)
      : htmlResponse(
        shell(
          "delete-account",
          lang,
          routeLabel("delete-account", lang),
          message,
          deleteAccountContent(lang, url, values, message),
        ),
        status,
        { "cache-control": "no-store", ...extraHeaders },
      );

  let form: FormData;
  try {
    form = await boundedFormData(request, maxBodyBytes);
  } catch (error) {
    const status = error instanceof BoundedBodyError ? error.status : 400;
    const message = status === 413
      ? lang === "ar"
        ? "طلب الحذف أكبر من الحد المسموح."
        : "The deletion request is larger than allowed."
      : status === 415
      ? lang === "ar"
        ? "نوع الطلب غير مدعوم."
        : "The request type is not supported."
      : lang === "ar"
      ? "تعذر قراءة طلب الحذف. أعد المحاولة."
      : "Unable to read the deletion request. Try again.";
    return failure(status, message);
  }

  const values = deleteAccountValues(form);
  if (String(form.get("website") ?? "").trim().length > 0) {
    return wantsJson ? jsonResponse(201, { ok: true }) : new Response(null, {
      status: 303,
      headers: {
        "cache-control": "no-store",
        location: `${url.pathname}?sent=1&lang=${lang}`,
      },
    });
  }
  const invalid = deleteAccountValidationError(values, lang);
  if (invalid) return failure(400, invalid, values);

  const submission = await storeSupportRequest(
    request,
    lang,
    deletionSubmission(values, lang),
  );
  if (submission === "unavailable") {
    const message = lang === "ar"
      ? "إرسال طلب الحذف غير متاح مؤقتًا. حاول لاحقًا."
      : "Account deletion requests are temporarily unavailable. Try again later.";
    return failure(503, message, values);
  }
  if (submission === "rate_limited") {
    const message = lang === "ar"
      ? "وصلت إلى حد الطلبات اليومي. حاول بعد 24 ساعة."
      : "The daily request limit has been reached. Try again in 24 hours.";
    return failure(429, message, values, { "retry-after": "86400" });
  }
  if (submission !== "accepted") {
    const message = lang === "ar"
      ? "تعذر إرسال طلب الحذف. حاول مرة أخرى."
      : "Unable to submit the deletion request. Try again.";
    return failure(500, message, values);
  }
  return wantsJson ? jsonResponse(201, { ok: true }) : new Response(null, {
    status: 303,
    headers: {
      "cache-control": "no-store",
      location: `${url.pathname}?sent=1&lang=${lang}`,
    },
  });
}

Deno.serve(async (request) => {
  const url = new URL(request.url);
  const route = routeFor(url);
  if (!route) {
    return new Response(null, {
      status: 302,
      headers: { location: "./privacy" },
    });
  }
  const lang = languageFor(request, url);
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: securityHeaders });
  }
  if (request.method === "POST" && route === "support") {
    return await submitSupport(request, url, lang);
  }
  if (request.method === "POST" && route === "delete-account") {
    return await submitDeleteAccount(request, url, lang);
  }
  if (request.method !== "GET" && request.method !== "HEAD") {
    return new Response("Method not allowed", {
      status: 405,
      headers: {
        allow: route === "support" || route === "delete-account"
          ? "GET, HEAD, POST"
          : "GET, HEAD",
      },
    });
  }

  const content = route === "privacy"
    ? privacyContent(lang)
    : route === "terms"
    ? termsContent(lang)
    : route === "support"
    ? supportContent(lang, url)
    : deleteAccountContent(lang, url);
  const descriptions = lang === "ar"
    ? {
      privacy: "كيف يتعامل VoiceBrief مع بياناتك والصوت الذي تختاره.",
      terms: "القواعد الواضحة لاستخدام VoiceBrief.",
      support: "مساعدة VoiceBrief وطلبات الدعم.",
      "delete-account": "حذف حساب VoiceBrief وبياناته المرتبطة.",
    }
    : {
      privacy: "How VoiceBrief handles your data and the audio you choose.",
      terms: "Clear rules for using VoiceBrief.",
      support: "VoiceBrief help and support requests.",
      "delete-account": "Delete a VoiceBrief account and associated data.",
    };
  const page = shell(
    route,
    lang,
    routeLabel(route, lang),
    descriptions[route],
    content,
  );
  return htmlResponse(request.method === "HEAD" ? "" : page);
});
