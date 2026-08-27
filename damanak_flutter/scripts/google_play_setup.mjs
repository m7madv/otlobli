#!/usr/bin/env node

import { createPrivateKey, sign } from 'node:crypto';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

const API_ROOT = 'https://androidpublisher.googleapis.com/androidpublisher/v3';
const TOKEN_URL = 'https://oauth2.googleapis.com/token';
const PACKAGE_NAME = 'com.damanak.damanak';
const SAUDI_VAT_RATE = 0.15;
const mode = process.argv.includes('--activate')
  ? 'activate'
  : process.argv.includes('--apply')
    ? 'apply'
    : 'inspect';
const GULF_REGION_CODES = ['SA', 'AE', 'BH', 'KW', 'OM', 'QA'];
const outputIndex = process.argv.indexOf('--output');
const outputPath = resolve(
  outputIndex >= 0 && process.argv[outputIndex + 1]
    ? process.argv[outputIndex + 1]
    : 'build/google-play-setup/report.json',
);

const definitions = [
  {
    productId: 'com.damanak.subscription.starter',
    title: 'خطة بداية في ضمانك',
    description: 'إدارة الضمانات والمبيعات لفريق صغير.',
    benefits: ['عضوان في الفريق', '100 ضمان شهرياً'],
    intendedPricesSar: { monthly: 39, yearly: 390 },
    intendedPricesQar: { monthly: 39.99, yearly: 399.99 },
  },
  {
    productId: 'com.damanak.subscription.growth',
    title: 'خطة نمو في ضمانك',
    description: 'إدارة متقدمة للمحل والفروع والفريق.',
    benefits: ['5 أعضاء في الفريق', '600 ضمان شهرياً'],
    intendedPricesSar: { monthly: 99, yearly: 990 },
    intendedPricesQar: { monthly: 79.99, yearly: 799.99 },
  },
  {
    productId: 'com.damanak.subscription.scale',
    title: 'خطة توسع في ضمانك',
    description: 'تشغيل متعدد الفروع للمتاجر المتوسعة.',
    benefits: ['15 عضواً في الفريق', '3000 ضمان شهرياً'],
    intendedPricesSar: { monthly: 199, yearly: 1990 },
    intendedPricesQar: { monthly: 199.99, yearly: 1999.99 },
  },
];

function base64Url(value) {
  return Buffer.from(value).toString('base64url');
}

function readServiceAccount() {
  const raw = process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON;
  if (!raw) {
    throw new Error('Missing GOOGLE_PLAY_SERVICE_ACCOUNT_JSON');
  }
  try {
    const account = JSON.parse(raw);
    if (!account.client_email || !account.private_key) {
      throw new Error('service account is missing client_email or private_key');
    }
    return account;
  } catch (error) {
    throw new Error(
      `Invalid GOOGLE_PLAY_SERVICE_ACCOUNT_JSON: ${
        error instanceof Error ? error.message : String(error)
      }`,
    );
  }
}

async function createAccessToken(account) {
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const payload = base64Url(
    JSON.stringify({
      iss: account.client_email,
      scope: 'https://www.googleapis.com/auth/androidpublisher',
      aud: TOKEN_URL,
      iat: now,
      exp: now + 3600,
    }),
  );
  const input = `${header}.${payload}`;
  const signature = sign('RSA-SHA256', Buffer.from(input), {
    key: createPrivateKey(account.private_key),
  }).toString('base64url');
  const response = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: `${input}.${signature}`,
    }),
  });
  const body = await response.json();
  if (!response.ok || !body.access_token) {
    throw new Error(
      body.error_description || body.error || `OAuth failed (${response.status})`,
    );
  }
  return body.access_token;
}

function apiError(body, status) {
  const message = body?.error?.message || `Google Play request failed (${status})`;
  const reason = body?.error?.details?.[0]?.reason;
  return reason ? `${message} [${reason}]` : message;
}

