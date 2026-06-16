import axios from 'axios';
import https from 'https';

const agent = new https.Agent({ rejectUnauthorized: false });
const h = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
  'Accept': 'text/html,*/*',
  'Accept-Language': 'en-US,en;q=0.5',
  'Referer': 'https://www.google.com/',
};

const urls = [
  'https://shein.com/INAWLY-Women-Casual-Baggy-Loose-Pu-Jacket-p-1782348193605270.html',
  'https://www.shein.com/INAWLY-Women-Casual-Baggy-Loose-Pu-Jacket-p-1782348193605270.html',
  'https://us.shein.com/INAWLY-Women-Casual-Baggy-Loose-Pu-Jacket-p-1782348193605270.html',
];

async function go() {
  for (const url of urls) {
    try {
      const r = await axios.get(url, { headers: h, httpsAgent: agent, timeout: 10000, maxRedirects: 5, responseType: 'text' });
      const finalUrl = r.request.res.responseUrl || url;
      console.log(url);
      console.log('  Status:', r.status);
      console.log('  Final:', finalUrl.substring(0, 120));
      
      if (!finalUrl.includes('challenge') && !finalUrl.includes('captcha') && !finalUrl.includes('risk')) {
        const body = r.data;
        const goods = body.match(/"goods_name"\s*:\s*"([^"]+)"/);
        const price = body.match(/"sell_price"\s*:\s*"?([\d.]+)"?/);
        const title = body.match(/<title>([^<]+)<\/title>/);
        console.log('  Title:', goods ? goods[1].substring(0, 80) : (title ? title[1].substring(0, 80) : 'N/A'));
        console.log('  Price:', price ? price[1] : 'N/A');
        console.log('  Body length:', body.length);
        break;
      }
    } catch(e) {
      console.log(url, 'ERR:', e.message.substring(0, 100));
    }
  }
}

go();
