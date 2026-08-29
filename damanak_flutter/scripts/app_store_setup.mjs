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
const GROUP_LOCALIZED_NAME = 'خطط ضمانك';
const GROUP_CUSTOM_APP_NAME = 'ضمانك';
const INTERNAL_BETA_GROUP_NAME = 'Damanak Internal';
const PROFILE_NAME = 'Damanak App Store';
const APP_STORE_TERRITORIES = ['SAU', 'ARE', 'BHR', 'KWT', 'OMN', 'QAT'];
// Apple distinguishes paid-in-full subscriptions from 12-month commitments
// paid monthly: https://developer.apple.com/documentation/appstoreconnectapi/subscriptionplantype
const SUBSCRIPTION_PLAN_TYPE = 'UPFRONT';
const SUBSCRIPTION_REVIEW_NOTE =
  'Damanak is a B2B warranty-management app for Gulf retailers. Sign in with Apple or Google, create a store, then open Administration > Subscription. The subscription unlocks warranty issuance quotas and team seats; it does not sell physical goods. The review screenshot shows the paywall. No pre-created account is required because reviewers can use Sign in with Apple.';
const productDefinitions = [
  {
    productId: 'com.damanak.subscription.starter.monthly',
    name: 'Damanak Starter Monthly',
    localizedName: 'بداية شهري',
    description: '100 ضمان شهرياً وعضوان في الفريق',
    subscriptionPeriod: 'ONE_MONTH',
    groupLevel: 3,
    intendedPriceSar: 39,
  },
  {
    productId: 'com.damanak.subscription.starter.yearly',
    name: 'Damanak Starter Yearly',
    localizedName: 'بداية سنوي',
    description: '100 ضمان شهرياً وعضوان في الفريق',
    subscriptionPeriod: 'ONE_YEAR',
    groupLevel: 3,
    intendedPriceSar: 390,
  },
  {
    productId: 'com.damanak.subscription.growth.monthly',
    name: 'Damanak Growth Monthly',
    localizedName: 'نمو شهري',
    description: '600 ضمان شهرياً و5 أعضاء في الفريق',
    subscriptionPeriod: 'ONE_MONTH',
    groupLevel: 2,
    intendedPriceSar: 99,
  },
  {
    productId: 'com.damanak.subscription.growth.yearly',
    name: 'Damanak Growth Yearly',
    localizedName: 'نمو سنوي',
    description: '600 ضمان شهرياً و5 أعضاء في الفريق',
    subscriptionPeriod: 'ONE_YEAR',
    groupLevel: 2,
    intendedPriceSar: 990,
  },
  {
    productId: 'com.damanak.subscription.scale.monthly',
    name: 'Damanak Scale Monthly',
    localizedName: 'توسع شهري',
    description: '3000 ضمان شهرياً و15 عضواً في الفريق',
    subscriptionPeriod: 'ONE_MONTH',
    groupLevel: 1,
    intendedPriceSar: 199,
  },
  {
    productId: 'com.damanak.subscription.scale.yearly',
    name: 'Damanak Scale Yearly',
    localizedName: 'توسع سنوي',
    description: '3000 ضمان شهرياً و15 عضواً في الفريق',
    subscriptionPeriod: 'ONE_YEAR',
    groupLevel: 1,
    intendedPriceSar: 1990,
  },
];

const mode = process.argv.includes('--apply') ? 'apply' : 'inspect';
const applyPrices = process.argv.includes('--apply-prices');
const addSubscriptionsToReviewDraft = process.argv.includes(
  '--add-subscriptions-to-review-draft',
);
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

async function inspectBundleIdCapabilities(bundleId, report) {
  report.bundleIdCapabilities = [];
  report.inAppPurchaseCapabilityEnabled = false;
  if (!bundleId) return;

  const capabilities = await listAll(
    `/v1/bundleIds/${bundleId.id}/bundleIdCapabilities?limit=200`,
  );
  report.bundleIdCapabilities = capabilities.map((row) => ({
    capabilityType: row.attributes?.capabilityType || 'UNKNOWN',
    settings: row.attributes?.settings || [],
  }));
  report.inAppPurchaseCapabilityEnabled = capabilities.some(
    (row) => row.attributes?.capabilityType === 'IN_APP_PURCHASE',
  );
}

function sha256Base64Content(value) {
  if (!value) return null;
  return createHash('sha256')
    .update(Buffer.from(value, 'base64'))
    .digest('hex')
    .toUpperCase();
}

