import { readFile } from "node:fs/promises";
import { createPrivateKey, sign } from "node:crypto";

const API_ROOT = "https://api.appstoreconnect.apple.com/v1";
const requiredEnvironment = [
  "ASC_API_KEY_ID",
  "ASC_ISSUER_ID",
  "ASC_API_KEY_PATH",
  "OTLOBLI_ASC_APP_ID",
  "OTLOBLI_APP_VERSION",
  "OTLOBLI_APP_BUILD",
  "OTLOBLI_INTERNAL_GROUP",
  "OTLOBLI_INTERNAL_TESTER_EMAIL",
];

for (const name of requiredEnvironment) {
  if (!process.env[name]?.trim()) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
}

const config = {
  keyId: process.env.ASC_API_KEY_ID.trim(),
  issuerId: process.env.ASC_ISSUER_ID.trim(),
  keyPath: process.env.ASC_API_KEY_PATH.trim(),
  appId: process.env.OTLOBLI_ASC_APP_ID.trim(),
  appVersion: process.env.OTLOBLI_APP_VERSION.trim(),
  appBuild: process.env.OTLOBLI_APP_BUILD.trim(),
  groupName: process.env.OTLOBLI_INTERNAL_GROUP.trim(),
  testerEmail: process.env.OTLOBLI_INTERNAL_TESTER_EMAIL.trim().toLowerCase(),
  waitMinutes: Number.parseInt(
    process.env.OTLOBLI_ASC_WAIT_MINUTES || "20",
    10,
  ),
};

if (!/^[A-Z0-9]{10}$/.test(config.keyId))
  throw new Error("Invalid App Store Connect key ID.");
if (!/^[0-9a-f-]{36}$/i.test(config.issuerId))
  throw new Error("Invalid App Store Connect issuer ID.");
if (!/^\d+$/.test(config.appId))
  throw new Error("Invalid App Store Connect app ID.");
if (!/^\d+(?:\.\d+){1,2}$/.test(config.appVersion))
  throw new Error("Invalid app version.");
if (!/^\d+$/.test(config.appBuild))
  throw new Error("Invalid app build number.");
if (
  !Number.isInteger(config.waitMinutes) ||
  config.waitMinutes < 1 ||
  config.waitMinutes > 30
) {
  throw new Error("OTLOBLI_ASC_WAIT_MINUTES must be between 1 and 30.");
}

const privateKey = createPrivateKey(await readFile(config.keyPath, "utf8"));
const sleep = (milliseconds) =>
  new Promise((resolve) => setTimeout(resolve, milliseconds));
const base64url = (value) => Buffer.from(value).toString("base64url");

function authorizationToken() {
  const issuedAt = Math.floor(Date.now() / 1000) - 20;
  const header = base64url(
    JSON.stringify({ alg: "ES256", kid: config.keyId, typ: "JWT" }),
  );
  const payload = base64url(
    JSON.stringify({
      iss: config.issuerId,
      iat: issuedAt,
      exp: issuedAt + 600,
      aud: "appstoreconnect-v1",
    }),
  );
  const unsigned = `${header}.${payload}`;
  const signature = sign("sha256", Buffer.from(unsigned), {
    key: privateKey,
    dsaEncoding: "ieee-p1363",
  });
  return `${unsigned}.${signature.toString("base64url")}`;
}

function apiPath(resource, parameters = {}) {
  const query = new URLSearchParams();
  for (const [key, value] of Object.entries(parameters)) {
    if (value !== undefined && value !== null && value !== "")
      query.set(key, String(value));
  }
  const serialized = query.toString();
  return serialized ? `${resource}?${serialized}` : resource;
}

