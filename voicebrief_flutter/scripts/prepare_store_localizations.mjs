import {readFileSync, writeFileSync, readdirSync, mkdirSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {resolve, join} from 'node:path';

// Deterministic build output, no external services or credentials.
const root = resolve(import.meta.dirname, '..');
const output = join(root, 'store_assets/localized');
const release = JSON.parse(readFileSync(join(output, 'release_copy.json'), 'utf8'));
const locales = {ar:'ar-SA',en:'en-US',zh:'zh-Hans',hi:'hi',es:'es-ES',fr:'fr-FR',bn:'bn-BD',pt:'pt-BR',ru:'ru',ur:'ur-PK',id:'id'};
const manifest = {version:'0.1.2', build:21, screenshotOrigin:'Production Flutter widgets rendered with synthetic sample content, not physical-device captures.', localizations:[]};
for (const [language, locale] of Object.entries(locales)) {
  const strings = JSON.parse(readFileSync(join(root, `lib/l10n/app_${language}.arb`), 'utf8'));
  const attributes = {
    locale,
    description: [strings.homeHeadline,strings.homeSupporting,
      [strings.fullTranscript,strings.summaryAndKeyPoints,strings.actionItemsAndDates,strings.suggestedReplies].map(s=>'• '+s).join('\n'),
      strings.trimAudioHelp,strings.audioHandlingDescription,release[language][1],
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
      `https://voicebrief-legal.vercel.app/privacy?lang=${language==='ar'?'ar':'en'}`].join('\n\n'),
    promotionalText: strings.homeHeadline,
    whatsNew: release[language][0],
    supportUrl: `https://voicebrief-legal.vercel.app/support?lang=${language==='ar'?'ar':'en'}`,
  };
  for (const [key,max] of Object.entries({description:4000,promotionalText:170,whatsNew:4000})) {
    if ([...attributes[key]].length>max) throw new Error(`${locale}.${key} exceeds ${max}`);
  }
  const screenshots=[];
  for (const [device,type,width,height] of [['iphone','APP_IPHONE_65',1284,2778],['ipad','APP_IPAD_PRO_3GEN_129',2064,2752]]) {
    const files=readdirSync(join(output,language,device)).filter(f=>f.endsWith('.png')).sort();
    if (files.length!==4) throw new Error(`${locale}/${device}: expected 4 files`);
    for (const name of files) {
      const relative=`${language}/${device}/${name}`, data=readFileSync(join(output,relative));
      if (data.readUInt32BE(16)!==width || data.readUInt32BE(20)!==height) throw new Error(`Wrong dimensions: ${relative}`);
      screenshots.push({file:relative,type,width,height,bytes:data.length,sha256:createHash('sha256').update(data).digest('hex')});
    }
  }
  manifest.localizations.push({language,attributes,screenshots});
}
mkdirSync(output,{recursive:true});
writeFileSync(join(output,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
console.log(`Validated ${manifest.localizations.length} localizations and ${manifest.localizations.reduce((n,l)=>n+l.screenshots.length,0)} screenshots.`);