async function inspectProvisioningProfiles(bundleId, report) {
  report.provisioningProfiles = [];
  report.embeddedProvisioningProfile = {
    suppliedByWorkflow: false,
    matchedAppStoreConnectProfile: false,
  };
  if (!bundleId) return;

  const suppliedProfileHash = sha256Base64Content(
    process.env.DAMANAK_IOS_APP_STORE_PROFILE_BASE64,
  );
  report.embeddedProvisioningProfile.suppliedByWorkflow =
    Boolean(suppliedProfileHash);

  const profiles = await listAll(
    `/v1/bundleIds/${bundleId.id}/profiles?limit=200`,
  );
  for (const profile of profiles) {
    let profileContent = profile.attributes?.profileContent;
    if (!profileContent && suppliedProfileHash) {
      const detail = await request(`/v1/profiles/${profile.id}`);
      profileContent = detail.data?.attributes?.profileContent;
    }
    const profileHash = sha256Base64Content(profileContent);
    const matchesSuppliedProfile =
      Boolean(suppliedProfileHash) && profileHash === suppliedProfileHash;
    const summary = {
      id: profile.id,
      name: profile.attributes?.name || null,
      uuid: profile.attributes?.uuid || null,
      profileType: profile.attributes?.profileType || null,
      profileState: profile.attributes?.profileState || null,
      createdDate: profile.attributes?.createdDate || null,
      expirationDate: profile.attributes?.expirationDate || null,
      matchesSuppliedProfile,
    };
    report.provisioningProfiles.push(summary);
    if (matchesSuppliedProfile) {
      report.embeddedProvisioningProfile = {
        suppliedByWorkflow: true,
        matchedAppStoreConnectProfile: true,
        ...summary,
      };
    }
  }

  report.activeAppStoreProvisioningProfileCount =
    report.provisioningProfiles.filter(
      (profile) =>
        profile.profileType === 'IOS_APP_STORE' &&
        profile.profileState === 'ACTIVE' &&
        Date.parse(profile.expirationDate || '') > Date.now(),
    ).length;
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
    report.groupId = null;
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
  report.groupId = group?.id ?? null;
  return group;
}

function summarizeLocalization(localization) {
  return {
    id: localization?.id ?? null,
    locale: localization?.attributes?.locale ?? null,
    name: localization?.attributes?.name ?? null,
    description: localization?.attributes?.description ?? null,
    customAppName: localization?.attributes?.customAppName ?? null,
    reviewState: localization?.attributes?.state ?? null,
  };
}

function summarizeVersion(version, localizations, isExpectedLocalization) {
  return {
    id: version?.id ?? null,
    version: version?.attributes?.version ?? null,
    state: version?.attributes?.state ?? null,
    localizationCount: localizations.length,
    expectedMetadataMatches: localizations.some(isExpectedLocalization),
    localizations: localizations.map(summarizeLocalization),
  };
}

function newestVersion(left, right) {
  const leftVersion = Number(left?.version?.attributes?.version);
  const rightVersion = Number(right?.version?.attributes?.version);
  if (Number.isFinite(leftVersion) && Number.isFinite(rightVersion)) {
    return rightVersion - leftVersion;
  }
  return String(right?.version?.attributes?.version ?? '').localeCompare(
    String(left?.version?.attributes?.version ?? ''),
    undefined,
    { numeric: true },
  );
}

function isGroupLocalizationCorrect(localization) {
  return (
    localization?.attributes?.locale === PRIMARY_LOCALE &&
    localization?.attributes?.name === GROUP_LOCALIZED_NAME &&
    localization?.attributes?.customAppName === GROUP_CUSTOM_APP_NAME
  );
}

function isSubscriptionLocalizationCorrect(localization, definition) {
  return (
    localization?.attributes?.locale === PRIMARY_LOCALE &&
    localization?.attributes?.name === definition.localizedName &&
    localization?.attributes?.description === definition.description
  );
}

async function inspectLegacySubscriptionGroupLocalization(group, report) {
  if (!group) {
    report.subscriptionGroupLocalization = {
      state: 'blocked-until-group-exists',
      apiVersion: 'legacy-v1',
      preserved: true,
    };
    return;
  }
  const rows = await listAll(
    `/v1/subscriptionGroups/${group.id}/subscriptionGroupLocalizations?limit=50`,
  );
  const localization = rows.find(
    (row) => row.attributes?.locale === PRIMARY_LOCALE,
  );
  report.subscriptionGroupLocalization = {
    state: localization ? 'existing-preserved' : 'missing',
    apiVersion: 'legacy-v1',
    preserved: true,
    ...summarizeLocalization(localization),
  };
}

