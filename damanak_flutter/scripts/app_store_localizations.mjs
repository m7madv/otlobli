#!/usr/bin/env node
// Explicitly prepares localized metadata; never submits review, changes prices,
// cancels an in-flight submission or changes storefront availability.
import {readFileSync, mkdirSync, writeFileSync} from 'node:fs';
import {resolve, dirname} from 'node:path';
import {initializeAppStoreApi, request, listAll} from './app_store_screenshots.mjs';
const appId='6804792494';
const versionString=process.env.DAMANAK_STORE_VERSION;
const apply=process.argv.includes('--apply');
const root=resolve(import.meta.dirname,'..');
const metadata=JSON.parse(readFileSync(resolve(root,'app_store_assets/localized_metadata.json'),'utf8'));
const supportUrl='https://exxayzlklvgeyqhvtzgi.supabase.co/functions/v1/legal';
const eula='https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
const editable=new Set(['PREPARE_FOR_SUBMISSION','DEVELOPER_REJECTED','REJECTED','METADATA_REJECTED']);
const report={generatedAt:new Date().toISOString(),apply,appId,versionString,locales:[]};
const output=resolve(root,'build/app-store-localizations/report.json');

async function upsert(type, existing, attributes, relationships) {
  if (!apply) return {id:existing?.id,action:existing?'inspect-existing':'inspect-missing'};
  if (existing) {
    const patch={...attributes};
    delete patch.locale;
    await request(`/v1/${type}/${existing.id}`,{method:'PATCH',body:{data:{type,id:existing.id,attributes:patch}}});
    return {id:existing.id,action:'updated'};
  }
  const created=await request(`/v1/${type}`,{method:'POST',body:{data:{type,attributes,relationships}}});
  return {id:created.data.id,action:'created'};
}

async function main() {
  if (!versionString || !/^\d+\.\d+\.\d+$/.test(versionString)) throw new Error('Set an explicit semantic DAMANAK_STORE_VERSION.');
  initializeAppStoreApi();
  const app=(await request(`/v1/apps/${appId}`)).data;
  if (app.attributes.bundleId!=='com.damanak.damanak') throw new Error('Unexpected app identity.');
  let versions=await listAll(`/v1/apps/${appId}/appStoreVersions?filter[platform]=IOS&limit=200`);
  let version=versions.find(v=>v.attributes.versionString===versionString);
  if (!version && apply) {
    const other=versions.find(v=>!['READY_FOR_SALE','REPLACED_WITH_NEW_VERSION','REMOVED_FROM_SALE','DEVELOPER_REMOVED_FROM_SALE'].includes(v.attributes.appStoreState));
    if(other) throw new Error(`Another non-final version exists (${other.attributes.versionString}); inspect it before creating a release.`);
    version=(await request('/v1/appStoreVersions',{method:'POST',body:{data:{
      type:'appStoreVersions',attributes:{platform:'IOS',versionString,releaseType:'MANUAL',copyright:'2026 Damanak'},
      relationships:{app:{data:{type:'apps',id:appId}}},
    }}})).data;
  }
  if (!version) {report.state='version-missing';return;}
  report.versionId=version.id;
  report.state=version.attributes.appStoreState;
  if (apply && !editable.has(report.state)) throw new Error(`Version is not editable: ${report.state}`);
  const localizations=await listAll(`/v1/appStoreVersions/${version.id}/appStoreVersionLocalizations?limit=200`);
  const infos=await listAll(`/v1/apps/${appId}/appInfos?limit=200`);
  const editableInfos=infos.filter(info=>editable.has(info.attributes.appStoreState));
  if(apply && editableInfos.length!==1) throw new Error('Expected exactly one editable App Info; no live App Info will be changed.');
  const info=editableInfos.length===1?editableInfos[0]:null;
  for(const [locale,copy] of Object.entries(metadata)) {
    const attributes={locale,description:`${copy.description}\n\n${eula}`,keywords:copy.keywords,whatsNew:copy.whatsNew,supportUrl};
    const localized=await upsert('appStoreVersionLocalizations',localizations.find(l=>l.attributes.locale===locale),attributes,{
      appStoreVersion:{data:{type:'appStoreVersions',id:version.id}},
    });
    // Creating a version localization may also create its App Info locale.
    // Refresh after that mutation instead of using a stale pre-loop snapshot.
    const infoLocalizations=info?await listAll(`/v1/appInfos/${info.id}/appInfoLocalizations?limit=200`):[];
    const infoResult=info?await upsert('appInfoLocalizations',infoLocalizations.find(l=>l.attributes.locale===locale),{
      locale,name:copy.name,subtitle:copy.subtitle,privacyPolicyUrl:`${supportUrl}/privacy`,
    },{appInfo:{data:{type:'appInfos',id:info.id}}}):{action:'no-editable-app-info'};
    report.locales.push({locale,versionLocalization:localized,appInfoLocalization:infoResult});
  }
}

try {await main();} catch(error) {report.error=error.message;process.exitCode=1;}
mkdirSync(dirname(output),{recursive:true});
writeFileSync(output,JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify(report,null,2));
