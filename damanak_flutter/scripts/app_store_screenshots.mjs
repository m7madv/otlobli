#!/usr/bin/env node

import { createHash, createPrivateKey, sign } from 'node:crypto';
import {
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  writeFileSync,
} from 'node:fs';
import { basename, dirname, join, resolve } from 'node:path';

const API_ROOT = 'https://api.appstoreconnect.apple.com';
const BUNDLE_ID = 'com.damanak.damanak';
const RELEASE_VERSION = '4.5.0';
const PRIMARY_LOCALE = 'ar-SA';

const mode = process.argv.includes('--apply') ? 'apply' : 'inspect';
const outputIndex = process.argv.indexOf('--output');
const outputPath = resolve(
  outputIndex >= 0 && process.argv[outputIndex + 1]
    ? process.argv[outputIndex + 1]
    : 'build/app-store-assets/report.json',
);

const screenshotDefinitions = [
  {
    displayType: 'APP_IPHONE_65',
    label: 'iPhone 6.5-inch',
    directory: resolve('app_store_assets/ios/iphone-1284x2778'),
    width: 1284,
    height: 2778,
  },
  {
    displayType: 'APP_IPAD_PRO_3GEN_129',
    label: 'iPad 13-inch',
    directory: resolve('app_store_assets/ios/ipad-2048x2732'),
    width: 2048,
    height: 2732,
  },
];

const requiredEnvironment = [
  'APP_STORE_CONNECT_API_KEY_ID',
  'APP_STORE_CONNECT_ISSUER_ID',
  'APP_STORE_CONNECT_API_KEY_BASE64',
];

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

function summarizeApiError(body, status) {
  const errors = Array.isArray(body?.errors) ? body.errors : [];
  if (errors.length === 0) {
    return `App Store Connect request failed (${status})`;
  }
  return errors
    .map((error) => {
      const code = error?.code ? ` [${error.code}]` : '';
      const pointer = error?.source?.pointer
        ? ` (${error.source.pointer})`
        : '';
      return `${error?.detail || error?.title || 'Unknown error'}${code}${pointer}`;
    })
    .join('; ');
}

let token;

async function request(pathOrUrl, { method = 'GET', body } = {}) {
  for (let attempt = 0; attempt < 6; attempt += 1) {
    const url = pathOrUrl.startsWith('http')
      ? pathOrUrl
      : `${API_ROOT}${pathOrUrl}`;
    const response = await fetch(url, {
      method,
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: 'application/json',
        ...(body ? { 'Content-Type': 'application/json' } : {}),
      },
      ...(body ? { body: JSON.stringify(body) } : {}),
    });
    const responseText = await response.text();
    let parsed = {};
    if (responseText) {
      try {
        parsed = JSON.parse(responseText);
      } catch {
        parsed = {};
      }
    }
    if (response.ok) return parsed;

    if (response.status === 401 && attempt === 0) {
      token = createToken();
      continue;
    }
    const retryable = response.status === 429 || response.status >= 500;
    if (retryable && attempt < 5) {
      const retryAfter = Number(response.headers.get('retry-after'));
      const waitMilliseconds = Number.isFinite(retryAfter)
        ? retryAfter * 1000
        : Math.min(1000 * 2 ** attempt, 15000);
      await new Promise((resolveWait) =>
        setTimeout(resolveWait, waitMilliseconds),
      );
      continue;
    }

    const error = new Error(summarizeApiError(parsed, response.status));
    error.status = response.status;
    throw error;
  }
  throw new Error('App Store Connect request retries were exhausted');
}

async function listAll(path) {
  const rows = [];
  let next = path;
  while (next) {
    const page = await request(next);
    rows.push(...(page.data || []));
    next = page.links?.next || null;
  }
  return rows;
}

function readPngDimensions(buffer) {
  const pngSignature = '89504e470d0a1a0a';
  if (buffer.length < 24 || buffer.subarray(0, 8).toString('hex') !== pngSignature) {
    throw new Error('Only valid PNG screenshots are accepted');
  }
  return {
    width: buffer.readUInt32BE(16),
    height: buffer.readUInt32BE(20),
  };
}