async function ensureSubscriptionGroupVersionMetadata(group, report) {
  if (!group) {
    report.subscriptionGroupVersionMetadata = {
      state: 'blocked-until-group-exists',
      ready: false,
      groupId: null,
      versions: [],
    };
    return;
  }

  const versions = await listAll(
    `/v1/subscriptionGroups/${group.id}/versions?limit=200`,
  );
  const inspected = [];
  for (const version of versions) {
    const localizations = await listAll(
      `/v1/subscriptionGroupVersions/${version.id}/localizations?limit=50`,
    );
    inspected.push({ version, localizations });
  }
  inspected.sort(newestVersion);

  let selected = inspected.find(
    ({ version, localizations }) =>
      ['PREPARE_FOR_SUBMISSION', 'READY_FOR_REVIEW'].includes(
        version.attributes?.state,
      ) && localizations.some(isGroupLocalizationCorrect),
  );
  let state = selected ? 'existing-correct-version' : 'missing-correct-version';

  if (!selected) {
    selected = inspected.find(
      ({ version }) =>
        version.attributes?.state === 'PREPARE_FOR_SUBMISSION',
    );
    if (selected) state = 'existing-draft';
  }

  if (!selected && mode === 'apply') {
    const result = await request('/v1/subscriptionGroupVersions', {
      method: 'POST',
      body: {
        data: {
          type: 'subscriptionGroupVersions',
          relationships: {
            subscriptionGroup: {
              data: { type: 'subscriptionGroups', id: group.id },
            },
          },
        },
      },
    });
    selected = { version: result.data, localizations: [] };
    inspected.unshift(selected);
    state = 'created-draft';
  }

  let localization =
    selected?.localizations.find(isGroupLocalizationCorrect) ||
    selected?.localizations.find(
      (row) => row.attributes?.locale === PRIMARY_LOCALE,
    );
  if (
    selected &&
    selected.version.attributes?.state === 'PREPARE_FOR_SUBMISSION' &&
    mode === 'apply'
  ) {
    if (!localization) {
      const result = await request('/v2/subscriptionGroupLocalizations', {
        method: 'POST',
        body: {
          data: {
            type: 'subscriptionGroupLocalizations',
            attributes: {
              locale: PRIMARY_LOCALE,
              name: GROUP_LOCALIZED_NAME,
              customAppName: GROUP_CUSTOM_APP_NAME,
            },
            relationships: {
              version: {
                data: {
                  type: 'subscriptionGroupVersions',
                  id: selected.version.id,
                },
              },
            },
          },
        },
      });
      localization = result.data;
      selected.localizations.push(localization);
      state = state === 'created-draft' ? state : 'created-localization';
    } else if (!isGroupLocalizationCorrect(localization)) {
      const result = await request(
        `/v2/subscriptionGroupLocalizations/${localization.id}`,
        {
          method: 'PATCH',
          body: {
            data: {
              type: 'subscriptionGroupLocalizations',
              id: localization.id,
              attributes: {
                name: GROUP_LOCALIZED_NAME,
                customAppName: GROUP_CUSTOM_APP_NAME,
              },
            },
          },
        },
      );
      localization = result.data;
      const index = selected.localizations.findIndex(
        (row) => row.id === localization.id,
      );
      if (index >= 0) {
        selected.localizations[index] = localization;
      } else {
        selected.localizations.push(localization);
      }
      state = 'updated-localization';
    }
  }

  const ready = Boolean(
    selected &&
      ['PREPARE_FOR_SUBMISSION', 'READY_FOR_REVIEW'].includes(
        selected.version.attributes?.state,
      ) &&
      selected.localizations.some(isGroupLocalizationCorrect),
  );
  report.subscriptionGroupVersionMetadata = {
    state,
    ready,
    groupId: group.id,
    selectedVersionId: selected?.version.id ?? null,
    selectedVersion: selected?.version.attributes?.version ?? null,
    selectedVersionState: selected?.version.attributes?.state ?? null,
    localization: summarizeLocalization(localization),
    versionCount: inspected.length,
    versions: inspected.map(({ version, localizations }) =>
      summarizeVersion(version, localizations, isGroupLocalizationCorrect),
    ),
  };
}

async function inspectLegacySubscriptionLocalization(subscription, definition) {
  const rows = await listAll(
    `/v1/subscriptions/${subscription.id}/subscriptionLocalizations?limit=50`,
  );
  const localization = rows.find(
    (row) => row.attributes?.locale === PRIMARY_LOCALE,
  );
  return {
    state: localization ? 'existing-preserved' : 'missing',
    apiVersion: 'legacy-v1',
    preserved: true,
    expectedMetadataMatches: isSubscriptionLocalizationCorrect(
      localization,
      definition,
    ),
    ...summarizeLocalization(localization),
  };
}

