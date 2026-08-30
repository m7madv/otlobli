#!/usr/bin/env node

import { createPrivateKey, sign } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";

const API_ROOT = "https://androidpublisher.googleapis.com/androidpublisher/v3";
const UPLOAD_ROOT =
  "https://androidpublisher.googleapis.com/upload/androidpublisher/v3";
const TOKEN_URL = "https://oauth2.googleapis.com/token";
const PACKAGE_NAME = "app.voicebrief.mobile";
const TRACK = "internal";
const EXPECTED_VERSION_CODE = "18";
const EXPECTED_SHA256 =
  "aec8b94aa105fa083372fc7b65419a602ac2a3452da8f98161ce59e53e262aad";
const ALLOWED_PRIOR_VERSION_CODES = new Set(["7", EXPECTED_VERSION_CODE]);

const aabPath = process.argv[2];
const reportPath = process.argv[3];

if (!aabPath || !reportPath) {
  throw new Error("Usage: voicebrief_google_play_internal.mjs <aab> <report>");
}

function base64Url(value) {
  return Buffer.from(value).toString("base64url");
}

function summarizeTrack(track) {
  return {
    track: track.track,
    releases: (track.releases || []).map((release) => ({
      name: release.name || null,
      status: release.status || null,
      versionCodes: (release.versionCodes || []).map(String),
    })),
  };
}

function safeError(error) {
  return error instanceof Error ? error.message : String(error);
}

async function accessToken() {
  const raw = process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON;
  if (!raw) throw new Error("Missing Google Play service account secret");

  let account;
  try {
    account = JSON.parse(raw);
  } catch {
    throw new Error("Google Play service account secret is not valid JSON");
  }
  if (!account.client_email || !account.private_key) {
    throw new Error("Google Play service account secret is incomplete");
  }

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

async function jsonRequest(token, url, { method = "GET", body } = {}) {
  const response = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: "application/json",
      ...(body ? { "Content-Type": "application/json" } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  const text = await response.text();
  let parsed = {};
  if (text) {
    try {
      parsed = JSON.parse(text);
    } catch {
      throw new Error(
        `Google Play returned non-JSON status ${response.status}`,
      );
    }
  }
  if (!response.ok) {
    throw new Error(
      parsed?.error?.message ||
        `Google Play request failed (${response.status})`,
    );
  }
  return parsed;
}

async function uploadBundle(token, editId) {
  const response = await fetch(
    `${UPLOAD_ROOT}/applications/${PACKAGE_NAME}/edits/${editId}/bundles?uploadType=media`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/octet-stream",
      },
      body: readFileSync(aabPath),
    },
  );
  const body = await response.json();
  if (!response.ok || !body.versionCode) {
    throw new Error(
      body?.error?.message || `AAB upload failed (${response.status})`,
    );
  }
  return body;
}

async function discardEdit(token, editId) {
  if (!token || !editId) return;
  try {
    await jsonRequest(
      token,
      `${API_ROOT}/applications/${PACKAGE_NAME}/edits/${editId}`,
      { method: "DELETE" },
    );
  } catch {
    // Edits expire automatically. Preserve the original failure.
  }
}

