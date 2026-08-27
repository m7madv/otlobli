#!/usr/bin/env node

import { createHash, createPrivateKey, sign } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { basename, dirname, resolve } from 'node:path';

const API_ROOT = 'https://api.appstoreconnect.apple.com';
const BUNDLE_ID = 'com.damanak.damanak';
const APP_NAME = 'Damanak - ضمانك';
const APP_SKU = 'DAMANAK_IOS';
const PRIMARY_LOCALE = 'ar-SA';
const GROUP_REFERENCE_NAME = 'Damanak Plans';
const INTERNAL_BETA_GROUP_NAME = 'Damanak Internal';
const PROFILE_NAME = 'Damanak App Store';
const APP_STORE_TERRITORIES = ['SAU', 'ARE', 'BHR', 'KWT', 'OMN', 'QAT'];
const productDefinitions = [
  {
    productId: 'com.damanak.subscription.starter.monthly',
    name: 'Damanak Starter Monthly',
    localizedName: 'بداية شهري',
    description: 'اشتراك شهري لخطة بداية في ضمانك',
    subscriptionPeriod: 'ONE_MONTH',
    groupLevel: 3,
    intendedPriceSar: 39,
  },
  {
    productId: 'com.damanak.subscription.starter.yearly',
    name: 'Damanak Starter Yearly',
    localizedName: 'بداية سنوي',
    description: 'اشتراك سنوي لخطة بداية في ضمانك',
    subscriptionPeriod: 'ONE_YEAR',
    groupLevel: 3,
    intendedPriceSar: 390,
  },
  {
    productId: 'com.damanak.subscription.growth.monthly',
    name: 'Damanak Growth Monthly',
    localizedName: 'نمو شهري',
    description: 'اشتراك شهري لخطة نمو في ضمانك',
    subscriptionPeriod: 'ONE_MONTH',
    groupLevel: 2,
    intendedPriceSar: 99,
  },
  {
    productId: 'com.damanak.subscription.growth.yearly',
    name: 'Damanak Growth Yearly',
    localizedName: 'نمو سنوي',
    description: 'اشتراك سنوي لخطة نمو في ضمانك',
    subscriptionPeriod: 'ONE_YEAR',
    groupLevel: 2,
    intendedPriceSar: 990,
  },
  {
    productId: 'com.damanak.subscription.scale.monthly',
    name: 'Damanak Scale Monthly',
    localizedName: 'توسع شهري',
    description: 'اشتراك شهري لخطة توسع في ضمانك',
    subscriptionPeriod: 'ONE_MONTH',
    groupLevel: 1,
    intendedPriceSar: 199,
  },
  {
    productId: 'com.damanak.subscription.scale.yearly',
    name: 'Damanak Scale Yearly',
    localizedName: 'توسع سنوي',
    description: 'اشتراك سنوي لخطة توسع في ضمانك',
    subscriptionPeriod: 'ONE_YEAR',
    groupLevel: 1,
    intendedPriceSar: 1990,
  },
];

const mode = process.argv.includes('--apply') ? 'apply' : 'inspect';
const applyPrices = process.argv.includes('--apply-prices');
const outputIndex = process.argv.indexOf('--output');
const outputPath = resolve(
  outputIndex >= 0 && process.argv[outputIndex + 1]
    ? process.argv[outputIndex + 1]
    : 'build/app-store-setup/report.json',
);
const profileIndex = process.argv.indexOf('--profile-output');
const profilePath = resolve(
  profileIndex >= 0 && process.argv[profileIndex + 1]
    ? process.argv[profileIndex + 1]
    : 'build/app-store-setup/damanak.mobileprovision',
);
const reviewScreenshotIndex = process.argv.indexOf('--review-screenshot');
const reviewScreenshotPath = resolve(
  reviewScreenshotIndex >= 0 && process.argv[reviewScreenshotIndex + 1]
    ? process.argv[reviewScreenshotIndex + 1]
    : 'app_store_assets/subscription-review-1024x768.jpg',
);