async function ensureSubscriptionVersionMetadata(subscription, definition) {
  const versions = await listAll(
    `/v1/subscriptions/${subscription.id}/versions?limit=200`,
  );
  const inspected = [];
  for (const version of versions) {
    const localizations = await listAll(
      `/v1/subscriptionVersions/${version.id}/localizations?limit=50`,
    );
    inspected.push({ version, localizations });
  }
  inspected.sort(newestVersion);

  let selected = inspected.find(
    ({ version, localizations }) =>
      ['PREPARE_FOR_SUBMISSION', 'READY_FOR_REVIEW'].includes(
        version.attributes?.state,
      ) &&
      localizations.some((localization) =>
        isSubscriptionLocalizationCorrect(localization, definition),
      ),
  );
  let state = selected ? 'existing-correct-version' : 'missing-correct-version';

  if (!selected) {
    selected = inspected.find(
      ({ version }) =>
        version.attributes?.state === 'PREPARE_FOR_SUBMISSION',
    );
    if (selected) state = 'existing-draft';
  }

  if (!selected && mode === 'apply') {
    const result = await request('/v1/subscriptionVersions', {
      method: 'POST',
      body: {
        data: {
          type: 'subscriptionVersions',
          relationships: {
            subscription: {
              data: { type: 'subscriptions', id: subscription.id },
            },
          },
        },
      },
    });
    selected = { version: result.data, localizations: [] };
    inspected.unshift(selected);
    state = 'created-draft';
  }

  let localization =
    selected?.localizations.find((row) =>
      isSubscriptionLocalizationCorrect(row, definition),
    ) ||
    selected?.localizations.find(
      (row) => row.attributes?.locale === PRIMARY_LOCALE,
    );
  if (
    selected &&
    selected.version.attributes?.state === 'PREPARE_FOR_SUBMISSION' &&
    mode === 'apply'
  ) {
    if (!localization) {
      const result = await request('/v2/subscriptionLocalizations', {
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
              version: {
                data: {
                  type: 'subscriptionVersions',
                  id: selected.version.id,
                },
              },
            },
          },
        },
      });
      localization = result.data;
      selected.localizations.push(localization);
      state = state === 'created-draft' ? state : 'created-localization';
    } else if (!isSubscriptionLocalizationCorrect(localization, definition)) {
      const result = await request(
        `/v2/subscriptionLocalizations/${localization.id}`,
        {
          method: 'PATCH',
          body: {
            data: {
              type: 'subscriptionLocalizations',
              id: localization.id,
              attributes: {
                name: definition.localizedName,
                description: definition.description,
              },
            },
          },
        },
      );
      localization = result.data;
      const index = selected.localizations.findIndex(
        (row) => row.id === localization.id,
      );
      if (index >= 0) {
        selected.localizations[index] = localization;
      } else {
        selected.localizations.push(localization);
      }
      state = 'updated-localization';
    }
  }

  const ready = Boolean(
    selected &&
      ['PREPARE_FOR_SUBMISSION', 'READY_FOR_REVIEW'].includes(
        selected.version.attributes?.state,
      ) &&
      selected.localizations.some((row) =>
        isSubscriptionLocalizationCorrect(row, definition),
      ),
  );
  return {
    state,
    ready,
    subscriptionId: subscription.id,
    selectedVersionId: selected?.version.id ?? null,
    selectedVersion: selected?.version.attributes?.version ?? null,
    selectedVersionState: selected?.version.attributes?.state ?? null,
    localization: summarizeLocalization(localization),
    versionCount: inspected.length,
    versions: inspected.map(({ version, localizations }) =>
      summarizeVersion(version, localizations, (row) =>
        isSubscriptionLocalizationCorrect(row, definition),
      ),
    ),
  };
}

async function ensureSubscriptionReviewMetadata(subscription, definition) {
  const attributes = subscription.attributes || {};
  const needsUpdate =
    attributes.reviewNote !== SUBSCRIPTION_REVIEW_NOTE ||
    attributes.familySharable !== false ||
    attributes.groupLevel !== definition.groupLevel;
  if (mode !== 'apply' || !needsUpdate) return subscription;
  const result = await request(`/v1/subscriptions/${subscription.id}`, {
    method: 'PATCH',
    body: {
      data: {
        type: 'subscriptions',
        id: subscription.id,
        attributes: {
          name: definition.name,
          familySharable: false,
          reviewNote: SUBSCRIPTION_REVIEW_NOTE,
          groupLevel: definition.groupLevel,
        },
      },
    },
  });
  return result.data;
}

function sameTerritorySet(left, right) {
  return (
    left.length === right.length &&
    left.every((territory, index) => territory === right[index])
  );
}

