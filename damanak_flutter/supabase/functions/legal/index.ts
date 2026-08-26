const baseUrl =
  'https://exxayzlklvgeyqhvtzgi.supabase.co/functions/v1/legal';
const supportEmail = 'mhm1981x@gmail.com';

type LegalPage = {
  title: string;
  lead: string;
  body: string;
};

const pages: Record<string, LegalPage> = {
  home: {
    title: 'ضمانك',
    lead: 'إدارة مبسطة للمبيعات والمخزون والضمانات وفرق المتاجر.',
    body: `
      <section>
        <h2>عن التطبيق</h2>
        <p>يساعد ضمانك أصحاب المحلات وفرقهم على إدارة المنتجات والفروع ونقاط البيع والضمانات من الهاتف.</p>
      </section>
      <section>
        <h2>الدعم</h2>
        <p>للمساعدة أو لطلب حذف البيانات، راسلنا على <a href="mailto:${supportEmail}">${supportEmail}</a>.</p>
      </section>`,
  },
  privacy: {
    title: 'سياسة الخصوصية',
    lead: 'آخر تحديث: 26 أغسطس 2026',
    body: `
      <section>
        <h2>البيانات التي يعالجها ضمانك</h2>
        <p>نعالج الاسم والبريد اللذين يرسلهما Apple أو Google عند تسجيل الدخول، وبيانات المتجر التي يدخلها المستخدم مثل الفروع والمنتجات والعملاء والمبيعات والضمانات وأعضاء الفريق.</p>
      </section>
      <section>
        <h2>لماذا نستخدم البيانات</h2>
        <p>نستخدم البيانات لتشغيل حساب المتجر، مزامنة العمل بين أعضاء الفريق، حفظ السجلات التي ينشئها المستخدم، وتقديم الدعم وحماية الخدمة.</p>
      </section>
      <section>
        <h2>الكاميرا والدفع</h2>
        <p>يُطلب إذن الكاميرا فقط عند مسح باركود منتج أو رقم تسلسلي. تتم الاشتراكات عبر App Store أو Google Play، ولا يستلم ضمانك أرقام البطاقات البنكية.</p>
      </section>
      <section>
        <h2>المشاركة والاحتفاظ</h2>
        <p>لا نبيع البيانات الشخصية. قد تعالج Supabase وApple وGoogle البيانات اللازمة لتقديم الاستضافة وتسجيل الدخول والدفع وفق سياساتهم. نحتفظ بالبيانات ما دام الحساب قائمًا أو بالقدر اللازم للالتزامات النظامية وتسوية النزاعات.</p>
      </section>
      <section>
        <h2>حقوق المستخدم</h2>
        <p>يمكن حذف الحساب من داخل التطبيق. حذف الحساب لا يلغي تلقائيًا اشتراك المتجر؛ يجب إدارة الاشتراك من App Store أو Google Play. للاستفسار راسل <a href="mailto:${supportEmail}">${supportEmail}</a>.</p>
      </section>`,
  },
  terms: {
    title: 'شروط الاستخدام',
    lead: 'آخر تحديث: 26 أغسطس 2026',
    body: `
      <section>
        <h2>استخدام الخدمة</h2>
        <p>يجب استخدام ضمانك لإدارة نشاط مشروع وبمعلومات صحيحة، مع المحافظة على حساب كل عضو وعدم مشاركة صلاحيات الدخول.</p>
      </section>
      <section>
        <h2>مسؤولية بيانات المتجر</h2>
        <p>صاحب المتجر مسؤول عن صحة المنتجات والأسعار والمبيعات والضمانات والبيانات التي يدخلها فريقه، وعن الالتزام بالأنظمة السارية في بلده.</p>
      </section>
      <section>
        <h2>الاشتراكات</h2>
        <p>تظهر الأسعار بعملة متجر الجهاز، وتُدار المدفوعات والتجديدات والاستردادات عبر App Store أو Google Play. يمكن إلغاء التجديد من إعدادات حساب المتجر.</p>
      </section>
      <section>
        <h2>توفر الخدمة</h2>
        <p>نسعى إلى إبقاء الخدمة متاحة وآمنة، وقد تتوقف مؤقتًا للصيانة أو لأسباب خارجة عن السيطرة. يُنصح بالتحقق من السجلات المهمة والاحتفاظ بما يلزم نظاميًا.</p>
      </section>
      <section>
        <h2>التواصل</h2>
        <p>للأسئلة المتعلقة بهذه الشروط راسل <a href="mailto:${supportEmail}">${supportEmail}</a>.</p>
      </section>`,
  },
};

const styles = `
  :root { color-scheme: light dark; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
  * { box-sizing: border-box; }
  body { margin: 0; background: #f4f6f5; color: #15211f; line-height: 1.8; }
  main { width: min(760px, calc(100% - 32px)); margin: 48px auto; }
  header { margin-bottom: 28px; }
  h1 { margin: 0 0 8px; font-size: clamp(2rem, 6vw, 3.6rem); line-height: 1.15; }
  h2 { margin: 0 0 8px; font-size: 1.15rem; }
  p { margin: 0; }
  .lead { color: #52615e; }
  section { margin: 14px 0; padding: 22px; border: 1px solid #d7dedc; border-radius: 18px; background: #fff; }
  nav { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 24px; }
  a { color: #176b57; font-weight: 650; }
  nav a { padding: 9px 13px; border: 1px solid #b9c9c5; border-radius: 999px; text-decoration: none; }
  footer { margin-top: 30px; color: #66736f; font-size: .9rem; }
  @media (prefers-color-scheme: dark) {
    body { background: #0d1110; color: #eef4f2; }
    .lead, footer { color: #aab7b3; }
    section { background: #171c1b; border-color: #303936; }
    a { color: #6bd7b6; }
    nav a { border-color: #45534f; }
  }
`;

function render(page: LegalPage): string {
  return `<!doctype html>
  <html lang="ar" dir="rtl">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>${page.title} | ضمانك</title>
      <meta name="description" content="${page.lead}">
      <style>${styles}</style>
    </head>
    <body>
      <main>
        <header><h1>${page.title}</h1><p class="lead">${page.lead}</p></header>
        ${page.body}
        <nav aria-label="روابط ضمانك">
          <a href="${baseUrl}">الدعم</a>
          <a href="${baseUrl}/privacy">سياسة الخصوصية</a>
          <a href="${baseUrl}/terms">شروط الاستخدام</a>
        </nav>
        <footer>© 2026 ضمانك</footer>
      </main>
    </body>
  </html>`;
}

Deno.serve((request) => {
  const pathname = new URL(request.url).pathname.replace(/\/+$/, '');
  const slug = pathname.endsWith('/privacy')
    ? 'privacy'
    : pathname.endsWith('/terms')
    ? 'terms'
    : 'home';
  return new Response(render(pages[slug]), {
    headers: {
      'content-type': 'text/html; charset=utf-8',
      'cache-control': 'public, max-age=300',
      'x-content-type-options': 'nosniff',
      'referrer-policy': 'no-referrer',
    },
  });
});
