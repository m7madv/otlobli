import { handle } from "./index.ts";

Deno.test("invite page is HTTPS-only guidance and never cached", async () => {
  const response = handle(
    new Request(
      "https://example.test/functions/v1/legal/join?code=DMN-A1B2C3D4E5F60718293A4B5C6D7E8F90&role=staff",
    ),
  );
  const html = await response.text();
  if (response.headers.get("cache-control") !== "no-store") {
    throw new Error("invite secrets must never be cached");
  }
  if (
    !html.includes("DMN-A1B2C3D4E5F60718293A4B5C6D7E8F90") ||
    html.includes("com.damanak.damanak://")
  ) {
    throw new Error(
      "invite page must show the manual code without a hijackable scheme",
    );
  }
});

Deno.test("invite page accepts only the supported hexadecimal code lengths", async () => {
  for (
    const code of [
      "DMN-A1B2C3D4E5",
      "DMN-A1B2C3D4E5F60718",
      "DMN-A1B2C3D4E5F60718293A4B5C6D7E8F90",
    ]
  ) {
    const html = await handle(
      new Request(`https://example.test/functions/v1/legal/join?code=${code}`),
    ).text();
    if (!html.includes("دعوة فريق ضمانك") || !html.includes(code)) {
      throw new Error(`Supported invitation code was rejected: ${code}`);
    }
  }

  for (
    const code of [
      "DMN-A1B2C3D4E",
      "DMN-A1B2C3D4E5F",
      "DMN-A1B2C3D4E5F6071",
      "DMN-A1B2C3D4E5F607182",
      "DMN-A1B2C3D4E5F60718293A4B5C6D7E8F9",
      "DMN-A1B2C3D4E5F60718293A4B5C6D7E8F901",
      "DMN-A1B2C3D4EG",
    ]
  ) {
    const html = await handle(
      new Request(`https://example.test/functions/v1/legal/join?code=${code}`),
    ).text();
    if (!html.includes("رابط دعوة غير صالح")) {
      throw new Error(`Invalid invitation code was accepted: ${code}`);
    }
  }
});

Deno.test("privacy page discloses current AI, identifier, sharing, and retention flows", async () => {
  const response = handle(
    new Request("https://example.test/functions/v1/legal/privacy"),
  );
  const html = await response.text();
  if (response.status !== 200) {
    throw new Error("privacy page must be available");
  }
  if (!response.headers.get("content-type")?.includes("text/html")) {
    throw new Error("privacy page must be served as HTML");
  }

  const requiredDisclosures = [
    "حصة Gemini المجانية",
    "قد يراجعها أشخاص",
    "لا يحفظ ضمانك المنتجات تلقائياً",
    "OpenAI",
    "store: false",
    "تحليل أول ملفين أيضاً",
    "SHA-256",
    "رمز شراء Google Play",
    "مرفقات المطالبات",
    "رابط ضمان عام موقّع",
    "Webhooks",
    "مدة الاحتفاظ",
    "حذف الحساب نهائياً",
    "تُنقل ملكية المتجر إليه",
  ];
  for (const disclosure of requiredDisclosures) {
    if (!html.includes(disclosure)) {
      throw new Error(`privacy disclosure missing: ${disclosure}`);
    }
  }
});

Deno.test("terms require rights to uploaded content and grant limited processing permission", async () => {
  const response = handle(
    new Request("https://example.test/functions/v1/legal/terms"),
  );
  const html = await response.text();
  const requiredTerms = [
    "الحقوق والتراخيص والموافقات اللازمة",
    "إذناً محدوداً",
    "لتقديم الخدمة",
    "من دون نقل ملكية المحتوى إلى ضمانك",
  ];
  for (const term of requiredTerms) {
    if (!html.includes(term)) {
      throw new Error(`terms disclosure missing: ${term}`);
    }
  }
});
