import { claimReviewSchema, extractOutputText, sanitizeReview } from "./index.ts";

Deno.test("claim AI review stays strict and cannot decide the claim", () => {
  if (claimReviewSchema.additionalProperties !== false) throw new Error("schema not strict");
  const serialized = JSON.stringify(claimReviewSchema);
  if (serialized.includes("accept") || serialized.includes("reject")) {
    throw new Error("automated decision leaked into schema");
  }
  const text = extractOutputText({
    output: [{ content: [{ type: "output_text", text: '{"summary":"x"}' }] }],
  });
  if (text !== '{"summary":"x"}') throw new Error("output missing");
  const review = sanitizeReview({
    summary: " عطل عند التشغيل ",
    suggestedCategory: "invalid",
    suggestedPriority: "high",
    missingInformation: ["صورة الجهاز"],
    signals: ["انطفاء"],
    confidence: 4,
  });
  if (review.suggestedCategory !== "other" || review.confidence !== 1) {
    throw new Error("review sanitization failed");
  }
});
