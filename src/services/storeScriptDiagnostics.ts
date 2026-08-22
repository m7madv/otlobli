export type StoreScriptFlags = {
  runtime: boolean
  navigation: boolean
  navigationViewport: boolean
  navigationBar: boolean
  navigationTouch: boolean
  navigationBack: boolean
  navigationEarlyMount: boolean
  navigationEarlyProtection: boolean
  blocking: boolean
  capture: boolean
  session: boolean
}

export type StoreDiagnosticOutcome = 'pass' | 'fail'

export type StoreDiagnosticTraceEntry = {
  at: number
  kind: string
  url: string
  detail: string
}

export type StoreDiagnosticState = {
  version: 3
  activeProfile: string
  outcomes: Record<string, StoreDiagnosticOutcome>
  trace: StoreDiagnosticTraceEntry[]
  journey: {
    tap: boolean
    url: boolean
    document: boolean
    product: boolean
    error: boolean
  }
}

type StoreScriptDiagnosticProfile = {
  id: string
  code: string
  title: string
  description: string
  flags: StoreScriptFlags
}

const NAVIGATION_OFF = {
  navigation: false,
  navigationViewport: false,
  navigationBar: false,
  navigationTouch: false,
  navigationBack: false,
  navigationEarlyMount: false,
  navigationEarlyProtection: false,
}

const DIAGNOSTIC_BASE_FLAGS: StoreScriptFlags = {
  runtime: true,
  ...NAVIGATION_OFF,
  blocking: true,
  capture: true,
  session: false,
}

export const DEFAULT_STORE_SCRIPT_FLAGS: StoreScriptFlags = {
  runtime: true,
  navigation: true,
  navigationViewport: true,
  navigationBar: true,
  navigationTouch: true,
  navigationBack: true,
  navigationEarlyMount: true,
  navigationEarlyProtection: true,
  blocking: true,
  capture: true,
  session: true,
}

// Start from the exact broad state that worked on the physical iPhone:
// capture/blocking stay useful while every navigation and region action is off.
export const INITIAL_STORE_SCRIPT_DIAGNOSTIC_FLAGS: StoreScriptFlags = {
  ...DIAGNOSTIC_BASE_FLAGS,
}

export const STORE_SCRIPT_DIAGNOSTIC_PROFILES: StoreScriptDiagnosticProfile[] = [
  {
    id: 'baseline', code: 'N0', title: 'المرجع الآمن',
    description: 'الجذب والحجب فقط؛ كل أجزاء التنقّل والمنطقة متوقفة.',
    flags: { ...DIAGNOSTIC_BASE_FLAGS },
  },
  {
    id: 'viewport', code: 'N1', title: 'مساحة الشاشة',
    description: 'يضيف viewport-fit فقط، من دون شريط أو لمس أو مسح للصفحة.',
    flags: { ...DIAGNOSTIC_BASE_FLAGS, navigation: true, navigationViewport: true },
  },
  {
    id: 'bar', code: 'N2', title: 'رسم الشريط',
    description: 'يضيف شريط Otlobli بعد اكتمال الصفحة، ويبقيه بلا تدخل لمس.',
    flags: { ...DIAGNOSTIC_BASE_FLAGS, navigation: true, navigationViewport: true, navigationBar: true },
  },
  {
    id: 'touch', code: 'N3', title: 'لمس الشريط',
    description: 'يضيف توجيه لمس أزرار شريط Otlobli فقط.',
    flags: { ...DIAGNOSTIC_BASE_FLAGS, navigation: true, navigationViewport: true, navigationBar: true, navigationTouch: true },
  },
  {
    id: 'back', code: 'N4', title: 'رجوع المنتج',
    description: 'يضيف زر الرجوع وحالة سجل الصفحة فوق الطبقات السابقة.',
    flags: { ...DIAGNOSTIC_BASE_FLAGS, navigation: true, navigationViewport: true, navigationBar: true, navigationTouch: true, navigationBack: true },
  },
  {
    id: 'early-mount', code: 'N5', title: 'التركيب المبكر',
    description: 'يرسم الشريط منذ بداية الوثيقة قبل اكتمال SHEIN.',
    flags: { ...DIAGNOSTIC_BASE_FLAGS, navigation: true, navigationViewport: true, navigationBar: true, navigationTouch: true, navigationBack: true, navigationEarlyMount: true },
  },
  {
    id: 'early-protection', code: 'N6', title: 'الحماية المبكرة',
    description: 'يضيف ماسح شريط SHEIN وزر الإضافة والعرض السفلي المحدود.',
    flags: { ...DIAGNOSTIC_BASE_FLAGS, navigation: true, navigationViewport: true, navigationBar: true, navigationTouch: true, navigationBack: true, navigationEarlyMount: true, navigationEarlyProtection: true },
  },
  {
    id: 'region', code: 'R1', title: 'الجلسة والمنطقة',
    description: 'آخر اختبار مستقل: يضيف تغيير المنطقة بعد ثبوت طبقة التنقّل.',
    flags: { ...DEFAULT_STORE_SCRIPT_FLAGS },
  },
]

