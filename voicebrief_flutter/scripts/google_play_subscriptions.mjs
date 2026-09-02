#!/usr/bin/env node

import { createPrivateKey, sign } from "node:crypto";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const API_ROOT = "https://androidpublisher.googleapis.com/androidpublisher/v3";
const TOKEN_URL = "https://oauth2.googleapis.com/token";
const PACKAGE_NAME = "app.voicebrief.mobile";
const EXCLUDED_REGION_CODES = new Set(["FR"]);

function parseArguments(args) {
  let parsedMode = "inspect";
  let parsedOutputPath = "build/google-play-subscriptions/report.json";
  for (let index = 0; index < args.length; index += 1) {
    const argument = args[index];
    if (argument === "--apply" || argument === "--activate") {
      if (parsedMode !== "inspect") {
        throw new Error("Use either --apply or --activate, not both");
      }
      parsedMode = argument.slice(2);
      continue;
    }
    if (argument === "--output") {
      const value = args[index + 1];
      if (!value || value.startsWith("--")) {
        throw new Error("--output requires a file path");
      }
      parsedOutputPath = value;
      index += 1;
      continue;
    }
    throw new Error(`Unexpected argument ${argument}`);
  }
  return {
    mode: parsedMode,
    outputPath: resolve(parsedOutputPath),
  };
}

const { mode, outputPath } = parseArguments(process.argv.slice(2));

const plans = [
  {
    productId: "voicebrief_pro_monthly",
    basePlanId: "monthly",
    billingPeriodDuration: "P1M",
    gracePeriodDuration: "P7D",
    priceQar: 29,
  },
  {
    productId: "voicebrief_pro_annual",
    basePlanId: "annual",
    billingPeriodDuration: "P1Y",
    gracePeriodDuration: "P14D",
    priceQar: 229,
  },
];

const expectedPlanByProductId = new Map(
  plans.map((plan) => [plan.productId, plan]),
);

function assertExpectedPlan(plan) {
  const expected = expectedPlanByProductId.get(plan?.productId);
  if (
    !expected ||
    plan.basePlanId !== expected.basePlanId ||
    plan.billingPeriodDuration !== expected.billingPeriodDuration ||
    plan.gracePeriodDuration !== expected.gracePeriodDuration ||
    plan.priceQar !== expected.priceQar
  ) {
    throw new Error(
      `Refusing unexpected subscription plan ${
        plan?.productId || "<missing>"
      }/${plan?.basePlanId || "<missing>"}`,
    );
  }
  return expected;
}

function assertPlanCatalog() {
  if (
    EXCLUDED_REGION_CODES.size !== 1 ||
    !EXCLUDED_REGION_CODES.has("FR")
  ) {
    throw new Error(
      "The only explicitly excluded subscription region must be FR",
    );
  }
  if (expectedPlanByProductId.size !== plans.length) {
    throw new Error(
      "Duplicate product IDs in the expected subscription plan catalog",
    );
  }
  const basePlanIds = new Set(plans.map((plan) => plan.basePlanId));
  if (basePlanIds.size !== plans.length) {
    throw new Error(
      "Duplicate base plan IDs in the expected subscription plan catalog",
    );
  }
  for (const plan of plans) assertExpectedPlan(plan);
}

assertPlanCatalog();

function base64Url(value) {
  return Buffer.from(value).toString("base64url");
}

function readServiceAccount() {
  const raw = process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON;
  if (raw) {
    const account = JSON.parse(raw);
    if (!account.client_email || !account.private_key) {
      throw new Error(
        "service account JSON is missing client_email or private_key",
      );
    }
    return account;
  }

  const clientEmail = process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_EMAIL;
  const privateKeyPath =
    process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_PRIVATE_KEY_PATH;
  if (!clientEmail || !privateKeyPath) {
    throw new Error(
      "Set GOOGLE_PLAY_SERVICE_ACCOUNT_JSON or both GOOGLE_PLAY_SERVICE_ACCOUNT_EMAIL and GOOGLE_PLAY_SERVICE_ACCOUNT_PRIVATE_KEY_PATH",
    );
  }
  return {
    client_email: clientEmail,
    private_key: readFileSync(resolve(privateKeyPath), "utf8"),
  };
}