function loadLocalScreenshots(definition) {
  if (!existsSync(definition.directory)) {
    throw new Error(`Missing screenshot directory: ${definition.directory}`);
  }
  const paths = readdirSync(definition.directory)
    .filter((fileName) => fileName.toLowerCase().endsWith('.png'))
    .sort((left, right) => left.localeCompare(right, 'en'))
    .map((fileName) => join(definition.directory, fileName));
  if (paths.length !== 5) {
    throw new Error(
      `${definition.label} requires exactly 5 PNG files; found ${paths.length}`,
    );
  }
  return paths.map((path) => {
    const file = readFileSync(path);
    const dimensions = readPngDimensions(file);
    if (
      dimensions.width !== definition.width ||
      dimensions.height !== definition.height
    ) {
      throw new Error(
        `${basename(path)} is ${dimensions.width}x${dimensions.height}; expected ${definition.width}x${definition.height}`,
      );
    }
    return {
      path,
      file,
      fileName: basename(path),
      fileSize: file.length,
      md5: createHash('md5').update(file).digest('hex'),
      sha256: createHash('sha256').update(file).digest('hex'),
      ...dimensions,
    };
  });
}

async function waitForScreenshot(screenshotId) {
  for (let attempt = 0; attempt < 60; attempt += 1) {
    const result = await request(`/v1/appScreenshots/${screenshotId}`);
    const screenshot = result.data;
    const delivery = screenshot?.attributes?.assetDeliveryState;
    if (delivery?.state === 'COMPLETE') return screenshot;
    if (delivery?.state === 'FAILED') {
      const details = (delivery.errors || [])
        .map((error) => error.message || error.description || error.code)
        .filter(Boolean)
        .join('; ');
      throw new Error(
        `Apple rejected ${screenshot?.attributes?.fileName || screenshotId}${details ? `: ${details}` : ''}`,
      );
    }
    await new Promise((resolveWait) => setTimeout(resolveWait, 2000));
  }
  throw new Error(`Apple did not finish processing screenshot ${screenshotId}`);
}

async function uploadScreenshot(screenshotSetId, localScreenshot) {
  const reservation = await request('/v1/appScreenshots', {
    method: 'POST',
    body: {
      data: {
        type: 'appScreenshots',
        attributes: {
          fileName: localScreenshot.fileName,
          fileSize: localScreenshot.fileSize,
        },
        relationships: {
          appScreenshotSet: {
            data: { type: 'appScreenshotSets', id: screenshotSetId },
          },
        },
      },
    },
  });
  const screenshot = reservation.data;
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
      body: localScreenshot.file.subarray(offset, offset + length),
    });
    if (!response.ok) {
      throw new Error(
        `Apple upload failed for ${localScreenshot.fileName} (${response.status})`,
      );
    }
  }

  await request(`/v1/appScreenshots/${screenshot.id}`, {
    method: 'PATCH',
    body: {
      data: {
        type: 'appScreenshots',
        id: screenshot.id,
        attributes: {
          uploaded: true,
          sourceFileChecksum: localScreenshot.md5,
        },
      },
    },
  });
  const completed = await waitForScreenshot(screenshot.id);
  return {
    id: screenshot.id,
    fileName: localScreenshot.fileName,
    fileSize: localScreenshot.fileSize,
    sha256: localScreenshot.sha256,
    deliveryState: completed.attributes?.assetDeliveryState?.state,
  };
}

async function findAppAndLocalization(report) {
  const apps = await listAll(
    `/v1/apps?filter[bundleId]=${encodeURIComponent(BUNDLE_ID)}&limit=10`,
  );
  const app = apps.find((row) => row.attributes?.bundleId === BUNDLE_ID);
  if (!app) throw new Error(`App not found for bundle ID ${BUNDLE_ID}`);

  const versions = await listAll(
    `/v1/apps/${app.id}/appStoreVersions?filter[platform]=IOS&limit=200`,
  );
  const version = versions.find(
    (row) => row.attributes?.versionString === RELEASE_VERSION,
  );
  if (!version) {
    throw new Error(`iOS App Store version ${RELEASE_VERSION} was not found`);
  }

  const localizations = await listAll(
    `/v1/appStoreVersions/${version.id}/appStoreVersionLocalizations?limit=200`,
  );
  const localization =
    localizations.find((row) => row.attributes?.locale === PRIMARY_LOCALE) ||
    localizations.find((row) => row.attributes?.locale?.startsWith('ar'));
  if (!localization) {
    throw new Error(`Arabic localization ${PRIMARY_LOCALE} was not found`);
  }

  report.app = {
    id: app.id,
    bundleId: app.attributes?.bundleId,
    name: app.attributes?.name,
  };
  report.version = {
    id: version.id,
    versionString: version.attributes?.versionString,
    appStoreState: version.attributes?.appStoreState,
  };
  report.localization = {
    id: localization.id,
    locale: localization.attributes?.locale,
  };
  return localization;
}

