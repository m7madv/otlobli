import assert from "node:assert/strict";
import test from "node:test";

import {
  assertExpectedInventory,
  basePlanActivationPath,
  desiredBasePlan,
  parseArguments,
  pricingFromConversion,
  sameManagedBasePlanConfiguration,
  subscriptionPatchPath,
  subscriptionPath,
} from "./google_play_subscriptions.mjs";

const monthly = {
  productId: "voicebrief_pro_monthly",
  basePlanId: "monthly",
  billingPeriodDuration: "P1M",
  gracePeriodDuration: "P7D",
  priceQar: 29,
};

const annual = {
  productId: "voicebrief_pro_annual",
  basePlanId: "annual",
  billingPeriodDuration: "P1Y",
  gracePeriodDuration: "P14D",
  priceQar: 229,
};

function convertedPrices() {
  return {
    regionVersion: { version: "2026-09" },
    convertedRegionPrices: {
      FR: { price: { currencyCode: "EUR", units: "25", nanos: 0 } },
      QA: { price: { currencyCode: "QAR", units: "99", nanos: 0 } },
      US: { price: { currencyCode: "USD", units: "8", nanos: 990000000 } },
    },
    convertedOtherRegionsPrice: {
      usdPrice: { currencyCode: "USD", units: "8", nanos: 990000000 },
      eurPrice: { currencyCode: "EUR", units: "7", nanos: 990000000 },
    },
  };
}

test("arguments default to inspection and reject ambiguous mutations", () => {
  assert.equal(parseArguments([]).mode, "inspect");
  assert.equal(
    parseArguments(["--activate", "--output", "report.json"]).mode,
    "activate",
  );
  assert.throws(
    () => parseArguments(["--apply", "--activate"]),
    /either --apply or --activate/,
  );
  assert.throws(() => parseArguments(["--output"]), /requires a file path/);
});

test("API paths stay pinned to the VoiceBrief package and expected plans", () => {
  assert.equal(
    subscriptionPath(monthly.productId),
    "/applications/app.voicebrief.mobile/subscriptions/voicebrief_pro_monthly",
  );
  assert.match(
    subscriptionPatchPath(monthly, "2026-09"),
    /updateMask=basePlans/,
  );
  assert.match(
    subscriptionPatchPath(monthly, "2026-09"),
    /regionsVersion\.version=2026-09/,
  );
  assert.equal(
    basePlanActivationPath(annual),
    "/applications/app.voicebrief.mobile/subscriptions/voicebrief_pro_annual/basePlans/annual:activate",
  );
  assert.throws(() => subscriptionPath("unexpected_product"), /Refusing/);
});

test("regional conversion excludes France and pins Qatar and future regions", () => {
  const pricing = pricingFromConversion(monthly, convertedPrices());
  assert.deepEqual(
    pricing.regionalConfigs.map((config) => config.regionCode),
    ["QA", "US"],
  );
  assert.deepEqual(pricing.regionalConfigs[0].price, {
    currencyCode: "QAR",
    units: "29",
    nanos: 0,
  });
  assert.equal(pricing.otherRegionsConfig.newSubscriberAvailability, true);
});

test("desired plans preserve monthly quota cadence and are order-stable", () => {
  const pricing = pricingFromConversion(monthly, convertedPrices());
  const desired = desiredBasePlan(monthly, pricing);
  assert.equal(desired.autoRenewingBasePlanType.billingPeriodDuration, "P1M");
  assert.equal(desired.autoRenewingBasePlanType.gracePeriodDuration, "P7D");
  const reordered = {
    ...desired,
    regionalConfigs: [...desired.regionalConfigs].reverse(),
  };
  assert.equal(sameManagedBasePlanConfiguration(desired, reordered), true);
});

test("inventory guard requires only the two intended VoiceBrief products", () => {
  const inventory = assertExpectedInventory([
    {
      packageName: "app.voicebrief.mobile",
      productId: monthly.productId,
      basePlans: [],
    },
    {
      packageName: "app.voicebrief.mobile",
      productId: annual.productId,
      basePlans: [],
    },
  ]);
  assert.deepEqual([...inventory.keys()], [
    monthly.productId,
    annual.productId,
  ]);
  assert.throws(
    () =>
      assertExpectedInventory([
        {
          packageName: "app.voicebrief.mobile",
          productId: "unexpected_product",
          basePlans: [],
        },
      ]),
    /unexpected Google Play subscription/,
  );
});
