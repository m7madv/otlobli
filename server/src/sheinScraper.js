import { chromium } from 'playwright';

/**
 * جلب بيانات منتج Shein باستخدام جلسة Playwright مع localStorage
 * يعتمد على وجود session حقيقية مخزّنة
 */
export async function fetchSheinProduct(productUrl) {
  console.log(`🔍 Fetching Shein: ${productUrl}`);

  const browser = await chromium.launch({
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--single-process',
      '--no-zygote',
    ],
  });
  
  try {
    const context = await browser.newContext({
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
      viewport: { width: 1920, height: 1080 },
      locale: 'en-US',
      storageState: {
        origins: [{
          origin: 'https://us.shein.com',
          localStorage: [
            { name: 'auth_member', value: '{"value":{"AuthToken":"SLbRq/aUwpdQs4rDJsYdL5kEI9YMSEDCOmIszUTej6491VsGuw9zvVgx3BIRpPUtu5oJyy7AAXDtUu1s0GyAhWO5maDhneWBM3aG86Zr4kgfs2hJtTMZArSIP3CeR6wi1Szlhhc7zFgmnLrDGl3POCIXddBDrcnobMuN75Lzx3MoIJWq52qaXlaWItN6xjnWObm4KT/cMW2TBpQI3Fv+EgnKoI2yEWc/v++iHkt4rnhbuGN8YUOHLpexueW8OVVBeG0lnsA/d9EgZlOvi53R9w==","member_id":"4686428648"},"end":1784082097567}' },
            { name: 'armorToken', value: 'T0_3.12.1_osknnWoZtWQpgycy0MK335GfmF0l-O4Mpo3B_sEgkGA21n2jVfS0L9PnORrd3GkvszZ51ZdIOazui354uqTlxTyHOHymAhS7FohPpRbPIZNPjUdjWZ12FfdFHagCJqH8n7pucA9o-ymcED5ngoEoBl2DvsbSqhRnQmcOOhVbXvgW1TIfGa9Zjn_NC60jW8fL_1781492088063' },
            { name: 'armorUuid', value: '20260615095819cf12a6e79820138607ae443aca8957fa00c83758beb0351500' },
            { name: 'smidV2', value: '20260615045823f65bd5e55e58014d183712126015a21c0031ba2a82cbd95d0' },
          ],
        }],
        cookies: [
          { name: 'smidV2', value: '20260615045823f65bd5e55e58014d183712126015a21c0031ba2a82cbd95d0', domain: '.shein.com', path: '/', httpOnly: false, secure: true, sameSite: 'Lax' },
          { name: 'memberId', value: '4686428648', domain: '.shein.com', path: '/', httpOnly: false, secure: true, sameSite: 'Lax' },
          { name: 'armorUuid', value: '20260615095819cf12a6e79820138607ae443aca8957fa00c83758beb0351500', domain: '.shein.com', path: '/', httpOnly: false, secure: true, sameSite: 'Lax' },
        ],
      },
    });
    
    const page = await context.newPage();
    
    // منع طلبات التحليلات
    await page.route(/analytics|facebook|doubleclick/, route => route.abort());
    
    // ننتظر أولاً عشان localStorage ينحفظ
    await page.goto('about:blank');
    await new Promise(r => setTimeout(r, 1000));
    
    // 1. نفتح homepage عشان نضبط الجلسة
    console.log('🌐 Homepage...');
    await page.goto('https://us.shein.com/', { waitUntil: 'load', timeout: 20000 }).catch(() => {});
    await new Promise(r => setTimeout(r, 5000));
    
    // نتأكد إن الجلسة ضبطت
    const sessionCheck = await page.evaluate(() => !!localStorage.getItem('auth_member'));
    console.log('🔑 Session present:', sessionCheck);
    
    if (!sessionCheck) {
      // حقن الجلسة يدوي
      await page.evaluate(() => {
        localStorage.setItem('auth_member', '{"value":{"AuthToken":"SLbRq/aUwpdQs4rDJsYdL5kEI9YMSEDCOmIszUTej6491VsGuw9zvVgx3BIRpPUtu5oJyy7AAXDtUu1s0GyAhWO5maDhneWBM3aG86Zr4kgfs2hJtTMZArSIP3CeR6wi1Szlhhc7zFgmnLrDGl3POCIXddBDrcnobMuN75Lzx3MoIJWq52qaXlaWItN6xjnWObm4KT/cMW2TBpQI3Fv+EgnKoI2yEWc/v++iHkt4rnhbuGN8YUOHLpexueW8OVVBeG0lnsA/d9EgZlOvi53R9w==","member_id":"4686428648"},"end":1784082097567}');
        localStorage.setItem('armorToken', 'T0_3.12.1_osknnWoZtWQpgycy0MK335GfmF0l-O4Mpo3B_sEgkGA21n2jVfS0L9PnORrd3GkvszZ51ZdIOazui354uqTlxTyHOHymAhS7FohPpRbPIZNPjUdjWZ12FfdFHagCJqH8n7pucA9o-ymcED5ngoEoBl2DvsbSqhRnQmcOOhVbXvgW1TIfGa9Zjn_NC60jW8fL_1781492088063');
      });
      console.log('🔑 Session injected manually');
    }
    
    // تحديث الصفحة بعد حقن الجلسة
    await page.reload({ waitUntil: 'load', timeout: 20000 }).catch(() => {});
    await new Promise(r => setTimeout(r, 3000));
    
    // 2. نفتح صفحة المنتج
    console.log('📄 Product page...');
    await page.goto(productUrl, { waitUntil: 'domcontentloaded', timeout: 45000 }).catch(() => {});
    await new Promise(r => setTimeout(r, 10000));
    
    const currentUrl = page.url();
    console.log('📍 URL:', currentUrl.substring(0, 120));
    
    // 3. نستخرج البيانات
    const result = await extractData(page);
    return result;
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    throw error;
  } finally {
    await browser.close();
  }
}

