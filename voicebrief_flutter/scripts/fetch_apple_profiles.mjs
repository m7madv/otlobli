#!/usr/bin/env node

import { createPrivateKey, sign } from 'node:crypto';
import { chmodSync, mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

const API_ROOT = 'https://api.appstoreconnect.apple.com';
const APP_PROFILE_NAME = 'VoiceBrief App Store 2026';
const SHARE_PROFILE_NAME = 'VoiceBrief Share App Store 2026';
const APP_BUNDLE_ID = 'app.voicebrief.mobile';
const SHARE_BUNDLE_ID = 'app.voicebrief.mobile.share';

function argument(name, fallback) {
  const index = process.argv.indexOf(name);
  return resolve(index >= 0 && process.argv[index + 1] ? process.argv[index + 1] : fallback);
}

const appOutput = argument(
  '--app-output',
  'build/apple-profiles/voicebrief.mobileprovision',
);
const shareOutput = argument(
  '--share-output',
  'build/apple-profiles/voicebrief-share.mobileprovision',
);
const reportOutput = argument(
  '--report-output',
  'build/apple-profiles/report.json',
);

for (const variable of [
  'APP_STORE_CONNECT_API_KEY_ID',
  'APP_STORE_CONNECT_ISSUER_ID',
  'APP_STORE_CONNECT_API_KEY_BASE64',
]) {
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
  const privateKey = createPrivateKey(
    Buffer.from(
      process.env.APP_STORE_CONNECT_API_KEY_BASE64,
      'base64',
    ).toString('utf8'),
  );
  const signature = sign('sha256', Buffer.from(signingInput), {
    key: privateKey,
    dsaEncoding: 'ieee-p1363',
  }).toString('base64url');
  return `${signingInput}.${signature}`;
}

const token = createToken();

function apiError(body, status) {
  const errors = Array.isArray(body?.errors) ? body.errors : [];
  if (errors.length === 0) return `Apple request failed (${status})`;
  return errors
    .map((error) => error.detail || error.title || error.code || 'Unknown Apple error')
    .join('; ');
}

async function request(path) {
  const response = await fetch(`${API_ROOT}${path}`, {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/json',
    },
  });
  const text = await response.text();
  const body = text ? JSON.parse(text) : {};
  if (!response.ok) throw new Error(apiError(body, response.status));
  return body;
}

async function listAll(path) {
  const rows = [];
  let nextPath = path;
  while (nextPath) {
    const page = await request(nextPath);
    rows.push(...(page.data || []));
    const nextUrl = page.links?.next;
    nextPath = nextUrl
      ? `${new URL(nextUrl).pathname}${new URL(nextUrl).search}`
      : null;
  }
  return rows;
}

async function fetchProfile({ name, bundleIdentifier, output }) {
  const profiles = await listAll('/v1/profiles?limit=200');
  const candidates = profiles
    .filter(
      (profile) =>
        profile.attributes?.name === name &&
        profile.attributes?.profileType === 'IOS_APP_STORE' &&
        profile.attributes?.profileState === 'ACTIVE' &&
        Date.parse(profile.attributes?.expirationDate || '') > Date.now(),
    )
    .sort(
      (left, right) =>
        Date.parse(right.attributes.expirationDate) -
        Date.parse(left.attributes.expirationDate),
    );
  if (candidates.length === 0) {
    throw new Error(`No active App Store profile named ${name}`);
  }

  const profile = candidates[0];
  const bundle = await request(`/v1/profiles/${profile.id}/bundleId`);
  if (bundle.data?.attributes?.identifier !== bundleIdentifier) {
    throw new Error(`Profile ${name} is not assigned to ${bundleIdentifier}`);
  }
  const detail = await request(`/v1/profiles/${profile.id}`);
  const content = detail.data?.attributes?.profileContent;
  if (!content) throw new Error(`Apple returned no content for profile ${name}`);

  mkdirSync(dirname(output), { recursive: true });
  writeFileSync(output, content, 'base64');
  chmodSync(output, 0o600);
  return {
    name,
    bundleIdentifier,
    uuid: profile.attributes?.uuid,
    expirationDate: profile.attributes?.expirationDate,
  };
}

const report = {
  generatedAt: new Date().toISOString(),
  profiles: [
    await fetchProfile({
      name: APP_PROFILE_NAME,
      bundleIdentifier: APP_BUNDLE_ID,
      output: appOutput,
    }),
    await fetchProfile({
      name: SHARE_PROFILE_NAME,
      bundleIdentifier: SHARE_BUNDLE_ID,
      output: shareOutput,
    }),
  ],
};

mkdirSync(dirname(reportOutput), { recursive: true });
writeFileSync(reportOutput, `${JSON.stringify(report, null, 2)}\n`, 'utf8');
process.stdout.write('Fetched both active VoiceBrief App Store profiles.\n');