async function request(accessToken, path, { method = 'GET', body } = {}) {
  const response = await fetch(`${API_ROOT}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${accessToken}`,
      Accept: 'application/json',
      ...(body ? { 'Content-Type': 'application/json' } : {}),
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

async function findSubscription(accessToken, productId) {
  try {
    return await request(
      accessToken,
      `/applications/${PACKAGE_NAME}/subscriptions/${encodeURIComponent(productId)}`,
    );
  } catch (error) {
    if (error?.status === 404) return null;
    throw error;
  }
}

function currencyMoney(currencyCode, amount) {
  const units = Math.trunc(amount);
  const nanos = Math.round((amount - units) * 1_000_000_000);
  return { currencyCode, units: String(units), nanos };
}

const sarMoney = (amount) => currencyMoney('SAR', amount);
const qarMoney = (amount) => currencyMoney('QAR', amount);

async function convertSarPrice(accessToken, amount, qatarAmount) {
  // convertRegionPrices expects a tax-exclusive seed price, while the plan
  // amounts in this script are the customer-facing Saudi prices.
  const taxExclusiveAmount = amount / (1 + SAUDI_VAT_RATE);
  const conversion = await request(
    accessToken,
    `/applications/${PACKAGE_NAME}/pricing:convertRegionPrices`,
    {
      method: 'POST',
      body: {
        price: sarMoney(taxExclusiveAmount),
      },
    },
  );
  const version = conversion?.regionVersion?.version;
  if (!version) {
    throw new Error('Google Play did not return the current regions version');
  }
  const regionalConfigs = GULF_REGION_CODES.map((regionCode) => {
    const converted = conversion?.convertedRegionPrices?.[regionCode];
    if (!converted?.price) {
      throw new Error(`Google Play did not return a price for ${regionCode}`);
    }
    return {
      regionCode,
      newSubscriberAvailability: true,
      price: regionCode === 'SA'
        ? sarMoney(amount)
        : regionCode === 'QA'
          ? qarMoney(qatarAmount)
          : converted.price,
    };
  });
  return { version, regionalConfigs };
}

function desiredBasePlans(pricing) {
  return [
    {
      basePlanId: 'monthly',
      regionalConfigs: pricing.monthly.regionalConfigs,
      autoRenewingBasePlanType: { billingPeriodDuration: 'P1M' },
    },
    {
      basePlanId: 'yearly',
      regionalConfigs: pricing.yearly.regionalConfigs,
      autoRenewingBasePlanType: { billingPeriodDuration: 'P1Y' },
    },
  ];
}

function subscriptionBody(definition, pricing) {
  return {
    packageName: PACKAGE_NAME,
    productId: definition.productId,
    basePlans: desiredBasePlans(pricing),
    listings: [
      {
        languageCode: 'ar-SA',
        title: definition.title,
        description: definition.description,
        benefits: definition.benefits,
      },
    ],
  };
}

function desiredListings(definition) {
  return [
    {
      languageCode: 'ar-SA',
      title: definition.title,
      description: definition.description,
      benefits: definition.benefits,
    },
  ];
}

async function ensureSubscriptionListing(accessToken, subscription, definition) {
  const currentArabic = (subscription.listings || []).find(
    (listing) => listing.languageCode === 'ar-SA',
  );
  const expected = desiredListings(definition)[0];
  const unchanged =
    currentArabic?.title === expected.title &&
    currentArabic?.description === expected.description &&
    JSON.stringify(currentArabic?.benefits || []) ===
      JSON.stringify(expected.benefits);
  if (unchanged || mode === 'inspect') {
    return { subscription, state: unchanged ? 'existing' : 'needs-update' };
  }
  const updated = await request(
    accessToken,
    `/applications/${PACKAGE_NAME}/subscriptions/${encodeURIComponent(
      subscription.productId,
    )}?updateMask=listings`,
    {
      method: 'PATCH',
      body: {
        packageName: PACKAGE_NAME,
        productId: subscription.productId,
        listings: desiredListings(definition),
      },
    },
  );
  return { subscription: updated, state: 'updated' };
}

function moneyLabel(money) {
  if (!money?.currencyCode) return null;
  const units = Number(money.units || 0);
  const nanos = Number(money.nanos || 0) / 1_000_000_000;
  return `${(units + nanos).toFixed(2)} ${money.currencyCode}`;
}

function basePlanSummary(subscription, basePlanId) {
  const plan = (subscription?.basePlans || []).find(
    (candidate) => candidate.basePlanId === basePlanId,
  );
  const qatar = (plan?.regionalConfigs || []).find(
    (region) => region.regionCode === 'QA',
  );
  return {
    state: plan?.state || (subscription ? 'missing' : 'pending'),
    qatarPrice: moneyLabel(qatar?.price),
    qatarAvailable: qatar?.newSubscriberAvailability ?? null,
  };
}

async function activateBasePlans(accessToken, subscription) {
  const targetPlanIds = new Set(['monthly', 'yearly']);
  for (const plan of subscription.basePlans || []) {
    if (!targetPlanIds.has(plan.basePlanId)) continue;
    if (plan.state === 'ACTIVE') continue;
    await request(
      accessToken,
      `/applications/${PACKAGE_NAME}/subscriptions/${encodeURIComponent(
        subscription.productId,
      )}/basePlans/${encodeURIComponent(plan.basePlanId)}:activate`,
      { method: 'POST', body: {} },
    );
  }
}

async function addBasePlansToEmptySubscription(
  accessToken,
  subscription,
  pricing,
) {
  const existingPlans = subscription.basePlans || [];
  const existingPlanIds = new Set(existingPlans.map((plan) => plan.basePlanId));
  const missingPlanIds = ['monthly', 'yearly'].filter(
    (planId) => !existingPlanIds.has(planId),
  );
  if (missingPlanIds.length === 0) {
    return { subscription, changed: false };
  }
  if (existingPlans.length > 0) {
    throw new Error(
      `Refusing to replace partially configured subscription ${subscription.productId}; missing base plans: ${missingPlanIds.join(', ')}`,
    );
  }

  const updated = await request(
    accessToken,
    `/applications/${PACKAGE_NAME}/subscriptions/${encodeURIComponent(
      subscription.productId,
    )}?updateMask=basePlans&regionsVersion.version=${encodeURIComponent(
      pricing.regionsVersion,
    )}`,
    {
      method: 'PATCH',
      body: {
        packageName: PACKAGE_NAME,
        productId: subscription.productId,
        basePlans: desiredBasePlans(pricing),
      },
    },
  );
  return { subscription: updated, changed: true };
}

function comparableRegionalConfig(config) {
  return {
    regionCode: config.regionCode,
    newSubscriberAvailability: config.newSubscriberAvailability ?? false,
    price: {
      currencyCode: config.price?.currencyCode ?? '',
      units: String(config.price?.units ?? '0'),
      nanos: Number(config.price?.nanos ?? 0),
    },
  };
}

function sanitizedBasePlan(plan, desiredPlan) {
  const desiredByRegion = new Map(
    desiredPlan.regionalConfigs.map((config) => [config.regionCode, config]),
  );
  const mergedByRegion = new Map(
    (plan.regionalConfigs || []).map((config) => [config.regionCode, config]),
  );
  for (const [regionCode, config] of desiredByRegion) {
    mergedByRegion.set(regionCode, config);
  }
  const value = {
    basePlanId: plan.basePlanId,
    regionalConfigs: [...mergedByRegion.values()].map(comparableRegionalConfig),
  };
  if (plan.offerTags?.length) value.offerTags = plan.offerTags;
  if (plan.otherRegionsConfig) value.otherRegionsConfig = plan.otherRegionsConfig;
  for (const field of [
    'autoRenewingBasePlanType',
    'prepaidBasePlanType',
    'installmentsBasePlanType',
  ]) {
    if (plan[field]) value[field] = plan[field];
  }
  return value;
}

function gulfPricingMatches(plan, desiredPlan) {
  const currentByRegion = new Map(
    (plan.regionalConfigs || []).map((config) => [config.regionCode, config]),
  );
  return desiredPlan.regionalConfigs.every((expected) => {
    const current = currentByRegion.get(expected.regionCode);
    return (
      current &&
      JSON.stringify(comparableRegionalConfig(current)) ===
        JSON.stringify(comparableRegionalConfig(expected))
    );
  });
}

async function ensureBasePlanPricing(accessToken, subscription, pricing) {
  const expectedPlans = desiredBasePlans(pricing);
  const expectedById = new Map(
    expectedPlans.map((plan) => [plan.basePlanId, plan]),
  );
  const currentPlans = subscription.basePlans || [];
  const needsUpdate = currentPlans.some((plan) => {
    const expected = expectedById.get(plan.basePlanId);
    return expected && !gulfPricingMatches(plan, expected);
  });
  if (!needsUpdate || mode === 'inspect') {
    return {
      subscription,
      state: needsUpdate ? 'needs-update' : 'existing',
    };
  }
  const updated = await request(
    accessToken,
    `/applications/${PACKAGE_NAME}/subscriptions/${encodeURIComponent(
      subscription.productId,
    )}?updateMask=basePlans&regionsVersion.version=${encodeURIComponent(
      pricing.regionsVersion,
    )}`,
    {
      method: 'PATCH',
      body: {
        packageName: PACKAGE_NAME,
        productId: subscription.productId,
        basePlans: currentPlans.map((plan) => {
          const expected = expectedById.get(plan.basePlanId);
          return expected ? sanitizedBasePlan(plan, expected) : plan;
        }),
      },
    },
  );
  return { subscription: updated, state: 'updated' };
}

async function ensureSubscription(accessToken, definition, pricing) {
  let subscription = await findSubscription(accessToken, definition.productId);
  let state = subscription ? 'existing' : 'missing';
  if (!subscription && mode !== 'inspect') {
    subscription = await request(
      accessToken,
      `/applications/${PACKAGE_NAME}/subscriptions?productId=${encodeURIComponent(
        definition.productId,
      )}&regionsVersion.version=${encodeURIComponent(pricing.regionsVersion)}`,
      { method: 'POST', body: subscriptionBody(definition, pricing) },
    );
    state = 'created-draft';
  } else if (subscription && mode !== 'inspect') {
    const update = await addBasePlansToEmptySubscription(
      accessToken,
      subscription,
      pricing,
    );
    subscription = update.subscription;
    if (update.changed) state = 'existing-updated-draft';
  }

  let pricingState = subscription
    ? mode === 'inspect'
      ? 'not-changed'
      : 'pending'
    : 'missing';
  if (subscription && mode !== 'inspect') {
    const priceUpdate = await ensureBasePlanPricing(
      accessToken,
      subscription,
      pricing,
    );
    subscription = priceUpdate.subscription;
    pricingState = priceUpdate.state;
  }

  let listingState = subscription ? 'pending' : 'missing';
  if (subscription) {
    const listing = await ensureSubscriptionListing(
      accessToken,
      subscription,
      definition,
    );
    subscription = listing.subscription;
    listingState = listing.state;
  }

  if (subscription && mode === 'activate') {
    await activateBasePlans(accessToken, subscription);
    subscription = await findSubscription(accessToken, definition.productId);
    state = state === 'created-draft' ? 'created-active' : 'existing-activated';
  }

  const monthly = basePlanSummary(subscription, 'monthly');
  const yearly = basePlanSummary(subscription, 'yearly');
  return {
    productId: definition.productId,
    state,
    listing: listingState,
    basePlans: { monthly, yearly },
    intendedPricesSar: definition.intendedPricesSar,
    intendedPricesQar: definition.intendedPricesQar,
    pricing: pricingState,
    activation: mode === 'activate' ? 'requested' : 'pending-explicit-activation',
  };
}

async function main() {
  const report = {
    mode,
    generatedAt: new Date().toISOString(),
    packageName: PACKAGE_NAME,
    pricesApplied: false,
    basePlansActivated: false,
    targetRegions: GULF_REGION_CODES,
    pricingNote:
      'Gulf prices use Google conversion from the Saudi customer price, with explicit Qatar prices aligned to the Apple catalog. Apply updates new-purchase prices; activate also activates both base plans.',
    subscriptions: [],
  };

  try {
    const account = readServiceAccount();
    report.serviceAccount = account.client_email;
    const accessToken = await createAccessToken(account);
    for (const definition of definitions) {
      let pricing;
      if (mode !== 'inspect') {
        const monthly = await convertSarPrice(
          accessToken,
          definition.intendedPricesSar.monthly,
          definition.intendedPricesQar.monthly,
        );
        const yearly = await convertSarPrice(
          accessToken,
          definition.intendedPricesSar.yearly,
          definition.intendedPricesQar.yearly,
        );
        if (monthly.version !== yearly.version) {
          throw new Error('Google Play regions version changed during setup');
        }
        pricing = {
          regionsVersion: monthly.version,
          monthly,
          yearly,
        };
        report.regionsVersion = monthly.version;
      }
      report.subscriptions.push(
        await ensureSubscription(accessToken, definition, pricing),
      );
    }
    report.pricesApplied =
      mode !== 'inspect' &&
      report.subscriptions.every((subscription) =>
        ['existing', 'updated'].includes(subscription.pricing),
      );
    report.basePlansActivated =
      mode === 'activate' &&
      report.subscriptions.every(
        (subscription) =>
          subscription.basePlans.monthly.state === 'ACTIVE' &&
          subscription.basePlans.yearly.state === 'ACTIVE',
      );
    report.success = true;
  } catch (error) {
    report.success = false;
    report.error = error instanceof Error ? error.message : String(error);
  }

  mkdirSync(dirname(outputPath), { recursive: true });
  writeFileSync(outputPath, `${JSON.stringify(report, null, 2)}\n`, 'utf8');
  process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
  if (!report.success) process.exitCode = 1;
}

await main();
