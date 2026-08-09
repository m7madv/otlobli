// Diagnostic iPhone build only. The script observes real product taps without
// preventing, stopping, replaying, or otherwise changing any event.
export const SHEIN_TAP_DIAGNOSTIC_SCRIPT = `!function(){
  if(window.__otlobliTapDiagnosticInstalled)return;
  window.__otlobliTapDiagnosticInstalled=1;
  var seq=0,active=null,afterTimer=0,bubbled=typeof WeakSet==='function'?new WeakSet():null;
  function cut(v,n){try{return String(v==null?'':v).slice(0,n)}catch(e){return''}}
  function cls(n){var v=n&&n.className;return cut(v&&v.baseVal!=null?v.baseVal:v,120)}
  function rect(n){try{var r=n.getBoundingClientRect();return[Math.round(r.left),Math.round(r.top),Math.round(r.width),Math.round(r.height)]}catch(e){return[]}}
  function node(n){if(!n||n.nodeType!==1)return null;var s={};try{s=getComputedStyle(n)}catch(e){}return{tag:cut(n.tagName,20),id:cut(n.id,80),cls:cls(n),role:cut(n.getAttribute&&n.getAttribute('role'),40),pe:cut(s.pointerEvents,20),display:cut(s.display,20),visibility:cut(s.visibility,20),opacity:cut(s.opacity,16),z:cut(s.zIndex,20),position:cut(s.position,20),rect:rect(n)}}
  function point(e){var t=e.changedTouches&&e.changedTouches[0]||e.touches&&e.touches[0];return t?[Math.round(t.clientX),Math.round(t.clientY)]:[Math.round(e.clientX||0),Math.round(e.clientY||0)]}
  function parents(n){var a=[];for(var i=0;n&&i<8;i++,n=n.parentElement){var v=node(n);if(v)a.push(v)}return a}
  function stack(x,y){try{return document.elementsFromPoint?document.elementsFromPoint(x,y):[]}catch(e){return[]}}
  function product(n){for(var i=0;n&&i<9;i++,n=n.parentElement){var k=cls(n),h='';try{h=n.href||n.getAttribute('href')||''}catch(e){}if(/-p-\\d+/i.test(h)||(n.classList&&n.classList.contains('product-card'))||/sd-ccc-products__item|(?:^|\\s)(?:product|goods)[-_][^\\s]*(?:item|card)/i.test(k)||n.getAttribute&&n.getAttribute('role')==='link'&&/(?:product|goods|sd-ccc)/i.test(k))return n}return null}
  function productAt(e,x,y){var p=product(e.target),a=stack(x,y);if(p)return p;for(var i=0;i<a.length&&i<20;i++){p=product(a[i]);if(p)return p}return null}
  function fixedAt(x,y){var a=stack(x,y),out=[],seen=[];for(var i=0;i<a.length&&i<20;i++){for(var n=a[i],d=0;n&&d<8;d++,n=n.parentElement){if(seen.indexOf(n)>=0)continue;seen.push(n);var v=node(n);if(!v)continue;if((v.position==='fixed'||v.position==='sticky')&&v.rect.length&&x>=v.rect[0]&&x<=v.rect[0]+v.rect[2]&&y>=v.rect[1]&&y<=v.rect[1]+v.rect[3])out.push(v);if(out.length>=12)return out}}return out}
  function region(){try{return typeof window.__otlobliTapDiagnosticContext==='function'?window.__otlobliTapDiagnosticContext():null}catch(e){return{error:cut(e,100)}}}
  function send(stage,data){try{var d=data||{};d.type='otlobliTapDiagnostic';d.stage=stage;d.at=Date.now();d.perf=Math.round(performance.now());d.href=cut(location.href,600);d.visibility=document.visibilityState;var h=window.webkit&&window.webkit.messageHandlers&&window.webkit.messageHandlers.messageHandler;if(h)h.postMessage({detail:d});else if(window.mobileApp&&window.mobileApp.postMessage)window.mobileApp.postMessage({detail:d})}catch(e){}}
  window.__otlobliTapDiagnostic=function(stage,data){send('fallback:'+stage,data||{})};
  function snapshot(e,p,x,y){var top=null,a=stack(x,y);if(a.length)top=node(a[0]);return{target:node(e.target),elementFromPoint:top,product:node(p),ancestors:parents(e.target),fixedLayers:fixedAt(x,y),region:region()}}
  function observe(e,phase){var q=point(e),p=productAt(e,q[0],q[1]),now=Date.now();if(e.type==='touchstart'&&phase==='capture'&&p){active={id:++seq,at:now,x:q[0],y:q[1],href:cut(location.href,600),product:p}}else if((!active||now-active.at>1800)&&e.type==='click'&&phase==='capture'&&p){active={id:++seq,at:now,x:q[0],y:q[1],href:cut(location.href,600),product:p}}if(!active)return;if(!p&&Math.abs(q[0]-active.x)+Math.abs(q[1]-active.y)>40)return;if(phase==='bubble'&&bubbled)bubbled.add(e);var data={attempt:active.id,event:e.type,phase:phase,isTrusted:!!e.isTrusted,cancelable:!!e.cancelable,defaultPrevented:!!e.defaultPrevented,x:q[0],y:q[1],hrefBefore:active.href,hrefChanged:location.href!==active.href};if(phase==='capture'){data.snapshot=snapshot(e,p||active.product,q[0],q[1]);var ev=e,attempt=active.id,before=active.href;Promise.resolve().then(function(){send('event-final',{attempt:attempt,event:ev.type,bubbleSeen:bubbled?bubbled.has(ev):null,cancelable:!!ev.cancelable,defaultPrevented:!!ev.defaultPrevented,hrefBefore:before,hrefChanged:location.href!==before})})}send('event',data);if(e.type==='touchend'&&phase==='bubble'){clearTimeout(afterTimer);var a=active;afterTimer=setTimeout(function(){send('tap-after',{attempt:a.id,hrefBefore:a.href,hrefAfter:cut(location.href,600),hrefChanged:location.href!==a.href,region:region()})},720)}}
  ['touchstart','touchend','click'].forEach(function(t){document.addEventListener(t,function(e){observe(e,'capture')},{capture:true,passive:true});document.addEventListener(t,function(e){observe(e,'bubble')},{capture:false,passive:true})});
  ['pageshow','pagehide','visibilitychange','focus','blur'].forEach(function(t){addEventListener(t,function(e){send('document:'+t,{persisted:!!e.persisted,region:region()})},true)});
  send('installed',{ua:cut(navigator.userAgent,180)});
}();`

// Interpolated inside SHEIN_CAPTURE_SCRIPT so it can report the authoritative
// region state without exposing cookies or scanning the page.
export const SHEIN_TAP_DIAGNOSTIC_CONTEXT_JS = `
  if (window.__otlobliTapDiagnostic) {
    window.__otlobliTapDiagnosticContext = function () {
      var u = null;
      try { u = new URL(location.href); } catch (e) {}
      return {
        requiredCountry: SHEIN_REQUIRED_COUNTRY,
        addressCountry: sheinAddressCookieCountry(),
        signedReady: sheinSignedSaudiAddressReady(),
        transitionActive: sheinNativeCoverRepairActive,
        transitionMs: sheinNativeCoverRepairStartedAt ? Date.now() - sheinNativeCoverRepairStartedAt : 0,
        veilMounted: !!document.getElementById('otlobli-region-switching'),
        urlCountry: u ? String(u.searchParams.get('localcountry') || u.searchParams.get('country') || '') : ''
      };
    };
    window.__otlobliTapDiagnostic('capture-context-ready', window.__otlobliTapDiagnosticContext());
  }
`
