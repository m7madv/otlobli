#!/usr/bin/env node

import { createPrivateKey, sign } from 'node:crypto';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { basename, dirname, resolve } from 'node:path';

const API_ROOT = 'https://androidpublisher.googleapis.com/androidpublisher/v3';
const UPLOAD_ROOT =
  'https://androidpublisher.googleapis.com/upload/androidpublisher/v3';
const TOKEN_URL = 'https://oauth2.googleapis.com/token';
const PACKAGE_NAME = 'com.damanak.damanak';

function argument(name, fallback = '') {
  const index = process.argv.indexOf(name);
  return index >= 0 && process.argv[index + 1]
    ? process.argv[index + 1]
    : fallback;
}

const aabPath = resolve(argument('--aab'));
const track = argument('--track', 'internal');
const outputPath = resolve(
  argument('--output', 'build/google-play-upload/report.json'),
);

function base64Url(value) {
  return Buffer.from(value).toString('base64url');
}

function readServiceAccount() {
  const raw = process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON;
  if (!raw) throw new Error('Missing GOOGLE_PLAY_SERVICE_ACCOUNT_JSON');
  const account = JSON.parse(raw);
  if (!account.client_email || !account.private_key) {
    throw new Error('Google Play service account is incomplete');
  }
  return account;
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

async function jsonRequest(accessToken, url, { method = 'GET', body } = {}) {
  const response = await fetch(url, {
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
    throw new Error(parsed?.error?.message || `Google Play request failed (${response.status})`);
  }
  return parsed;
}

async function uploadBundle(accessToken, editId) {
  const response = await fetch(
    `${UPLOAD_ROOT}/applications/${PACKAGE_NAME}/edits/${editId}/bundles?uploadType=media`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/octet-stream',
      },
      body: readFileSync(aabPath),
    },
  );
  const body = await response.json();
  if (!response.ok || !body.versionCode) {
    throw new Error(body?.error?.message || `AAB upload failed (${response.status})`);
  }
  return body;
}

async function main() {
  const report = {
    packageName: PACKAGE_NAME,
    track,
    artifact: basename(aabPath),
    generatedAt: new Date().toISOString(),
    releaseStatus: 'draft',
  };
  try {
    const account = readServiceAccount();
    const accessToken = await createAccessToken(account);
    const edit = await jsonRequest(
      accessToken,
      `${API_ROOT}/applications/${PACKAGE_NAME}/edits`,
      { method: 'POST', body: {} },
    );
    const bundle = await uploadBundle(accessToken, edit.id);
    await jsonRequest(
      accessToken,
      `${API_ROOT}/applications/${PACKAGE_NAME}/edits/${edit.id}/tracks/${track}`,
      {
        method: 'PUT',
        body: {
          track,
          releases: [
            {
              name: `Damanak build ${bundle.versionCode}`,
              status: 'draft',
              versionCodes: [String(bundle.versionCode)],
            },
          ],
        },
      },
    );
    await jsonRequest(
      accessToken,
      `${API_ROOT}/applications/${PACKAGE_NAME}/edits/${edit.id}:commit`,
      { method: 'POST', body: {} },
    );
    report.versionCode = bundle.versionCode;
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
