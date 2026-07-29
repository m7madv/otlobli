export const SHEIN_REGION_DIAGNOSTICS_SCRIPT = `
(function () {
  if (window.__otlobliRegionDiagnostic) return;
  var seen = {};
  var pending = [];

  function snapshot() {
    var raw = '';
    var parsed = null;
    try {
      raw = localStorage.getItem('addressCookie') || '';
      parsed = raw ? JSON.parse(raw) : null;
    } catch (e) {}
    return {
      cookiePresent: !!raw,
      cookieCountry: parsed ? String(parsed.value || parsed.countryAbbr || parsed.countryCode || parsed.countryName || parsed.countryId || '') : '',
      cookieSignatureLength: parsed ? String(parsed.xAdFlag || '').length : 0
    };
  }

  function post(payload) {
    try {
      if (window.mobileApp && window.mobileApp.postMessage) {
        window.mobileApp.postMessage({ detail: payload });
        return true;
      }
    } catch (e) {}
    return false;
  }

  window.__otlobliRegionDiagnostic = function (stage, data, key) {
    var route = String(location.pathname || '/');
    var dedupeKey = stage + '|' + route + '|' + String(key || '');
    if (seen[dedupeKey]) return;
    seen[dedupeKey] = true;
    var payload = Object.assign({
      type: 'sheinRegionDiagnostic',
      stage: stage,
      href: String(location.href || '').slice(0, 700),
      route: route,
      readyState: document.readyState,
      at: Date.now()
    }, snapshot(), data || {});
    try { console.info('[otlobli-region]', payload); } catch (e) {}
    if (!post(payload) && pending.length < 32) pending.push(payload);
  };

  window.__otlobliRegionDiagnostic('capture-evaluation-start', {
    requiredCountry: String((((window.__OTLOBLI_STORE_REGIONS__ || {}).shein || {}).countryCode) || 'SA').toUpperCase()
  }, 'start');

  var attempts = 0;
  var flushTimer = setInterval(function () {
    attempts++;
    if (pending.length && window.mobileApp && window.mobileApp.postMessage) {
      var queued = pending.splice(0, pending.length);
      for (var i = 0; i < queued.length; i++) post(queued[i]);
    }
    if (!pending.length || attempts >= 20) clearInterval(flushTimer);
  }, 250);
})();
`
