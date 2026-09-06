import {readFileSync, writeFileSync, mkdirSync} from 'node:fs';
import {createPrivateKey, sign} from 'node:crypto';
import {resolve, join} from 'node:path';
import {storeNames} from './store_names.mjs';

const APP='6805194629', VERSION='0.1.2', BUILD='21';
const VERSION_ID='4ad274c0-fb1f-4f61-947a-ce57c461554c';
const INFO_ID='176e4637-e8be-499e-a3f2-93acf9dfeb92';
const mode=process.env.VOICEBRIEF_RELEASE_MODE || 'inspect';
if(!['inspect','submit'].includes(mode))throw new Error('Invalid release mode');
if(mode==='submit' && process.env.VOICEBRIEF_RELEASE_CONFIRMATION!==`${APP}:${VERSION}:${BUILD}:submit`)throw new Error('Explicit release confirmation required');
const dir=resolve(process.env.RUNNER_TEMP || '.', 'voicebrief-release-report');
mkdirSync(dir,{recursive:true});
const report={app:APP,version:VERSION,build:BUILD,mode,time:new Date().toISOString(),checks:[]};
const save=()=>writeFileSync(join(dir,'report.json'),JSON.stringify(report,null,2)+'\n');
const encode=v=>Buffer.from(JSON.stringify(v)).toString('base64url');
const rel=(type,id)=>({data:{type,id}});
function token(){
  for(const k of ['APP_STORE_CONNECT_API_KEY_BASE64','APP_STORE_CONNECT_API_KEY_ID','APP_STORE_CONNECT_ISSUER_ID'])if(!process.env[k])throw new Error(`Missing ${k}`);
  const now=Math.floor(Date.now()/1000);
  const input=encode({alg:'ES256',kid:process.env.APP_STORE_CONNECT_API_KEY_ID,typ:'JWT'})+'.'+encode({iss:process.env.APP_STORE_CONNECT_ISSUER_ID,iat:now-10,exp:now+1100,aud:'appstoreconnect-v1'});
  const key=createPrivateKey(Buffer.from(process.env.APP_STORE_CONNECT_API_KEY_BASE64,'base64'));
  return input+'.'+sign('sha256',Buffer.from(input),{key,dsaEncoding:'ieee-p1363'}).toString('base64url');
}
async function api(path,method='GET',body){
  if(!/^\/v[12]\//.test(path))throw new Error('Relative API path required');
  const res=await fetch('https://api.appstoreconnect.apple.com'+path,{method,headers:{Authorization:`Bearer ${token()}`,'Content-Type':'application/json'},body:body?JSON.stringify(body):undefined,signal:AbortSignal.timeout(60000)});
  if(res.status===204)return null;
  const json=await res.json();
  if(!res.ok){
    // Never include reviewer credentials or request/response bodies in reports.
    const codes=(json.errors||[]).map(e=>({code:e.code,pointer:e.source?.pointer}));
    throw new Error(`${method} ${path.split('?')[0]}: HTTP ${res.status} ${JSON.stringify(codes)}`);
  }
  return json;
}
async function list(path){
  const data=[];
  while(path){
    const page=await api(path);data.push(...page.data);
    const next=page.links?.next;
    if(!next)break;
    const url=new URL(next);
    if(url.origin!=='https://api.appstoreconnect.apple.com')throw new Error('Unexpected pagination host');
    path=url.pathname+url.search;
  }
  return data;
}
function check(name,passed){report.checks.push({name,passed:!!passed});save();}
try{
  const app=(await api(`/v1/apps/${APP}`)).data;
  check('Same app identity and Arabic primary locale',app.attributes.bundleId==='app.voicebrief.mobile' && app.attributes.primaryLocale==='ar-SA');
  const versions=await list(`/v1/apps/${APP}/appStoreVersions?filter[platform]=IOS&limit=200`);
  report.versions=versions.map(v=>({id:v.id,version:v.attributes.versionString,state:v.attributes.appStoreState,releaseType:v.attributes.releaseType}));
  const version=versions.find(v=>v.id===VERSION_ID && v.attributes.versionString===VERSION);
  if(!version)throw new Error('Expected draft version missing');
  report.state=version.attributes.appStoreState;
  let builds=[];
  const attempts=process.env.VOICEBRIEF_WAIT_FOR_BUILD==='true'?12:1;
  for(let attempt=0;attempt<attempts;attempt++){
    builds=await list(`/v1/builds?filter[app]=${APP}&filter[version]=${BUILD}&limit=200`);
    if(builds.some(b=>b.attributes.processingState==='VALID'))break;
    if(builds.some(b=>['FAILED','INVALID'].includes(b.attributes.processingState)))break;
    if(attempt+1<attempts){
      console.log('Apple has not finished processing build 21; checking again in 60 seconds.');
      await new Promise(r=>setTimeout(r,60000));
    }
  }
  report.builds=[];
  for(const b of builds){
    const train=(await api(`/v1/builds/${b.id}/preReleaseVersion`)).data;
    report.builds.push({id:b.id,number:b.attributes.version,state:b.attributes.processingState,expired:b.attributes.expired,version:train.attributes.version});
  }
  const build=report.builds.find(b=>b.version===VERSION && b.number===BUILD && b.state==='VALID' && !b.expired);
  check('Build 21 is VALID in the 0.1.2 train',build);
  const selected=(await api(`/v1/appStoreVersions/${VERSION_ID}/build`)).data;
  report.selectedBuild=selected?{id:selected.id,number:selected.attributes.version}:null;
  const infos=await list(`/v1/appInfos/${INFO_ID}/appInfoLocalizations?limit=200`);
  report.names=infos.map(l=>({locale:l.attributes.locale,name:l.attributes.name}));
  check('All 11 approved localized names and privacy links',infos.length===11 && infos.every(l=>l.attributes.name===storeNames[l.attributes.locale] && !!l.attributes.privacyPolicyUrl));
  const manifest=JSON.parse(readFileSync(resolve(import.meta.dirname,'../store_assets/localized/manifest.json'),'utf8'));
  const locales=await list(`/v1/appStoreVersions/${VERSION_ID}/appStoreVersionLocalizations?limit=200`);
  check('Exactly 11 version localizations',locales.length===11);
  report.locales=[];
  for(const local of manifest.localizations){
    const record=locales.find(l=>l.attributes.locale===local.attributes.locale);
    if(!record){check(`${local.attributes.locale} metadata and screenshots`,false);continue;}
    const metadataMatch=Object.entries(local.attributes).every(([k,v])=>record.attributes[k]===v);
    const sets=await list(`/v1/appStoreVersionLocalizations/${record.id}/appScreenshotSets?limit=200`);
    let complete=0,matching=true;
    for(const type of new Set(local.screenshots.map(s=>s.type))){
      const set=sets.find(s=>s.attributes.screenshotDisplayType===type);
      if(!set){matching=false;continue;}
      const screenshots=await list(`/v1/appScreenshotSets/${set.id}/appScreenshots?limit=200`);
      const names=local.screenshots.filter(s=>s.type===type).map(s=>`vb21_${s.file.replaceAll('/','_').replace('.png','')}_${s.sha256.slice(0,12)}.png`);
      matching=matching && screenshots.length===4 && screenshots.every((s,i)=>s.attributes.fileName===names[i] && s.attributes.assetDeliveryState?.state==='COMPLETE');
      complete+=screenshots.filter(s=>s.attributes.assetDeliveryState?.state==='COMPLETE').length;
    }
    report.locales.push({locale:local.attributes.locale,metadataMatch,complete,matching});
    check(`${local.attributes.locale} metadata and screenshots`,metadataMatch && complete===8 && matching);
  }
  const review=(await api(`/v1/appStoreVersions/${VERSION_ID}/appStoreReviewDetail`)).data;
  const r=review?.attributes || {};
  // Report only presence, never the values entered by the owner.
  report.review={id:review?.id,signInRequired:r.demoAccountRequired,hasUser:!!r.demoAccountName,hasPassword:!!r.demoAccountPassword,hasContact:!!(r.contactFirstName && r.contactLastName && r.contactEmail && r.contactPhone),hasNotes:!!r.notes};
  check('Existing reviewer access and contact complete',report.review.hasContact && report.review.hasNotes && (!r.demoAccountRequired || (r.demoAccountName && r.demoAccountPassword)));
  const availability=(await api(`/v1/apps/${APP}/appAvailabilityV2`)).data;
  const territories=await list(`/v2/appAvailabilities/${availability.id}/territoryAvailabilities?include=territory&limit=200`);
  const france=territories.find(t=>t.relationships?.territory?.data?.id==='FRA');
  report.availability={id:availability.id,territoryCount:territories.length,franceAvailable:france?.attributes.available};
  check('France remains excluded',!!france && france.attributes.available===false);
  let submissions=await list(`/v1/reviewSubmissions?filter[app]=${APP}&limit=200`);
  report.submissions=submissions.map(s=>({id:s.id,state:s.attributes.state,platform:s.attributes.platform}));save();
  if(mode==='submit'){
    if(['WAITING_FOR_REVIEW','IN_REVIEW','PENDING_APPLE_RELEASE','READY_FOR_SALE','PROCESSING_FOR_APP_STORE'].includes(report.state)){
      if(selected?.id!==build?.id)throw new Error('Submitted version does not contain expected build');
      report.result='ALREADY_SUBMITTED';
    }else{
      if(report.checks.some(c=>!c.passed))throw new Error('Release preflight failed; no submission performed');
      if(!['PREPARE_FOR_SUBMISSION','READY_FOR_REVIEW'].includes(report.state))throw new Error('Unexpected release state');
      await api(`/v1/appStoreVersions/${VERSION_ID}/relationships/build`,'PATCH',{data:{type:'builds',id:build.id}});
      await api(`/v1/appStoreVersions/${VERSION_ID}`,'PATCH',{data:{type:'appStoreVersions',id:VERSION_ID,attributes:{releaseType:'AFTER_APPROVAL'}}});
      let submission;
      for(const candidate of submissions.filter(s=>s.attributes.state==='READY_FOR_REVIEW')){
        const items=await list(`/v1/reviewSubmissions/${candidate.id}/items?include=appStoreVersion&limit=200`);
        if(items.length===1 && items[0].relationships?.appStoreVersion?.data?.id===VERSION_ID)submission=candidate;
      }
      if(!submission){
        // Never modify an unrelated review submission.
        if(submissions.some(s=>!['COMPLETE','CANCELED'].includes(s.attributes.state)))throw new Error('Another review submission is active; inspect before creating one');
        submission=(await api('/v1/reviewSubmissions','POST',{data:{type:'reviewSubmissions',attributes:{platform:'IOS'},relationships:{app:rel('apps',APP)}}})).data;
        report.createdSubmission=submission.id;save();
        await api('/v1/reviewSubmissionItems','POST',{data:{type:'reviewSubmissionItems',relationships:{reviewSubmission:rel('reviewSubmissions',submission.id),appStoreVersion:rel('appStoreVersions',VERSION_ID)}}});
      }
      const submitted=(await api(`/v1/reviewSubmissions/${submission.id}`,'PATCH',{data:{type:'reviewSubmissions',id:submission.id,attributes:{submitted:true}}})).data;
      report.submitted={id:submitted.id,state:submitted.attributes.state};
      report.result='SUBMITTED_WITH_AUTOMATIC_RELEASE_AFTER_APPROVAL';
      report.state=(await api(`/v1/appStoreVersions/${VERSION_ID}`)).data.attributes.appStoreState;
    }
  }else report.result='READ_ONLY_INSPECTION';
  save();console.log(JSON.stringify(report));
}catch(error){report.error=error.message;save();console.error(error.message);process.exitCode=1;}
