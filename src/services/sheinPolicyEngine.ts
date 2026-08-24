export const SHEIN_POLICY_VERSION = '2026.08.24-v86.231-policy-v2'

export type SheinRouteClass =
  | 'allowed-public'
  | 'home'
  | 'category'
  | 'search'
  | 'product'
  | 'human-verification'
  | 'blocked-login'
  | 'blocked-signup'
  | 'blocked-account'
  | 'blocked-country'
  | 'blocked-region'
  | 'blocked-language'
  | 'blocked-currency'
  | 'blocked-checkout'
  | 'external'
  | 'unknown'

const BLOCKED_ROUTE_CLASSES = new Set<SheinRouteClass>([
  'blocked-login',
  'blocked-signup',
  'blocked-account',
  'blocked-country',
  'blocked-region',
  'blocked-language',
  'blocked-currency',
  'blocked-checkout',
])

const HUMAN_PATH = /\/(?:cdn-cgi|challenge|captcha|verify|verification|security|robot|risk|anti[-_]?bot|human)(?:[/?#.-]|$)/i
const HUMAN_QUERY = /(?:^|[?&#])(?:captcha|challenge|verification|security_token|risk|robot|anti[-_]?bot|human)=/i

export function classifySheinRoute(rawUrl: string, baseUrl = 'https://m.shein.com/ar/'): SheinRouteClass {
  let url: URL
  try {
    url = new URL(rawUrl, baseUrl)
  } catch {
    return 'unknown'
  }
  if (url.protocol !== 'https:' && url.protocol !== 'http:') return 'external'
  const host = url.hostname.toLowerCase()
  if (host !== 'shein.com' && !host.endsWith('.shein.com')) return 'external'

  const path = url.pathname.replace(/\/{2,}/g, '/').toLowerCase()
  const route = `${path}${url.search}${url.hash}`
  if (HUMAN_PATH.test(path) || HUMAN_QUERY.test(route)) return 'human-verification'
  if (/\/(?:user\/)?(?:login|signin|sign-in|auth\/login)(?:[/?#.-]|$)/i.test(path)) return 'blocked-login'
  if (/\/(?:user\/)?(?:register|signup|sign-up|join)(?:[/?#.-]|$)/i.test(path)) return 'blocked-signup'
  if (/\/(?:user|account|profile|my-account|member|orders?)(?:[/?#.-]|$)/i.test(path)) return 'blocked-account'
  if (/\/(?:country|countries|ship-to|shipping-country)(?:[/?#.-]|$)/i.test(path)) return 'blocked-country'
  if (/\/(?:region|location|shipping-address|address-book)(?:[/?#.-]|$)/i.test(path)) return 'blocked-region'
  if (/\/(?:language|languages|locale)(?:[/?#.-]|$)/i.test(path)) return 'blocked-language'
  if (/\/(?:currency|currencies)(?:[/?#.-]|$)/i.test(path)) return 'blocked-currency'
  if (/\/(?:cart|bag|checkout|order-confirm|payment)(?:[/?#.-]|$)/i.test(path)) return 'blocked-checkout'
  if (/(?:-p-\d+|\/product\/|\/goods\/|\/item\/)/i.test(path) || /[?&](?:goods_id|goodsid|product_id|productid|mallcode|skc)=/i.test(url.search)) return 'product'
  if (/\/(?:search|search-result)(?:[/?#.-]|$)/i.test(path) || url.searchParams.has('search')) return 'search'
  if (/\/(?:category|categories|collection|collections|campaign|daily|women|men|kids|curve|home-living)(?:[/?#.-]|$)/i.test(path)) return 'category'

  const normalized = path.replace(/^\/+|\/+$/g, '')
  if (!normalized || /^[a-z]{2}(?:-[a-z]{2})?$/.test(normalized)) return 'home'
  return 'allowed-public'
}

export const isBlockedSheinRoute = (routeClass: SheinRouteClass) => BLOCKED_ROUTE_CLASSES.has(routeClass)

const DOCUMENT_START_CSS = `
[data-otlobli-policy-hidden="1"],
a[href*="/user/login" i],a[href*="/login" i],a[href*="/signin" i],
a[href*="/signup" i],a[href*="/sign-up" i],a[href*="/register" i],
a[href*="/account" i],a[href*="/profile" i],a[href*="/my-account" i],
a[href*="/country" i],a[href*="/region" i],a[href*="/language" i],a[href*="/currency" i],
a[href*="/cart" i],a[href*="/checkout" i],a[href*="/payment" i]
{display:none!important;visibility:hidden!important;}
`

// This policy is deliberately independent from product capture. It installs at
// document start, owns one observer, never wraps history/fetch/XHR/console, and
// never installs a document-wide input handler.
export const SHEIN_POLICY_DOCUMENT_START_SCRIPT = `
(function(){
  'use strict';
  if(!/(^|\\.)shein\\.com$/i.test(location.hostname||''))return;
  var VERSION=${JSON.stringify(SHEIN_POLICY_VERSION)};
  var existing=window.__otlobliSheinPolicyEngine;
  if(existing&&existing.version===VERSION){existing.verify&&existing.verify('duplicate-install');return;}
  if(existing&&existing.observer&&existing.observer.disconnect)try{existing.observer.disconnect();}catch(e){}
  var state={version:VERSION,installCount:1,observer:null,hiddenCount:0,mismatchCount:0,lastVerification:'',verify:null};
  window.__otlobliSheinPolicyEngine=state;
  var MAX_ROOTS=96,MAX_NODES_PER_ROOT=320,MAX_MISMATCHES=8;
  var pending=[],scheduled=false,reported={};
  var candidateSelector='a[href],area[href],form[action],button,[role="button"],[role="link"],[aria-label],[data-testid],[data-qa],[data-type],[data-role],[data-action],[data-name]';
  var blockedClasses={
    'blocked-login':1,'blocked-signup':1,'blocked-account':1,'blocked-country':1,
    'blocked-region':1,'blocked-language':1,'blocked-currency':1,'blocked-checkout':1
  };
  var humanPattern=/(captcha|challenge|verification|verify|security|robot|risk|anti[-_]?bot|human|\\u062a\\u062d\\u0642\\u0642|\\u0623\\u0646\\u0627 \\u0625\\u0646\\u0633\\u0627\\u0646)/i;
  function post(detail){try{if(window.mobileApp&&window.mobileApp.postMessage)window.mobileApp.postMessage({detail:detail});}catch(e){}}
  function routeClass(raw){
    try{
      var u=new URL(raw,location.href),host=(u.hostname||'').toLowerCase(),path=(u.pathname||'').replace(/\\/{2,}/g,'/').toLowerCase(),all=path+u.search+u.hash;
      if(host!=='shein.com'&&!/\\.shein\\.com$/.test(host))return'external';
      if(/\\/(?:cdn-cgi|challenge|captcha|verify|verification|security|robot|risk|anti[-_]?bot|human)(?:[/?#.-]|$)/i.test(path)||/(?:^|[?&#])(?:captcha|challenge|verification|security_token|risk|robot|anti[-_]?bot|human)=/i.test(all))return'human-verification';
      if(/\\/(?:user\\/)?(?:login|signin|sign-in|auth\\/login)(?:[/?#.-]|$)/i.test(path))return'blocked-login';
      if(/\\/(?:user\\/)?(?:register|signup|sign-up|join)(?:[/?#.-]|$)/i.test(path))return'blocked-signup';
      if(/\\/(?:user|account|profile|my-account|member|orders?)(?:[/?#.-]|$)/i.test(path))return'blocked-account';
      if(/\\/(?:country|countries|ship-to|shipping-country)(?:[/?#.-]|$)/i.test(path))return'blocked-country';
      if(/\\/(?:region|location|shipping-address|address-book)(?:[/?#.-]|$)/i.test(path))return'blocked-region';
      if(/\\/(?:language|languages|locale)(?:[/?#.-]|$)/i.test(path))return'blocked-language';
      if(/\\/(?:currency|currencies)(?:[/?#.-]|$)/i.test(path))return'blocked-currency';
      if(/\\/(?:cart|bag|checkout|order-confirm|payment)(?:[/?#.-]|$)/i.test(path))return'blocked-checkout';
      return'allowed-public';
    }catch(e){return'unknown';}
  }
  function challengeOwned(el){
    for(var n=el,d=0;n&&d<7;n=n.parentElement,d++){
      var hint=((n.id||'')+' '+(n.className||'')+' '+(n.getAttribute&&n.getAttribute('aria-label')||'')).slice(0,500);
      if(humanPattern.test(hint))return true;
    }
    return humanPattern.test(location.pathname+location.search);
  }
  function owned(el){
    if(!el||el.nodeType!==1)return true;
    if((el.id||'').indexOf('otlobli')===0)return true;
    if(el.closest&&el.closest('[id^="otlobli"],[data-otlobli-capture-owned="1"],#otlobli-add-btn,#otlobli-nav'))return true;
    // The customer cannot open SHEIN's country/region UI because policy hides
    // it normally. During Otlobli's own bounded signed-address repair, however,
    // the capture runtime must be able to operate the active cascade drawer.
    // Scope the exemption to the exact drawer and only while our repair veil
    // exists; login/account/checkout surfaces remain blocked throughout.
    if(document.getElementById('otlobli-region-switching')&&el.closest&&el.closest('.sui-drawer.cascade'))return true;
    return challengeOwned(el);
  }
  function semanticClass(el){
    var aria=String(el.getAttribute('aria-label')||'').trim().toLowerCase();
    if(aria){
      if(/sign in|log in|login|\\u062a\\u0633\\u062c\\u064a\\u0644 \\u0627\\u0644\\u062f\\u062e\\u0648\\u0644/.test(aria))return'blocked-login';
      if(/sign up|register|join|\\u0625\\u0646\\u0634\\u0627\\u0621 \\u062d\\u0633\\u0627\\u0628/.test(aria))return'blocked-signup';
      if(/account|profile|my shein|\\u062d\\u0633\\u0627\\u0628\\u064a|\\u0627\\u0644\\u062d\\u0633\\u0627\\u0628/.test(aria))return'blocked-account';
      if(/country|ship to|\\u0627\\u0644\\u0628\\u0644\\u062f|\\u0627\\u0644\\u062f\\u0648\\u0644\\u0629/.test(aria))return'blocked-country';
      if(/region|location|\\u0627\\u0644\\u0645\\u0646\\u0637\\u0642\\u0629|\\u0627\\u0644\\u0645\\u0648\\u0642\\u0639/.test(aria))return'blocked-region';
      if(/currency|\\u0627\\u0644\\u0639\\u0645\\u0644\\u0629/.test(aria))return'blocked-currency';
      if(/language|\\u0627\\u0644\\u0644\\u063a\\u0629/.test(aria))return'blocked-language';
      if(/checkout|shopping bag|cart|\\u0627\\u0644\\u0633\\u0644\\u0629|\\u0627\\u0644\\u062f\\u0641\\u0639/.test(aria))return'blocked-checkout';
    }
    var data=['data-testid','data-qa','data-type','data-role','data-action','data-name'].map(function(k){return el.getAttribute(k)||'';}).join(' ').toLowerCase();
    if(/(?:^|[-_ ])(?:login|signin|sign-in)(?:$|[-_ ])/.test(data))return'blocked-login';
    if(/(?:^|[-_ ])(?:signup|sign-up|register)(?:$|[-_ ])/.test(data))return'blocked-signup';
    if(/(?:^|[-_ ])(?:account|profile|member)(?:$|[-_ ])/.test(data))return'blocked-account';
    if(/(?:^|[-_ ])(?:country|ship-to)(?:$|[-_ ])/.test(data))return'blocked-country';
    if(/(?:^|[-_ ])(?:region|location)(?:$|[-_ ])/.test(data))return'blocked-region';
    if(/(?:^|[-_ ])currency(?:$|[-_ ])/.test(data))return'blocked-currency';
    if(/(?:^|[-_ ])(?:language|locale)(?:$|[-_ ])/.test(data))return'blocked-language';
    if(/(?:^|[-_ ])(?:cart|bag|checkout|payment)(?:$|[-_ ])/.test(data))return'blocked-checkout';
    var role=String(el.getAttribute('role')||'').toLowerCase(),tag=String(el.tagName||'').toUpperCase();
    if(role!=='button'&&role!=='link'&&tag!=='BUTTON'&&tag!=='A')return'';
    var text=String(el.textContent||'').replace(/\\s+/g,' ').trim();
    if(!text||text.length>48)return'';
    if(/^(?:sign in|log in|login|\\u062a\\u0633\\u062c\\u064a\\u0644 \\u0627\\u0644\\u062f\\u062e\\u0648\\u0644)$/i.test(text))return'blocked-login';
    if(/^(?:sign up|register|join|\\u0625\\u0646\\u0634\\u0627\\u0621 \\u062d\\u0633\\u0627\\u0628)$/i.test(text))return'blocked-signup';
    if(/^(?:my account|account|profile|\\u062d\\u0633\\u0627\\u0628\\u064a|\\u0627\\u0644\\u062d\\u0633\\u0627\\u0628)$/i.test(text))return'blocked-account';
    if(/^(?:change country|country|ship to|\\u062a\\u063a\\u064a\\u064a\\u0631 \\u0627\\u0644\\u0628\\u0644\\u062f|\\u0627\\u0644\\u062f\\u0648\\u0644\\u0629)$/i.test(text))return'blocked-country';
    if(/^(?:change region|region|\\u062a\\u063a\\u064a\\u064a\\u0631 \\u0627\\u0644\\u0645\\u0646\\u0637\\u0642\\u0629|\\u0627\\u0644\\u0645\\u0646\\u0637\\u0642\\u0629)$/i.test(text))return'blocked-region';
    if(/^(?:change currency|currency|\\u062a\\u063a\\u064a\\u064a\\u0631 \\u0627\\u0644\\u0639\\u0645\\u0644\\u0629|\\u0627\\u0644\\u0639\\u0645\\u0644\\u0629)$/i.test(text))return'blocked-currency';
    if(/^(?:change language|language|\\u062a\\u063a\\u064a\\u064a\\u0631 \\u0627\\u0644\\u0644\\u063a\\u0629|\\u0627\\u0644\\u0644\\u063a\\u0629)$/i.test(text))return'blocked-language';
    return'';
  }
  function classify(el){
    var target=el.getAttribute&&((el.getAttribute('href')||el.getAttribute('action'))||'');
    if(target){var byRoute=routeClass(target);if(blockedClasses[byRoute])return byRoute;}
    return semanticClass(el);
  }
  function hide(el,kind){
    if(!kind||owned(el)||el.getAttribute('data-otlobli-policy-hidden')==='1')return;
    el.setAttribute('data-otlobli-policy-hidden','1');
    el.setAttribute('data-otlobli-policy-class',kind);
    el.setAttribute('aria-hidden','true');
    el.setAttribute('tabindex','-1');
    state.hiddenCount++;
  }
  function scan(root){
    if(!root||root.nodeType!==1)return;
    if(root.matches&&root.matches(candidateSelector))hide(root,classify(root));
    var nodes=root.querySelectorAll?root.querySelectorAll(candidateSelector):[];
    for(var i=0;i<nodes.length&&i<MAX_NODES_PER_ROOT;i++)hide(nodes[i],classify(nodes[i]));
    if(nodes.length>MAX_NODES_PER_ROOT)mismatch('subtree-cap');
  }
  function enqueue(root){
    if(!root||root.nodeType!==1||pending.length>=MAX_ROOTS)return false;
    var relevant=(root.matches&&root.matches(candidateSelector))||
      (root.querySelector&&root.querySelector(candidateSelector));
    if(!relevant)return false;
    for(var i=pending.length-1;i>=0;i--){
      var queued=pending[i];
      if(queued===root||(queued.contains&&queued.contains(root)))return false;
      if(root.contains&&root.contains(queued))pending.splice(i,1);
    }
    pending.push(root);return true;
  }
  function mismatch(code){
    if(reported[code]||state.mismatchCount>=MAX_MISMATCHES)return;
    reported[code]=1;state.mismatchCount++;
    post({type:'sheinPolicyMismatch',version:VERSION,code:code});
  }
  function flush(){
    scheduled=false;
    var roots=pending.splice(0,MAX_ROOTS);
    var hiddenBefore=state.hiddenCount,mismatchBefore=state.mismatchCount;
    for(var i=0;i<roots.length;i++)scan(roots[i]);
    if(pending.length){pending.length=0;mismatch('mutation-root-cap');}
    if(state.hiddenCount!==hiddenBefore||state.mismatchCount!==mismatchBefore)verify('mutation');
  }
  function schedule(){
    if(scheduled)return;scheduled=true;
    (window.requestAnimationFrame||function(cb){return setTimeout(cb,16);})(flush);
  }
  function verify(reason){
    var challenge=humanPattern.test(location.pathname+location.search)||!!document.querySelector('[class*="captcha" i],[class*="challenge" i],[class*="verification" i],[aria-label*="verification" i]');
    var interactive=!!document.querySelector('a[href*="-p-"],a[href*="/product/"],a[href*="/category/"],a[href*="/search"],input[type="search"]');
    var capture=window.__otlobliStoreRuntimeReady===true;
    var key=[location.pathname,challenge,interactive,capture,state.hiddenCount,state.mismatchCount].join('|');
    if(key===state.lastVerification&&reason!=='duplicate-install')return;
    state.lastVerification=key;
    post({type:'sheinPolicyState',version:VERSION,installed:true,installCount:state.installCount,observerCount:state.observer?1:0,humanVerificationAvailable:challenge,publicInteractionAvailable:interactive,captureInstalled:capture,hiddenCount:state.hiddenCount,mismatchCount:state.mismatchCount,reason:reason});
  }
  state.verify=verify;
  function install(){
    var parent=document.head||document.documentElement;
    if(parent&&!document.getElementById('otlobli-shein-policy-style')){
      var style=document.createElement('style');style.id='otlobli-shein-policy-style';style.textContent=${JSON.stringify(DOCUMENT_START_CSS)};parent.appendChild(style);
    }
    var root=document.documentElement;
    if(!root)return;
    scan(root);
    if(!state.observer){
      state.observer=new MutationObserver(function(records){
        var queued=false;
        for(var i=0;i<records.length&&pending.length<MAX_ROOTS;i++){
          var record=records[i];
          if(record.type==='attributes'){
            if(record.target.matches&&record.target.matches(candidateSelector))queued=enqueue(record.target)||queued;
          }else for(var j=0;j<record.addedNodes.length&&pending.length<MAX_ROOTS;j++)queued=enqueue(record.addedNodes[j])||queued;
        }
        if(queued)schedule();
      });
      // Class/id animation churn cannot change semanticClass(). Observe only
      // attributes that can actually turn an element into a blocked control.
      state.observer.observe(root,{subtree:true,childList:true,attributes:true,attributeFilter:['href','action','aria-label','role','data-testid','data-qa','data-type','data-role','data-action','data-name']});
    }
    verify('install');
  }
  install();
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',function(){scan(document.documentElement);verify('dom-ready');},{once:true});
})();
`