const PROFILE_IDS = new Set(STORE_SCRIPT_DIAGNOSTIC_PROFILES.map((profile) => profile.id))
const TRACE_KINDS = new Set([
  'panel-ready', 'product-tap', 'url-changed', 'document-ready', 'product-surface',
  'checkpoint', 'script-error', 'promise-error', 'native-url-change',
  'native-page-loaded', 'native-page-error', 'result-pass', 'result-fail',
])

const hasOwn = (value: Record<string, unknown>, key: string) =>
  Object.prototype.hasOwnProperty.call(value, key)

const normalizedNavigationFlag = (
  candidate: Record<string, unknown>,
  key: keyof StoreScriptFlags,
  navigation: boolean,
) => hasOwn(candidate, key) ? candidate[key] !== false : navigation

export const normalizeStoreScriptFlags = (value: unknown): StoreScriptFlags => {
  const candidate = value && typeof value === 'object' ? value as Record<string, unknown> : {}
  const navigation = candidate.navigation !== false
  return {
    runtime: candidate.runtime !== false,
    navigation,
    navigationViewport: normalizedNavigationFlag(candidate, 'navigationViewport', navigation),
    navigationBar: normalizedNavigationFlag(candidate, 'navigationBar', navigation),
    navigationTouch: normalizedNavigationFlag(candidate, 'navigationTouch', navigation),
    navigationBack: normalizedNavigationFlag(candidate, 'navigationBack', navigation),
    navigationEarlyMount: normalizedNavigationFlag(candidate, 'navigationEarlyMount', navigation),
    navigationEarlyProtection: normalizedNavigationFlag(candidate, 'navigationEarlyProtection', navigation),
    blocking: candidate.blocking !== false,
    capture: candidate.capture !== false,
    session: candidate.session !== false,
  }
}

const cleanText = (value: unknown, maxLength: number) =>
  String(value ?? '').replace(/\s+/g, ' ').trim().slice(0, maxLength)

export const normalizeStoreDiagnosticState = (value: unknown): StoreDiagnosticState => {
  const candidate = value && typeof value === 'object' ? value as Record<string, unknown> : {}
  const rawOutcomes = candidate.outcomes && typeof candidate.outcomes === 'object'
    ? candidate.outcomes as Record<string, unknown>
    : {}
  const outcomes: Record<string, StoreDiagnosticOutcome> = {}
  for (const id of PROFILE_IDS) {
    if (rawOutcomes[id] === 'pass' || rawOutcomes[id] === 'fail') outcomes[id] = rawOutcomes[id]
  }
  const rawJourney = candidate.journey && typeof candidate.journey === 'object'
    ? candidate.journey as Record<string, unknown>
    : {}
  const trace = Array.isArray(candidate.trace)
    ? candidate.trace.slice(-40).flatMap((entry): StoreDiagnosticTraceEntry[] => {
        if (!entry || typeof entry !== 'object') return []
        const raw = entry as Record<string, unknown>
        const kind = cleanText(raw.kind, 32)
        if (!TRACE_KINDS.has(kind)) return []
        const at = Number(raw.at)
        return [{
          at: Number.isFinite(at) && at > 0 ? Math.floor(at) : Date.now(),
          kind,
          url: cleanText(raw.url, 420),
          detail: cleanText(raw.detail, 180),
        }]
      })
    : []
  const activeProfile = cleanText(candidate.activeProfile, 32)
  return {
    version: 3,
    activeProfile: PROFILE_IDS.has(activeProfile) ? activeProfile : 'baseline',
    outcomes,
    trace,
    journey: {
      tap: rawJourney.tap === true,
      url: rawJourney.url === true,
      document: rawJourney.document === true,
      product: rawJourney.product === true,
      error: rawJourney.error === true,
    },
  }
}

export const appendStoreDiagnosticHostEvent = (
  value: unknown,
  kind: 'native-url-change' | 'native-page-loaded' | 'native-page-error',
  url = '',
  detail = '',
) => {
  const state = normalizeStoreDiagnosticState(value)
  const nextUrl = cleanText(url, 420)
  const productRoute = /(?:-p-\d+|\/product\/|\/goods\/|\/item\/)/i.test(nextUrl) ||
    /[?&](?:goods_id|goodsId|product_id|productId|mallCode|skc)=/i.test(nextUrl)
  if (kind === 'native-url-change' && productRoute) state.journey.url = true
  if (kind === 'native-page-loaded' && productRoute) {
    state.journey.document = true
    state.journey.url = true
  }
  if (kind === 'native-page-error' && (state.journey.tap || productRoute)) state.journey.error = true
  state.trace = [...state.trace, {
    at: Date.now(), kind, url: nextUrl, detail: cleanText(detail, 180),
  }].slice(-40)
  return state
}

export const buildStoreScriptDiagnosticsPrelude = (flags: StoreScriptFlags) =>
  `window.__OTLOBLI_SCRIPT_FLAGS__=${JSON.stringify(normalizeStoreScriptFlags(flags))};`

