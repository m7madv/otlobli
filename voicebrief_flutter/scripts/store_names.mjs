// Owner-approved store-only descriptors. Bundle/display names stay VoiceBrief.
export const storeNames = Object.freeze({
  'ar-SA': 'VoiceBrief',
  'en-US': 'VoiceBrief: Audio Summaries',
  'zh-Hans': 'VoiceBrief: 语音摘要',
  hi: 'VoiceBrief: ऑडियो सारांश',
  'es-ES': 'VoiceBrief: Resúmenes de audio',
  'fr-FR': 'VoiceBrief: Résumés audio',
  'bn-BD': 'VoiceBrief: অডিও সারাংশ',
  'pt-BR': 'VoiceBrief: Resumos de áudio',
  ru: 'VoiceBrief: Аудиосводки',
  'ur-PK': 'VoiceBrief: صوتی خلاصے',
  id: 'VoiceBrief: Ringkasan Audio',
});

for (const [locale, name] of Object.entries(storeNames)) {
  if (!name.startsWith('VoiceBrief') || [...name].length > 30) {
    throw new Error(`Invalid approved store name for ${locale}`);
  }
}
