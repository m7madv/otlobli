#!/usr/bin/env node
import {readFileSync, readdirSync, existsSync} from 'node:fs';
import {resolve} from 'node:path';
const root=resolve(import.meta.dirname,'..');
const metadata=JSON.parse(readFileSync(resolve(root,'app_store_assets/localized_metadata.json'),'utf8'));
const locales=['ar-SA','en-US','es-ES','fr-FR','de-DE','pt-BR','zh-Hans','hi','ja','ru'];
const errors=[];
for (const locale of locales) {
  const entry=metadata[locale];
  if (!entry) {errors.push(`${locale}: missing metadata`);continue;}
  for (const [field,max] of Object.entries({name:30,subtitle:30,description:4000,keywords:100,whatsNew:4000})) {
    if (typeof entry[field]!=='string' || !entry[field].trim() || Array.from(entry[field]).length>max) errors.push(`${locale}: invalid ${field}`);
  }
  for (const [folder,width,height] of [['iphone-1284x2778',1284,2778],['ipad-2048x2732',2048,2732]]) {
    const directory=resolve(root,'app_store_assets/ios/localized',locale,folder);
    if (!existsSync(directory)) {errors.push(`${locale}/${folder}: missing screenshots`);continue;}
    const files=readdirSync(directory).filter(file=>file.endsWith('.png')).sort();
    if (files.length!==5) errors.push(`${locale}/${folder}: expected exactly 5 PNGs, found ${files.length}`);
    for (const file of files) {
      const bytes=readFileSync(resolve(directory,file));
      if(bytes.length<24 || bytes.subarray(0,8).toString('hex')!=='89504e470d0a1a0a' || bytes.readUInt32BE(16)!==width || bytes.readUInt32BE(20)!==height) errors.push(`${locale}/${file}: invalid PNG dimensions`);
    }
  }
}
if(errors.length){console.error(errors.join('\n'));process.exitCode=1;}
else console.log('10 metadata localizations and 100 screenshot dimensions verified. Visual and linguistic approval remain separate.');
