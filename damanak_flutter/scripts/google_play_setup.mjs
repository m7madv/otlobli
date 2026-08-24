#!/usr/bin/env node

import { createPrivateKey, sign } from 'node:crypto';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

const API_ROOT = 'https://androidpublisher.googleapis.com/androidpublisher/v3';
const TOKEN_URL = 'https://oauth2.googleapis.com/token';
const PACKAGE_NAME = 'com.damanak.damanak';
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
    benefits: ['عضوان في الفريق', '60 ضماناً شهرياً'],
    intendedPricesSar: { monthly: 39, yearly: 390 },
  },
  {
    productId: 'com.damanak.subscription.growth',
    title: 'خطة نمو في ضمانك',
    description: 'إدارة متقدمة للمحل والفروع والفريق.',
    benefits: ['5 أعضاء في الفريق', '250 ضماناً شهرياً'],
    intendedPricesSar: { monthly: 99, yearly: 990 },
  },
  {
    productId: 'com.damanak.subscription.scale',
    title: 'خطة توسع في ضمانك',
    description: 'تشغيل متعدد الفروع للمتاجر المتوسعة.',
    benefits: ['15 عضواً في الفريق', '1200 ضمان شهرياً'],
    intendedPricesSar: { monthly: 199, yearly: 1990 },
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

function sarMoney(amount) {
  const units = Math.trunc(amount);
  const nanos = Math.round((amount - units) * 1_000_000_000);
  return { currencyCode: 'SAR', units: String(units), nanos };
}

async function convertSarPrice(accessToken, amount) {
  const conversion = await request(
    accessToken,
    `/applications/${PACKAGE_NAME}/pricing:convertRegionPrices`,
    {
      method: 'POST',
      body: {
        price: sarMoney(amount),
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
      price: converted.price,
    };
  });
  return { version, regionalConfigs };
}

function subscriptionBody(definition, pricing) {
  return {
    packageName: PACKAGE_NAME,
    productId: definition.productId,
    basePlans: [
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
    ],
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

async function activateBasePlans(accessToken, subscription) {
  for (const plan of subscription.basePlans || []) {
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
  }

  if (subscription && mode === 'activate') {
    await activateBasePlans(accessToken, subscription);
    subscription = await findSubscription(accessToken, definition.productId);
    state = state === 'created-draft' ? 'created-active' : 'existing-activated';
  }

  const basePlans = new Map(
    (subscription?.basePlans || []).map((plan) => [plan.basePlanId, plan.state]),
  );
  return {
    productId: definition.productId,
    state,
    basePlans: {
      monthly: basePlans.get('monthly') || (subscription ? 'missing' : 'pending'),
      yearly: basePlans.get('yearly') || (subscription ? 'missing' : 'pending'),
    },
    intendedPricesSar: definition.intendedPricesSar,
    pricing:
      mode === 'inspect'
        ? 'not-changed'
        : `applied-to-${GULF_REGION_CODES.join('-')}`,
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
      'Apply creates priced drafts for the six Gulf markets; activate also activates both base plans.',
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
        );
        const yearly = await convertSarPrice(
          accessToken,
          definition.intendedPricesSar.yearly,
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
    report.pricesApplied = mode !== 'inspect';
    report.basePlansActivated =
      mode === 'activate' &&
      report.subscriptions.every(
        (subscription) =>
          subscription.basePlans.monthly === 'ACTIVE' &&
          subscription.basePlans.yearly === 'ACTIVE',
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