const requiredEnvironment = [
  'APP_STORE_CONNECT_API_KEY_ID',
  'APP_STORE_CONNECT_ISSUER_ID',
  'APP_STORE_CONNECT_API_KEY_BASE64',
];
for (const variable of requiredEnvironment) {
  if (!process.env[variable]) {
    throw new Error(`Missing required environment variable: ${variable}`);
  }
}

function base64Url(value) {
  return Buffer.from(value).toString('base64url');
}

function createToken() {
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(
    JSON.stringify({
      alg: 'ES256',
      kid: process.env.APP_STORE_CONNECT_API_KEY_ID,
      typ: 'JWT',
    }),
  );
  const payload = base64Url(
    JSON.stringify({
      iss: process.env.APP_STORE_CONNECT_ISSUER_ID,
      iat: now,
      exp: now + 15 * 60,
      aud: 'appstoreconnect-v1',
    }),
  );
  const signingInput = `${header}.${payload}`;
  const privateKeyText = Buffer.from(
    process.env.APP_STORE_CONNECT_API_KEY_BASE64,
    'base64',
  ).toString('utf8');
  const privateKey = createPrivateKey(privateKeyText);
  const signature = sign('sha256', Buffer.from(signingInput), {
    key: privateKey,
    dsaEncoding: 'ieee-p1363',
  }).toString('base64url');
  return `${signingInput}.${signature}`;
}

let token = createToken();

function redactApiErrors(body, status) {
  const errors = Array.isArray(body?.errors) ? body.errors : [];
  if (errors.length === 0) return `App Store Connect request failed (${status})`;
  return errors
    .map((error) => {
      const code = error.code ? ` [${error.code}]` : '';
      const detail = error.detail || error.title || 'Unknown error';
      return `${detail}${code}`;
    })
    .join('; ');
}