async function ensureScreenshotSet(localization, definition, localFiles) {
  const sets = await listAll(
    `/v1/appStoreVersionLocalizations/${localization.id}/appScreenshotSets?limit=200`,
  );
  let set = sets.find(
    (row) => row.attributes?.screenshotDisplayType === definition.displayType,
  );
  if (!set && mode === 'apply') {
    const created = await request('/v1/appScreenshotSets', {
      method: 'POST',
      body: {
        data: {
          type: 'appScreenshotSets',
          attributes: { screenshotDisplayType: definition.displayType },
          relationships: {
            appStoreVersionLocalization: {
              data: {
                type: 'appStoreVersionLocalizations',
                id: localization.id,
              },
            },
          },
        },
      },
    });
    set = created.data;
  }

  if (!set) {
    return {
      displayType: definition.displayType,
      label: definition.label,
      state: 'missing',
      localFiles: localFiles.map(({ fileName, fileSize, sha256 }) => ({
        fileName,
        fileSize,
        sha256,
      })),
    };
  }

  let existing = await listAll(
    `/v1/appScreenshotSets/${set.id}/appScreenshots?limit=200`,
  );
  const expectedNames = localFiles.map((file) => file.fileName);
  const existingNames = existing.map((row) => row.attributes?.fileName).sort();
  const namesMatch =
    existingNames.length === expectedNames.length &&
    existingNames.every((name, index) => name === [...expectedNames].sort()[index]);

  if (mode === 'inspect') {
    return {
      displayType: definition.displayType,
      label: definition.label,
      screenshotSetId: set.id,
      state: namesMatch ? 'complete-or-processing' : 'different',
      existingFiles: existing.map((row) => ({
        id: row.id,
        fileName: row.attributes?.fileName,
        deliveryState: row.attributes?.assetDeliveryState?.state,
      })),
      expectedFiles: expectedNames,
    };
  }

  if (namesMatch) {
    const completed = [];
    for (const row of existing) {
      const screenshot =
        row.attributes?.assetDeliveryState?.state === 'COMPLETE'
          ? row
          : await waitForScreenshot(row.id);
      completed.push({
        id: screenshot.id,
        fileName: screenshot.attributes?.fileName,
        deliveryState: screenshot.attributes?.assetDeliveryState?.state,
      });
    }
    return {
      displayType: definition.displayType,
      label: definition.label,
      screenshotSetId: set.id,
      state: 'existing',
      screenshots: completed,
    };
  }

  for (const row of existing) {
    await request(`/v1/appScreenshots/${row.id}`, { method: 'DELETE' });
  }
  existing = [];
  const uploaded = [];
  for (const localScreenshot of localFiles) {
    uploaded.push(await uploadScreenshot(set.id, localScreenshot));
  }
  return {
    displayType: definition.displayType,
    label: definition.label,
    screenshotSetId: set.id,
    state: 'uploaded',
    screenshots: uploaded,
  };
}

async function main() {
  for (const variable of requiredEnvironment) {
    if (!process.env[variable]) {
      throw new Error(`Missing required environment variable: ${variable}`);
    }
  }
  token = createToken();
  const report = {
    generatedAt: new Date().toISOString(),
    mode,
    bundleId: BUNDLE_ID,
    releaseVersion: RELEASE_VERSION,
    screenshotSets: [],
  };
  const localization = await findAppAndLocalization(report);
  for (const definition of screenshotDefinitions) {
    const localFiles = loadLocalScreenshots(definition);
    report.screenshotSets.push(
      await ensureScreenshotSet(localization, definition, localFiles),
    );
  }
  mkdirSync(dirname(outputPath), { recursive: true });
  writeFileSync(outputPath, `${JSON.stringify(report, null, 2)}\n`);
  console.log(JSON.stringify(report, null, 2));
}

main().catch((error) => {
  const failure = {
    generatedAt: new Date().toISOString(),
    mode,
    bundleId: BUNDLE_ID,
    releaseVersion: RELEASE_VERSION,
    error: error instanceof Error ? error.message : String(error),
  };
  mkdirSync(dirname(outputPath), { recursive: true });
  writeFileSync(outputPath, `${JSON.stringify(failure, null, 2)}\n`);
  console.error(failure.error);
  process.exitCode = 1;
});