async function apiRequest(path, { method = "GET", body } = {}) {
  for (let attempt = 1; attempt <= 5; attempt += 1) {
    const response = await fetch(`${API_ROOT}${path}`, {
      method,
      headers: {
        Authorization: `Bearer ${authorizationToken()}`,
        ...(body ? { "Content-Type": "application/json" } : {}),
      },
      ...(body ? { body: JSON.stringify(body) } : {}),
    });
    const responseText = await response.text();
    if (response.ok) return responseText ? JSON.parse(responseText) : null;

    if ((response.status === 429 || response.status >= 500) && attempt < 5) {
      await sleep(attempt * 2_000);
      continue;
    }

    let detail = responseText.slice(0, 1_000);
    try {
      const parsed = JSON.parse(responseText);
      detail =
        (parsed.errors || [])
          .map(
            (error) =>
              `${error.code || response.status}: ${error.detail || error.title || "request failed"}`,
          )
          .join("; ") || detail;
    } catch {
      // Keep the bounded response text when Apple does not return JSON.
    }
    throw new Error(
      `App Store Connect ${method} ${path} failed (${response.status}): ${detail}`,
    );
  }
  throw new Error(`App Store Connect ${method} ${path} exhausted retries.`);
}

function includedResource(response, relationship) {
  const id = relationship?.data?.id;
  const type = relationship?.data?.type;
  return response.included?.find(
    (resource) => resource.id === id && resource.type === type,
  );
}

async function findProcessedBuild() {
  const deadline = Date.now() + config.waitMinutes * 60_000;
  let lastState = "NOT_VISIBLE";

  while (Date.now() <= deadline) {
    const response = await apiRequest(
      apiPath("/builds", {
        "filter[app]": config.appId,
        "filter[version]": config.appBuild,
        include: "preReleaseVersion",
        "fields[builds]":
          "version,uploadedDate,processingState,expired,preReleaseVersion",
        "fields[preReleaseVersions]": "version,platform",
        limit: 10,
      }),
    );

    const candidates = response.data
      .map((build) => ({
        build,
        release: includedResource(
          response,
          build.relationships?.preReleaseVersion,
        ),
      }))
      .filter(
        ({ build, release }) =>
          build.attributes?.version === config.appBuild &&
          release?.attributes?.version === config.appVersion &&
          release?.attributes?.platform === "IOS",
      )
      .sort((left, right) =>
        String(right.build.attributes?.uploadedDate).localeCompare(
          String(left.build.attributes?.uploadedDate),
        ),
      );

    const match = candidates[0]?.build;
    if (match) {
      lastState = match.attributes.processingState;
      if (lastState === "VALID") return match;
      if (lastState === "FAILED" || lastState === "INVALID") {
        throw new Error(
          `App Store Connect rejected ${config.appVersion} (${config.appBuild}): ${lastState}.`,
        );
      }
    }

    if (Date.now() + 30_000 > deadline) break;
    console.log(`Waiting for App Store Connect processing: ${lastState}.`);
    await sleep(30_000);
  }

  throw new Error(
    `Timed out waiting for ${config.appVersion} (${config.appBuild}); last state: ${lastState}.`,
  );
}

async function findInternalGroup() {
  const response = await apiRequest(
    apiPath("/betaGroups", {
      "filter[app]": config.appId,
      "filter[name]": config.groupName,
      "filter[isInternalGroup]": "true",
      "fields[betaGroups]":
        "name,isInternalGroup,hasAccessToAllBuilds,publicLinkEnabled",
      limit: 20,
    }),
  );
  const matches = response.data.filter(
    (group) =>
      group.attributes?.name === config.groupName &&
      group.attributes?.isInternalGroup === true,
  );
  if (matches.length !== 1) {
    throw new Error(
      `Expected exactly one internal beta group named ${config.groupName}; found ${matches.length}.`,
    );
  }
  if (matches[0].attributes.publicLinkEnabled) {
    throw new Error(
      `${config.groupName} unexpectedly has a public link enabled.`,
    );
  }
  return matches[0];
}