async function request(path, { method = 'GET', body } = {}) {
  const response = await fetch(`${API_ROOT}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/json',
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  const text = await response.text();
  const parsed = text ? JSON.parse(text) : {};
  if (!response.ok) {
    const error = new Error(redactApiErrors(parsed, response.status));
    error.status = response.status;
    throw error;
  }
  return parsed;
}

async function listAll(path) {
  const data = [];
  let nextPath = path;
  while (nextPath) {
    const page = await request(nextPath);
    data.push(...(page.data || []));
    const nextUrl = page.links?.next;
    nextPath = nextUrl ? new URL(nextUrl).pathname + new URL(nextUrl).search : null;
  }
  return data;
}

async function findBundleId() {
  const rows = await listAll(
    `/v1/bundleIds?filter[identifier]=${encodeURIComponent(BUNDLE_ID)}&limit=10`,
  );
  return rows.find((row) => row.attributes?.identifier === BUNDLE_ID) || null;
}

async function ensureBundleId(report) {
  let bundleId = await findBundleId();
  report.bundleId = bundleId ? 'existing' : 'missing';
  if (!bundleId && mode === 'apply') {
    const result = await request('/v1/bundleIds', {
      method: 'POST',
      body: {
        data: {
          type: 'bundleIds',
          attributes: {
            identifier: BUNDLE_ID,
            name: 'Damanak',
            platform: 'IOS',
          },
        },
      },
    });
    bundleId = result.data;
    report.bundleId = 'created';
  }
  return bundleId;
}

async function findApp() {
  const rows = await listAll(
    `/v1/apps?filter[bundleId]=${encodeURIComponent(BUNDLE_ID)}&limit=10`,
  );
  return rows.find((row) => row.attributes?.bundleId === BUNDLE_ID) || null;
}

async function findPossibleAppRecords() {
  const rows = await listAll('/v1/apps?limit=200');
  return rows
    .filter((row) => {
      const name = String(row.attributes?.name || '').toLowerCase();
      const sku = String(row.attributes?.sku || '').toLowerCase();
      return name.includes('damanak') || name.includes('ضمانك') || sku.includes('damanak');
    })
    .map((row) => ({
      name: row.attributes?.name,
      sku: row.attributes?.sku,
      bundleId: row.attributes?.bundleId,
    }));
}

async function ensureApp(report) {
  let app = await findApp();
  report.app = app ? 'existing' : 'missing';
  if (!app && mode === 'apply') {
    report.possibleAppRecords = await findPossibleAppRecords();
    try {
      const result = await request('/v1/apps', {
        method: 'POST',
        body: {
          data: {
            type: 'apps',
            attributes: {
              bundleId: BUNDLE_ID,
              name: APP_NAME,
              primaryLocale: PRIMARY_LOCALE,
              sku: APP_SKU,
            },
          },
        },
      });
      app = result.data;
      report.app = 'created';
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      if (message.includes("resource 'apps' does not allow 'CREATE'")) {
        report.app = 'blocked-ui-creation-required';
        report.appCreationNote =
          'Apple requires the initial app record to be created in App Store Connect.';
      } else {
        throw error;
      }
    }
  }
  return app;
}

async function inspectBuilds(app, report) {
  if (!app) {
    report.builds = [];
    return;
  }
  const builds = await listAll(
    `/v1/builds?filter[app]=${app.id}&sort=-uploadedDate&limit=10`,
  );
  report.builds = builds.map((build) => ({
    id: build.id,
    version: build.attributes?.version,
    uploadedDate: build.attributes?.uploadedDate,
    processingState: build.attributes?.processingState,
    expired: build.attributes?.expired,
    expirationDate: build.attributes?.expirationDate,
    minOsVersion: build.attributes?.minOsVersion,
    usesNonExemptEncryption: build.attributes?.usesNonExemptEncryption,
  }));
}

async function ensureInternalBetaGroup(app, report) {
  if (!app) {
    report.internalBetaGroup = { state: 'blocked-until-app-exists' };
    return;
  }
  const groups = await listAll(`/v1/apps/${app.id}/betaGroups?limit=200`);
  let group = groups.find(
    (row) =>
      row.attributes?.name === INTERNAL_BETA_GROUP_NAME &&
      row.attributes?.isInternalGroup === true,
  );
  let state = group ? 'existing' : 'missing';
  if (!group && mode === 'apply') {
    const result = await request('/v1/betaGroups', {
      method: 'POST',
      body: {
        data: {
          type: 'betaGroups',
          attributes: {
            name: INTERNAL_BETA_GROUP_NAME,
            isInternalGroup: true,
            hasAccessToAllBuilds: true,
            feedbackEnabled: true,
          },
          relationships: {
            app: { data: { type: 'apps', id: app.id } },
          },
        },
      },
    });
    group = result.data;
    state = 'created';
  }
  const groupBuilds = group
    ? await listAll(`/v1/betaGroups/${group.id}/builds?limit=200`)
    : [];
  const groupTesters = group
    ? await listAll(`/v1/betaGroups/${group.id}/betaTesters?limit=200`)
    : [];
  report.internalBetaGroup = {
    state,
    id: group?.id,
    name: group?.attributes?.name,
    isInternalGroup: group?.attributes?.isInternalGroup,
    hasAccessToAllBuilds: group?.attributes?.hasAccessToAllBuilds,
    feedbackEnabled: group?.attributes?.feedbackEnabled,
    buildCount: groupBuilds.length,
    buildIds: groupBuilds.map((build) => build.id),
    testerCount: groupTesters.length,
  };
}

async function ensureSubscriptionGroup(app, report) {
  if (!app) {
    report.subscriptionGroup = 'blocked-until-app-exists';
    return null;
  }
  const groups = await listAll(`/v1/apps/${app.id}/subscriptionGroups?limit=200`);
  let group = groups.find(
    (row) => row.attributes?.referenceName === GROUP_REFERENCE_NAME,
  );
  report.subscriptionGroup = group ? 'existing' : 'missing';
  if (!group && mode === 'apply') {
    const result = await request('/v1/subscriptionGroups', {
      method: 'POST',
      body: {
        data: {
          type: 'subscriptionGroups',
          attributes: { referenceName: GROUP_REFERENCE_NAME },
          relationships: {
            app: { data: { type: 'apps', id: app.id } },
          },
        },
      },
    });
    group = result.data;
    report.subscriptionGroup = 'created';
  }
  return group;
}

async function ensureSubscriptionGroupLocalization(group, report) {
  if (!group) {
    report.subscriptionGroupLocalization = 'blocked-until-group-exists';
    return;
  }
  const rows = await listAll(
    `/v1/subscriptionGroups/${group.id}/subscriptionGroupLocalizations?limit=50`,
  );
  const existing = rows.find((row) => row.attributes?.locale === PRIMARY_LOCALE);
  report.subscriptionGroupLocalization = existing ? 'existing' : 'missing';
  if (!existing && mode === 'apply') {
    await request('/v1/subscriptionGroupLocalizations', {
      method: 'POST',
      body: {
        data: {
          type: 'subscriptionGroupLocalizations',
          attributes: {
            locale: PRIMARY_LOCALE,
            name: 'خطط ضمانك',
          },
          relationships: {
            subscriptionGroup: {
              data: { type: 'subscriptionGroups', id: group.id },
            },
          },
        },
      },
    });
    report.subscriptionGroupLocalization = 'created';
  }
}

async function ensureSubscriptionLocalization(subscription, definition) {
  const rows = await listAll(
    `/v1/subscriptions/${subscription.id}/subscriptionLocalizations?limit=50`,
  );
  const existing = rows.find((row) => row.attributes?.locale === PRIMARY_LOCALE);
  if (existing) return 'existing';
  if (mode !== 'apply') return 'missing';
  await request('/v1/subscriptionLocalizations', {
    method: 'POST',
    body: {
      data: {
        type: 'subscriptionLocalizations',
        attributes: {
          locale: PRIMARY_LOCALE,
          name: definition.localizedName,
          description: definition.description,
        },
        relationships: {
          subscription: {
            data: { type: 'subscriptions', id: subscription.id },
          },
        },
      },
    },
  });
  return 'created';
}

async function ensureSubscriptionAvailability(subscription) {
  let availability = null;
  let availableTerritoryIds = [];
  try {
    const result = await request(
      `/v1/subscriptions/${subscription.id}/subscriptionAvailability` +
        '?include=availableTerritories&limit[availableTerritories]=50',
    );
    availability = result.data || null;
    availableTerritoryIds = (result.included || [])
      .filter((row) => row.type === 'territories')
      .map((row) => row.id)
      .sort();
  } catch (error) {
    if (error.status !== 404) throw error;
  }
  let state = availability ? 'existing' : 'missing';
  if (applyPrices) {
    const result = await request('/v1/subscriptionAvailabilities', {
      method: 'POST',
      body: {
        data: {
          type: 'subscriptionAvailabilities',
          attributes: {
            availableInNewTerritories: false,
          },
          relationships: {
            subscription: {
              data: { type: 'subscriptions', id: subscription.id },
            },
            availableTerritories: {
              data: APP_STORE_TERRITORIES.map((id) => ({
                type: 'territories',
                id,
              })),
            },
          },
        },
      },
    });
    availability = result.data;
    availableTerritoryIds = [...APP_STORE_TERRITORIES].sort();
    state = state === 'existing' ? 'updated' : 'created';
  }
  return {
    state,
    availableInNewTerritories:
      availability?.attributes?.availableInNewTerritories ?? null,
    territoryIds: availableTerritoryIds,
    qatarAvailable: availableTerritoryIds.includes('QAT'),
  };
}

function samePrice(left, right) {
  return Number(left) === Number(right);
}

async function existingPricesByTerritory(subscription) {
  const rows = await listAll(
    `/v1/subscriptions/${subscription.id}/prices?filter[territory]=${APP_STORE_TERRITORIES.join(',')}` +
      '&include=subscriptionPricePoint,territory&limit=200',
  );
  const prices = new Map();
  for (const row of rows) {
    const territory = row.relationships?.territory?.data?.id;
    if (territory && !prices.has(territory)) prices.set(territory, row);
  }
  return prices;
}

async function inspectExistingPrices(subscription) {
  const response = await request(
    `/v1/subscriptions/${subscription.id}/prices?filter[territory]=${APP_STORE_TERRITORIES.join(',')}` +
      '&include=subscriptionPricePoint,territory&limit=200',
  );
  const includedById = new Map(
    (response.included || []).map((row) => [row.id, row]),
  );
  return (response.data || [])
    .map((row) => {
      const territoryId = row.relationships?.territory?.data?.id || null;
      const pricePointId =
        row.relationships?.subscriptionPricePoint?.data?.id || null;
      const pricePoint = pricePointId ? includedById.get(pricePointId) : null;
      return {
        territory: territoryId,
        customerPrice: pricePoint?.attributes?.customerPrice ?? null,
        startDate: row.attributes?.startDate ?? null,
        preserved: row.attributes?.preserved ?? null,
      };
    })
    .sort((left, right) =>
      String(left.territory).localeCompare(String(right.territory)),
    );
}

async function findApprovedPricePoints(subscription, intendedPriceSar) {
  const sourceRows = await listAll(
    `/v1/subscriptions/${subscription.id}/pricePoints?filter[territory]=SAU` +
      '&include=territory&limit=8000',
  );
  let source = sourceRows.find((row) =>
    samePrice(row.attributes?.customerPrice, intendedPriceSar),
  );
  let exactAnchorPrice = true;
  if (!source) {
    source = sourceRows
      .filter((row) => Number.isFinite(Number(row.attributes?.customerPrice)))
      .sort(
        (left, right) =>
          Math.abs(Number(left.attributes.customerPrice) - intendedPriceSar) -
          Math.abs(Number(right.attributes.customerPrice) - intendedPriceSar),
      )[0];
    if (!source) {
      throw new Error(
        `Apple returned no SAU App Store price points for SAR ${intendedPriceSar}`,
      );
    }
    const effectivePrice = Number(source.attributes.customerPrice);
    const deviationPercent =
      (Math.abs(effectivePrice - intendedPriceSar) / intendedPriceSar) * 100;
    if (deviationPercent > 2) {
      throw new Error(
        `Closest SAU App Store price point to SAR ${intendedPriceSar} is SAR ${effectivePrice}, which exceeds the 2% safety limit`,
      );
    }
    exactAnchorPrice = false;
  }

  const targetTerritories = APP_STORE_TERRITORIES.filter((id) => id !== 'SAU');
  const equalizedRows = await listAll(
    `/v1/subscriptionPricePoints/${encodeURIComponent(source.id)}/equalizations` +
      `?filter[territory]=${targetTerritories.join(',')}` +
      '&include=territory&limit=200',
  );
  const result = new Map([['SAU', source]]);
  for (const row of equalizedRows) {
    const territory = row.relationships?.territory?.data?.id;
    if (territory && targetTerritories.includes(territory)) {
      result.set(territory, row);
    }
  }
  const missing = APP_STORE_TERRITORIES.filter((id) => !result.has(id));
  if (missing.length > 0) {
    throw new Error(
      `Apple returned no adjusted price point for: ${missing.join(', ')}`,
    );
  }
  return {
    points: result,
    exactAnchorPrice,
    effectiveAnchorPriceSar: Number(source.attributes?.customerPrice),
  };
}

async function ensureApprovedPrices(subscription, definition) {
  if (!applyPrices) {
    const existingPrices = await inspectExistingPrices(subscription);
    return {
      state: existingPrices.length > 0 ? 'existing' : 'missing',
      anchorTerritory: 'SAU',
      intendedAnchorPriceSar: definition.intendedPriceSar,
      existingPrices,
      qatarPrice:
        existingPrices.find((price) => price.territory === 'QAT')
          ?.customerPrice ?? null,
    };
  }

  const priceSelection = await findApprovedPricePoints(
    subscription,
    definition.intendedPriceSar,
  );
  const pricePoints = priceSelection.points;
  const existing = await existingPricesByTerritory(subscription);
  const territories = {};

  for (const territory of APP_STORE_TERRITORIES) {
    const point = pricePoints.get(territory);
    const current = existing.get(territory);
    if (current) {
      territories[territory] = {
        state: 'existing-not-overwritten',
        approvedCustomerPrice: point.attributes?.customerPrice,
      };
      continue;
    }
    await request('/v1/subscriptionPrices', {
      method: 'POST',
      body: {
        data: {
          type: 'subscriptionPrices',
          attributes: {
            startDate: null,
          },
          relationships: {
            subscription: {
              data: { type: 'subscriptions', id: subscription.id },
            },
            subscriptionPricePoint: {
              data: { type: 'subscriptionPricePoints', id: point.id },
            },
          },
        },
      },
    });
    territories[territory] = {
      state: 'created',
      customerPrice: point.attributes?.customerPrice,
    };
  }
  return {
    state: 'applied',
    pricingMode: 'standard-auto-renewable',
    anchorTerritory: 'SAU',
    requestedAnchorPriceSar: definition.intendedPriceSar,
    effectiveAnchorPriceSar: priceSelection.effectiveAnchorPriceSar,
    exactAnchorPrice: priceSelection.exactAnchorPrice,
    territories,
  };
}

async function currentReviewScreenshot(subscription) {
  try {
    const result = await request(
      `/v1/subscriptions/${subscription.id}/appStoreReviewScreenshot`,
    );
    return result.data || null;
  } catch (error) {
    if (error.status === 404) return null;
    throw error;
  }
}

async function waitForReviewScreenshot(screenshotId) {
  for (let attempt = 0; attempt < 40; attempt++) {
    const result = await request(
      `/v1/subscriptionAppStoreReviewScreenshots/${screenshotId}`,
    );
    const screenshot = result.data;
    const delivery = screenshot?.attributes?.assetDeliveryState;
    if (delivery?.state === 'COMPLETE') return screenshot;
    if (delivery?.state === 'FAILED') {
      const details = (delivery.errors || [])
        .map((error) => error.message || error.description || error.code)
        .filter(Boolean)
        .join('; ');
      throw new Error(
        `Apple rejected the subscription review screenshot${details ? `: ${details}` : ''}`,
      );
    }
    await new Promise((resolveWait) => setTimeout(resolveWait, 1500));
  }
  throw new Error('Apple did not finish processing the review screenshot in time');
}

async function uploadReviewScreenshot(subscription) {
  let screenshot = await currentReviewScreenshot(subscription);
  if (screenshot) {
    const delivery = screenshot.attributes?.assetDeliveryState;
    if (delivery?.state === 'COMPLETE') {
      return {
        state: 'existing',
        fileName: screenshot.attributes?.fileName,
        deliveryState: delivery.state,
      };
    }
    if (mode !== 'apply') {
      return {
        state: 'processing',
        fileName: screenshot.attributes?.fileName,
        deliveryState: delivery?.state,
      };
    }
    if (delivery?.state === 'UPLOAD_COMPLETE') {
      screenshot = await waitForReviewScreenshot(screenshot.id);
      return {
        state: 'existing',
        fileName: screenshot.attributes?.fileName,
        deliveryState: screenshot.attributes?.assetDeliveryState?.state,
      };
    }
    await request(
      `/v1/subscriptionAppStoreReviewScreenshots/${screenshot.id}`,
      { method: 'DELETE' },
    );
  }

  if (mode !== 'apply') return { state: 'missing' };
  if (!existsSync(reviewScreenshotPath)) {
    throw new Error(
      `Missing subscription review screenshot: ${reviewScreenshotPath}`,
    );
  }

  const file = readFileSync(reviewScreenshotPath);
  const fileName = basename(reviewScreenshotPath);
  const reservation = await request(
    '/v1/subscriptionAppStoreReviewScreenshots',
    {
      method: 'POST',
      body: {
        data: {
          type: 'subscriptionAppStoreReviewScreenshots',
          attributes: {
            fileName,
            fileSize: file.length,
          },
          relationships: {
            subscription: {
              data: { type: 'subscriptions', id: subscription.id },
            },
          },
        },
      },
    },
  );
  screenshot = reservation.data;
  for (const operation of screenshot.attributes?.uploadOperations || []) {
    const offset = Number(operation.offset || 0);
    const length = Number(operation.length || 0);
    const headers = Object.fromEntries(
      (operation.requestHeaders || []).map((header) => [
        header.name,
        header.value,
      ]),
    );
    const response = await fetch(operation.url, {
      method: operation.method,
      headers,
      body: file.subarray(offset, offset + length),
    });
    if (!response.ok) {
      throw new Error(
        `Apple screenshot upload failed (${response.status})`,
      );
    }
  }

  const sourceFileChecksum = createHash('md5').update(file).digest('hex');
  await request(
    `/v1/subscriptionAppStoreReviewScreenshots/${screenshot.id}`,
    {
      method: 'PATCH',
      body: {
        data: {
          type: 'subscriptionAppStoreReviewScreenshots',
          id: screenshot.id,
          attributes: {
            uploaded: true,
            sourceFileChecksum,
          },
        },
      },
    },
  );
  screenshot = await waitForReviewScreenshot(screenshot.id);
  return {
    state: 'created',
    fileName,
    fileSize: file.length,
    sha256: createHash('sha256').update(file).digest('hex'),
    deliveryState: screenshot.attributes?.assetDeliveryState?.state,
    imageAsset: screenshot.attributes?.imageAsset,
  };
}

async function ensureSubscriptions(group, report) {
  report.subscriptions = [];
  if (!group) {
    report.subscriptions = productDefinitions.map((definition) => ({
      productId: definition.productId,
      state: 'blocked-until-group-exists',
      intendedPriceSar: definition.intendedPriceSar,
    }));
    return;
  }

  const rows = await listAll(
    `/v1/subscriptionGroups/${group.id}/subscriptions?limit=200`,
  );
  for (const definition of productDefinitions) {
    let subscription = rows.find(
      (row) => row.attributes?.productId === definition.productId,
    );
    let state = subscription ? 'existing' : 'missing';
    if (!subscription && mode === 'apply') {
      const result = await request('/v1/subscriptions', {
        method: 'POST',
        body: {
          data: {
            type: 'subscriptions',
            attributes: {
              name: definition.name,
              productId: definition.productId,
              familySharable: false,
              subscriptionPeriod: definition.subscriptionPeriod,
              groupLevel: definition.groupLevel,
            },
            relationships: {
              group: {
                data: { type: 'subscriptionGroups', id: group.id },
              },
            },
          },
        },
      });
      subscription = result.data;
      state = 'created';
    }
    const localization = subscription
      ? await ensureSubscriptionLocalization(subscription, definition)
      : 'blocked-until-subscription-exists';
    const availability = subscription
      ? await ensureSubscriptionAvailability(subscription)
      : 'blocked-until-subscription-exists';
    const pricing = subscription
      ? await ensureApprovedPrices(subscription, definition)
      : { state: 'blocked-until-subscription-exists' };
    const reviewScreenshot = subscription
      ? await uploadReviewScreenshot(subscription)
      : { state: 'blocked-until-subscription-exists' };
    report.subscriptions.push({
      productId: definition.productId,
      state,
      reviewState: subscription?.attributes?.state ?? null,
      subscriptionPeriod: subscription?.attributes?.subscriptionPeriod ?? null,
      groupLevel: subscription?.attributes?.groupLevel ?? null,
      localization,
      availability,
      intendedPriceSar: definition.intendedPriceSar,
      pricing,
      reviewScreenshot,
    });
  }
}

function normalizeSerial(value) {
  return String(value || '')
    .replace(/^0+/, '')
    .toUpperCase();
}

async function selectDistributionCertificate(report) {
  const certificates = await listAll('/v1/certificates?limit=200');
  const active = certificates.filter((row) => {
    const type = row.attributes?.certificateType || '';
    const expires = Date.parse(row.attributes?.expirationDate || '');
    return type.includes('DISTRIBUTION') && expires > Date.now();
  });
  const requestedSerial = normalizeSerial(
    process.env.APPLE_DISTRIBUTION_CERTIFICATE_SERIAL,
  );
  const matching = requestedSerial
    ? active.filter(
        (row) => normalizeSerial(row.attributes?.serialNumber) === requestedSerial,
      )
    : active;
  report.activeDistributionCertificateCount = active.length;
  if (requestedSerial) {
    report.distributionCertificateMatch = matching.length === 1;
  }
  return matching.length === 1 ? matching[0] : null;
}

async function ensureProvisioningProfile(bundleId, report) {
  report.provisioningProfile = 'not-checked';
  if (!bundleId) {
    report.provisioningProfile = 'blocked-until-bundle-id-exists';
    return;
  }

  const profiles = await listAll(`/v1/bundleIds/${bundleId.id}/profiles?limit=200`);
  let profile = profiles.find(
    (row) =>
      row.attributes?.name === PROFILE_NAME &&
      row.attributes?.profileState === 'ACTIVE' &&
      Date.parse(row.attributes?.expirationDate || '') > Date.now(),
  );
  report.provisioningProfile = profile ? 'existing' : 'missing';

  if (!profile && mode === 'apply') {
    const certificate = await selectDistributionCertificate(report);
    if (!certificate) {
      report.provisioningProfile =
        'blocked-no-unique-matching-distribution-certificate';
      return;
    }
    const result = await request('/v1/profiles', {
      method: 'POST',
      body: {
        data: {
          type: 'profiles',
          attributes: {
            name: PROFILE_NAME,
            profileType: 'IOS_APP_STORE',
          },
          relationships: {
            bundleId: { data: { type: 'bundleIds', id: bundleId.id } },
            certificates: {
              data: [{ type: 'certificates', id: certificate.id }],
            },
          },
        },
      },
    });
    profile = result.data;
    report.provisioningProfile = 'created';
  }

  if (profile && mode === 'apply') {
    const detail = await request(`/v1/profiles/${profile.id}`);
    const profileContent = detail.data?.attributes?.profileContent;
    if (profileContent) {
      mkdirSync(dirname(profilePath), { recursive: true });
      writeFileSync(profilePath, profileContent, 'base64');
      report.provisioningProfileArtifact = true;
    } else {
      report.provisioningProfileArtifact = false;
    }
  }
}

async function main() {
  const report = {
    mode,
    generatedAt: new Date().toISOString(),
    bundleIdentifier: BUNDLE_ID,
    appName: APP_NAME,
    pricesApproved: true,
    pricesRequested: applyPrices,
    pricesApplied: false,
    priceTerritories: APP_STORE_TERRITORIES,
    pricingNote:
      applyPrices
        ? 'Approved SAR anchor prices and Apple-equalized Gulf price points were requested in this run.'
        : 'Approved prices are recorded but not applied in this run.',
  };

  try {
    const bundleId = await ensureBundleId(report);
    const app = await ensureApp(report);
    await inspectBuilds(app, report);
    await ensureInternalBetaGroup(app, report);
    const group = await ensureSubscriptionGroup(app, report);
    await ensureSubscriptionGroupLocalization(group, report);
    await ensureSubscriptions(group, report);
    report.pricesApplied =
      report.subscriptions.length === productDefinitions.length &&
      report.subscriptions.every(
        (subscription) => subscription.pricing?.state === 'applied',
      );
    if (applyPrices && !report.pricesApplied) {
      report.pricingNote =
        'Approved prices were requested but not applied because one or more required App Store resources are still missing.';
    }
    report.reviewScreenshotsApplied =
      report.subscriptions.length === productDefinitions.length &&
      report.subscriptions.every((subscription) =>
        ['created', 'existing'].includes(subscription.reviewScreenshot?.state),
      );
    if (mode === 'apply' && !report.reviewScreenshotsApplied) {
      throw new Error(
        'One or more App Store subscription review screenshots are missing',
      );
    }
    try {
      await ensureProvisioningProfile(bundleId, report);
    } catch (error) {
      report.provisioningProfile = 'needs-cleanup';
      report.provisioningProfileError =
        error instanceof Error ? error.message : String(error);
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