async function main() {
  const report = {
    packageName: PACKAGE_NAME,
    track: TRACK,
    expectedVersionCode: EXPECTED_VERSION_CODE,
    expectedSha256: EXPECTED_SHA256,
    generatedAt: new Date().toISOString(),
    success: false,
  };
  let token = "";
  let editId = "";

  try {
    token = await accessToken();
    const edit = await jsonRequest(
      token,
      `${API_ROOT}/applications/${PACKAGE_NAME}/edits`,
      { method: "POST", body: {} },
    );
    editId = edit.id;
    if (!editId) throw new Error("Google Play did not return an edit ID");

    const [tracksBody, bundlesBody] = await Promise.all([
      jsonRequest(
        token,
        `${API_ROOT}/applications/${PACKAGE_NAME}/edits/${editId}/tracks`,
      ),
      jsonRequest(
        token,
        `${API_ROOT}/applications/${PACKAGE_NAME}/edits/${editId}/bundles`,
      ),
    ]);
    const internalTrack = (tracksBody.tracks || []).find(
      (candidate) => candidate.track === TRACK,
    );
    report.trackBefore = internalTrack ? summarizeTrack(internalTrack) : null;

    const priorCodes = new Set(
      (internalTrack?.releases || []).flatMap((release) =>
        (release.versionCodes || []).map(String),
      ),
    );
    const unexpectedCodes = [...priorCodes].filter(
      (code) => !ALLOWED_PRIOR_VERSION_CODES.has(code),
    );
    if (unexpectedCodes.length) {
      throw new Error(
        `Refusing to replace unexpected internal version codes: ${unexpectedCodes.join(", ")}`,
      );
    }

    let bundle = (bundlesBody.bundles || []).find(
      (candidate) => String(candidate.versionCode) === EXPECTED_VERSION_CODE,
    );
    if (bundle) {
      report.bundleAction = "alreadyPresent";
    } else {
      bundle = await uploadBundle(token, editId);
      report.bundleAction = "uploaded";
    }

    const returnedVersionCode = String(bundle.versionCode || "");
    const returnedSha256 = String(bundle.sha256 || "").toLowerCase();
    if (returnedVersionCode !== EXPECTED_VERSION_CODE) {
      throw new Error(
        `Google Play returned version code ${returnedVersionCode || "missing"}, expected ${EXPECTED_VERSION_CODE}`,
      );
    }
    if (returnedSha256 !== EXPECTED_SHA256) {
      throw new Error(
        `Google Play returned SHA-256 ${returnedSha256 || "missing"}, expected ${EXPECTED_SHA256}`,
      );
    }
    report.bundleVersionCode = returnedVersionCode;
    report.bundleSha256 = returnedSha256;

    await jsonRequest(
      token,
      `${API_ROOT}/applications/${PACKAGE_NAME}/edits/${editId}/tracks/${TRACK}`,
      {
        method: "PUT",
        body: {
          track: TRACK,
          releases: [
            {
              name: "VoiceBrief 0.1.0 build 18",
              status: "completed",
              versionCodes: [EXPECTED_VERSION_CODE],
              releaseNotes: [
                {
                  language: "ar",
                  text: "تحسين المشاركة ومعالجة الصوت والمواعيد والمنبهات والثبات والأمان.",
                },
                {
                  language: "en-US",
                  text: "Improved sharing, audio processing, dates, alarms, persistence, and security.",
                },
              ],
            },
          ],
        },
      },
    );
    await jsonRequest(
      token,
      `${API_ROOT}/applications/${PACKAGE_NAME}/edits/${editId}:validate`,
      { method: "POST", body: {} },
    );
    await jsonRequest(
      token,
      `${API_ROOT}/applications/${PACKAGE_NAME}/edits/${editId}:commit`,
      { method: "POST", body: {} },
    );
    editId = "";
    report.committed = true;

    const verificationEdit = await jsonRequest(
      token,
      `${API_ROOT}/applications/${PACKAGE_NAME}/edits`,
      { method: "POST", body: {} },
    );
    editId = verificationEdit.id;
    const verifiedTrack = await jsonRequest(
      token,
      `${API_ROOT}/applications/${PACKAGE_NAME}/edits/${editId}/tracks/${TRACK}`,
    );
    report.trackAfter = summarizeTrack(verifiedTrack);
    const verifiedRelease = (verifiedTrack.releases || []).find(
      (release) =>
        release.status === "completed" &&
        (release.versionCodes || [])
          .map(String)
          .includes(EXPECTED_VERSION_CODE),
    );
    if (!verifiedRelease) {
      throw new Error(
        "Google Play internal track did not expose completed build 18",
      );
    }
    await discardEdit(token, editId);
    editId = "";
    report.success = true;
  } catch (error) {
    report.error = safeError(error);
    await discardEdit(token, editId);
    process.exitCode = 1;
  } finally {
    writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`, "utf8");
    process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
  }
}

await main();
