import { copyFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { createHash, randomBytes } from 'node:crypto';
import { dirname, join, resolve } from 'node:path';
import { marketingGuides } from './marketing_guides.mjs';

// Public, static marketing only. No application credentials, tracking, or customer data.
const root = resolve(import.meta.dirname, '..');
const out = join(root, 'legal_site');
const origin = 'https://voicebrief-legal.vercel.app';
const appStore = 'https://apps.apple.com/app/id6805194629';
// Public ownership proof supplied by Search Console for the owner-approved account.
// Keep this across rebuilds; it is not an API key or a tracking integration.
const googleSiteVerification = 'xj01l4NyENmfI34W8c1lRz-b_4P7XSo2dQO_WKqiT1Q';
const updated = '2026-09-20';
const appCheckedOn = '2026-09-19';
const languages = ['Arabic', 'English', 'Bengali', 'French', 'Hindi', 'Indonesian', 'Portuguese', 'Russian', 'Simplified Chinese', 'Spanish', 'Urdu'];
const esc = (text) => String(text).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
const put = (path, data) => { const dest = join(out, path); mkdirSync(dirname(dest), { recursive: true }); writeFileSync(dest, data); };
const link = (url, text, attrs = '') => `<a href="${esc(url)}"${attrs ? ` ${attrs}` : ''}>${text}</a>`;
const home = (lang) => lang === 'ar' ? '/ar' : '/';
const guide = (lang) => `${lang === 'ar' ? '/ar' : ''}/guides/whatsapp-voice-notes`;
const press = (lang) => `${lang === 'ar' ? '/ar' : ''}/press`;
const resource = (lang, slug) => `${lang === 'ar' ? '/ar' : ''}/guides/${slug}`;
const route = (lang, kind) => kind === 'home' ? home(lang) : kind === 'guide' ? guide(lang) : kind === 'press' ? press(lang) : resource(lang, kind);
const legal = (page, lang) => `/${page}?lang=${lang}`;
const copy = {
  en: {
    title: 'VoiceBrief — Voice note summaries for iPhone & iPad',
    description: 'Turn shared WhatsApp voice notes and audio files into transcripts, summaries, tasks, dates, and suggested replies. VoiceBrief for iPhone and iPad.',
    skip: 'Skip to content', nav: 'Main navigation', features: 'What you get', how: 'How it works', help: 'Support', download: 'Download on the App Store', switch: 'العربية', switchLang: 'ar',
    eyebrow: 'VOICEBRIEF · FOR IPHONE & IPAD', headline: 'Long voice notes.\nClear next steps.',
    intro: 'A long voice note. A clear next step. Turn the audio you share into a readable summary, a transcript, and the details worth keeping.',
    price: 'Free to download · Optional Pro subscription', require: 'iOS 14 or later · Internet and an Apple or Google account required',
    caption: 'Real app screens with illustrative sample content.',
    storyLabel: 'FROM A VOICE NOTE TO A PLAN', story: 'The message is more than words.',
    storyText: 'Understand the point, find the next action, and check the details without replaying the whole recording.',
    outputs: [
      ['Read the essentials', 'A concise brief and key points, alongside the word-for-word transcript for reference.'],
      ['Keep track of the next step', 'Review suggested tasks and important dates. Confirm the details before adding an event to your calendar.'],
      ['Find the words to reply', 'Use a suggested reply as a starting point. Edit it, copy it, and send it yourself.'],
      ['Return to what matters', 'Choose which results to keep in your on-device text history. Share-extension results are saved locally for their ready notification.'],
    ],
    steps: [
      ['Bring your audio', 'Share a voice note from WhatsApp or another app that offers audio sharing, choose an audio file, or record in VoiceBrief.'],
      ['Choose what to process', 'In the app, preview the audio and select a section before processing. An internet connection is required.'],
      ['Read, check, and act', 'Review the result, edit a reply, or confirm a date. AI can make mistakes, especially with names and ambiguous times.'],
    ],
    guideLink: 'How to summarize a WhatsApp voice note on iPhone', gallery: 'A closer look at VoiceBrief',
    galleryLabels: ['Import or record audio', 'Summary and key points', 'Dates and suggested replies', 'Saved text history'],
    langTitle: 'Your interface. Your language.', langBody: 'Choose from 11 interface languages in Settings. Your choice stays saved after restarting. Interface language is separate from the language spoken in a recording.',
    privacyTitle: 'Know what happens to your audio.', privacyBody: 'You choose what to upload. Processing uses cloud services, not an offline-only model. Audio is handled as temporary data; generated results may remain on the server for up to 24 hours for safe retries. The privacy policy explains deletion, interruptions, and provider retention.',
    privacyLink: 'Read the privacy policy', faqTitle: 'Before you download',
    faq: [
      ['Is VoiceBrief completely free?', 'It is free to download with limited free usage and optional Pro subscriptions. Some result sections and reply styles require Pro. Current prices and limits are shown in the app and your App Store region.'],
      ['Can it summarize WhatsApp voice messages?', 'Yes. Select a voice message in WhatsApp and use its sharing options to choose VoiceBrief. The exact steps depend on the source app. VoiceBrief processes only audio you choose to share; it does not read your chats.'],
      ['Does it work offline?', 'No. Sign in with Apple or Google and connect to the internet for audio processing. Saved text history is stored on your device.'],
      ['Will every date be correct?', 'No AI system can guarantee that. Review dates and times before relying on them. Ambiguous times may need confirmation, and calendar events open for your review before saving.'],
      ['Are alarms added to the iPhone Clock app?', 'No. On iOS 26.1 or later, supported alarms belong to VoiceBrief and can be managed in the app, not the Clock alarm list. Older iOS versions use notification reminders. Permissions are required.'],
      ['Who makes this VoiceBrief?', 'VoiceBrief: Audio Summaries is published by mohammad alzouabi. Its Apple App Store ID is 6805194629. Use the store link on this page to distinguish it from similarly named products.'],
    ],
    bottom: 'Your next voice note, made clearer.', bottomText: 'Download VoiceBrief for iPhone and iPad.', privacy: 'Privacy', terms: 'Terms', delete: 'Delete account', press: 'Press & product facts', footer: 'An independent app by MOHAMMAD ALZOUABI. Not affiliated with WhatsApp or Meta.',
    guideTitle: 'How to summarize WhatsApp voice notes on iPhone', guideDescription: 'A practical guide to sharing a WhatsApp voice message with VoiceBrief, reviewing its transcript and summary, and checking extracted dates.',
    guideIntro: 'VoiceBrief turns an audio message you choose to share into a transcript and a brief. It does not connect to or scan your WhatsApp conversations.',
    guideSteps: [
      ['Set up VoiceBrief', 'Install VoiceBrief from the App Store, open it, and sign in with Apple or Google. Check your available processing minutes and internet connection. Allow notifications if you want a summary-ready alert.'],
      ['Share the message from WhatsApp', 'Press and hold the voice message, then use WhatsApp’s forwarding or sharing controls to open the iOS share sheet. Choose VoiceBrief; if it is not visible, check More. Menus can differ by WhatsApp version.'],
      ['Follow the import status', 'Read the status in the VoiceBrief share window. Follow its on-screen instructions about when you can close it. If a summary-ready notification arrives, tap it to open that result. iOS does not guarantee that sharing will open the full app immediately.'],
      ['Check the result before acting', 'Read the summary and expand the transcript when you need the original wording. Review any proposed date, choose a time when it is ambiguous, and confirm it in the calendar editor before saving.'],
    ],
    guideTrouble: 'If you cannot share the file', guideTroubleText: 'Open VoiceBrief and import an audio file you have permission to use. Check the supported format, connection, sign-in state, and remaining minutes. For a specific failure, contact support without sending passwords or sensitive recordings.',
    pressTitle: 'VoiceBrief — press kit & product facts', pressDescription: 'Official VoiceBrief product information, App Store link, screenshots, icon, capabilities, and limitations for editors and app directories.',
    pressIntro: 'Accurate, reusable information for app directories, reviewers, and journalists. Product details were checked against the public App Store listing on September 19, 2026.',
    short: 'Short description', long: 'About the app', images: 'Official screenshots', icon: 'Download the app icon', screenshotsNote: 'Screenshots show the actual app interface with illustrative, non-personal sample data. They are software-rendered marketing images, not photographs of physical devices. Credit VoiceBrief; do not imply Apple endorsement or add unshipped features.',
    facts: [['Product', 'VoiceBrief: Audio Summaries'], ['Publisher', 'mohammad alzouabi'], ['Apple App Store ID', '6805194629'], ['Platforms promoted here', 'iPhone and iPad, iOS / iPadOS 14 or later'], ['Pricing', 'Free download with limited free usage; optional in-app subscriptions'], ['Published version verified', '0.1.2'], ['Interface languages', languages.join(', ')], ['Processing', 'Cloud-based; internet connection and sign-in required']],
  },
  ar: {
    title: 'VoiceBrief — تلخيص الرسائل الصوتية للآيفون والآيباد',
    description: 'حوّل رسائل واتساب الصوتية والملفات الصوتية إلى نص وملخص ومهام ومواعيد وردود مقترحة. تعرّف على VoiceBrief وحمّله للآيفون والآيباد.',
    skip: 'انتقل إلى المحتوى', nav: 'التنقل الرئيسي', features: 'ماذا تحصل عليه؟', how: 'كيف يعمل؟', help: 'الدعم', download: 'تنزيل من App Store', switch: 'English', switchLang: 'en',
    eyebrow: 'VOICEBRIEF · للآيفون والآيباد', headline: 'افهم الرسالة.\nدون تكرار الاستماع.',
    intro: 'رسالة صوتية طويلة، وخطوة تالية واضحة. حوّل الصوت الذي تشاركه إلى ملخص مقروء ونص مكتوب وتفاصيل تستحق أن تحتفظ بها.',
    price: 'تنزيل مجاني · اشتراك Pro اختياري', require: 'يتطلب iOS 14 أو أحدث، واتصالًا بالإنترنت، وحساب Apple أو Google',
    caption: 'واجهات التطبيق الفعلية بمحتوى توضيحي.',
    storyLabel: 'من رسالة صوتية إلى خطوة واضحة', story: 'في الرسالة أكثر من كلمات.',
    storyText: 'افهم الفكرة، وحدّد المطلوب، وراجع التفاصيل دون إعادة التسجيل كاملًا.',
    outputs: [
      ['اقرأ المهم', 'ملخص موجز ونقاط أساسية، مع النص الحرفي للتسجيل عندما تحتاج إلى مراجعة الكلام.'],
      ['تابع الخطوة التالية', 'راجع المهام والمواعيد المقترحة، ثم أكّد التفاصيل قبل إضافة موعد إلى تقويمك.'],
      ['ابدأ الرد بكلمات مناسبة', 'استخدم الرد المقترح نقطة بداية، ثم عدّله وانسخه وأرسله بنفسك.'],
      ['ارجع إلى ما يهمك', 'اختر النتائج التي تحتفظ بها في السجل النصي على جهازك. تُحفظ نتائج نافذة المشاركة محليًا لفتحها من إشعار الجاهزية.'],
    ],
    steps: [
      ['اختر التسجيل', 'شارك رسالة صوتية من واتساب أو تطبيق يتيح مشاركة الصوت، أو اختر ملفًا صوتيًا، أو سجّل داخل VoiceBrief.'],
      ['حدّد الجزء المطلوب', 'داخل التطبيق يمكنك الاستماع إلى التسجيل وتحديد الجزء الذي تريد معالجته. يلزم اتصال بالإنترنت.'],
      ['اقرأ وراجع وتصرّف', 'راجع النتيجة، وعدّل الرد، أو أكّد الموعد. قد يخطئ الذكاء الاصطناعي، خصوصًا في الأسماء والأوقات المبهمة.'],
    ],
    guideLink: 'طريقة تلخيص رسائل واتساب الصوتية على الآيفون', gallery: 'نظرة من داخل VoiceBrief',
    galleryLabels: ['استيراد الصوت أو تسجيله', 'الملخص والنقاط الأساسية', 'المواعيد والردود المقترحة', 'السجل النصي المحفوظ'],
    langTitle: 'واجهتك، بلغتك.', langBody: 'اختر من 11 لغة للواجهة في الإعدادات. يبقى اختيارك محفوظًا بعد إعادة التشغيل. لغة الواجهة مستقلة عن اللغة المنطوقة في التسجيل.',
    privacyTitle: 'اعرف أين يذهب تسجيلك.', privacyBody: 'أنت تختار ما ترفعه. تتم المعالجة عبر خدمات سحابية، وليست محلية دون إنترنت. يُعامل الصوت كبيانات مؤقتة، وقد تبقى النتائج على الخادم حتى 24 ساعة لإعادة المحاولة بأمان. توضح سياسة الخصوصية الحذف وحالات الانقطاع واحتفاظ مزودي الخدمة بالبيانات.',
    privacyLink: 'اقرأ سياسة الخصوصية', faqTitle: 'قبل التنزيل',
    faq: [
      ['هل VoiceBrief مجاني بالكامل؟', 'التنزيل مجاني مع استخدام مجاني محدود واشتراكات Pro اختيارية. تحتاج بعض أقسام النتيجة وأنماط الردود إلى Pro. تظهر الأسعار والحدود الحالية داخل التطبيق وفي متجر بلدك.'],
      ['هل يلخّص رسائل واتساب الصوتية؟', 'نعم. اختر رسالة صوتية في واتساب واستخدم خيارات المشاركة للوصول إلى VoiceBrief. تختلف الخطوات بحسب التطبيق المصدر. لا يقرأ VoiceBrief محادثاتك؛ يعالج فقط الصوت الذي تختار مشاركته.'],
      ['هل يعمل دون إنترنت؟', 'لا. تحتاج معالجة الصوت إلى اتصال بالإنترنت وتسجيل الدخول عبر Apple أو Google. يُخزّن السجل النصي المحفوظ على جهازك.'],
      ['هل جميع المواعيد المستخرجة صحيحة؟', 'لا يمكن ضمان ذلك. راجع التاريخ والوقت قبل الاعتماد عليهما. قد تحتاج الأوقات المبهمة إلى تأكيد، ويُفتح الموعد في محرر التقويم لتراجعه قبل الحفظ.'],
      ['هل تظهر المنبّهات داخل تطبيق الساعة؟', 'لا. في iOS 26.1 أو أحدث، تتبع المنبّهات المدعومة VoiceBrief وتُدار داخله، وليس في قائمة منبّهات تطبيق الساعة. تستخدم الإصدارات الأقدم تذكيرات بالإشعارات، ويلزم منح الأذونات.'],
      ['من مطوّر هذا التطبيق؟', 'ينشر التطبيق mohammad alzouabi، واسمه الإنجليزي في المتجر VoiceBrief: Audio Summaries، ومعرّفه لدى Apple هو 6805194629. استخدم رابط هذه الصفحة لتمييزه عن المنتجات ذات الأسماء المتشابهة.'],
    ],
    bottom: 'رسالتك الصوتية التالية، أوضح.', bottomText: 'حمّل VoiceBrief على الآيفون والآيباد.', privacy: 'الخصوصية', terms: 'الشروط', delete: 'حذف الحساب', press: 'المعلومات والصور الصحفية', footer: 'تطبيق مستقل من MOHAMMAD ALZOUABI، وغير تابع لواتساب أو Meta.',
    guideTitle: 'كيف تلخّص رسائل واتساب الصوتية على الآيفون؟', guideDescription: 'دليل مشاركة رسالة صوتية من واتساب مع VoiceBrief، وقراءة النص والملخص، ومراجعة المواعيد قبل إضافتها إلى التقويم.',
    guideIntro: 'يحوّل VoiceBrief الرسالة الصوتية التي تختار مشاركتها إلى نص وملخص. لا يتصل بمحادثات واتساب ولا يفحصها.',
    guideSteps: [
      ['جهّز VoiceBrief', 'نزّل التطبيق من App Store، وافتحه وسجّل الدخول عبر Apple أو Google. تحقق من الدقائق المتاحة واتصال الإنترنت. اسمح بالإشعارات إذا أردت تنبيهًا عندما يصبح الملخص جاهزًا.'],
      ['شارك الرسالة من واتساب', 'اضغط مطولًا على الرسالة الصوتية، ثم استخدم خيارات إعادة التوجيه أو المشاركة لإظهار نافذة مشاركة iOS. اختر VoiceBrief، وابحث ضمن «المزيد» إذا لم يظهر. قد تختلف القوائم بحسب إصدار واتساب.'],
      ['تابع حالة الاستيراد', 'اقرأ الحالة داخل نافذة مشاركة VoiceBrief واتبع تعليماتها بشأن وقت إغلاقها. عند وصول إشعار جاهزية الملخص، اضغط عليه لفتح النتيجة. لا يضمن iOS فتح التطبيق كاملًا فور المشاركة.'],
      ['راجع النتيجة قبل التصرف', 'اقرأ الملخص، وافتح النص الحرفي عند الحاجة إلى الكلمات الأصلية. راجع أي موعد مقترح وحدّد الوقت إذا كان مبهمًا، ثم أكّده في محرر التقويم قبل الحفظ.'],
    ],
    guideTrouble: 'إذا لم تتمكن من مشاركة الملف', guideTroubleText: 'افتح VoiceBrief واستورد ملفًا صوتيًا تملك صلاحية استخدامه. تحقق من الصيغة المدعومة والاتصال وتسجيل الدخول والدقائق المتبقية. تواصل مع الدعم عند استمرار المشكلة دون إرسال كلمات مرور أو تسجيلات حساسة.',
    pressTitle: 'VoiceBrief — معلومات التطبيق والصور الصحفية', pressDescription: 'المصدر الرسمي لمعلومات VoiceBrief ورابط App Store وأيقونة التطبيق والصور والميزات والقيود لأدلة التطبيقات والكتّاب.',
    pressIntro: 'معلومات دقيقة قابلة للاستخدام في أدلة التطبيقات والمراجعات والمقالات. روجعت بيانات المنتج في صفحة App Store العامة بتاريخ 19 سبتمبر 2026.',
    short: 'وصف قصير', long: 'عن التطبيق', images: 'الصور الرسمية', icon: 'تنزيل أيقونة التطبيق', screenshotsNote: 'تعرض الصور واجهات التطبيق الفعلية بمحتوى توضيحي لا يخص مستخدمين حقيقيين. هي صور تسويقية مولّدة برمجيًا وليست تصويرًا لأجهزة فعلية. تُنسب إلى VoiceBrief دون الإيحاء بتأييد Apple أو إضافة ميزات غير موجودة.',
    facts: [['التطبيق', 'VoiceBrief: Audio Summaries'], ['الناشر', 'mohammad alzouabi'], ['معرّف Apple', '6805194629'], ['الأجهزة المروّج لها هنا', 'iPhone وiPad، بنظام iOS / iPadOS 14 أو أحدث'], ['السعر', 'تنزيل مجاني واستخدام مجاني محدود؛ اشتراكات داخل التطبيق اختيارية'], ['الإصدار المنشور الذي تم التحقق منه', '0.1.2'], ['لغات الواجهة', 'العربية، الإنجليزية، البنغالية، الفرنسية، الهندية، الإندونيسية، البرتغالية، الروسية، الصينية المبسطة، الإسبانية، الأردية'], ['المعالجة', 'سحابية؛ تتطلب الإنترنت وتسجيل الدخول']],
  },
};

const application = {
  '@type': 'MobileApplication', '@id': `${origin}/#app`, name: 'VoiceBrief: Audio Summaries', alternateName: 'VoiceBrief',
  applicationCategory: 'ProductivityApplication', operatingSystem: 'iOS 14.0 or later; iPadOS 14.0 or later',
  url: origin, downloadUrl: appStore, installUrl: appStore, sameAs: [appStore], identifier: '6805194629',
  image: `${origin}/assets/app-icon.png`, softwareVersion: '0.1.2', inLanguage: ['ar', 'en', 'bn', 'fr', 'hi', 'id', 'pt', 'ru', 'zh-Hans', 'es', 'ur'],
  author: { '@type': 'Person', name: 'mohammad alzouabi' },
  description: copy.en.description, featureList: ['Audio transcription', 'Audio summaries and key points', 'Action items and dates for review', 'Suggested replies', 'Audio range selection', 'On-device saved text history'],
  offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD', description: 'Free download with limited free usage and optional in-app subscriptions.', url: appStore },
};
const pages = [];
const hashes = new Set();
const cta = (c) => link(appStore, `${esc(c.download)} <span aria-hidden="true">↗</span>`, 'class="button"');
const screenshot = (lang, index, attrs = '') => `<img src="/assets/${lang}-${['01_home', '02_brief', '03_dates', '04_history'][index]}.png" width="1284" height="2778" alt="${esc(copy[lang].galleryLabels[index])}" ${attrs}>`;
const footer = (lang, c) => `<footer class="wrap footer"><div><a class="brand" href="${home(lang)}" translate="no">VoiceBrief</a><p>${esc(c.footer)}</p><p>© 2026 MOHAMMAD ALZOUABI</p></div><nav aria-label="${lang === 'ar' ? 'روابط إضافية' : 'Additional links'}">${link(home(lang) + '#guides', lang === 'ar' ? 'أدلة الاستخدام' : 'Practical guides')}${[['privacy', c.privacy], ['terms', c.terms], ['support', c.help], ['delete-account', c.delete]].map(([page, text]) => link(legal(page, lang), esc(text))).join('')}${link(press(lang), esc(c.press))}</nav></footer>`;
const resources = (lang, current = 'home') => `<section class="wrap resource-section"${current === 'home' ? ' id="guides"' : ''}><h2>${lang === 'ar' ? 'أدلة تساعدك على الاستفادة من تسجيلاتك' : 'Make more of your voice notes'}</h2><ul class="resource-list">${[
  { kind: 'guide', title: copy[lang].guideTitle, description: copy[lang].guideDescription },
  ...marketingGuides.map(g => ({ kind: g.slug, ...g[lang] })),
].filter(g => g.kind !== current).map(g => `<li><h3>${link(route(lang, g.kind), esc(g.title))}</h3><p>${esc(g.description)}</p></li>`).join('')}</ul></section>`;

function render(lang, kind, title, description, body) {
  const c = copy[lang];
  const path = route(lang, kind);
  const alternate = route(c.switchLang, kind);
  const english = lang === 'en' ? path : alternate;
  const arabic = lang === 'ar' ? path : alternate;
  const structured = JSON.stringify({ '@context': 'https://schema.org', '@graph': [
    application,
    { '@type': 'WebSite', '@id': `${origin}/#website`, url: `${origin}/`, name: 'VoiceBrief', inLanguage: ['en', 'ar'] },
    { '@type': 'WebPage', '@id': origin + path, url: origin + path, name: title, description, inLanguage: lang, isPartOf: { '@id': `${origin}/#website` }, about: { '@id': `${origin}/#app` }, ...(kind !== 'home' ? { breadcrumb: { '@id': `${origin + path}#breadcrumb` } } : {}) },
    ...(kind !== 'home' ? [{ '@type': 'BreadcrumbList', '@id': `${origin + path}#breadcrumb`, itemListElement: [
      { '@type': 'ListItem', position: 1, name: 'VoiceBrief', item: origin + home(lang) },
      { '@type': 'ListItem', position: 2, name: title, item: origin + path },
    ] }] : []),
    ...(!['home', 'press'].includes(kind) ? [{ '@type': 'Article', headline: title, description, inLanguage: lang, mainEntityOfPage: { '@id': origin + path }, author: { '@type': 'Person', name: 'mohammad alzouabi', url: `${origin}/press` }, datePublished: kind === 'guide' ? '2026-09-19' : '2026-09-20', dateModified: updated }] : []),
  ] }).replaceAll('<', '\\u003c');
  hashes.add(`'sha256-${createHash('sha256').update(structured).digest('base64')}'`);
  put(path === '/' ? 'index.html' : `${path.slice(1)}.html`, `<!doctype html>
<html lang="${lang}" dir="${lang === 'ar' ? 'rtl' : 'ltr'}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(title)}</title>
<meta name="description" content="${esc(description)}">
<meta name="robots" content="index,follow,max-image-preview:large">
<meta name="theme-color" content="#ffffff">
<meta name="apple-itunes-app" content="app-id=6805194629">
${kind === 'home' ? `<meta name="google-site-verification" content="${googleSiteVerification}">\n` : ''}\
<link rel="canonical" href="${origin + path}">
<link rel="alternate" hreflang="en" href="${origin + english}">
<link rel="alternate" hreflang="ar" href="${origin + arabic}">
<link rel="alternate" hreflang="x-default" href="${origin + english}">
<meta property="og:type" content="website">
<meta property="og:site_name" content="VoiceBrief">
<meta property="og:title" content="${esc(title)}">
<meta property="og:description" content="${esc(description)}">
<meta property="og:url" content="${origin + path}">
<meta property="og:locale" content="${lang === 'ar' ? 'ar_AR' : 'en_US'}">
<meta property="og:image" content="${origin}/assets/app-icon.png">
<meta property="og:image:alt" content="VoiceBrief app icon">
<meta name="twitter:card" content="summary">
<meta name="twitter:title" content="${esc(title)}">
<meta name="twitter:description" content="${esc(description)}">
<meta name="twitter:image" content="${origin}/assets/app-icon.png">
<link rel="icon" href="/favicon.png" type="image/png">
<link rel="stylesheet" href="/marketing.css">
<script type="application/ld+json">${structured}</script>
</head>
<body>
<a class="skip" href="#content">${esc(c.skip)}</a>
<header class="wrap header"><a class="brand" href="${home(lang)}" translate="no"><img src="/assets/app-icon.png" alt="" width="38" height="38">VoiceBrief</a><nav aria-label="${esc(c.nav)}">${link(home(lang) + '#features', esc(c.features), 'class="nav-detail"')}${link(legal('support', lang), esc(c.help))}${link(alternate, esc(c.switch), `lang="${c.switchLang}" hreflang="${c.switchLang}" class="language"`)}</nav></header>
<main id="content">${kind !== 'home' ? `<nav class="wrap breadcrumbs" aria-label="${lang === 'ar' ? 'مسار الصفحة' : 'Breadcrumb'}"><ol><li>${link(home(lang), 'VoiceBrief', 'translate="no"')}</li><li aria-current="page">${esc(title)}</li></ol></nav>` : ''}${body}${kind !== 'home' ? resources(lang, kind) : ''}</main>
${footer(lang, c)}
</body></html>\n`);
  pages.push({ path, lang, kind });
}

for (const [lang, c] of Object.entries(copy)) {
  render(lang, 'home', c.title, c.description, `
<section class="wrap hero"><div class="hero-copy"><p class="eyebrow">${esc(c.eyebrow)}</p><h1>${c.headline.split('\n').map(esc).join('<br>')}</h1><p class="intro">${esc(c.intro)}</p>${cta(c)}<p class="download-note">${esc(c.price)}</p><p class="fine">${esc(c.require)}</p></div><figure class="hero-image">${screenshot(lang, 1, 'fetchpriority="high"')}<figcaption>${esc(c.caption)}</figcaption></figure></section>
<section class="wrap section" id="features"><div class="section-heading"><p class="eyebrow">${esc(c.storyLabel)}</p><h2>${esc(c.story)}</h2><p>${esc(c.storyText)}</p></div><div class="outputs">${c.outputs.map(([h, p]) => `<article><h3>${esc(h)}</h3><p>${esc(p)}</p></article>`).join('')}</div></section>
<section class="section surface" id="how"><div class="wrap"><h2>${esc(c.how)}</h2><ol class="steps">${c.steps.map(([h, p], i) => `<li><span class="step-number" aria-hidden="true">0${i + 1}</span><h3>${esc(h)}</h3><p>${esc(p)}</p></li>`).join('')}</ol>${link(guide(lang), `${esc(c.guideLink)} <span aria-hidden="true">↗</span>`, 'class="text-link"')}</div></section>
<section class="wrap section"><h2>${esc(c.gallery)}</h2><div class="gallery">${c.galleryLabels.map((label, i) => `<figure>${link(`/assets/${lang}-${['01_home', '02_brief', '03_dates', '04_history'][i]}.png`, screenshot(lang, i, 'loading="lazy" decoding="async"'), `aria-label="${esc(label)}"`)}<figcaption>${esc(label)}</figcaption></figure>`).join('')}</div><p class="fine">${esc(c.caption)}</p></section>
<section class="wrap details-section"><div><h2>${esc(c.langTitle)}</h2><p>${esc(c.langBody)}</p><p class="languages" lang="en" dir="ltr">${esc(languages.join(' · '))}</p></div><div><h2>${esc(c.privacyTitle)}</h2><p>${esc(c.privacyBody)}</p>${link(legal('privacy', lang), esc(c.privacyLink), 'class="text-link"')}</div></section>
<section class="wrap section faq"><h2>${esc(c.faqTitle)}</h2>${c.faq.map(([q, a]) => `<details><summary>${esc(q)}</summary><p>${esc(a)}</p></details>`).join('')}</section>
${resources(lang)}
<section class="closing"><div class="wrap"><h2>${esc(c.bottom)}</h2><p>${esc(c.bottomText)}</p>${cta(c)}</div></section>`);

  render(lang, 'guide', c.guideTitle, c.guideDescription, `<article class="wrap article"><p class="eyebrow">VOICEBRIEF · ${lang === 'ar' ? 'دليل الاستخدام' : 'PRACTICAL GUIDE'}</p><h1>${esc(c.guideTitle)}</h1><p class="intro">${esc(c.guideIntro)}</p><ol class="guide-steps">${c.guideSteps.map(([h, p]) => `<li><h2>${esc(h)}</h2><p>${esc(p)}</p></li>`).join('')}</ol><aside class="notice"><h2>${esc(c.guideTrouble)}</h2><p>${esc(c.guideTroubleText)}</p>${link(legal('support', lang), esc(c.help))}</aside><p>${esc(c.price)}</p>${cta(c)}<p class="fine">${esc(c.require)}</p></article>`);

  for (const entry of marketingGuides) {
    const g = entry[lang];
    render(lang, entry.slug, g.title, g.description, `<article class="wrap article"><p class="eyebrow">VOICEBRIEF · ${lang === 'ar' ? 'دليل الاستخدام' : 'PRACTICAL GUIDE'}</p><h1>${esc(g.title)}</h1><p class="intro">${esc(g.intro)}</p>${g.sections.map(s => `<section><h2>${esc(s.title)}</h2>${s.paragraphs.map(p => `<p>${esc(p)}</p>`).join('')}</section>`).join('')}<aside class="notice"><h2>${lang === 'ar' ? 'الخلاصة' : 'The takeaway'}</h2><p>${esc(g.takeaway)}</p></aside><p>${link(legal('privacy', lang), esc(c.privacyLink))} · ${link(legal('support', lang), esc(c.help))}</p><p class="fine">${lang === 'ar' ? 'دليل من ناشر التطبيق، MOHAMMAD ALZOUABI، وليس مراجعة مستقلة.' : 'A guide from the app publisher, MOHAMMAD ALZOUABI, not an independent review.'}</p>${cta(c)}<p class="fine">${esc(c.price)} · ${esc(c.require)}</p></article>`);
  }

  render(lang, 'press', c.pressTitle, c.pressDescription, `<article class="wrap article"><p class="eyebrow">VOICEBRIEF · ${lang === 'ar' ? 'المصدر الرسمي' : 'OFFICIAL SOURCE'}</p><h1>${esc(c.pressTitle)}</h1><p class="intro">${esc(c.pressIntro)}</p><h2>${esc(c.short)}</h2><p>${esc(c.description)}</p><h2>${esc(c.long)}</h2><p>${esc(c.intro)} ${esc(c.storyText)} ${esc(c.price)}.</p><dl class="facts">${c.facts.map(([k, v]) => `<div><dt>${esc(k)}</dt><dd>${esc(v)}</dd></div>`).join('')}</dl><p>${link(appStore, 'VoiceBrief: Audio Summaries ↗', 'translate="no"')}</p><p>${link('/assets/app-icon.png', esc(c.icon), 'download="VoiceBrief-icon.png"')}</p><h2>${esc(c.images)}</h2><p>${esc(c.screenshotsNote)}</p><div class="gallery">${c.galleryLabels.map((label, i) => `<figure>${link(`/assets/${lang}-${['01_home', '02_brief', '03_dates', '04_history'][i]}.png`, screenshot(lang, i, 'loading="lazy" decoding="async"'), 'download')}<figcaption>${esc(label)}</figcaption></figure>`).join('')}</div><h2>${esc(c.privacyTitle)}</h2><p>${esc(c.privacyBody)}</p>${link(legal('privacy', lang), esc(c.privacyLink))}<p>${link(legal('support', lang), esc(c.help))}</p></article>`);
}

mkdirSync(join(out, 'assets'), { recursive: true });
copyFileSync(join(root, 'assets/brand/voicebrief_icon.png'), join(out, 'assets/app-icon.png'));
for (const lang of ['en', 'ar']) for (const name of ['01_home', '02_brief', '03_dates', '04_history']) {
  copyFileSync(join(root, `store_assets/localized/${lang}/iphone/${name}.png`), join(out, `assets/${lang}-${name}.png`));
}
put('app-facts.json', JSON.stringify({ checkedOn: appCheckedOn, application, limitations: ['Not an offline application.', 'AI output must be reviewed.', 'Some features require Pro.', 'Not affiliated with WhatsApp or Meta.', 'This site promotes the iPhone and iPad App Store release only.'], sources: [appStore, `${origin}/privacy?lang=en`, `${origin}/press`] }, null, 2) + '\n');
const keyPath = join(out, 'indexnow-key.txt');
if (!existsSync(keyPath)) put('indexnow-key.txt', randomBytes(16).toString('hex') + '\n');
put('robots.txt', `User-agent: *\nAllow: /\n\nSitemap: ${origin}/sitemap.xml\n`);
put('sitemap.xml', `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">\n${pages.map(({ path, kind }) => {
  const en = pages.find(p => p.lang === 'en' && p.kind === kind).path;
  const ar = pages.find(p => p.lang === 'ar' && p.kind === kind).path;
  return `<url><loc>${origin + path}</loc><lastmod>${updated}</lastmod><xhtml:link rel="alternate" hreflang="en" href="${origin + en}"/><xhtml:link rel="alternate" hreflang="ar" href="${origin + ar}"/><xhtml:link rel="alternate" hreflang="x-default" href="${origin + en}"/></url>`;
}).join('\n')}\n</urlset>\n`);
const vercel = JSON.parse(readFileSync(join(out, 'vercel.json'), 'utf8'));
vercel.redirects = (vercel.redirects ?? []).filter(r => !(r.source === '/' && r.destination === '/privacy'));
for (const group of vercel.headers) for (const header of group.headers) if (header.key === 'Content-Security-Policy') {
  const directives = header.value.split(';').map(x => x.trim()).filter(x => x && !x.startsWith('script-src '));
  header.value = [...directives, `script-src 'self' ${[...hashes].join(' ')}`].join('; ');
}
put('vercel.json', JSON.stringify(vercel, null, 2) + '\n');
console.log(`Built ${pages.length} static marketing pages; copied 8 existing screenshots. Legal content and forms are not generated.`);