export const isStoreScriptFlagsChangedMessage = (detail: unknown) =>
  Boolean(detail && typeof detail === 'object' && (detail as { type?: unknown }).type === 'storeScriptFlagsChanged')

export const isStoreDiagnosticStateMessage = (detail: unknown) =>
  Boolean(detail && typeof detail === 'object' && (detail as { type?: unknown }).type === 'storeDiagnosticState')

export const buildDiagnosticStoreCaptureScript = (
  regions: unknown,
  flags: StoreScriptFlags,
  diagnosticState: unknown,
  privacyCompatScript: string,
  captureScript: string,
) => {
  const normalizedFlags = normalizeStoreScriptFlags(flags)
  const runtime = normalizedFlags.runtime
    ? `try{\n${captureScript}\n}catch(__otlobliCaptureError){}`
    : ''
  return `window.__OTLOBLI_STORE_REGIONS__=${JSON.stringify(regions)};\n${buildStoreScriptDiagnosticsPrelude(normalizedFlags)}\nwindow.__OTLOBLI_DIAGNOSTIC_STATE__=${JSON.stringify(normalizeStoreDiagnosticState(diagnosticState))};\n${privacyCompatScript}\n${STORE_SCRIPT_DIAGNOSTICS_PANEL_SCRIPT}\n${runtime}`
}

const DIAGNOSTIC_PROFILES_JSON = JSON.stringify(STORE_SCRIPT_DIAGNOSTIC_PROFILES)

