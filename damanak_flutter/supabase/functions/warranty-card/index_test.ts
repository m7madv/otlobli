import { renderWarranty } from "./index.ts";

function assert(condition: unknown, message: string) {
  if (!condition) throw new Error(message);
}

Deno.test("renders a private Arabic claim portal without full customer data", () => {
  const html = renderWarranty(
    {
      id: "warranty-1",
      warranty_number: "DMN-100001",
      store_id: "store-1",
      customer_name: "سارة العتيبي",
      customer_phone: "0500001122",
      product_name: "ماكينة قهوة",
      serial_number: "SN-SECRET-7788",
      purchase_date: "2026-08-20",
      expiry_date: "2028-08-20",
      created_at: "2026-08-20T10:00:00Z",
    },
    { name: "متجر الاختبار", city: "الدوحة", phone: "+974 5555 0000" },
    [{
      id: "claim-1",
      claim_number: 42,
      status: "waiting_for_customer",
      issue: "الجهاز لا يعمل <script>",
      customer_notes: "يرجى إرسال صورة",
      decision_reason: "",
      resolution: "none",
      created_at: "2026-08-30T10:00:00Z",
      updated_at: "2026-08-30T11:00:00Z",
    }],
    "token.value",
    "42",
    true,
  );

  assert(html.includes('lang="ar" dir="rtl"'), "Arabic RTL is required");
  assert(
    html.includes('enctype="multipart/form-data"'),
    "Attachment form missing",
  );
  assert(html.includes("CLM-000042"), "Claim number missing");
  assert(html.includes("بانتظار ردك"), "Safe customer status missing");
  assert(html.includes("لم تُرفع الملفات"), "Attachment warning missing");
  assert(html.includes("token=token.value"), "Signed token action missing");
  assert(!html.includes("سارة العتيبي"), "Full customer name leaked");
  assert(!html.includes("0500001122"), "Full phone leaked");
  assert(!html.includes("SN-SECRET-7788"), "Full serial leaked");
  assert(!html.includes("<script>"), "Claim content was not escaped");
});

Deno.test("does not offer claim submission for an expired warranty", () => {
  const html = renderWarranty(
    {
      id: "warranty-expired",
      warranty_number: "DMN-100002",
      store_id: "store-1",
      customer_name: "عميل الاختبار",
      customer_phone: "0500002211",
      product_name: "هاتف",
      serial_number: "EXPIRED-1122",
      purchase_date: "2020-01-01",
      expiry_date: "2021-01-01",
      created_at: "2020-01-01T10:00:00Z",
    },
    { name: "متجر الاختبار", city: "الدوحة", phone: null },
    [],
    "token.expired",
    null,
    false,
  );

  assert(html.includes("انتهت مدة هذا الضمان"), "Expired guidance missing");
  assert(
    !html.includes('enctype="multipart/form-data"'),
    "Expired warranty exposes a submission form",
  );
});
