import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {createHash,createPrivateKey,sign} from 'node:crypto';
import {resolve,join} from 'node:path';

const APP='6805194629', VERSION='0.1.2', ROOT='https://api.appstoreconnect.apple.com/v1';
const directory=resolve(import.meta.dirname,'../store_assets/localized');
const mode=process.env.VOICEBRIEF_STORE_MODE || 'inspect';
if (!['inspect','prepare'].includes(mode)) throw new Error('Unsupported store mode');
const report={app:APP,version:VERSION,mode,startedAt:new Date().toISOString(),localizations:[]};
const reportDir=resolve(process.env.RUNNER_TEMP || '.', 'voicebrief-localization-report');
mkdirSync(reportDir,{recursive:true});
const save=()=>writeFileSync(join(reportDir,'report.json'),JSON.stringify(report,null,2)+'\n');
const encode=v=>Buffer.from(JSON.stringify(v)).toString('base64url');
function token(){
  for(const k of ['APP_STORE_CONNECT_API_KEY_BASE64','APP_STORE_CONNECT_API_KEY_ID','APP_STORE_CONNECT_ISSUER_ID']) if(!process.env[k]) throw new Error(`Missing ${k}`);
  const now=Math.floor(Date.now()/1000);
  const data=encode({alg:'ES256',kid:process.env.APP_STORE_CONNECT_API_KEY_ID,typ:'JWT'})+'.'+encode({iss:process.env.APP_STORE_CONNECT_ISSUER_ID,iat:now-10,exp:now+1100,aud:'appstoreconnect-v1'});
  const key=createPrivateKey(Buffer.from(process.env.APP_STORE_CONNECT_API_KEY_BASE64,'base64'));
  return data+'.'+sign('sha256',Buffer.from(data),{key,dsaEncoding:'ieee-p1363'}).toString('base64url');
}
async function api(path,method='GET',body){
  if(!path.startsWith('/')) throw new Error('Relative API path required');
  const res=await fetch(ROOT+path,{method,headers:{Authorization:`Bearer ${token()}`,'Content-Type':'application/json'},body:body?JSON.stringify(body):undefined,signal:AbortSignal.timeout(60000)});
  if(res.status===204)return null;
  const data=await res.json();
  if(!res.ok)throw new Error(`${method} ${path.split('?')[0]}: HTTP ${res.status} ${(data.errors||[]).map(e=>e.code).join(',')}`);
  return data;
}
async function list(path){
  const data=[];
  let next=path;
  while(next){
    const page=await api(next);data.push(...page.data);
    if(page.links?.next){
      const url=new URL(page.links.next);
      if(url.origin!=='https://api.appstoreconnect.apple.com'||!url.pathname.startsWith('/v1/'))throw new Error('Unexpected pagination origin');
      next=url.pathname.slice(3)+url.search;
    }else next=null;
  }
  return data;
}
const relationship=(type,id)=>({data:{type,id}});
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
async function waitForScreenshot(id){
  for(let attempt=0;attempt<24;attempt++){
    const item=(await api(`/appScreenshots/${id}`)).data;
    const state=item.attributes.assetDeliveryState?.state;
    if(state==='COMPLETE')return item;
    if(state==='FAILED')throw new Error(`Screenshot ${id} failed: ${JSON.stringify(item.attributes.assetDeliveryState.errors?.map(e=>e.code))}`);
    await sleep(5000);
  }
  throw new Error(`Screenshot ${id} delivery still pending; rerun to resume.`);
}
async function uploadScreenshot(setId,asset,existing){
  const bytes=readFileSync(join(directory,asset.file));
  if(createHash('sha256').update(bytes).digest('hex')!==asset.sha256)throw new Error('Asset hash mismatch');
  const fileName=`vb21_${asset.file.replaceAll('/','_').replace('.png','')}_${asset.sha256.slice(0,12)}.png`;
  let record=existing.find(item=>item.attributes.fileName===fileName);
  if(record && record.attributes.assetDeliveryState?.state!=='AWAITING_UPLOAD')return waitForScreenshot(record.id);
  if(!record)record=(await api('/appScreenshots','POST',{data:{type:'appScreenshots',attributes:{fileName,fileSize:bytes.length},relationships:{appScreenshotSet:relationship('appScreenshotSets',setId)}}})).data;
  for(const operation of record.attributes.uploadOperations || []){
    const url=new URL(operation.url);
    if(url.protocol!=='https:' || !url.hostname.endsWith('.apple.com'))throw new Error('Unexpected asset upload origin');
    const headers=Object.fromEntries(operation.requestHeaders.map(h=>[h.name,h.value]));
    const response=await fetch(url,{method:operation.method,headers,body:bytes.subarray(operation.offset,operation.offset+operation.length),signal:AbortSignal.timeout(60000)});
    if(!response.ok)throw new Error(`Asset transfer failed: HTTP ${response.status}`);
  }
  await api(`/appScreenshots/${record.id}`,'PATCH',{data:{type:'appScreenshots',id:record.id,attributes:{uploaded:true,sourceFileChecksum:createHash('md5').update(bytes).digest('hex')}}});
  return waitForScreenshot(record.id);
}