async function ensureBuildAccess(build, group) {
  if (group.attributes.hasAccessToAllBuilds) return "all-builds";

  const relationshipPath = `/builds/${encodeURIComponent(build.id)}/relationships/betaGroups`;
  const current = await apiRequest(apiPath(relationshipPath, { limit: 200 }));
  if (current.data.some((item) => item.id === group.id))
    return "already-linked";

  await apiRequest(
    `/betaGroups/${encodeURIComponent(group.id)}/relationships/builds`,
    {
      method: "POST",
      body: { data: [{ type: "builds", id: build.id }] },
    },
  );
  const verified = await apiRequest(apiPath(relationshipPath, { limit: 200 }));
  if (!verified.data.some((item) => item.id === group.id)) {
    throw new Error(
      "Build-to-group relationship was not visible after assignment.",
    );
  }
  return "linked-now";
}

async function ensureTesterMembership(group) {
  const groupMembersPath = apiPath(
    `/betaGroups/${encodeURIComponent(group.id)}/betaTesters`,
    {
      "fields[betaTesters]": "email,state,inviteType",
      limit: 200,
    },
  );
  const findExpectedMember = async () => {
    const response = await apiRequest(groupMembersPath);
    return response.data.find(
      (candidate) =>
        candidate.attributes?.email?.toLowerCase() === config.testerEmail,
    );
  };

  const existingMember = await findExpectedMember();
  if (existingMember) return existingMember.attributes?.state || "UNKNOWN";

  const testerQuery = {
    "filter[email]": config.testerEmail,
    "filter[apps]": config.appId,
    "fields[betaTesters]": "email,state,inviteType",
    limit: 20,
  };
  const allMatches = await apiRequest(apiPath("/betaTesters", testerQuery));
  const tester = allMatches.data.find(
    (candidate) =>
      candidate.attributes?.email?.toLowerCase() === config.testerEmail,
  );
  if (!tester)
    throw new Error(
      "The expected internal tester does not exist in App Store Connect.",
    );

  try {
    await apiRequest(
      `/betaGroups/${encodeURIComponent(group.id)}/relationships/betaTesters`,
      {
        method: "POST",
        body: { data: [{ type: "betaTesters", id: tester.id }] },
      },
    );
  } catch (error) {
    const memberAfterConflict = await findExpectedMember();
    if (memberAfterConflict)
      return memberAfterConflict.attributes?.state || "UNKNOWN";
    throw error;
  }

  const verified = await findExpectedMember();
  if (!verified) {
    throw new Error(
      "Tester-to-group relationship was not visible after assignment.",
    );
  }
  return verified.attributes?.state || "UNKNOWN";
}

async function readInternalBuildState(build) {
  const response = await apiRequest(
    apiPath(`/builds/${encodeURIComponent(build.id)}/buildBetaDetail`, {
      "fields[buildBetaDetails]":
        "internalBuildState,externalBuildState,autoNotifyEnabled",
    }),
  );
  return response.data?.attributes?.internalBuildState || "UNKNOWN";
}

function appendOutput(name, value) {
  if (!process.env.GITHUB_OUTPUT) return;
  return import("node:fs/promises").then(({ appendFile }) =>
    appendFile(process.env.GITHUB_OUTPUT, `${name}=${value}\n`, "utf8"),
  );
}

const build = await findProcessedBuild();
const group = await findInternalGroup();
const buildAccess = await ensureBuildAccess(build, group);
console.log(
  `Verified TestFlight build ${config.appVersion} (${config.appBuild}) is VALID.`,
);
console.log(
  `Verified internal group ${config.groupName}; build access: ${buildAccess}.`,
);
const testerState = await ensureTesterMembership(group);
const internalBuildState = await readInternalBuildState(build);

console.log(
  `Verified expected tester membership; tester state: ${testerState}.`,
);
console.log(`TestFlight internal build state: ${internalBuildState}.`);

await appendOutput("processing_state", build.attributes.processingState);
await appendOutput("internal_build_state", internalBuildState);
await appendOutput("build_access", buildAccess);
await appendOutput("tester_state", testerState);
await appendOutput("uploaded_date", build.attributes.uploadedDate || "UNKNOWN");
