import {
  extractOutputText,
  productImportSchema,
  sanitizeProducts,
} from "./index.ts";

Deno.test("AI import schema is strict and sanitizes review-only rows", () => {
  if (productImportSchema.additionalProperties !== false) {
    throw new Error("schema must reject unknown root fields");
  }
  const text = extractOutputText({
    output: [{ content: [{ type: "output_text", text: '{"products":[]}' }] }],
  });
  if (text !== '{"products":[]}') throw new Error("output text missing");

  const products = sanitizeProducts({
    products: [{
      name: "  هاتف تجريبي  ",
      brand: "نور",
      warrantyMonths: 200,
      salePrice: 100,
      costPrice: null,
      quantity: 0,
      confidence: 4,
      sourceText: "line 1",
    }, { name: "" }],
  });
  if (products.length !== 1) throw new Error("invalid rows must be removed");
  if (products[0].warrantyMonths !== 120 || products[0].quantity !== 1) {
    throw new Error("numeric limits not enforced");
  }
  if (products[0].confidence !== 1) {
    throw new Error("confidence limit not enforced");
  }
});
