import axios from 'axios';
import https from 'https';

const agent = new https.Agent({ rejectUnauthorized: false });

const fullHeaders = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
  'Accept-Language': 'en-US,en;q=0.9',
  'Accept-Encoding': 'gzip, deflate, br',
  'Cache-Control': 'max-age=0',
  'Sec-Ch-Ua': '"Google Chrome";v="125", "Chromium";v="125", "Not.A/Brand";v="24"',
  'Sec-Ch-Ua-Mobile': '?0',
  'Sec-Ch-Ua-Platform': '"Windows"',
  'Sec-Fetch-Dest': 'document',
  'Sec-Fetch-Mode': 'navigate',
  'Sec-Fetch-Site': 'same-origin',
  'Sec-Fetch-User': '?1',
  'Upgrade-Insecure-Requests': '1',
};

async function tryExtract() {
  // Step 1: Get homepage cookies
  const home = await axios.get('https://jo.shein.com/', { headers: fullHeaders, httpsAgent: agent, maxRedirects: 5 });
  const setCookies = home.headers['set-cookie'] || [];
  const cookies = setCookies.map(c => c.split(';')[0]).join('; ');
  console.log('Homepage cookies:', setCookies.length, 'cookies received');
  
  // Step 2: Get product HTML
  const prodUrl = 'https://jo.shein.com/INAWLY-Women-Casual-Baggy-Loose-Pu-Jacket-p-1782348193605270.html';
  const prod = await axios.get(prodUrl, {
    headers: { ...fullHeaders, 'Cookie': cookies, 'Referer': 'https://jo.shein.com/' },
    httpsAgent: agent,
    timeout: 20000,
    responseType: 'text',
    maxRedirects: 5,
  });
  
  const body = prod.data;
  console.log('Status:', prod.status, 'Length:', body.length, 'URL:', prod.request?.res?.responseUrl || prodUrl);

  if (body.includes('challenge') || body.includes('captcha') || body.includes('risk')) {
    console.log('CAPTCHA/RISK page detected! Need browser rendering.');
    console.log('First 2000 chars:', body.substring(0, 2000));
    return;
  }
  
  // Search methodically - look for these specific patterns from Shein's SSR
  const searches = [
    // product data in <script id="__NEXT_DATA__">
    { name: '__NEXT_DATA__', find: /<script[^>]*id="__NEXT_DATA__"[^>]*>([\s\S]*?)<\/script>/ },
    // Shein uses __INITIAL_STATE__ or __INIT_DATA__
    { name: '__INITIAL_STATE__', find: /window\.__INITIAL_STATE__\s*=\s*(\{[\s\S]*?\})(?:<\/script>|;)/ },
    { name: '__INIT_DATA__', find: /window\['__INIT_DATA__'\]\s*=\s*(\{[\s\S]*?\});/ },
    { name: '__NUXT__', find: /window\.__NUXT__\s*=\s*(\{[\s\S]*?\});/ },
    // Shein SSR data
    { name: 'SSR_DATA', find: /<script[^>]*>window\.\_\_SSR_DATA[\s\S]{0,5}=(\{[\s\S]*?\});/ },
    // Try finding goods JSON directly
    { name: 'goodsData', find: /"goodsData"\s*:\s*(\{[^;]*?\})/ },
    { name: 'productData', find: /"productData"\s*:\s*(\{[^;]*?\})/ },
  ];
  
  for (const { name, find } of searches) {
    const m = body.match(find);
    if (m) {
      console.log(`\n✅ Found ${name}!`);
      try {
        const parsed = JSON.parse(m[1]);
        console.log(JSON.stringify(parsed, null, 2).substring(0, 3000));
        return;
      } catch {
        console.log('Raw (not valid JSON):', m[1].substring(0, 500));
      }
    }
  }
  
  console.log('\n❌ None of the known patterns found.');
  console.log('Searching for any structured data...');
  
  // Look for script tags with JSON content
  const scripts = [...body.matchAll(/<script[^>]*>([\s\S]{100,}?)<\/script>/gi)];
  let dataScripts = scripts.filter(s => {
    const text = s[1];
    return text.includes('{') && text.includes('}') && (text.includes('goods') || text.includes('product') || text.includes('sku'));
  });
  console.log(`Found ${dataScripts.length} potential data scripts`);
  dataScripts.slice(0,3).forEach((s, i) => {
    console.log(`\n--- Script ${i+1} (${s[1].length} chars) ---`);
    console.log(s[1].substring(0, 1000));
  });
}

tryExtract().catch(e => console.log('ERR:', e.message));