async function ensureSubscriptionPlanAvailability(subscription) {
  const planAvailabilities = await listAll(
    `/v1/subscriptions/${subscription.id}/planAvailabilities?limit=200`,
  );
  const matching = planAvailabilities.filter(
    (row) => row.attributes?.planType === SUBSCRIPTION_PLAN_TYPE,
  );
  if (matching.length > 1) {
    throw new Error(
      `Apple returned ${matching.length} ${SUBSCRIPTION_PLAN_TYPE} plan availabilities for subscription ${subscription.id}`,
    );
  }

  let availability = matching[0] || null;
  let state = availability ? 'existing' : 'missing';
  let availableTerritoryIds = availability
    ? (
        await listAll(
          `/v1/subscriptionPlanAvailabilities/${encodeURIComponent(availability.id)}/availableTerritories?limit=200`,
        )
      )
        .map((row) => row.id)
        .sort()
    : [];
  const requestedTerritoryIds = [...APP_STORE_TERRITORIES].sort();
  const configuredPlanTypes = new Set(
    planAvailabilities
      .map((row) => row.attributes?.planType)
      .filter(Boolean),
  );

  if (mode === 'apply' && applyPrices) {
    if (!availability) {
      const result = await request('/v1/subscriptionPlanAvailabilities', {
        method: 'POST',
        body: {
          data: {
            type: 'subscriptionPlanAvailabilities',
            attributes: {
              planType: SUBSCRIPTION_PLAN_TYPE,
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
      configuredPlanTypes.add(SUBSCRIPTION_PLAN_TYPE);
      availableTerritoryIds = requestedTerritoryIds;
      state = 'created';
    } else {
      let updated = false;
      if (availability.attributes?.availableInNewTerritories !== false) {
        const result = await request(
          `/v1/subscriptionPlanAvailabilities/${encodeURIComponent(availability.id)}`,
          {
            method: 'PATCH',
            body: {
              data: {
                type: 'subscriptionPlanAvailabilities',
                id: availability.id,
                attributes: {
                  availableInNewTerritories: false,
                },
              },
            },
          },
        );
        availability = result.data;
        updated = true;
      }
      if (!sameTerritorySet(availableTerritoryIds, requestedTerritoryIds)) {
        await request(
          `/v1/subscriptionPlanAvailabilities/${encodeURIComponent(availability.id)}/relationships/availableTerritories`,
          {
            method: 'PATCH',
            body: {
              data: APP_STORE_TERRITORIES.map((id) => ({
                type: 'territories',
                id,
              })),
            },
          },
        );
        availableTerritoryIds = requestedTerritoryIds;
        updated = true;
      }
      if (updated) state = 'updated';
    }
  }

  const missingTerritoryIds = requestedTerritoryIds.filter(
    (id) => !availableTerritoryIds.includes(id),
  );
  const unexpectedTerritoryIds = availableTerritoryIds.filter(
    (id) => !requestedTerritoryIds.includes(id),
  );
  return {
    state,
    resourceType: 'subscriptionPlanAvailabilities',
    planType: availability?.attributes?.planType ?? SUBSCRIPTION_PLAN_TYPE,
    availableInNewTerritories:
      availability?.attributes?.availableInNewTerritories ?? null,
    requestedTerritoryIds,
    territoryIds: availableTerritoryIds,
    missingTerritoryIds,
    unexpectedTerritoryIds,
    exactTerritoryMatch:
      missingTerritoryIds.length === 0 && unexpectedTerritoryIds.length === 0,
    qatarAvailable: availableTerritoryIds.includes('QAT'),
    configuredPlanTypes: [...configuredPlanTypes].sort(),
  };
}

function samePrice(left, right) {
  return Number(left) === Number(right);
}

async function existingPricesByTerritory(subscription) {
  const rows = await listAll(
    `/v1/subscriptions/${subscription.id}/prices?filter[planType]=${SUBSCRIPTION_PLAN_TYPE}` +
      `&filter[territory]=${APP_STORE_TERRITORIES.join(',')}` +
      '&include=subscriptionPricePoint,territory&limit=200',
  );
  const prices = new Map();
  for (const row of rows) {
    const territory = row.relationships?.territory?.data?.id;
    if (
      row.attributes?.planType === SUBSCRIPTION_PLAN_TYPE &&
      territory &&
      !prices.has(territory)
    ) {
      prices.set(territory, row);
    }
  }
  return prices;
}

async function inspectExistingPrices(subscription) {
  const response = await request(
    `/v1/subscriptions/${subscription.id}/prices?filter[planType]=${SUBSCRIPTION_PLAN_TYPE}` +
      `&filter[territory]=${APP_STORE_TERRITORIES.join(',')}` +
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
        planType: row.attributes?.planType ?? null,
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
      planType: SUBSCRIPTION_PLAN_TYPE,
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
        planType: current.attributes?.planType ?? null,
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
            planType: SUBSCRIPTION_PLAN_TYPE,
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
      planType: SUBSCRIPTION_PLAN_TYPE,
      customerPrice: point.attributes?.customerPrice,
    };
  }
  return {
    state: 'applied',
    pricingMode: 'upfront-auto-renewable',
    planType: SUBSCRIPTION_PLAN_TYPE,
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
      subscriptionId: null,
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
    if (subscription) {
      subscription = await ensureSubscriptionReviewMetadata(
        subscription,
        definition,
      );
    }
    const localization = subscription
      ? await inspectLegacySubscriptionLocalization(subscription, definition)
      : {
          state: 'blocked-until-subscription-exists',
          apiVersion: 'legacy-v1',
          preserved: true,
        };
    const versionMetadata = subscription
      ? await ensureSubscriptionVersionMetadata(subscription, definition)
      : {
          state: 'blocked-until-subscription-exists',
          ready: false,
          versions: [],
        };
    const availability = subscription
      ? await ensureSubscriptionPlanAvailability(subscription)
      : 'blocked-until-subscription-exists';
    const pricing = subscription
      ? await ensureApprovedPrices(subscription, definition)
      : { state: 'blocked-until-subscription-exists' };
    const reviewScreenshot = subscription
      ? await uploadReviewScreenshot(subscription)
      : { state: 'blocked-until-subscription-exists' };
    const refreshedSubscription = subscription
      ? (await request(`/v1/subscriptions/${subscription.id}`)).data
      : null;
    report.subscriptions.push({
      productId: definition.productId,
      subscriptionId: refreshedSubscription?.id ?? subscription?.id ?? null,
      state,
      reviewState: refreshedSubscription?.attributes?.state ?? null,
      subscriptionPeriod:
        refreshedSubscription?.attributes?.subscriptionPeriod ?? null,
      groupLevel: refreshedSubscription?.attributes?.groupLevel ?? null,
      familySharable:
        refreshedSubscription?.attributes?.familySharable ?? null,
      hasReviewNote: Boolean(
        refreshedSubscription?.attributes?.reviewNote?.trim(),
      ),
      localization,
      versionMetadata,
      availability,
      intendedPriceSar: definition.intendedPriceSar,
      pricing,
      reviewScreenshot,
    });
  }
}

function relatedResourceId(item, relationshipName) {
  const relationship = item.relationships?.[relationshipName]?.data;
  return relationship && !Array.isArray(relationship)
    ? relationship.id ?? null
    : null;
}

function currentReviewVersionIds(report) {
  return {
    groupVersionId:
      report.subscriptionGroupVersionMetadata?.ready === true
        ? report.subscriptionGroupVersionMetadata.selectedVersionId ?? null
        : null,
    subscriptionVersionIds: report.subscriptions
      .filter((subscription) => subscription.versionMetadata?.ready === true)
      .map((subscription) => subscription.versionMetadata.selectedVersionId)
      .filter(Boolean),
  };
}

async function inspectReadyReviewDrafts(app, report) {
  const { groupVersionId, subscriptionVersionIds } =
    currentReviewVersionIds(report);
  const expectedSubscriptionVersionIds = new Set(subscriptionVersionIds);
  if (!app) {
    return {
      state: 'blocked-until-app-exists',
      currentGroupVersionId: groupVersionId,
      configuredSubscriptionVersionCount: subscriptionVersionIds.length,
      requiredSubscriptionVersionCount: productDefinitions.length,
      readySubmissionCount: 0,
      matchingDraftCount: 0,
      readySubscriptionVersionCount: 0,
      drafts: [],
    };
  }

  const submissions = await listAll(
    `/v1/apps/${app.id}/reviewSubmissions?filter[state]=READY_FOR_REVIEW&filter[platform]=IOS&limit=200`,
  );
  const drafts = [];
  for (const submission of submissions) {
    const items = await listAll(
      `/v1/reviewSubmissions/${submission.id}/items?fields[reviewSubmissionItems]=state,subscriptionVersion,subscriptionGroupVersion&include=subscriptionVersion,subscriptionGroupVersion&limit=200`,
    );
    const summarizedItems = items.map((item) => ({
      id: item.id,
      state: item.attributes?.state ?? null,
      subscriptionVersionId: relatedResourceId(item, 'subscriptionVersion'),
      subscriptionGroupVersionId: relatedResourceId(
        item,
        'subscriptionGroupVersion',
      ),
      relationshipTypes: Object.entries(item.relationships || {})
        .filter(([, relationship]) => relationship?.data)
        .map(([name]) => name),
    }));
    const currentSubscriptionItems = summarizedItems.filter(
      (item) =>
        item.subscriptionVersionId &&
        expectedSubscriptionVersionIds.has(item.subscriptionVersionId),
    );
    drafts.push({
      id: submission.id,
      platform: submission.attributes?.platform ?? null,
      state: submission.attributes?.state ?? null,
      itemCount: summarizedItems.length,
      readyItemCount: summarizedItems.filter(
        (item) => item.state === 'READY_FOR_REVIEW',
      ).length,
      containsCurrentGroupVersion: summarizedItems.some(
        (item) =>
          groupVersionId &&
          item.subscriptionGroupVersionId === groupVersionId,
      ),
      currentSubscriptionVersionItemCount: currentSubscriptionItems.length,
      currentSubscriptionVersionReadyCount: currentSubscriptionItems.filter(
        (item) => item.state === 'READY_FOR_REVIEW',
      ).length,
      subscriptionVersionIds: summarizedItems
        .map((item) => item.subscriptionVersionId)
        .filter(Boolean),
      subscriptionGroupVersionIds: summarizedItems
        .map((item) => item.subscriptionGroupVersionId)
        .filter(Boolean),
      items: summarizedItems,
    });
  }

  const matchingDrafts = drafts.filter(
    (draft) => draft.containsCurrentGroupVersion,
  );
  return {
    state: 'inspected',
    currentGroupVersionId: groupVersionId,
    configuredSubscriptionVersionCount: subscriptionVersionIds.length,
    requiredSubscriptionVersionCount: productDefinitions.length,
    readySubmissionCount: submissions.length,
    matchingDraftCount: matchingDrafts.length,
    readySubscriptionVersionCount:
      matchingDrafts.length === 1
        ? matchingDrafts[0].currentSubscriptionVersionReadyCount
        : 0,
    drafts,
  };
}

async function inspectReviewDrafts(app, report) {
  const inspection = await inspectReadyReviewDrafts(app, report);
  report.reviewDraft = {
    mutationRequested: addSubscriptionsToReviewDraft,
    mutationAttempted: false,
    mutationState: addSubscriptionsToReviewDraft
      ? 'pending-validation'
      : 'not-requested',
    addedSubscriptionVersionIds: [],
    before: inspection,
    after: inspection,
    readySubmissionCount: inspection.readySubmissionCount,
    matchingDraftCount: inspection.matchingDraftCount,
    readySubscriptionVersionCount: inspection.readySubscriptionVersionCount,
  };
}

async function addReadySubscriptionsToReviewDraft(app, report) {
  if (!addSubscriptionsToReviewDraft) return;
  if (mode !== 'apply') {
    report.reviewDraft.mutationState = 'refused-requires-apply-mode';
    throw new Error(
      '--add-subscriptions-to-review-draft requires --apply',
    );
  }

  const { groupVersionId, subscriptionVersionIds } =
    currentReviewVersionIds(report);
  const uniqueSubscriptionVersionIds = [...new Set(subscriptionVersionIds)];
  if (
    !app ||
    !groupVersionId ||
    uniqueSubscriptionVersionIds.length !== productDefinitions.length
  ) {
    report.reviewDraft.mutationState = 'refused-incomplete-current-versions';
    throw new Error(
      'Review draft mutation requires one ready current group version and all six ready current subscription versions',
    );
  }

  const matchingDrafts = report.reviewDraft.before.drafts.filter(
    (draft) => draft.containsCurrentGroupVersion,
  );
  if (matchingDrafts.length !== 1) {
    report.reviewDraft.mutationState = 'refused-ambiguous-review-draft';
    throw new Error(
      `Expected exactly one READY_FOR_REVIEW iOS draft containing the current subscription group version; found ${matchingDrafts.length}`,
    );
  }

  const reviewDraft = matchingDrafts[0];
  const existingSubscriptionVersionIds = new Set(
    reviewDraft.subscriptionVersionIds,
  );
  const missingSubscriptionVersionIds = uniqueSubscriptionVersionIds.filter(
    (versionId) => !existingSubscriptionVersionIds.has(versionId),
  );
  report.reviewDraft.mutationAttempted = true;
  report.reviewDraft.mutationState =
    missingSubscriptionVersionIds.length === 0
      ? 'already-complete'
      : 'adding-missing-subscriptions';
  report.reviewDraft.selectedDraftId = reviewDraft.id;
  report.reviewDraft.missingSubscriptionVersionIds =
    missingSubscriptionVersionIds;

  let mutationError = null;
  for (const subscriptionVersionId of missingSubscriptionVersionIds) {
    try {
      await request('/v1/reviewSubmissionItems', {
        method: 'POST',
        body: {
          data: {
            type: 'reviewSubmissionItems',
            relationships: {
              reviewSubmission: {
                data: { type: 'reviewSubmissions', id: reviewDraft.id },
              },
              subscriptionVersion: {
                data: {
                  type: 'subscriptionVersions',
                  id: subscriptionVersionId,
                },
              },
            },
          },
        },
      });
      report.reviewDraft.addedSubscriptionVersionIds.push(
        subscriptionVersionId,
      );
    } catch (error) {
      mutationError = error;
      break;
    }
  }

  const after = await inspectReadyReviewDrafts(app, report);
  report.reviewDraft.after = after;
  report.reviewDraft.readySubmissionCount = after.readySubmissionCount;
  report.reviewDraft.matchingDraftCount = after.matchingDraftCount;
  report.reviewDraft.readySubscriptionVersionCount =
    after.readySubscriptionVersionCount;

  if (mutationError) {
    report.reviewDraft.mutationState = 'failed-after-partial-reinspection';
    throw mutationError;
  }

  const selectedAfter = after.drafts.filter(
    (draft) => draft.containsCurrentGroupVersion,
  );
  if (
    selectedAfter.length !== 1 ||
    selectedAfter[0].currentSubscriptionVersionItemCount !==
      productDefinitions.length ||
    selectedAfter[0].currentSubscriptionVersionReadyCount !==
      productDefinitions.length
  ) {
    report.reviewDraft.mutationState = 'failed-postcondition';
    throw new Error(
      `Review draft contains ${after.readySubscriptionVersionCount} of ${productDefinitions.length} ready current subscription versions after mutation`,
    );
  }
  report.reviewDraft.mutationState =
    missingSubscriptionVersionIds.length === 0
      ? 'already-complete'
      : 'added-and-reinspected';
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
    subscriptionPlanType: SUBSCRIPTION_PLAN_TYPE,
    planAvailabilityTerritories: APP_STORE_TERRITORIES,
    planAvailabilityScope: 'exact-gulf-only',
    planAvailabilityRequested: mode === 'apply' && applyPrices,
    addSubscriptionsToReviewDraftRequested:
      addSubscriptionsToReviewDraft,
    planAvailabilityReady: false,
    planAvailabilityConfiguredProductCount: 0,
    catalogMetadataApiVersion: '4.4.1-version-based-v2',
    catalogMetadataReady: false,
    catalogMetadataConfiguredProductCount: 0,
    availableInNewTerritories: false,
    pricingNote:
      applyPrices
        ? 'UPFRONT availability and approved SAR anchor prices with Apple-equalized Gulf price points were requested in this run.'
        : 'UPFRONT availability and approved prices are inspected but not modified in this run.',
  };

  try {
    const bundleId = await ensureBundleId(report);
    await inspectBundleIdCapabilities(bundleId, report);
    await inspectProvisioningProfiles(bundleId, report);
    const app = await ensureApp(report);
    await inspectBuilds(app, report);
    await ensureInternalBetaGroup(app, report);
    const group = await ensureSubscriptionGroup(app, report);
    await inspectLegacySubscriptionGroupLocalization(group, report);
    await ensureSubscriptionGroupVersionMetadata(group, report);
    await ensureSubscriptions(group, report);
    await inspectReviewDrafts(app, report);
    const configuredVersionMetadata = report.subscriptions.filter(
      (subscription) => subscription.versionMetadata?.ready === true,
    );
    report.catalogMetadataConfiguredProductCount =
      configuredVersionMetadata.length;
    report.catalogMetadataReady =
      report.subscriptionGroupVersionMetadata?.ready === true &&
      report.subscriptions.length === productDefinitions.length &&
      configuredVersionMetadata.length === productDefinitions.length;
    report.catalogMetadataNote = report.catalogMetadataReady
      ? 'The subscription group and all six subscriptions have exact Arabic metadata on reusable PREPARE_FOR_SUBMISSION or READY_FOR_REVIEW versions.'
      : `${configuredVersionMetadata.length} of ${productDefinitions.length} subscriptions have exact version-based metadata; group ready: ${report.subscriptionGroupVersionMetadata?.ready === true}.`;
    if (mode === 'apply' && !report.catalogMetadataReady) {
      throw new Error(
        'One or more subscriptions are missing exact App Store Connect 4.4.1 version-based metadata',
      );
    }
    const configuredPlanAvailabilities = report.subscriptions.filter(
      (subscription) =>
        subscription.availability?.planType === SUBSCRIPTION_PLAN_TYPE &&
        subscription.availability?.availableInNewTerritories === false &&
        subscription.availability?.exactTerritoryMatch === true,
    );
    report.planAvailabilityConfiguredProductCount =
      configuredPlanAvailabilities.length;
    report.planAvailabilityReady =
      report.subscriptions.length === productDefinitions.length &&
      configuredPlanAvailabilities.length === productDefinitions.length;
    report.planAvailabilityNote = report.planAvailabilityReady
      ? 'All six subscriptions use UPFRONT availability in exactly the six configured Gulf territories.'
      : `${configuredPlanAvailabilities.length} of ${productDefinitions.length} subscriptions have exact UPFRONT Gulf availability.`;
    if (mode === 'apply' && applyPrices && !report.planAvailabilityReady) {
      throw new Error(
        'One or more subscriptions are missing exact UPFRONT Gulf plan availability',
      );
    }
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
    await addReadySubscriptionsToReviewDraft(app, report);
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
