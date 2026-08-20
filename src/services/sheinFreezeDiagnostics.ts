// Dedicated iPhone diagnostic build only. This probe is passive: it does not
// alter the page DOM, cancel/replay input, patch console/fetch/XHR/history,
// navigate, reload, or write website data. The only mutation observed by its
// MutationObserver heartbeat is a detached Text node that is never attached to
// the SHEIN document. URLs are stripped to origin + path before logging.
export const SHEIN_FREEZE_DIAGNOSTIC_SCRIPT = `!function(){
  'use strict';
  if(window.top!==window)return;
  var existing=window.__otlobliRootCauseProbe;
  if(existing&&typeof existing.noteInjection==='function'){existing.noteInjection('document-start-repeat');return}

  var probeVersion='2026.08.20-v86.202-root-cause-v1';
  var sequence=0,installationAttempts=1,lastResourceIndex=0,resourceBudget=180;
  var interactionSequence=0,interactionBudget=60,lastPath='';
  var documentId=makeId('doc');
  var heartbeat={
    promise:{count:0,last:0},microtask:{count:0,last:0},timeout:{count:0,last:0},
    interval:{count:0,last:0},raf:{count:0,last:0},mutation:{count:0,last:0},
    messageChannel:{count:0,last:0},longTask:{count:0,last:0,totalDuration:0}
  };

  function makeId(prefix){
    try{var words=new Uint32Array(3);crypto.getRandomValues(words);return prefix+'-'+Date.now().toString(36)+'-'+Array.prototype.map.call(words,function(value){return value.toString(36)}).join('-')}
    catch(error){return prefix+'-'+Date.now().toString(36)+'-'+Math.round(performance.now()).toString(36)+'-'+Math.random().toString(36).slice(2,10)}
  }
  function text(value,limit){var result='';try{result=String(value==null?'':value)}catch(error){result='[unprintable]'}return result.slice(0,limit)}
  function hash(value){value=text(value,32768);var result=2166136261;for(var index=0;index<value.length;index++)result=Math.imul(result^value.charCodeAt(index),16777619);return('00000000'+(result>>>0).toString(16)).slice(-8)}
  function safeUrl(value){try{var url=new URL(String(value||''),location.href);return text(url.origin+url.pathname,1024)}catch(error){return text(String(value||'').split(/[?#]/)[0],1024)}}
  function cleanStack(value){return text(value,8192).replace(/https?:\\/\\/[^\\s)>\\]}]+/g,function(url){return safeUrl(url)}).slice(0,4096)}
  function nativeContext(){var value=window.__otlobliRootCauseNativeContext;return value&&typeof value==='object'?value:{}}
  function common(){var native=nativeContext();return{
    probeVersion:probeVersion,sequence:++sequence,at:Date.now(),performanceNow:Math.round(performance.now()),
    runId:text(native.runId,80),browserId:text(native.browserId,120),webViewId:text(native.webViewId,120),
    navigationId:text(native.navigationId,80),documentId:documentId,installationAttempts:installationAttempts,
    url:safeUrl(location.href),path:text(location.pathname,1024),visibilityState:text(document.visibilityState,32),
    hidden:!!document.hidden,hasFocus:!!(document.hasFocus&&document.hasFocus()),readyState:text(document.readyState,32),
    wasDiscarded:!!document.wasDiscarded,online:navigator.onLine!==false
  }}
  function bridge(){return window.webkit&&window.webkit.messageHandlers&&window.webkit.messageHandlers.messageHandler}
  function send(stage,extra){try{var detail=common();detail.type='otlobliRootCauseProbe';detail.stage=stage;if(extra)for(var key in extra)if(Object.prototype.hasOwnProperty.call(extra,key))detail[key]=extra[key];var handler=bridge();if(handler)handler.postMessage({detail:detail});else if(window.mobileApp&&window.mobileApp.postMessage)window.mobileApp.postMessage({detail:detail})}catch(error){}}

  function age(entry,now){return entry.last?Math.max(0,now-entry.last):-1}
  function heartbeatState(){var now=Date.now();return{
    promiseCount:heartbeat.promise.count,promiseAgeMs:age(heartbeat.promise,now),
    microtaskCount:heartbeat.microtask.count,microtaskAgeMs:age(heartbeat.microtask,now),
    timeoutCount:heartbeat.timeout.count,timeoutAgeMs:age(heartbeat.timeout,now),
    intervalCount:heartbeat.interval.count,intervalAgeMs:age(heartbeat.interval,now),
    rafCount:heartbeat.raf.count,rafAgeMs:age(heartbeat.raf,now),
    mutationCount:heartbeat.mutation.count,mutationAgeMs:age(heartbeat.mutation,now),
    messageChannelCount:heartbeat.messageChannel.count,messageChannelAgeMs:age(heartbeat.messageChannel,now),
    longTaskCount:heartbeat.longTask.count,lastLongTaskAgeMs:age(heartbeat.longTask,now),
    longTaskTotalDuration:Math.round(heartbeat.longTask.totalDuration)
  }}

  function nodeInfo(node){if(!node||node.nodeType!==1)return null;var classes='';try{classes=node.className&&node.className.baseVal!=null?node.className.baseVal:node.className||''}catch(error){}return{
    tag:text(node.tagName,24),id:text(node.id,80),classes:text(classes,160),role:text(node.getAttribute&&node.getAttribute('role'),48),
    href:safeUrl(node.href||node.getAttribute&&node.getAttribute('href')||''),ariaLabel:text(node.getAttribute&&node.getAttribute('aria-label'),120)
  }}
  function visibleCount(nodes,limit){var count=0,max=Math.min(nodes.length,limit);for(var index=0;index<max;index++){try{var rect=nodes[index].getBoundingClientRect(),style=getComputedStyle(nodes[index]);if(rect.width>0&&rect.height>0&&style.display!=='none'&&style.visibility!=='hidden'&&Number(style.opacity||1)>0)count++}catch(error){}}return{visible:count,sampled:max,total:nodes.length}}
  function rootNode(){return document.querySelector('#app,#root,#main,[data-v-app],main,[role="main"]')||document.body||document.documentElement}
  function rootState(){var root=rootNode();if(!root)return{present:false};var rows=[],children=root.children||[];for(var index=0;index<children.length&&index<60;index++){var child=children[index],classes='';try{classes=child.className&&child.className.baseVal!=null?child.className.baseVal:child.className||''}catch(error){}rows.push(text(child.tagName,24)+'#'+text(child.id,48)+'.'+text(classes,96)+':'+String(child.childElementCount||0))}return{
    present:true,tag:text(root.tagName,24),id:text(root.id,80),classes:text(root.className&&root.className.baseVal!=null?root.className.baseVal:root.className,160),
    childCount:Number(root.childElementCount||0),textLength:Number((root.textContent||'').length),structureHash:hash(rows.join('|'))
  }}
  function pageFingerprint(){var links=document.links||[],buttons=document.querySelectorAll('button,[role="button"]'),interactive=document.querySelectorAll('a[href],button,input,select,textarea,[role="button"],[role="link"],[tabindex]'),images=document.images||[],loadedImages=0;for(var imageIndex=0;imageIndex<images.length;imageIndex++)if(images[imageIndex].complete&&images[imageIndex].naturalWidth>0)loadedImages++;var visible=visibleCount(interactive,600);var scripts=document.scripts||[],moduleScripts=0;for(var scriptIndex=0;scriptIndex<scripts.length;scriptIndex++)if(String(scripts[scriptIndex].type||'').toLowerCase()==='module')moduleScripts++;var skeletons=document.querySelectorAll('[class*="skeleton" i],[class*="loading" i],[aria-busy="true"]');return{
    bodyTextLength:Number(document.body&&(document.body.textContent||'').length||0),linkCount:links.length,buttonCount:buttons.length,
    interactiveCount:interactive.length,visibleInteractiveCount:visible.visible,visibleInteractiveSampled:visible.sampled,
    scriptCount:scripts.length,moduleScriptCount:moduleScripts,imageCount:images.length,loadedImageCount:loadedImages,
    skeletonLikeCount:skeletons.length,frameCount:window.frames.length,historyLength:history.length,root:rootState()
  }}
  function reactionState(){var fingerprint=pageFingerprint();return{
    url:safeUrl(location.href),path:text(location.pathname,1024),historyLength:history.length,
    bodyTextLength:fingerprint.bodyTextLength,skeletonLikeCount:fingerprint.skeletonLikeCount,
    interactiveCount:fingerprint.interactiveCount,root:fingerprint.root
  }}

  function storageAreaMetadata(storage){try{var keys=[],approximateSize=0;for(var index=0;index<storage.length;index++){var key=String(storage.key(index)||'');keys.push(text(key,240));var value=storage.getItem(key);approximateSize+=key.length+(value==null?0:String(value).length)}keys.sort();return{count:storage.length,keyNames:keys.slice(0,240),keyNamesTruncated:keys.length>240,approximateCharacterSize:approximateSize}}catch(error){return{count:-1,keyNames:[],errorName:text(error&&error.name,80)}}}
  function cookieMetadata(){try{var names=String(document.cookie||'').split(';').map(function(row){var clean=row.trim(),split=clean.indexOf('=');return text(split<0?clean:clean.slice(0,split),240)}).filter(Boolean);names=Array.from(new Set(names)).sort();return{count:names.length,names:names}}catch(error){return{count:-1,names:[],errorName:text(error&&error.name,80)}}}
  function syncStorageMetadata(){return{cookies:cookieMetadata(),localStorage:storageAreaMetadata(localStorage),sessionStorage:storageAreaMetadata(sessionStorage)}}
  function asyncStorageMetadata(label){var jobs=[];
    jobs.push(typeof indexedDB!=='undefined'&&indexedDB.databases?indexedDB.databases().then(function(databases){return{indexedDB:databases.map(function(database){return{name:text(database.name,240),version:Number(database.version||0)}})}}).catch(function(error){return{indexedDB:[],indexedDBError:text(error&&error.name,80)}}):Promise.resolve({indexedDB:[],indexedDBUnsupported:true}));
    jobs.push(typeof caches!=='undefined'&&caches.keys?caches.keys().then(function(names){return{cacheStorageNames:names.map(function(name){return text(name,240)}).sort()}}).catch(function(error){return{cacheStorageNames:[],cacheStorageError:text(error&&error.name,80)}}):Promise.resolve({cacheStorageNames:[],cacheStorageUnsupported:true}));
    jobs.push(navigator.serviceWorker&&navigator.serviceWorker.getRegistrations?navigator.serviceWorker.getRegistrations().then(function(registrations){var controller=navigator.serviceWorker.controller;return{serviceWorkerController:!!controller,serviceWorkerControllerPath:safeUrl(controller&&controller.scriptURL||''),serviceWorkers:registrations.map(function(registration){var worker=registration.active||registration.waiting||registration.installing;return{scope:safeUrl(registration.scope),scriptPath:safeUrl(worker&&worker.scriptURL||''),state:text(worker&&worker.state,40)}})}}).catch(function(error){return{serviceWorkers:[],serviceWorkerError:text(error&&error.name,80)}}):Promise.resolve({serviceWorkers:[],serviceWorkerUnsupported:true}));
    Promise.all(jobs).then(function(parts){var metadata={snapshotLabel:label};for(var index=0;index<parts.length;index++)for(var key in parts[index])metadata[key]=parts[index][key];send('storage-async-metadata',metadata)})
  }

  function navigationState(){try{var entries=performance.getEntriesByType('navigation'),entry=entries&&entries[0];return{
    type:text(entry&&entry.type||(performance.navigation&&performance.navigation.type),40),redirectCount:Number(entry&&entry.redirectCount||performance.navigation&&performance.navigation.redirectCount||0),
    responseStatus:Number(entry&&entry.responseStatus||0),startTime:Math.round(entry&&entry.startTime||0),responseStart:Math.round(entry&&entry.responseStart||0),
    responseEnd:Math.round(entry&&entry.responseEnd||0),domInteractive:Math.round(entry&&entry.domInteractive||0),
    domContentLoaded:Math.round(entry&&entry.domContentLoadedEventEnd||0),loadEventEnd:Math.round(entry&&entry.loadEventEnd||0),
    transferSize:Number(entry&&entry.transferSize||0),encodedBodySize:Number(entry&&entry.encodedBodySize||0),decodedBodySize:Number(entry&&entry.decodedBodySize||0)
  }}catch(error){return{type:'error',errorName:text(error&&error.name,80)}}}
  function resourceSnapshot(label){try{var entries=performance.getEntriesByType('resource')||[],summary={snapshotLabel:label,totalCount:entries.length,newCount:Math.max(0,entries.length-lastResourceIndex),status4xx:0,status5xx:0,status429:0,scriptCount:0,fetchCount:0,zeroTransferCount:0};for(var index=0;index<entries.length;index++){var entry=entries[index],status=Number(entry.responseStatus||0),kind=text(entry.initiatorType,40);if(status>=400&&status<500)summary.status4xx++;if(status>=500)summary.status5xx++;if(status===429)summary.status429++;if(kind==='script')summary.scriptCount++;if(kind==='fetch'||kind==='xmlhttprequest')summary.fetchCount++;if(Number(entry.transferSize||0)===0)summary.zeroTransferCount++}send('resource-summary',summary);for(var row=lastResourceIndex;row<entries.length&&resourceBudget>0;row++){var current=entries[row],currentStatus=Number(current.responseStatus||0),initiator=text(current.initiatorType,40),important=currentStatus>=400||initiator==='script'||initiator==='fetch'||initiator==='xmlhttprequest'||initiator==='link';if(!important)continue;resourceBudget--;send('resource-entry',{snapshotLabel:label,resourceUrl:safeUrl(current.name),initiatorType:initiator,responseStatus:currentStatus,startTime:Math.round(current.startTime||0),duration:Math.round(current.duration||0),transferSize:Number(current.transferSize||0),encodedBodySize:Number(current.encodedBodySize||0),decodedBodySize:Number(current.decodedBodySize||0),protocol:text(current.nextHopProtocol,40)})}lastResourceIndex=entries.length}catch(error){send('resource-snapshot-error',{snapshotLabel:label,errorName:text(error&&error.name,80),message:text(error&&error.message,240)})}}

  function snapshot(label){label=text(label||'MANUAL',120);var payload={snapshotLabel:label,heartbeat:heartbeatState(),fingerprint:pageFingerprint(),navigation:navigationState(),storage:syncStorageMetadata()};send('root-cause-snapshot',payload);asyncStorageMetadata(label);resourceSnapshot(label);return payload}
  function lifecycle(stage,event){send('page-lifecycle',{lifecycleStage:stage,persisted:!!(event&&event.persisted)});if(stage==='pageshow'||stage==='load'||stage==='visibilitychange'||stage==='pagehide')snapshot('LIFECYCLE_'+stage.toUpperCase())}

  var mutationNode=document.createTextNode('0');
  try{new MutationObserver(function(){heartbeat.mutation.count++;heartbeat.mutation.last=Date.now()}).observe(mutationNode,{characterData:true})}catch(error){}
  var channel=null;
  try{channel=new MessageChannel();channel.port1.onmessage=function(){heartbeat.messageChannel.count++;heartbeat.messageChannel.last=Date.now()};channel.port1.start&&channel.port1.start()}catch(error){}
  try{new PerformanceObserver(function(list){var entries=list.getEntries();for(var index=0;index<entries.length;index++){heartbeat.longTask.count++;heartbeat.longTask.last=Date.now();heartbeat.longTask.totalDuration+=Number(entries[index].duration||0)}}).observe({entryTypes:['longtask']})}catch(error){}
  function kickHeartbeats(){var now=Date.now();heartbeat.interval.count++;heartbeat.interval.last=now;Promise.resolve().then(function(){heartbeat.promise.count++;heartbeat.promise.last=Date.now()});if(typeof queueMicrotask==='function')queueMicrotask(function(){heartbeat.microtask.count++;heartbeat.microtask.last=Date.now()});else Promise.resolve().then(function(){heartbeat.microtask.count++;heartbeat.microtask.last=Date.now()});setTimeout(function(){heartbeat.timeout.count++;heartbeat.timeout.last=Date.now()},0);try{requestAnimationFrame(function(){heartbeat.raf.count++;heartbeat.raf.last=Date.now()})}catch(error){}try{mutationNode.data=mutationNode.data==='0'?'1':'0'}catch(error){}try{channel&&channel.port2.postMessage(1)}catch(error){}var currentPath=location.pathname;if(lastPath&&currentPath!==lastPath)send('spa-route-observed',{fromPath:text(lastPath,1024),toPath:text(currentPath,1024),historyLength:history.length});lastPath=currentPath}
  kickHeartbeats();setInterval(kickHeartbeats,400);setInterval(function(){send('event-loop-heartbeat',{heartbeat:heartbeatState()})},1000);

  function eventPoint(event){var touch=event&&event.changedTouches&&event.changedTouches[0]||event&&event.touches&&event.touches[0];return{x:Math.round(touch?touch.clientX:Number(event&&event.clientX||0)),y:Math.round(touch?touch.clientY:Number(event&&event.clientY||0))}}
  function interaction(event){if(interactionBudget<=0)return;interactionBudget--;var point=eventPoint(event),top=null;try{top=document.elementFromPoint(point.x,point.y)}catch(error){}var id=++interactionSequence,before=reactionState();send('interaction-event',{interactionId:id,eventType:text(event.type,32),isTrusted:!!event.isTrusted,defaultPrevented:!!event.defaultPrevented,x:point.x,y:point.y,target:nodeInfo(event.target),elementFromPoint:nodeInfo(top),before:before});if(event.type!=='click')return;[50,250,1000].forEach(function(delay){setTimeout(function(){var after=reactionState();send('interaction-reaction',{interactionId:id,eventType:'click',delayMs:delay,isTrusted:!!event.isTrusted,defaultPrevented:!!event.defaultPrevented,before:before,after:after,pathChanged:before.path!==after.path,urlChanged:before.url!==after.url,historyChanged:before.historyLength!==after.historyLength,rootChanged:!!(before.root&&after.root&&before.root.structureHash!==after.root.structureHash)})},delay)})}
  ['pointerdown','touchstart','click'].forEach(function(name){document.addEventListener(name,interaction,{capture:true,passive:true})});

  addEventListener('error',function(event){var target=event&&event.target;if(target&&target!==window&&!(typeof ErrorEvent!=='undefined'&&event instanceof ErrorEvent)){send('resource-error',{tag:text(target.tagName,32),resourceUrl:safeUrl(target.currentSrc||target.src||target.href||''),resourceType:text(target.type,80),resourceRel:text(target.rel,80),resourceAs:text(target.as,80)});return}var value=event&&event.error;send('javascript-error',{message:text(event&&event.message,1024),errorName:text(value&&value.name,80),source:safeUrl(event&&event.filename),line:Number(event&&event.lineno||0),column:Number(event&&event.colno||0),stack:cleanStack(value&&(value.stack||value.message)||'')})},true);
  addEventListener('unhandledrejection',function(event){var reason=event&&event.reason;send('promise-rejection',{message:text(reason&&(reason.message||reason),1024),errorName:text(reason&&reason.name,80),stack:cleanStack(reason&&(reason.stack||reason.message)||'')})},true);
  addEventListener('securitypolicyviolation',function(event){send('csp-violation',{blockedUrl:safeUrl(event&&event.blockedURI),source:safeUrl(event&&event.sourceFile),effectiveDirective:text(event&&event.effectiveDirective,120),violatedDirective:text(event&&event.violatedDirective,120),disposition:text(event&&event.disposition,32),line:Number(event&&event.lineNumber||0),column:Number(event&&event.columnNumber||0),statusCode:Number(event&&event.statusCode||0)})},true);

  ['visibilitychange','pageshow','pagehide','focus','blur','freeze','resume','DOMContentLoaded','load','beforeunload','popstate','hashchange','online','offline'].forEach(function(name){addEventListener(name,function(event){lifecycle(name,event)},true)});
  var api={version:probeVersion,documentId:documentId,snapshot:snapshot,health:heartbeatState,noteInjection:function(source){installationAttempts++;send('duplicate-injection-attempt',{source:text(source,120),installationAttempts:installationAttempts})}};
  try{Object.defineProperty(window,'__otlobliRootCauseProbe',{value:api,configurable:false,enumerable:false,writable:false})}catch(error){window.__otlobliRootCauseProbe=api}
  send('probe-installed',{snapshotLabel:'DOCUMENT_START'});
  snapshot('DOCUMENT_START');
}();`