try{
  const versions=await list(`/apps/${APP}/appStoreVersions?filter[platform]=IOS&limit=200`);
  report.versions=versions.map(v=>({id:v.id,version:v.attributes.versionString,state:v.attributes.appStoreState}));save();
  if(mode==='inspect'){
    console.log(JSON.stringify(report.versions));
  }else{
    const manifest=JSON.parse(readFileSync(join(directory,'manifest.json'),'utf8'));
    if(manifest.version!==VERSION||manifest.localizations.length!==11)throw new Error('Unexpected localization manifest');
    // Validate every artifact before creating or mutating any store draft.
    for(const local of manifest.localizations)for(const asset of local.screenshots){
      if(!/^(ar|en|zh|hi|es|fr|bn|pt|ru|ur|id)\/(iphone|ipad)\/0[1-4]_[a-z]+\.png$/.test(asset.file))throw new Error('Invalid asset path');
      const bytes=readFileSync(join(directory,asset.file));
      if(createHash('sha256').update(bytes).digest('hex')!==asset.sha256)throw new Error('Asset checksum mismatch');
    }
    let version=versions.find(v=>v.attributes.versionString===VERSION);
    let created=false;
    if(!version){
      version=(await api('/appStoreVersions','POST',{data:{type:'appStoreVersions',attributes:{platform:'IOS',versionString:VERSION,releaseType:'MANUAL'},relationships:{app:relationship('apps',APP)}}})).data;
      created=true;
    }
    if(!['PREPARE_FOR_SUBMISSION','REJECTED','DEVELOPER_REJECTED'].includes(version.attributes.appStoreState))throw new Error('Target version is not an editable draft');
    report.draftId=version.id;report.createdDraft=created;save();
    const localized=await list(`/appStoreVersions/${version.id}/appStoreVersionLocalizations?limit=200`);
    writeFileSync(join(reportDir,'before-metadata.json'),JSON.stringify(localized,null,2));
    for(const local of manifest.localizations){
      const locale=local.attributes.locale;
      let record=localized.find(l=>l.attributes.locale===locale);
      if(!record)record=(await api('/appStoreVersionLocalizations','POST',{data:{type:'appStoreVersionLocalizations',attributes:local.attributes,relationships:{appStoreVersion:relationship('appStoreVersions',version.id)}}})).data;
      else{
        const {locale:ignored,...attributes}=local.attributes;
        await api(`/appStoreVersionLocalizations/${record.id}`,'PATCH',{data:{type:'appStoreVersionLocalizations',id:record.id,attributes}});
      }
      const sets=await list(`/appStoreVersionLocalizations/${record.id}/appScreenshotSets?limit=200`);
      const completed={locale,id:record.id,sets:[]};report.localizations.push(completed);save();
      for(const type of [...new Set(local.screenshots.map(s=>s.type))]){
        let set=sets.find(s=>s.attributes.screenshotDisplayType===type);
        if(!set)set=(await api('/appScreenshotSets','POST',{data:{type:'appScreenshotSets',attributes:{screenshotDisplayType:type},relationships:{appStoreVersionLocalization:relationship('appStoreVersionLocalizations',record.id)}}})).data;
        const before=await list(`/appScreenshotSets/${set.id}/appScreenshots?limit=200`);
        writeFileSync(join(reportDir,`before-${locale}-${type}.json`),JSON.stringify(before,null,2));
        if(!created && before.some(s=>!s.attributes.fileName.startsWith('vb21_')))throw new Error(`Existing non-VoiceBrief21 screenshots in ${locale}/${type}; preserve them and request review.`);
        const wanted=[];
        for(const asset of local.screenshots.filter(s=>s.type===type))wanted.push(await uploadScreenshot(set.id,asset,before));
        // Never remove inherited assets until all four replacements are verified COMPLETE.
        const wantedIds=new Set(wanted.map(s=>s.id));
        const removed=[];
        for(const old of before)if(!wantedIds.has(old.id)){await api(`/appScreenshots/${old.id}`,'DELETE');removed.push(old.id);}
        await api(`/appScreenshotSets/${set.id}/relationships/appScreenshots`,'PATCH',{data:wanted.map(s=>({type:'appScreenshots',id:s.id}))});
        const final=await list(`/appScreenshotSets/${set.id}/appScreenshots?limit=200`);
        if(final.length!==4||final.some(s=>!wantedIds.has(s.id)||s.attributes.assetDeliveryState?.state!=='COMPLETE'))throw new Error('Screenshot verification failed');
        completed.sets.push({id:set.id,type,complete:4,removedDraftScreenshotIds:removed});save();
        console.log(`${locale} ${type}: 4 screenshots COMPLETE`);
      }
    }
    report.finishedAt=new Date().toISOString();report.result='DRAFT_LOCALIZED_NOT_SUBMITTED';save();
    console.log('VoiceBrief 0.1.2 draft localized. No build selected, no review submission, no release or territory changes.');
  }
}catch(error){report.error=error.message;save();console.error(error.message);process.exitCode=1;}