async function createAccessToken(account) {
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = base64Url(
    JSON.stringify({
      iss: account.client_email,
      scope: "https://www.googleapis.com/auth/androidpublisher",
      aud: TOKEN_URL,
      iat: now,
      exp: now + 3600,
    }),
  );
  const input = `${header}.${payload}`;
  const signature = sign("RSA-SHA256", Buffer.from(input), {
    key: createPrivateKey(account.private_key),
  }).toString("base64url");
  const response = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${input}.${signature}`,
    }),
  });
  const body = await response.json();
  if (!response.ok || !body.access_token) {
    throw new Error(
      body.error_description || body.error || "Google OAuth failed",
    );
  }
  return body.access_token;
}

function apiError(body, status) {
  const message = body?.error?.message ||
    `Google Play request failed (${status})`;
  const reason = body?.error?.details?.[0]?.reason;
  return reason ? `${message} [${reason}]` : message;
}

async function request(accessToken, path, { method = "GET", body } = {}) {
  const response = await fetch(`${API_ROOT}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${accessToken}`,
      Accept: "application/json",
      ...(body ? { "Content-Type": "application/json" } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  const text = await response.text();
  const parsed = text ? JSON.parse(text) : {};
  if (!response.ok) {
    const error = new Error(apiError(parsed, response.status));
    error.status = response.status;
    throw error;
  }
  return parsed;
}

function qarMoney(amount) {
  return { currencyCode: "QAR", units: String(Math.trunc(amount)), nanos: 0 };
}

function subscriptionPath(productId) {
  const plan = expectedPlanByProductId.get(productId);
  if (!plan) {
    throw new Error(`Refusing unexpected product ${productId || "<missing>"}`);
  }
  return `/applications/${PACKAGE_NAME}/subscriptions/${
    encodeURIComponent(productId)
  }`;
}

function subscriptionPatchPath(plan, regionsVersion) {
  assertExpectedPlan(plan);
  if (!regionsVersion) throw new Error("Missing Google Play regions version");
  const query = new URLSearchParams({
    updateMask: "basePlans",
    "regionsVersion.version": regionsVersion,
  });
  return `${subscriptionPath(plan.productId)}?${query}`;
}

function basePlanActivationPath(plan) {
  assertExpectedPlan(plan);
  return `${subscriptionPath(plan.productId)}/basePlans/${
    encodeURIComponent(plan.basePlanId)
  }:activate`;
}

function convertRegionPricesPath() {
  return `/applications/${PACKAGE_NAME}/pricing:convertRegionPrices`;
}

function normalizedMoney(money) {
  if (!money?.currencyCode || money.units === undefined) return null;
  return {
    currencyCode: money.currencyCode,
    units: String(BigInt(money.units)),
    nanos: Number(money.nanos || 0),
  };
}

function normalizedRegionalConfigs(configs) {
  return (Array.isArray(configs) ? configs : [])
    .map((config) => ({
      regionCode: config.regionCode,
      newSubscriberAvailability: config.newSubscriberAvailability === true,
      price: normalizedMoney(config.price),
    }))
    .sort((left, right) => left.regionCode.localeCompare(right.regionCode));
}

function managedBasePlanConfiguration(basePlan) {
  const autoRenewing = basePlan?.autoRenewingBasePlanType || {};
  return {
    basePlanId: basePlan?.basePlanId,
    regionalConfigs: normalizedRegionalConfigs(basePlan?.regionalConfigs),
    otherRegionsConfig: basePlan?.otherRegionsConfig
      ? {
        usdPrice: normalizedMoney(basePlan.otherRegionsConfig.usdPrice),
        eurPrice: normalizedMoney(basePlan.otherRegionsConfig.eurPrice),
        newSubscriberAvailability:
          basePlan.otherRegionsConfig.newSubscriberAvailability === true,
      }
      : null,
    autoRenewingBasePlanType: {
      billingPeriodDuration: autoRenewing.billingPeriodDuration,
      gracePeriodDuration: autoRenewing.gracePeriodDuration,
      resubscribeState: autoRenewing.resubscribeState,
      prorationMode: autoRenewing.prorationMode,
    },
  };
}

function sameManagedBasePlanConfiguration(left, right) {
  return (
    JSON.stringify(managedBasePlanConfiguration(left)) ===
      JSON.stringify(managedBasePlanConfiguration(right))
  );
}

function assertUniqueRegionalConfigs(configs, context) {
  const seen = new Set();
  for (const config of configs) {
    const regionCode = config?.regionCode;
    if (!/^[A-Z]{2}$/.test(regionCode || "") || seen.has(regionCode)) {
      throw new Error(
        `${context} contains an invalid or duplicate region code`,
      );
    }
    seen.add(regionCode);
  }
}

function assertExpectedPricing(plan, pricing) {
  assertExpectedPlan(plan);
  if (!pricing?.version) {
    throw new Error("Missing Google Play regions version");
  }
  if (
    !Array.isArray(pricing.regionalConfigs) ||
    pricing.regionalConfigs.length === 0
  ) {
    throw new Error("Google Play returned no regional subscription pricing");
  }
  assertUniqueRegionalConfigs(
    pricing.regionalConfigs,
    `${plan.productId}/${plan.basePlanId} pricing`,
  );
  if (
    pricing.regionalConfigs.some(
      (config) => EXCLUDED_REGION_CODES.has(config.regionCode),
    )
  ) {
    throw new Error("France must not appear in regional subscription pricing");
  }
  if (
    pricing.regionalConfigs.some(
      (config) =>
        config.newSubscriberAvailability !== true ||
        !normalizedMoney(config.price),
    )
  ) {
    throw new Error(
      "Every included region must be available and have a valid price",
    );
  }
  const qatar = pricing.regionalConfigs.find(
    (config) => config.regionCode === "QA",
  );
  if (
    !qatar ||
    JSON.stringify(normalizedMoney(qatar.price)) !==
      JSON.stringify(normalizedMoney(qarMoney(plan.priceQar)))
  ) {
    throw new Error(`Qatar price must be exactly QAR ${plan.priceQar}`);
  }
  if (
    !normalizedMoney(pricing.otherRegionsConfig?.usdPrice) ||
    !normalizedMoney(pricing.otherRegionsConfig?.eurPrice) ||
    pricing.otherRegionsConfig?.newSubscriberAvailability !== true
  ) {
    throw new Error(
      "Future Google Play regions must be available with converted USD and EUR prices",
    );
  }
}

function pricingFromConversion(plan, conversion) {
  assertExpectedPlan(plan);
  const amount = plan.priceQar;
  const version = conversion?.regionVersion?.version;
  if (!version) {
    throw new Error("Google Play did not return the current regions version");
  }

  const convertedRegions = Object.entries(
    conversion.convertedRegionPrices || {},
  );
  const regionsWithoutPrices = convertedRegions
    .filter(
      ([regionCode, value]) =>
        !EXCLUDED_REGION_CODES.has(regionCode) && !value?.price,
    )
    .map(([regionCode]) => regionCode);
  if (regionsWithoutPrices.length > 0) {
    throw new Error(
      `Google Play omitted prices for included region(s): ${
        regionsWithoutPrices.join(", ")
      }`,
    );
  }
  const regionalConfigs = convertedRegions
    .filter(([regionCode]) => !EXCLUDED_REGION_CODES.has(regionCode))
    .map(([regionCode, value]) => ({
      regionCode,
      newSubscriberAvailability: true,
      price: regionCode === "QA" ? qarMoney(amount) : value.price,
    }))
    .sort((left, right) => left.regionCode.localeCompare(right.regionCode));
  const other = conversion.convertedOtherRegionsPrice;
  // FR is an existing Play region and is excluded above. This fallback applies
  // only to locations Play may launch later, which the owner wants enabled.
  const pricing = {
    version,
    regionalConfigs,
    otherRegionsConfig: {
      usdPrice: other?.usdPrice,
      eurPrice: other?.eurPrice,
      newSubscriberAvailability: true,
    },
  };
  assertExpectedPricing(plan, pricing);
  return pricing;
}

async function convertPrice(accessToken, plan) {
  assertExpectedPlan(plan);
  const conversion = await request(accessToken, convertRegionPricesPath(), {
    method: "POST",
    body: { price: qarMoney(plan.priceQar) },
  });
  return pricingFromConversion(plan, conversion);
}

async function listSubscriptions(accessToken) {
  const subscriptions = [];
  let pageToken;
  do {
    const query = new URLSearchParams({ pageSize: "1000" });
    if (pageToken) query.set("pageToken", pageToken);
    const response = await request(
      accessToken,
      `/applications/${PACKAGE_NAME}/subscriptions?${query}`,
    );
    if (
      response.subscriptions !== undefined &&
      !Array.isArray(response.subscriptions)
    ) {
      throw new Error("Google Play returned an invalid subscriptions list");
    }
    subscriptions.push(...(response.subscriptions || []));
    pageToken = response.nextPageToken;
  } while (pageToken);
  return subscriptions;
}

async function getSubscription(accessToken, productId) {
  const plan = expectedPlanByProductId.get(productId);
  if (!plan) {
    throw new Error(`Refusing unexpected product ${productId || "<missing>"}`);
  }
  assertExpectedPlan(plan);
  return request(
    accessToken,
    subscriptionPath(productId),
  );
}

function assertExpectedSubscription(subscription, plan) {
  assertExpectedPlan(plan);
  if (subscription?.packageName !== PACKAGE_NAME) {
    throw new Error(
      `Refusing subscription for unexpected package ${
        subscription?.packageName || "<missing>"
      }`,
    );
  }
  if (subscription.productId !== plan.productId) {
    throw new Error(
      `Refusing unexpected product ${
        subscription.productId || "<missing>"
      }; expected ${plan.productId}`,
    );
  }
  const basePlans = Array.isArray(subscription.basePlans)
    ? subscription.basePlans
    : [];
  const unexpected = basePlans.filter(
    (basePlan) => basePlan?.basePlanId !== plan.basePlanId,
  );
  if (unexpected.length > 0) {
    throw new Error(
      `Refusing unexpected base plan(s) for ${plan.productId}: ${
        unexpected
          .map((basePlan) => basePlan?.basePlanId || "<missing>")
          .join(", ")
      }`,
    );
  }
  if (basePlans.length > 1) {
    throw new Error(`Refusing duplicate base plan ${plan.basePlanId}`);
  }
  const basePlan = basePlans[0];
  if (!basePlan) return;
  const typeCount = [
    basePlan.autoRenewingBasePlanType,
    basePlan.prepaidBasePlanType,
    basePlan.installmentsBasePlanType,
  ].filter(Boolean).length;
  if (typeCount !== 1 || !basePlan.autoRenewingBasePlanType) {
    throw new Error(
      `Refusing non-auto-renewing base plan ${plan.productId}/${plan.basePlanId}`,
    );
  }
  if (
    basePlan.autoRenewingBasePlanType.billingPeriodDuration !==
      plan.billingPeriodDuration
  ) {
    throw new Error(
      `Refusing immutable billing period mismatch for ${plan.productId}/${plan.basePlanId}`,
    );
  }
  const allowedStates = new Set(["DRAFT", "ACTIVE", "INACTIVE"]);
  if (!allowedStates.has(basePlan.state)) {
    throw new Error(
      `Refusing unexpected base plan state ${basePlan.state || "<missing>"}`,
    );
  }
  assertUniqueRegionalConfigs(
    basePlan.regionalConfigs || [],
    `${plan.productId}/${plan.basePlanId}`,
  );
}

function assertExpectedInventory(subscriptions) {
  const byProductId = new Map();
  for (const subscription of subscriptions) {
    const plan = expectedPlanByProductId.get(subscription?.productId);
    if (!plan) {
      throw new Error(
        `Refusing unexpected Google Play subscription ${
          subscription?.productId || "<missing>"
        }`,
      );
    }
    if (byProductId.has(subscription.productId)) {
      throw new Error(
        `Refusing duplicate subscription ${subscription.productId}`,
      );
    }
    assertExpectedSubscription(subscription, plan);
    byProductId.set(subscription.productId, subscription);
  }
  const missing = plans
    .map((plan) => plan.productId)
    .filter((productId) => !byProductId.has(productId));
  if (missing.length > 0) {
    throw new Error(
      `Missing expected Google Play subscription(s): ${missing.join(", ")}`,
    );
  }
  return byProductId;
}

function desiredBasePlan(plan, pricing, existing) {
  assertExpectedPlan(plan);
  assertExpectedPricing(plan, pricing);
  const desired = {
    basePlanId: plan.basePlanId,
    regionalConfigs: pricing.regionalConfigs,
    otherRegionsConfig: pricing.otherRegionsConfig,
    autoRenewingBasePlanType: {
      billingPeriodDuration: plan.billingPeriodDuration,
      gracePeriodDuration: plan.gracePeriodDuration,
      resubscribeState: "RESUBSCRIBE_STATE_ACTIVE",
      prorationMode: "SUBSCRIPTION_PRORATION_MODE_CHARGE_ON_NEXT_BILLING_DATE",
    },
  };
  if (Array.isArray(existing?.offerTags) && existing.offerTags.length > 0) {
    desired.offerTags = existing.offerTags;
  }
  return desired;
}

async function applyPlan(accessToken, plan) {
  assertExpectedPlan(plan);
  let subscription = await getSubscription(accessToken, plan.productId);
  assertExpectedSubscription(subscription, plan);
  const pricing = await convertPrice(accessToken, plan);
  let existing = (subscription.basePlans || [])[0];
  let basePlan = desiredBasePlan(plan, pricing, existing);
  if (existing && sameManagedBasePlanConfiguration(existing, basePlan)) {
    return { subscription, changed: false };
  }

  // Re-read immediately before a write so an operator cannot silently replace a
  // concurrently changed or newly activated plan.
  subscription = await getSubscription(accessToken, plan.productId);
  assertExpectedSubscription(subscription, plan);
  existing = (subscription.basePlans || [])[0];
  basePlan = desiredBasePlan(plan, pricing, existing);
  if (existing && sameManagedBasePlanConfiguration(existing, basePlan)) {
    return { subscription, changed: false };
  }
  if (existing && existing.state !== "DRAFT") {
    throw new Error(
      `Refusing to modify non-draft base plan ${plan.productId}/${plan.basePlanId} (${existing.state})`,
    );
  }

  subscription = await request(
    accessToken,
    subscriptionPatchPath(plan, pricing.version),
    {
      method: "PATCH",
      body: {
        packageName: PACKAGE_NAME,
        productId: plan.productId,
        basePlans: [basePlan],
      },
    },
  );
  assertExpectedSubscription(subscription, plan);
  const applied = (subscription.basePlans || [])[0];
  if (!applied || !sameManagedBasePlanConfiguration(applied, basePlan)) {
    throw new Error(
      `Google Play did not persist the expected configuration for ${plan.productId}/${plan.basePlanId}`,
    );
  }
  return { subscription, changed: true };
}

async function activatePlan(accessToken, plan, subscription) {
  assertExpectedPlan(plan);
  assertExpectedSubscription(subscription, plan);
  const basePlan = (subscription.basePlans || [])[0];
  if (!basePlan) throw new Error(`Missing base plan ${plan.basePlanId}`);
  if (basePlan.state === "ACTIVE") {
    return { subscription, changed: false };
  }
  if (!["DRAFT", "INACTIVE"].includes(basePlan.state)) {
    throw new Error(
      `Refusing to activate base plan in unexpected state ${basePlan.state}`,
    );
  }
  try {
    subscription = await request(
      accessToken,
      basePlanActivationPath(plan),
      { method: "POST", body: {} },
    );
  } catch (error) {
    // A concurrent activation is harmless. Accept it only after a fresh,
    // fully validated read proves that the exact expected plan is active.
    const current = await getSubscription(accessToken, plan.productId);
    assertExpectedSubscription(current, plan);
    const currentBasePlan = (current.basePlans || [])[0];
    if (currentBasePlan?.state === "ACTIVE") {
      return { subscription: current, changed: false };
    }
    throw error;
  }
  assertExpectedSubscription(subscription, plan);
  if ((subscription.basePlans || [])[0]?.state !== "ACTIVE") {
    throw new Error(
      `Google Play did not activate ${plan.productId}/${plan.basePlanId}`,
    );
  }
  return { subscription, changed: true };
}

async function main() {
  const report = {
    mode,
    generatedAt: new Date().toISOString(),
    packageName: PACKAGE_NAME,
    products: [],
  };
  try {
    const account = readServiceAccount();
    report.serviceAccount = account.client_email;
    const accessToken = await createAccessToken(account);
    const subscriptions = await listSubscriptions(accessToken);
    const inventory = assertExpectedInventory(subscriptions);
    for (const plan of plans) {
      let subscription = inventory.get(plan.productId);
      let configurationChanged = false;
      let activationChanged = false;
      if (mode !== "inspect") {
        const applied = await applyPlan(accessToken, plan);
        subscription = applied.subscription;
        configurationChanged = applied.changed;
      }
      if (mode === "activate") {
        const activated = await activatePlan(accessToken, plan, subscription);
        subscription = activated.subscription;
        activationChanged = activated.changed;
      }
      assertExpectedSubscription(subscription, plan);
      const basePlan = (subscription.basePlans || [])[0];
      report.products.push({
        productId: plan.productId,
        basePlanId: plan.basePlanId,
        priceQar: plan.priceQar,
        billingPeriodDuration: plan.billingPeriodDuration,
        gracePeriodDuration: plan.gracePeriodDuration,
        changed: configurationChanged || activationChanged,
        configurationChanged,
        activationChanged,
        state: basePlan?.state || "MISSING",
        regionalCount: basePlan?.regionalConfigs?.length || 0,
        franceRegionalConfigPresent: basePlan?.regionalConfigs?.some(
          (config) => config.regionCode === "FR",
        ) || false,
        futureRegions:
          basePlan?.otherRegionsConfig?.newSubscriberAvailability || false,
      });
    }
    report.success = true;
  } catch (error) {
    report.success = false;
    report.error = error instanceof Error ? error.message : String(error);
  }

  mkdirSync(dirname(outputPath), { recursive: true });
  writeFileSync(outputPath, `${JSON.stringify(report, null, 2)}\n`, "utf8");
  process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
  if (!report.success) process.exitCode = 1;
}

const isMainModule = process.argv[1] &&
  resolve(process.argv[1]) === resolve(fileURLToPath(import.meta.url));
if (isMainModule) await main();

export {
  activatePlan,
  applyPlan,
  assertExpectedInventory,
  assertExpectedPlan,
  assertExpectedPricing,
  basePlanActivationPath,
  convertRegionPricesPath,
  desiredBasePlan,
  managedBasePlanConfiguration,
  normalizedRegionalConfigs,
  parseArguments,
  pricingFromConversion,
  sameManagedBasePlanConfiguration,
  subscriptionPatchPath,
  subscriptionPath,
};
