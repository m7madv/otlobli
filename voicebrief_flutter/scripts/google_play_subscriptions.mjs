#!/usr/bin/env node

import { createPrivateKey, sign } from 'node:crypto';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

const API_ROOT = 'https://androidpublisher.googleapis.com/androidpublisher/v3';
const TOKEN_URL = 'https://oauth2.googleapis.com/token';
const PACKAGE_NAME = 'app.voicebrief.mobile';

const mode = process.argv.includes('--activate')
  ? 'activate'
  : process.argv.includes('--apply')
    ? 'apply'
    : 'inspect';
const outputIndex = process.argv.indexOf('--output');
const outputPath = resolve(
  outputIndex >= 0 && process.argv[outputIndex + 1]
    ? process.argv[outputIndex + 1]
    : 'build/google-play-subscriptions/report.json',
);

const plans = [
  {
    productId: 'voicebrief_pro_monthly',
    basePlanId: 'monthly',
    billingPeriodDuration: 'P1M',
    priceQar: 29,
  },
  {
    productId: 'voicebrief_pro_annual',
    basePlanId: 'annual',
    billingPeriodDuration: 'P1Y',
    priceQar: 229,
  },
];

function base64Url(value) {
  return Buffer.from(value).toString('base64url');
}

function readServiceAccount() {
  const raw = process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON;
  if (raw) {
    const account = JSON.parse(raw);
    if (!account.client_email || !account.private_key) {
      throw new Error('service account JSON is missing client_email or private_key');
    }
    return account;
  }

  const clientEmail = process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_EMAIL;
  const privateKeyPath = process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_PRIVATE_KEY_PATH;
  if (!clientEmail || !privateKeyPath) {
    throw new Error(
      'Set GOOGLE_PLAY_SERVICE_ACCOUNT_JSON or both GOOGLE_PLAY_SERVICE_ACCOUNT_EMAIL and GOOGLE_PLAY_SERVICE_ACCOUNT_PRIVATE_KEY_PATH',
    );
  }
  return {
    client_email: clientEmail,
    private_key: readFileSync(resolve(privateKeyPath), 'utf8'),
  };
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
    throw new Error(body.error_description || body.error || 'Google OAuth failed');
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

function qarMoney(amount) {
  return { currencyCode: 'QAR', units: String(Math.trunc(amount)), nanos: 0 };
}

async function convertPrice(accessToken, amount) {
  const conversion = await request(
    accessToken,
    `/applications/${PACKAGE_NAME}/pricing:convertRegionPrices`,
    { method: 'POST', body: { price: qarMoney(amount) } },
  );
  const version = conversion?.regionVersion?.version;
  if (!version) {
    throw new Error('Google Play did not return the current regions version');
  }

  const regionalConfigs = Object.entries(conversion.convertedRegionPrices || {})
    .map(([regionCode, value]) => ({
      regionCode,
      newSubscriberAvailability: true,
      price: regionCode === 'QA' ? qarMoney(amount) : value.price,
    }))
    .filter((config) => config.price);
  if (!regionalConfigs.some((config) => config.regionCode === 'QA')) {
    throw new Error('Google Play did not return Qatar regional pricing');
  }

  const other = conversion.convertedOtherRegionsPrice;
  const otherRegionsConfig =
    other?.usdPrice && other?.eurPrice
      ? {
          usdPrice: other.usdPrice,
          eurPrice: other.eurPrice,
          newSubscriberAvailability: true,
        }
      : undefined;
  return { version, regionalConfigs, otherRegionsConfig };
}

async function getSubscription(accessToken, productId) {
  return request(
    accessToken,
    `/applications/${PACKAGE_NAME}/subscriptions/${encodeURIComponent(productId)}`,
  );
}

async function applyPlan(accessToken, plan) {
  let subscription = await getSubscription(accessToken, plan.productId);
  const existingPlans = subscription.basePlans || [];
  const existing = existingPlans.find(
    (candidate) => candidate.basePlanId === plan.basePlanId,
  );
  if (existing) {
    return { subscription, changed: false };
  }
  if (existingPlans.length > 0) {
    throw new Error(
      `Refusing to replace partially configured ${plan.productId}: ${existingPlans.map((item) => item.basePlanId).join(', ')}`,
    );
  }

  const pricing = await convertPrice(accessToken, plan.priceQar);
  const basePlan = {
    basePlanId: plan.basePlanId,
    regionalConfigs: pricing.regionalConfigs,
    autoRenewingBasePlanType: {
      billingPeriodDuration: plan.billingPeriodDuration,
      gracePeriodDuration: 'P7D',
      resubscribeState: 'RESUBSCRIBE_STATE_ACTIVE',
      prorationMode:
        'SUBSCRIPTION_PRORATION_MODE_CHARGE_ON_NEXT_BILLING_DATE',
    },
    ...(pricing.otherRegionsConfig
      ? { otherRegionsConfig: pricing.otherRegionsConfig }
      : {}),
  };
  subscription = await request(
    accessToken,
    `/applications/${PACKAGE_NAME}/subscriptions/${encodeURIComponent(
      plan.productId,
    )}?updateMask=basePlans&regionsVersion.version=${encodeURIComponent(pricing.version)}`,
    {
      method: 'PATCH',
      body: {
        packageName: PACKAGE_NAME,
        productId: plan.productId,
        basePlans: [basePlan],
      },
    },
  );
  return { subscription, changed: true };
}

async function activatePlan(accessToken, plan, subscription) {
  const basePlan = (subscription.basePlans || []).find(
    (candidate) => candidate.basePlanId === plan.basePlanId,
  );
  if (!basePlan) throw new Error(`Missing base plan ${plan.basePlanId}`);
  if (basePlan.state === 'ACTIVE') return subscription;
  await request(
    accessToken,
    `/applications/${PACKAGE_NAME}/subscriptions/${encodeURIComponent(
      plan.productId,
    )}/basePlans/${encodeURIComponent(plan.basePlanId)}:activate`,
    { method: 'POST', body: {} },
  );
  return getSubscription(accessToken, plan.productId);
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
    for (const plan of plans) {
      let subscription = await getSubscription(accessToken, plan.productId);
      let changed = false;
      if (mode !== 'inspect') {
        const applied = await applyPlan(accessToken, plan);
        subscription = applied.subscription;
        changed = applied.changed;
      }
      if (mode === 'activate') {
        subscription = await activatePlan(accessToken, plan, subscription);
      }
      const basePlan = (subscription.basePlans || []).find(
        (candidate) => candidate.basePlanId === plan.basePlanId,
      );
      report.products.push({
        productId: plan.productId,
        basePlanId: plan.basePlanId,
        priceQar: plan.priceQar,
        changed,
        state: basePlan?.state || 'MISSING',
        regionalCount: basePlan?.regionalConfigs?.length || 0,
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
  writeFileSync(outputPath, `${JSON.stringify(report, null, 2)}\n`, 'utf8');
  process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
  if (!report.success) process.exitCode = 1;
}

await main();