async function extractData(page) {
  const result = {
    goodsId: '', title: '', price: '', originalPrice: '',
    currency: '', images: [], colors: [], sizes: [],
    description: '', url: page.url(),
  };
  
  // 1. Try __NUXT__ first
  try {
    const nuxt = await page.evaluate(() => {
      try { if (typeof __NUXT__ !== 'undefined') return JSON.parse(JSON.stringify(__NUXT__)); } catch {}
      try { if (typeof window.__INITIAL_STATE__ !== 'undefined') return JSON.parse(JSON.stringify(window.__INITIAL_STATE__)); } catch {}
      return null;
    });
    
    if (nuxt) {
      const info = nuxt?.data?.info || nuxt?.info || nuxt?.productDetail || nuxt?.productInfo;
      if (info) {
        result.goodsId = info.goods_id || info.goodsId || '';
        result.title = (info.goods_name || info.productName || '').replace(/<[^>]*>/g, '').trim();
        result.price = info.sell_price || info.price || info.salePrice || '';
        result.originalPrice = info.original_price || info.marketPrice || '';
        if (info.goods_img && Array.isArray(info.goods_img))
          result.images = info.goods_img.map(i => typeof i === 'string' ? i : (i?.url || ''));
        if (info.specs) {
          info.specs.forEach(s => {
            const name = (s.name || '').toLowerCase();
            const vals = (s.values || []).map(v => v.name || '').filter(Boolean);
            if (name.includes('color')) result.colors = vals;
            if (name.includes('size')) result.sizes = vals;
          });
        }
      }
    }
  } catch (e) { console.log('⚠️ NUXT:', e.message); }
  
  if (result.title) {
    console.log('✅ Extracted from __NUXT__');
    return result;
  }
  
  // 2. Try OG/meta tags
  try {
    const meta = await page.evaluate(() => {
      const og = (n) => document.querySelector(`meta[property="${n}"]`)?.getAttribute('content') || '';
      const h1 = document.querySelector('h1')?.textContent?.trim() || '';
      return { title: og('og:title') || h1, price: og('product:price:amount'), image: og('og:image') };
    });
    if (meta.title) result.title = meta.title.replace(/&#39;/g, "'").replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/\s*\|\s*SHEIN.*$/i, '').trim();
    if (meta.price) result.price = meta.price;
    if (meta.image) result.images.push(meta.image);
    console.log('✅ Extracted from meta tags');
  } catch { console.log('⚠️ Meta failed'); }
  
  // 3. Check logged in state
  try {
    const login = await page.evaluate(() => {
      const am = localStorage.getItem('auth_member');
      const mm = localStorage.getItem('memberId');
      return { hasAuth: !!am, amSample: am?.substring(0, 50), mm };
    });
    console.log('🔑 Login state:', JSON.stringify(login));
  } catch {}
  
  return result;
}

export default { fetchSheinProduct };