// Diagnostic-build only. The bounded state is stored in the Otlobli host
// through native messages, never in SHEIN cookies or website storage.
export const STORE_SCRIPT_DIAGNOSTICS_PANEL_SCRIPT = `
(function () {
  if (window.top !== window || window.__otlobliScriptDiagnosticsMounted) return;
  window.__otlobliScriptDiagnosticsMounted = true;
  var profiles = ${DIAGNOSTIC_PROFILES_JSON};
  var flags = window.__OTLOBLI_SCRIPT_FLAGS__ || profiles[0].flags;
  var state = window.__OTLOBLI_DIAGNOSTIC_STATE__ || { version: 3, activeProfile: 'baseline', outcomes: {}, trace: [], journey: {} };
  var root = null, status = null, journeyList = null, profileList = null;
  var lastProductTouchAt = 0, lastProductHref = '', startingUrl = String(location.href || ''), recordedErrors = 0;

  function text(value, max) { return String(value == null ? '' : value).replace(/\\s+/g, ' ').trim().slice(0, max || 180); }
  function isProductUrl(value) {
    return /(?:-p-\\d+|\\/product\\/|\\/goods\\/|\\/item\\/)/i.test(String(value || '')) ||
      /[?&](?:goods_id|goodsId|product_id|productId|mallCode|skc)=/i.test(String(value || ''));
  }
  function profileForFlags(candidate) {
    for (var i = profiles.length - 1; i >= 0; i--) {
      var wanted = profiles[i].flags, match = true;
      for (var key in wanted) if (wanted[key] !== candidate[key]) { match = false; break; }
      if (match) return profiles[i];
    }
    return profiles[0];
  }
  function normalizeState(value) {
    var source = value && typeof value === 'object' ? value : {};
    var journey = source.journey && typeof source.journey === 'object' ? source.journey : {};
    return { version: 3, activeProfile: text(source.activeProfile || profileForFlags(flags).id, 32),
      outcomes: source.outcomes && typeof source.outcomes === 'object' ? source.outcomes : {},
      trace: Array.isArray(source.trace) ? source.trace.slice(-40) : [],
      journey: { tap: journey.tap === true, url: journey.url === true, document: journey.document === true,
        product: journey.product === true, error: journey.error === true } };
  }
  function post(detail) {
    try { if (window.mobileApp && window.mobileApp.postMessage) window.mobileApp.postMessage({ detail: detail }); } catch (e) {}
  }
  function persist() { state.trace = state.trace.slice(-40); post({ type: 'storeDiagnosticState', state: state }); }
  function currentProfile() {
    for (var i = 0; i < profiles.length; i++) if (profiles[i].id === state.activeProfile) return profiles[i];
    return profileForFlags(flags);
  }
  function record(kind, detail, url) {
    state.trace.push({ at: Date.now(), kind: kind, url: text(url || location.href, 420), detail: text(detail, 180) });
    if (kind === 'product-tap') state.journey.tap = true;
    if (kind === 'url-changed') state.journey.url = true;
    if (kind === 'document-ready') state.journey.document = true;
    if (kind === 'product-surface') state.journey.product = true;
    if (kind === 'script-error' || kind === 'promise-error' || kind === 'native-page-error') state.journey.error = true;
    persist(); renderLiveState();
  }
  function hasProductSurface() {
    if (!isProductUrl(location.href)) return false;
    try { return !!document.querySelector('.product-intro__head,.product-intro__info,[class*="product-intro" i],[class*="product-detail" i],[class*="goods-detail" i]'); }
    catch (e) { return false; }
  }
  function inspectJourney(label) {
    if (!state.journey.url && String(location.href) !== startingUrl && isProductUrl(location.href)) record('url-changed', label, location.href);
    if (isProductUrl(location.href) && document.readyState !== 'loading' && !state.journey.document) record('document-ready', document.readyState, location.href);
    if (hasProductSurface() && !state.journey.product) record('product-surface', label, location.href);
    if (!state.journey.product) record('checkpoint', label + ' · ' + document.readyState, location.href);
  }
  function productHrefFromEvent(event) {
    var node = event.target;
    for (var depth = 0; node && depth < 8; depth++, node = node.parentElement) {
      if (!node.getAttribute) continue;
      var href = node.getAttribute('href') || node.getAttribute('data-href') || '';
      var goods = node.getAttribute('data-goods-id') || node.getAttribute('data-product-id') || '';
      if (isProductUrl(href) || goods) return href ? String(new URL(href, location.href)) : 'goods:' + goods;
    }
    return '';
  }
  function captureProductTap(event) {
    var href = ''; try { href = productHrefFromEvent(event); } catch (e) {}
    if (!href) return;
    var now = Date.now(); if (href === lastProductHref && now - lastProductTouchAt < 700) return;
    lastProductHref = href; lastProductTouchAt = now; startingUrl = String(location.href || '');
    state.journey = { tap: false, url: false, document: false, product: false, error: false }; state.trace = [];
    record('product-tap', href, startingUrl);
    setTimeout(function () { inspectJourney('بعد 0.4 ثانية'); }, 400);
    setTimeout(function () { inspectJourney('بعد 1.5 ثانية'); }, 1500);
    setTimeout(function () { inspectJourney('بعد 4 ثوانٍ'); }, 4000);
  }

  document.addEventListener('touchend', captureProductTap, { capture: true, passive: true });
  document.addEventListener('click', captureProductTap, true);
  window.addEventListener('popstate', function () { inspectJourney('popstate'); }, false);
  window.addEventListener('hashchange', function () { inspectJourney('hashchange'); }, false);
  window.addEventListener('pageshow', function () { inspectJourney('pageshow'); }, false);
  window.addEventListener('load', function () { inspectJourney('load'); }, { once: true });
  window.addEventListener('error', function (event) {
    if (recordedErrors >= 6) return; recordedErrors++; record('script-error', event.message || 'خطأ JavaScript', location.href);
  }, false);
  window.addEventListener('unhandledrejection', function (event) {
    if (recordedErrors >= 6) return; recordedErrors++;
    var reason = event && event.reason; record('promise-error', reason && (reason.message || reason.name) || 'Promise مرفوض', location.href);
  }, false);
  window.addEventListener('messageFromNative', function (event) {
    var detail = event && event.detail;
    if (!detail || detail.type !== '__storeDiagnosticHostState' || !detail.state) return;
    state = normalizeState(detail.state); renderLiveState();
  });

  state = normalizeState(state); state.activeProfile = profileForFlags(flags).id;
  if (isProductUrl(location.href)) {
    state.journey.url = true;
    if (document.readyState !== 'loading') state.journey.document = true;
    if (hasProductSurface()) state.journey.product = true;
  }
  record('panel-ready', document.readyState, location.href);

  function element(tag, className, value) {
    var node = document.createElement(tag); if (className) node.className = className;
    if (value != null) node.textContent = value; return node;
  }
  function setStatus(message, tone) {
    if (!status) return; status.textContent = message; status.setAttribute('data-tone', tone || 'neutral');
  }
  function outcomeLabel(value) { return value === 'pass' ? 'فتح المنتج' : value === 'fail' ? 'بقي يحمّل' : 'لم يُسجّل'; }
  function nextRecommendedIndex() {
    for (var i = 0; i < profiles.length; i++) if (!state.outcomes[profiles[i].id]) return i;
    return profiles.length - 1;
  }
  function renderProfiles() {
    if (!profileList) return; profileList.textContent = '';
    var active = currentProfile(), recommended = nextRecommendedIndex();
    for (var i = 0; i < profiles.length; i++) {
      (function (profile, index) {
        var button = element('button', 'otlobli-diagnostic-profile'); button.type = 'button';
        button.setAttribute('aria-pressed', profile.id === active.id ? 'true' : 'false');
        button.setAttribute('data-outcome', state.outcomes[profile.id] || '');
        if (index === recommended) button.setAttribute('data-recommended', '1');
        var code = element('span', 'otlobli-diagnostic-code', profile.code); code.setAttribute('translate', 'no');
        var body = element('span', 'otlobli-diagnostic-profile-body');
        body.appendChild(element('b', '', profile.title)); body.appendChild(element('small', '', profile.description));
        body.appendChild(element('em', '', outcomeLabel(state.outcomes[profile.id])));
        button.appendChild(code); button.appendChild(body);
        button.addEventListener('click', function () {
          if (profile.id === active.id) { setStatus('هذا الاختبار يعمل الآن. افتح منتجًا ثم سجّل النتيجة.', 'neutral'); return; }
          state.activeProfile = profile.id;
          state.journey = { tap: false, url: false, document: false, product: false, error: false }; state.trace = []; persist();
          setStatus(profile.code + ' — جاري إعادة تشغيل المتجر…', 'working');
          post({ type: 'storeScriptFlagsChanged', flags: profile.flags, diagnosticState: state, label: profile.code + ' — ' + profile.title });
        });
        profileList.appendChild(button);
      })(profiles[i], i);
    }
  }
  function renderJourney() {
    if (!journeyList) return; journeyList.textContent = '';
    var steps = [['tap','1','وصلت ضغطة المنتج'],['url','2','تغيّر رابط الصفحة'],['document','3','اكتملت وثيقة المنتج'],['product','4','ظهرت واجهة المنتج']];
    for (var i = 0; i < steps.length; i++) {
      var done = state.journey[steps[i][0]] === true, row = element('li', 'otlobli-diagnostic-journey-step');
      row.setAttribute('data-done', done ? '1' : '0'); var node = element('span', '', done ? '✓' : steps[i][1]); node.setAttribute('aria-hidden', 'true');
      row.appendChild(node); row.appendChild(element('b', '', steps[i][2])); journeyList.appendChild(row);
    }
    if (state.journey.error) journeyList.setAttribute('data-error', '1'); else journeyList.removeAttribute('data-error');
  }
  function renderLiveState() {
    renderJourney(); renderProfiles(); if (!root) return;
    var completed = Number(state.journey.tap) + Number(state.journey.url) + Number(state.journey.document) + Number(state.journey.product);
    root.setAttribute('data-progress', String(completed));
  }
  function makeReport() {
    var active = currentProfile(), lines = [
      'تقرير فحص Otlobli — SHEIN iPhone',
      'الوقت: ' + new Intl.DateTimeFormat('ar', { dateStyle: 'medium', timeStyle: 'medium' }).format(new Date()),
      'الاختبار الحالي: ' + active.code + ' — ' + active.title,
      'الرابط: ' + String(location.href), '', 'رحلة ضغطة المنتج:',
      '- وصلت الضغطة: ' + (state.journey.tap ? 'نعم' : 'لا'),
      '- تغيّر الرابط: ' + (state.journey.url ? 'نعم' : 'لا'),
      '- اكتملت الوثيقة: ' + (state.journey.document ? 'نعم' : 'لا'),
      '- ظهرت واجهة المنتج: ' + (state.journey.product ? 'نعم' : 'لا'),
      '- سُجل خطأ: ' + (state.journey.error ? 'نعم' : 'لا'), '', 'نتائج الملفات:'
    ];
    for (var i = 0; i < profiles.length; i++) lines.push('- ' + profiles[i].code + ' ' + profiles[i].title + ': ' + outcomeLabel(state.outcomes[profiles[i].id]));
    lines.push('', 'آخر الأحداث:'); var recent = state.trace.slice(-12);
    for (var j = 0; j < recent.length; j++) {
      var item = recent[j], time = new Intl.DateTimeFormat('ar', { hour: '2-digit', minute: '2-digit', second: '2-digit' }).format(new Date(Number(item.at) || Date.now()));
      lines.push('- ' + time + ' · ' + text(item.kind, 32) + (item.detail ? ' · ' + text(item.detail, 100) : ''));
    }
    return lines.join('\\n');
  }
  function copyReport() {
    var report = makeReport();
    var fallback = function () {
      var area = document.createElement('textarea'); area.value = report; area.setAttribute('readonly', ''); area.setAttribute('aria-label', 'تقرير الفحص'); area.style.position = 'fixed'; area.style.opacity = '0';
      document.body.appendChild(area); area.select();
      try { document.execCommand('copy'); setStatus('تم نسخ التقرير. أرسله مباشرة في الشات.', 'success'); }
      catch (e) { setStatus('تعذّر النسخ. صوّر رحلة الضغطة والنتائج.', 'error'); }
      area.remove();
    };
    if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(report).then(function () { setStatus('تم نسخ التقرير. أرسله مباشرة في الشات.', 'success'); }).catch(fallback);
    else fallback();
  }
  function markOutcome(outcome) {
    var profile = currentProfile(); state.outcomes[profile.id] = outcome;
    record(outcome === 'pass' ? 'result-pass' : 'result-fail', profile.code, location.href);
    setStatus(outcome === 'pass' ? 'سُجل: المنتج فتح. انتقل للاختبار التالي.' : 'سُجل: بقي يحمّل. هذا أول ملف مشتبه به؛ انسخ التقرير.', outcome === 'pass' ? 'success' : 'error');
  }

  function mount() {
    if (!document.body || document.getElementById('otlobli-script-diagnostics')) return;
    var style = document.createElement('style'); style.id = 'otlobli-script-diagnostics-style';
    style.textContent =
      '#otlobli-script-diagnostics,#otlobli-script-diagnostics *{box-sizing:border-box;font-family:Cairo,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}' +
      '#otlobli-script-diagnostics-trigger{position:fixed;left:0;top:38%;z-index:2147483647;width:58px;min-height:50px;border:1px solid #8cb3a4;border-left:0;border-radius:0 16px 16px 0;background:#073f32;color:#fff;font-size:12px;font-weight:900;box-shadow:0 8px 24px rgba(4,38,30,.24);touch-action:manipulation;-webkit-tap-highlight-color:rgba(255,255,255,.18)}' +
      '#otlobli-script-diagnostics-trigger:after{content:"";position:absolute;top:7px;right:7px;width:7px;height:7px;border-radius:50%;background:#f6b84b}' +
      '#otlobli-script-diagnostics[data-progress="4"] #otlobli-script-diagnostics-trigger:after{background:#64d19a}' +
      '#otlobli-script-diagnostics[data-open="1"] #otlobli-script-diagnostics-trigger{opacity:0;pointer-events:none}' +
      '#otlobli-script-diagnostics button:focus-visible{outline:3px solid #f6b84b;outline-offset:2px}' +
      '#otlobli-script-diagnostics-backdrop{position:fixed;inset:0;z-index:2147483645;border:0;background:rgba(5,22,18,.48);opacity:0;pointer-events:none;transition:opacity .16s ease;touch-action:manipulation;-webkit-tap-highlight-color:transparent}' +
      '#otlobli-script-diagnostics-panel{position:fixed;z-index:2147483646;left:50%;bottom:0;width:min(100%,520px);max-height:88vh;padding:12px 16px max(16px,env(safe-area-inset-bottom));background:#f4f8f5;color:#14251f;border-radius:22px 22px 0 0;box-shadow:0 -18px 54px rgba(5,31,24,.24);transform:translate(-50%,104%);transition:transform .2s ease;overflow-y:auto;overflow-x:hidden;overscroll-behavior:contain;direction:rtl;text-align:right}' +
      '#otlobli-script-diagnostics[data-open="1"] #otlobli-script-diagnostics-backdrop{opacity:1;pointer-events:auto}' +
      '#otlobli-script-diagnostics[data-open="1"] #otlobli-script-diagnostics-panel{transform:translate(-50%,0)}' +
      '.otlobli-diagnostic-handle{width:42px;height:4px;margin:0 auto 12px;border-radius:999px;background:#b8c8c0}' +
      '.otlobli-diagnostic-head{display:flex;align-items:flex-start;justify-content:space-between;gap:12px}' +
      '.otlobli-diagnostic-kicker{margin:0 0 3px;color:#087453;font-size:10px;font-weight:900;letter-spacing:.08em}' +
      '#otlobli-script-diagnostics h2{margin:0;font-size:20px;line-height:1.35;text-wrap:balance}' +
      '.otlobli-diagnostic-intro{margin:6px 0 12px;color:#53655e;font-size:12px;line-height:1.7;text-wrap:pretty}' +
      '.otlobli-diagnostic-close{width:44px;height:44px;flex:0 0 44px;border:1px solid #cad8d1;border-radius:14px;background:#fff;color:#173b30;font-size:24px;line-height:1;touch-action:manipulation}' +
      '.otlobli-diagnostic-section{margin:12px 0 0;padding:12px;border:1px solid #d7e2dc;border-radius:16px;background:#fff}' +
      '.otlobli-diagnostic-section-head{display:flex;align-items:center;justify-content:space-between;gap:8px;margin-bottom:10px}' +
      '.otlobli-diagnostic-section h3{margin:0;font-size:14px;line-height:1.45}' +
      '.otlobli-diagnostic-badge{padding:4px 8px;border-radius:999px;background:#e7f2ed;color:#075b43;font-size:10px;font-weight:900}' +
      '.otlobli-diagnostic-journey{position:relative;display:grid;grid-template-columns:repeat(4,1fr);gap:5px;margin:0;padding:0;list-style:none}' +
      '.otlobli-diagnostic-journey:before{content:"";position:absolute;top:16px;right:10%;left:10%;height:2px;background:#d7e1dc}' +
      '.otlobli-diagnostic-journey-step{position:relative;display:grid;justify-items:center;gap:6px;min-width:0;text-align:center}' +
      '.otlobli-diagnostic-journey-step>span{z-index:1;display:grid;place-items:center;width:32px;height:32px;border:2px solid #c8d6cf;border-radius:50%;background:#fff;color:#6e7e77;font-size:12px;font-weight:900;font-variant-numeric:tabular-nums}' +
      '.otlobli-diagnostic-journey-step[data-done="1"]>span{border-color:#087453;background:#087453;color:#fff}' +
      '.otlobli-diagnostic-journey-step b{font-size:9px;line-height:1.45;color:#53655e}' +
      '.otlobli-diagnostic-profiles{display:grid;gap:7px;margin-top:10px}' +
      '.otlobli-diagnostic-profile{width:100%;min-height:68px;display:flex;align-items:center;gap:10px;border:1px solid #d6e1db;border-radius:14px;padding:9px 10px;background:#fff;color:#182a24;text-align:right;touch-action:manipulation;-webkit-tap-highlight-color:rgba(8,116,83,.1)}' +
      '.otlobli-diagnostic-profile[aria-pressed="true"]{border-color:#087453;box-shadow:inset 0 0 0 1px #087453;background:#f2faf6}' +
      '.otlobli-diagnostic-profile[data-recommended="1"]:not([aria-pressed="true"]){border-style:dashed;border-color:#d08b24}' +
      '.otlobli-diagnostic-code{display:grid;place-items:center;width:42px;height:42px;flex:0 0 42px;border-radius:12px;background:#e8f2ed;color:#075b43;font-size:12px;font-weight:900;font-variant-numeric:tabular-nums}' +
      '.otlobli-diagnostic-profile-body{display:grid;gap:2px;min-width:0}' +
      '.otlobli-diagnostic-profile-body b{font-size:13px;line-height:1.35}' +
      '.otlobli-diagnostic-profile-body small{color:#63736c;font-size:10px;line-height:1.45;overflow-wrap:anywhere}' +
      '.otlobli-diagnostic-profile-body em{color:#8a641d;font-size:9px;font-style:normal;font-weight:900}' +
      '.otlobli-diagnostic-profile[data-outcome="pass"] .otlobli-diagnostic-profile-body em{color:#087453}' +
      '.otlobli-diagnostic-profile[data-outcome="fail"] .otlobli-diagnostic-profile-body em{color:#b43d35}' +
      '.otlobli-diagnostic-actions{display:grid;grid-template-columns:1fr 1fr;gap:8px}' +
      '.otlobli-diagnostic-actions button,.otlobli-diagnostic-footer button{min-height:44px;border:1px solid #b9cec3;border-radius:12px;background:#fff;color:#0a5d45;font-size:12px;font-weight:900;touch-action:manipulation}' +
      '.otlobli-diagnostic-actions .otlobli-diagnostic-fail{border-color:#e0b6b1;color:#a53630}' +
      '#otlobli-script-diagnostics-status{min-height:40px;margin:10px 0 0;padding:9px 11px;border-radius:11px;background:#e9f2ed;color:#285345;font-size:11px;line-height:1.55;overflow-wrap:anywhere}' +
      '#otlobli-script-diagnostics-status[data-tone="success"]{background:#e2f4e9;color:#0a623f}' +
      '#otlobli-script-diagnostics-status[data-tone="error"]{background:#fbe9e7;color:#92342e}' +
      '#otlobli-script-diagnostics-status[data-tone="working"]{background:#fff2d9;color:#80591c}' +
      '.otlobli-diagnostic-footer{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-top:10px}' +
      '.otlobli-diagnostic-footer .otlobli-diagnostic-copy-report{grid-column:1/-1;background:#073f32;color:#fff;border-color:#073f32}' +
      '.otlobli-diagnostic-footer .otlobli-diagnostic-clear{color:#765922}' +
      '.otlobli-diagnostic-footer .otlobli-diagnostic-exit{color:#8d342e;border-color:#e3c7c2}' +
      '#otlobli-script-diagnostics button:active{transform:translateY(1px)}' +
      '@media(hover:hover){#otlobli-script-diagnostics button:hover{border-color:#087453;background-color:#edf5f1}}' +
      '@media(prefers-reduced-motion:reduce){#otlobli-script-diagnostics-backdrop,#otlobli-script-diagnostics-panel{transition:none}#otlobli-script-diagnostics button:active{transform:none}}';
    (document.head || document.documentElement).appendChild(style);

    root = element('div'); root.id = 'otlobli-script-diagnostics'; root.setAttribute('data-open', '0');
    var trigger = element('button', '', 'فحص'); trigger.id = 'otlobli-script-diagnostics-trigger'; trigger.type = 'button';
    trigger.setAttribute('aria-label', 'فتح مسجّل رحلة المنتج'); trigger.setAttribute('aria-expanded', 'false');
    var backdrop = element('button'); backdrop.id = 'otlobli-script-diagnostics-backdrop'; backdrop.type = 'button'; backdrop.setAttribute('aria-label', 'إغلاق لوحة الفحص');
    var panel = element('section'); panel.id = 'otlobli-script-diagnostics-panel'; panel.setAttribute('role', 'dialog'); panel.setAttribute('aria-modal', 'true'); panel.setAttribute('aria-labelledby', 'otlobli-script-diagnostics-title'); panel.setAttribute('aria-describedby', 'otlobli-script-diagnostics-intro');
    panel.appendChild(element('div', 'otlobli-diagnostic-handle'));
    var head = element('div', 'otlobli-diagnostic-head'), heading = element('div');
    var kicker = element('p', 'otlobli-diagnostic-kicker', 'OTLOBLI FLIGHT RECORDER'); kicker.setAttribute('translate', 'no');
    var title = element('h2', '', 'رحلة ضغطة المنتج'); title.id = 'otlobli-script-diagnostics-title';
    heading.appendChild(kicker); heading.appendChild(title);
    var close = element('button', 'otlobli-diagnostic-close', '×'); close.type = 'button'; close.setAttribute('aria-label', 'إغلاق اللوحة');
    head.appendChild(heading); head.appendChild(close); panel.appendChild(head);
    var intro = element('p', 'otlobli-diagnostic-intro', 'ابدأ من N0. افتح منتجًا، ثم سجّل إن فتح أو بقي يحمّل. انتقل بالترتيب حتى تظهر أول نتيجة سيئة.'); intro.id = 'otlobli-script-diagnostics-intro'; panel.appendChild(intro);

    var journeySection = element('section', 'otlobli-diagnostic-section'), journeyHead = element('div', 'otlobli-diagnostic-section-head');
    journeyHead.appendChild(element('h3', '', 'المسار الحي')); journeyHead.appendChild(element('span', 'otlobli-diagnostic-badge', 'قياس تلقائي'));
    journeyList = element('ol', 'otlobli-diagnostic-journey'); journeyList.setAttribute('aria-live', 'polite'); journeyList.setAttribute('aria-label', 'مراحل فتح المنتج'); journeySection.appendChild(journeyHead); journeySection.appendChild(journeyList); panel.appendChild(journeySection);

    var profilesSection = element('section', 'otlobli-diagnostic-section'), profilesHead = element('div', 'otlobli-diagnostic-section-head');
    profilesHead.appendChild(element('h3', '', 'ملفات العزل')); profilesHead.appendChild(element('span', 'otlobli-diagnostic-badge', 'بالترتيب'));
    profileList = element('div', 'otlobli-diagnostic-profiles'); profilesSection.appendChild(profilesHead);
    var actions = element('div', 'otlobli-diagnostic-actions');
    var pass = element('button', '', '✓ فتح المنتج'); pass.type = 'button'; pass.addEventListener('click', function () { markOutcome('pass'); });
    var fail = element('button', 'otlobli-diagnostic-fail', '! بقي يحمّل'); fail.type = 'button'; fail.addEventListener('click', function () { markOutcome('fail'); });
    actions.appendChild(pass); actions.appendChild(fail); profilesSection.appendChild(actions); profilesSection.appendChild(profileList); panel.appendChild(profilesSection);

    status = element('p'); status.id = 'otlobli-script-diagnostics-status'; status.setAttribute('role', 'status'); status.setAttribute('aria-live', 'polite');
    status.textContent = 'الاختبار الحالي: ' + currentProfile().code + ' — افتح منتجًا واحدًا.'; panel.appendChild(status);
    var footer = element('div', 'otlobli-diagnostic-footer');
    var reportButton = element('button', 'otlobli-diagnostic-copy-report', 'نسخ التقرير الكامل'); reportButton.type = 'button'; reportButton.addEventListener('click', copyReport);
    var clear = element('button', 'otlobli-diagnostic-clear', 'مسح الجولة'); clear.type = 'button'; clear.addEventListener('click', function () {
      state.outcomes = {}; state.trace = []; state.journey = { tap: false, url: false, document: false, product: false, error: false }; persist(); renderLiveState(); setStatus('مُسحت النتائج. ابدأ من N0.', 'neutral');
    });
    var exit = element('button', 'otlobli-diagnostic-exit', 'اختيار المتجر'); exit.type = 'button'; exit.addEventListener('click', function () { post({ type: 'closeStore' }); });
    footer.appendChild(reportButton); footer.appendChild(clear); footer.appendChild(exit); panel.appendChild(footer);

    function setOpen(open) {
      root.setAttribute('data-open', open ? '1' : '0'); trigger.setAttribute('aria-expanded', open ? 'true' : 'false'); trigger.tabIndex = open ? -1 : 0;
      backdrop.hidden = !open; panel.hidden = !open; panel.setAttribute('aria-hidden', open ? 'false' : 'true'); panel.inert = !open;
      if (open) close.focus(); else trigger.focus();
    }
    trigger.addEventListener('click', function () { setOpen(true); }); backdrop.addEventListener('click', function () { setOpen(false); }); close.addEventListener('click', function () { setOpen(false); });
    panel.addEventListener('keydown', function (event) {
      if (event.key === 'Escape') { setOpen(false); return; } if (event.key !== 'Tab') return;
      var focusable = panel.querySelectorAll('button:not([disabled])'); if (!focusable.length) return;
      var first = focusable[0], last = focusable[focusable.length - 1];
      if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus(); }
      else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); }
    });
    root.appendChild(trigger); root.appendChild(backdrop); root.appendChild(panel); document.body.appendChild(root);
    renderLiveState(); setOpen(false);
    if (/shein/i.test(location.hostname)) post({ type: 'sheinPageInteractive', diagnostic: true });
    else if (/temu/i.test(location.hostname)) post({ type: 'temuProductVisible', diagnostic: true, url: location.href });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', mount, { once: true }); else mount();
})();
`
