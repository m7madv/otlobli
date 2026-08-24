import { createClient } from "@supabase/supabase-js";

type Language = "en" | "ar";
type LegalRoute = "privacy" | "terms" | "support";

const policyDate = "2026-08-24";
const maxBodyBytes = 32_768;
const maxRequestsPerDay = 5;

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
  if (route === "privacy" || route === "terms" || route === "support") {
    return route;
  }
  return null;
}

function routeLabel(route: LegalRoute, lang: Language) {
  const labels = {
    en: { privacy: "Privacy", terms: "Terms", support: "Support" },
    ar: { privacy: "الخصوصية", terms: "الشروط", support: "الدعم" },
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
  const updatedText = lang === "ar" ? "24 أغسطس 2026" : "August 24, 2026";
  const footerText =
    lang === "ar"
      ? "VoiceBrief — رسائلك الصوتية، واضحة."
      : "VoiceBrief — Voice messages, made clear.";

  const nav = (["privacy", "terms", "support"] as LegalRoute[])
    .map(
      (item) =>
        `<a href="./${item}?lang=${lang}"${item === route ? ' aria-current="page"' : ""}>${routeLabel(item, lang)}</a>`,
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
      <nav aria-label="${lang === "ar" ? "روابط قانونية" : "Legal navigation"}">${nav}<a class="language" lang="${otherLanguage}" href="./${route}?lang=${otherLanguage}">${otherLabel}</a></nav>
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
<section><h2>البيانات التي نعالجها</h2><ul><li><strong>بيانات الحساب:</strong> البريد الإلكتروني، معرّف الحساب، ومعلومات مزود تسجيل الدخول.</li><li><strong>المحتوى الصوتي:</strong> الملف الذي تختار مشاركته أو استيراده أو تسجيله لمعالجته.</li><li><strong>النتائج:</strong> النص المكتوب والملخص والمهام والردود المقترحة التي ينشئها التطبيق.</li><li><strong>الاشتراك والاستخدام:</strong> حالة الاستحقاق، مدة الاشتراك، والدقائق المستخدمة.</li><li><strong>الدعم والتشخيص:</strong> المعلومات التي ترسلها في نموذج الدعم ورموز أخطاء تشغيلية منقحة.</li></ul></section>
<section><h2>طريقة معالجة الصوت</h2><p>لا يبدأ الرفع إلا بعد أن تختار ملفًا أو تسجيلًا. يُرفع الصوت إلى مساحة خاصة مؤقتة في Supabase، ثم يُرسل إلى OpenAI لتحويله إلى نص وإنشاء النتيجة. يُحذف الملف المؤقت بعد اكتمال المعالجة أو فشلها. لا يستخدم VoiceBrief خدمة Gemini لمعالجة الصوت أو تلخيصه.</p><p>لا يُحفظ النص أو الملخص في سجل الجهاز إلا عندما تختار الحفظ. قد يُحتفظ ببيانات عمل تقنية محدودة لمدة تصل إلى 24 ساعة لمنع تكرار احتساب الطلب نفسه، من دون الاحتفاظ بنسخة دائمة من الصوت.</p></section>
<section><h2>الخدمات التي نعتمد عليها</h2><ul><li><strong>Supabase:</strong> الحساب، قاعدة البيانات، التخزين المؤقت، وتشغيل المعالجة.</li><li><strong>OpenAI:</strong> تحويل الصوت إلى نص وإنشاء الملخص والمهام والردود.</li><li><strong>RevenueCat ومتجرا Apple وGoogle:</strong> إدارة الاشتراك وحالة الشراء عند تفعيل المنتجات.</li><li><strong>Apple أو Google:</strong> تسجيل الدخول فقط عندما تختار أحدهما وبعد تفعيله.</li></ul><p>يُفتح حدث التقويم في محرر النظام لتراجعه قبل الحفظ؛ لا يحفظ VoiceBrief تقويمك على خوادمه.</p></section>
<section><h2>ما لا نفعله</h2><p>لا نبيع بياناتك، ولا نستخدم شبكة إعلانات، ولا نضيف أدوات تتبع إعلاني. لا يصل VoiceBrief إلى صوت لم تختر مشاركته أو تسجيله.</p></section>
<section><h2>الاحتفاظ والحذف</h2><p>تبقى بيانات الحساب والاستخدام اللازمة لتقديم الخدمة حتى حذف الحساب أو انتهاء الحاجة التشغيلية إليها. يمكنك حذف الحساب من الإعدادات؛ يشمل ذلك بيانات الحساب والتخزين المرتبط به. قد يتطلب إلغاء الاشتراك إجراءً منفصلًا داخل متجر Apple أو Google، وتخضع سجلات الدفع لسياسة المتجر والمتطلبات النظامية.</p><p>نحتفظ بطلبات الدعم فقط للمدة اللازمة للرد وحماية الخدمة، ثم نحذفها وفق سياسة الاحتفاظ التشغيلية.</p></section>
<section><h2>اختياراتك وأمان البيانات</h2><p>يمكنك الامتناع عن رفع الصوت، حذف النتائج المحلية، تسجيل الخروج، إلغاء أذونات النظام، وحذف الحساب. نستخدم اتصالًا مشفرًا وصلاحيات وصول مقيدة، لكن لا توجد خدمة إلكترونية خالية تمامًا من المخاطر.</p></section>
<section><h2>التغييرات والتواصل</h2><p>قد نحدّث هذه السياسة عندما تتغير الخدمة أو المتطلبات. سنحدّث التاريخ أعلى الصفحة عند إجراء تغيير جوهري. لأسئلة الخصوصية أو طلبات البيانات، استخدم <a href="./support?lang=ar">صفحة الدعم</a>.</p></section>`;
  }
  return `
<section><h2>Scope</h2><p>This policy explains how VoiceBrief handles data when you create an account, share audio, purchase a subscription, or contact support.</p></section>
<section><h2>Data We Process</h2><ul><li><strong>Account data:</strong> email address, account identifier, and sign-in provider information.</li><li><strong>Audio content:</strong> the file you choose to share, import, or record for processing.</li><li><strong>Generated results:</strong> transcript, summary, tasks, dates, and suggested replies.</li><li><strong>Subscription and usage:</strong> entitlement status, subscription period, and processing minutes used.</li><li><strong>Support and diagnostics:</strong> information you submit through the support form and redacted operational error codes.</li></ul></section>
<section><h2>How Audio Is Processed</h2><p>Uploading starts only after you select or record audio. The audio is uploaded to private temporary storage in Supabase, then sent to OpenAI for transcription and result generation. The temporary audio is deleted after processing succeeds or fails. VoiceBrief does not use Gemini to process or summarize your audio.</p><p>Transcripts and briefs are saved in local history only when you choose Save. Limited job metadata may remain for up to 24 hours to prevent duplicate billing, without keeping a permanent copy of the audio.</p></section>
<section><h2>Service Providers</h2><ul><li><strong>Supabase:</strong> authentication, database, temporary storage, and server processing.</li><li><strong>OpenAI:</strong> audio transcription and generation of summaries, tasks, and suggested replies.</li><li><strong>RevenueCat, Apple, and Google:</strong> subscription and purchase status when store products are enabled.</li><li><strong>Apple or Google:</strong> sign-in only when you choose that option and it is enabled.</li></ul><p>Calendar events open in your device’s system editor for review before saving. VoiceBrief does not store your calendar on its servers.</p></section>
<section><h2>What We Do Not Do</h2><p>We do not sell your data, use an advertising network, or include advertising-tracking tools. VoiceBrief cannot access audio you did not choose to share or record.</p></section>
<section><h2>Retention and Deletion</h2><p>Account and usage data needed to provide the service remains until you delete the account or it is no longer operationally required. You can delete your account in Settings; this removes the account data and associated storage controlled by VoiceBrief. Canceling a subscription may require a separate action in the Apple or Google store, and payment records remain subject to store policies and legal requirements.</p><p>Support requests are kept only as long as needed to respond and protect the service, then removed under the operational retention process.</p></section>
<section><h2>Your Choices and Data Security</h2><p>You can choose not to upload audio, delete local results, sign out, revoke system permissions, and delete your account. We use encrypted transport and restricted access, but no online service is completely risk-free.</p></section>
<section><h2>Changes and Contact</h2><p>This policy may change when the service or requirements change. The date at the top will be updated for material changes. For privacy questions or data requests, use the <a href="./support?lang=en">Support page</a>.</p></section>`;
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
  const categories =
    lang === "ar"
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
        `<option value="${value}"${values.category === value ? " selected" : ""}>${label}</option>`,
    )
    .join("");
  const action = `${url.pathname}?lang=${lang}`;

  if (lang === "ar") {
    return `
${sent ? '<div class="notice success" role="status"><strong>تم إرسال طلبك.</strong><br>احتفظ بهذه الصفحة، وسيراجع فريق VoiceBrief الرسالة من لوحة الدعم.</div>' : ""}
${error ? `<div class="notice error" role="alert">${escapeHtml(error)}</div>` : ""}
<section><h2>مساعدة سريعة</h2><ul><li><strong>لم تتم معالجة الصوت:</strong> تأكد أن الاتصال مستقر وأن الملف مدعوم، ثم أعد المحاولة.</li><li><strong>لم يظهر الاشتراك:</strong> استخدم «استعادة المشتريات» بالحساب نفسه الذي اشترى الاشتراك.</li><li><strong>حذف الحساب:</strong> افتح الإعدادات ثم اختر حذف الحساب. ألغِ اشتراك المتجر بصورة منفصلة إذا كان نشطًا.</li></ul></section>
<section><h2>أرسل طلب دعم</h2><p>اكتب التفاصيل اللازمة فقط. لا ترسل كلمة مرور أو مفتاح API أو رقم بطاقة أو تسجيلًا صوتيًا حساسًا.</p>
<form method="post" action="${escapeHtml(action)}">
  <label>البريد الإلكتروني<input type="email" name="email" autocomplete="email" inputmode="email" spellcheck="false" maxlength="254" required value="${escapeHtml(values.email)}"><span class="hint">سنستخدمه للرد على هذا الطلب فقط.</span></label>
  <label>نوع المشكلة<select name="category" required>${options}</select></label>
  <label>العنوان<input type="text" name="subject" autocomplete="off" minlength="3" maxlength="120" required value="${escapeHtml(values.subject)}"></label>
  <label>التفاصيل<textarea name="message" autocomplete="off" minlength="20" maxlength="4000" required>${escapeHtml(values.message)}</textarea><span class="hint">اشرح ما حدث وما الذي كنت تتوقعه، من دون بيانات سرية.</span></label>
  <label class="trap" aria-hidden="true">الموقع<input type="text" name="website" autocomplete="off" tabindex="-1"></label>
  <button type="submit">إرسال طلب الدعم</button>
</form></section>
<section><h2>الخصوصية في الدعم</h2><p>نحفظ بريدك ورسالتك وبيانات محدودة لمنع الإغراق بالطلبات، ونستخدمها للرد وحماية الخدمة. راجع <a href="./privacy?lang=ar">سياسة الخصوصية</a>.</p></section>`;
  }
  return `
${sent ? '<div class="notice success" role="status"><strong>Support request sent.</strong><br>Keep this page for reference. The VoiceBrief team can review your message in the support dashboard.</div>' : ""}
${error ? `<div class="notice error" role="alert">${escapeHtml(error)}</div>` : ""}
<section><h2>Quick Help</h2><ul><li><strong>Audio did not process:</strong> Check that your connection is stable and the file type is supported, then try again.</li><li><strong>Subscription is missing:</strong> Use Restore Purchases with the same store account that made the purchase.</li><li><strong>Delete your account:</strong> Open Settings and choose Delete Account. Cancel an active store subscription separately.</li></ul></section>
<section><h2>Send a Support Request</h2><p>Include only the details needed to help. Never send a password, API key, payment-card number, or sensitive audio.</p>
<form method="post" action="${escapeHtml(action)}">
  <label>Email Address<input type="email" name="email" autocomplete="email" inputmode="email" spellcheck="false" maxlength="254" required value="${escapeHtml(values.email)}"><span class="hint">Used only to reply to this request.</span></label>
  <label>Issue Type<select name="category" required>${options}</select></label>
  <label>Subject<input type="text" name="subject" autocomplete="off" minlength="3" maxlength="120" required value="${escapeHtml(values.subject)}"></label>
  <label>Details<textarea name="message" autocomplete="off" minlength="20" maxlength="4000" required>${escapeHtml(values.message)}</textarea><span class="hint">Describe what happened and what you expected, without including secrets.</span></label>
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
          extraHeaders,
        );
  const contentLength = Number(request.headers.get("content-length") ?? "0");
  if (contentLength > maxBodyBytes) {
    const message =
      lang === "ar"
        ? "الطلب أكبر من الحد المسموح."
        : "The request is larger than allowed.";
    return failure(413, message);
  }

  let form: FormData;
  try {
    form = await request.formData();
  } catch {
    const message =
      lang === "ar"
        ? "تعذر قراءة الطلب. أعد المحاولة."
        : "Unable to read the request. Try again.";
    return failure(400, message);
  }
  const values = supportValues(form);
  if (String(form.get("website") ?? "").trim().length > 0) {
    return wantsJson
      ? jsonResponse(201, { ok: true })
      : new Response(null, {
          status: 303,
          headers: { location: `${url.pathname}?sent=1&lang=${lang}` },
        });
  }
  const invalid = validationError(values, lang);
  if (invalid) {
    return failure(400, invalid, values);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const hashSecret = Deno.env.get("SUPPORT_HASH_SECRET") ?? "";
  if (!supabaseUrl || !serviceKey || !hashSecret) {
    const message =
      lang === "ar"
        ? "الدعم غير متاح مؤقتًا. حاول لاحقًا."
        : "Support is temporarily unavailable. Try again later.";
    return failure(503, message, values);
  }

  const forwarded =
    request.headers.get("x-forwarded-for")?.split(",")[0].trim() ?? "unknown";
  const fingerprint = await sha256(`${hashSecret}:${forwarded}`);
  const client = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false },
  });
  const since = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
  const { count, error: countError } = await client
    .from("support_requests")
    .select("id", { count: "exact", head: true })
    .eq("request_key_hash", fingerprint)
    .gte("created_at", since);
  if (countError) {
    const message =
      lang === "ar"
        ? "الدعم غير متاح مؤقتًا. حاول لاحقًا."
        : "Support is temporarily unavailable. Try again later.";
    return failure(503, message, values);
  }
  if ((count ?? 0) >= maxRequestsPerDay) {
    const message =
      lang === "ar"
        ? "وصلت إلى حد طلبات الدعم اليومي. حاول بعد 24 ساعة."
        : "The daily support-request limit has been reached. Try again in 24 hours.";
    return failure(429, message, values, { "retry-after": "86400" });
  }

  const { error } = await client.from("support_requests").insert({
    email: values.email,
    category: values.category,
    subject: values.subject,
    message: values.message,
    language: lang,
    request_key_hash: fingerprint,
  });
  if (error) {
    const message =
      lang === "ar"
        ? "تعذر إرسال الطلب. حاول مرة أخرى."
        : "Unable to send the request. Try again.";
    return failure(500, message, values);
  }
  return wantsJson
    ? jsonResponse(201, { ok: true })
    : new Response(null, {
        status: 303,
        headers: { location: `${url.pathname}?sent=1&lang=${lang}` },
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
  if (request.method !== "GET" && request.method !== "HEAD") {
    return new Response("Method not allowed", {
      status: 405,
      headers: { allow: route === "support" ? "GET, HEAD, POST" : "GET, HEAD" },
    });
  }

  const content =
    route === "privacy"
      ? privacyContent(lang)
      : route === "terms"
        ? termsContent(lang)
        : supportContent(lang, url);
  const descriptions =
    lang === "ar"
      ? {
          privacy: "كيف يتعامل VoiceBrief مع بياناتك والصوت الذي تختاره.",
          terms: "القواعد الواضحة لاستخدام VoiceBrief.",
          support: "مساعدة VoiceBrief وطلبات الدعم.",
        }
      : {
          privacy: "How VoiceBrief handles your data and the audio you choose.",
          terms: "Clear rules for using VoiceBrief.",
          support: "VoiceBrief help and support requests.",
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
