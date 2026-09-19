// Run with playwright-cli run-code --filename after starting the loopback preview.
// No form submissions, store navigation, account data, or remote requests.
async (page) => {
  const paths = ['/', '/ar', '/guides/whatsapp-voice-notes', '/ar/guides/whatsapp-voice-notes', '/press', '/ar/press', '/guides/arabic-audio-to-text', '/ar/guides/arabic-audio-to-text', '/guides/voice-notes-to-calendar', '/ar/guides/voice-notes-to-calendar'];
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', message => {
    if (message.type() === 'error') errors.push(message.text());
  });
  const layouts = [];
  for (const path of paths) for (const width of [320, 390, 768, 1440]) {
    await page.setViewportSize({ width, height: 900 });
    const response = await page.goto('http://127.0.0.1:4179' + path);
    const checks = await page.evaluate(() => ({
      overflow: document.documentElement.scrollWidth > innerWidth,
      h1: document.querySelectorAll('h1').length,
      lang: document.documentElement.lang,
      dir: document.documentElement.dir,
    }));
    if (response.status() !== 200 || checks.overflow || checks.h1 !== 1) {
      throw new Error(JSON.stringify({ path, width, status: response.status(), checks }));
    }
    layouts.push({ path, width, ...checks });
  }
  const legal = [];
  for (const path of ['privacy', 'terms', 'support', 'delete-account']) for (const lang of ['en', 'ar']) {
    await page.goto('http://127.0.0.1:4179/' + path + '?lang=' + lang);
    const href = await page.locator('.brand').getAttribute('href');
    if (href !== (lang === 'ar' ? '/ar' : '/')) throw new Error('Wrong legal brand link ' + path + lang);
    const forms = await page.locator('[data-support-form], [data-deletion-form]').count();
    await page.locator('.brand').click();
    await page.waitForURL('http://127.0.0.1:4179' + (lang === 'ar' ? '/ar' : '/'), { waitUntil: 'domcontentloaded' });
    legal.push({ path, lang, forms });
  }
  await page.goto('http://127.0.0.1:4179/ar/guides/arabic-audio-to-text');
  await page.locator('a.language').click();
  await page.waitForURL('http://127.0.0.1:4179/guides/arabic-audio-to-text', { waitUntil: 'domcontentloaded' });
  await page.locator('.breadcrumbs a').focus();
  await page.keyboard.press('Enter');
  await page.waitForURL('http://127.0.0.1:4179/', { waitUntil: 'domcontentloaded' });
  await page.locator('summary').first().focus();
  await page.keyboard.press('Enter');
  if (await page.locator('details').first().getAttribute('open') === null) throw new Error('FAQ keyboard failed');
  if (errors.length) throw new Error(JSON.stringify(errors));
  return { layouts: layouts.length, legal, errors, languageAndKeyboard: 'passed' };
}
