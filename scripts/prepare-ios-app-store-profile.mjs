import { createHash, createPrivateKey, randomBytes, sign } from "node:crypto";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, isAbsolute } from "node:path";

const API_ROOT = "https://api.appstoreconnect.apple.com/v1";
const ASSOCIATED_DOMAINS_CAPABILITY = "ASSOCIATED_DOMAINS";
const APP_STORE_PROFILE_TYPE = "IOS_APP_STORE";
const DISTRIBUTION_CERTIFICATE_TYPES = new Set([
  "DISTRIBUTION",
  "IOS_DISTRIBUTION",
]);
const IOS_BUNDLE_ID_PLATFORMS = new Set(["IOS", "UNIVERSAL"]);

class AppStoreConnectError extends Error {
  constructor(message, status, errors = []) {
    super(message);
    this.name = "AppStoreConnectError";
    this.status = status;
    this.errors = errors;
  }
}

const sleep = (milliseconds) =>
  new Promise((resolve) => setTimeout(resolve, milliseconds));
const base64url = (value) => Buffer.from(value).toString("base64url");

function certificateFingerprint(content) {
  return createHash("sha256").update(content).digest("hex");
}

function embeddedProvisioningPlist(content) {
  const start = content.indexOf(Buffer.from("<?xml"));
  const closing = Buffer.from("</plist>");
  const end = start >= 0 ? content.indexOf(closing, start) : -1;
  if (start < 0 || end < 0) return "";
  return content.subarray(start, end + closing.length).toString("utf8");
}

function plistElementBody(xml, startIndex, tagName) {
  const token = new RegExp(`<\\/?${tagName}\\b[^>]*>`, "g");
  token.lastIndex = startIndex;
  let depth = 0;
  let bodyStart = -1;
  for (let match = token.exec(xml); match; match = token.exec(xml)) {
    const value = match[0];
    const closing = value.startsWith("</");
    const selfClosing = value.endsWith("/>");
    if (!closing) {
      if (depth === 0) bodyStart = token.lastIndex;
      if (!selfClosing) depth += 1;
    } else {
      depth -= 1;
      if (depth === 0 && bodyStart >= 0) {
        return xml.slice(bodyStart, match.index);
      }
      if (depth < 0) return "";
    }
  }
  return "";
}

function profileSupportsAssociatedDomains(content) {
  const plist = embeddedProvisioningPlist(content);
  const entitlementsKey = "<key>Entitlements</key>";
  const entitlementsKeyIndex = plist.indexOf(entitlementsKey);
  if (entitlementsKeyIndex < 0) return false;
  const afterEntitlementsKey = entitlementsKeyIndex + entitlementsKey.length;
  const entitlementsOpen = /\s*<dict\s*>/y;
  entitlementsOpen.lastIndex = afterEntitlementsKey;
  const entitlementsMatch = entitlementsOpen.exec(plist);
  if (!entitlementsMatch) return false;
  const entitlements = plistElementBody(
    plist,
    entitlementsMatch.index + entitlementsMatch[0].search(/<dict/),
    "dict",
  );
  if (!entitlements) return false;

  const associatedDomainsKey =
    "<key>com.apple.developer.associated-domains</key>";
  const associatedDomainsKeyIndex = entitlements.indexOf(associatedDomainsKey);
  if (associatedDomainsKeyIndex < 0) return false;
  const afterAssociatedDomainsKey =
    associatedDomainsKeyIndex + associatedDomainsKey.length;
  const wildcard = /\s*<string>\s*\*\s*<\/string>/y;
  wildcard.lastIndex = afterAssociatedDomainsKey;
  if (wildcard.test(entitlements)) return true;
  const arrayOpen = /\s*<array\s*>/y;
  arrayOpen.lastIndex = afterAssociatedDomainsKey;
  const arrayMatch = arrayOpen.exec(entitlements);
  if (!arrayMatch) return false;
  const domains = plistElementBody(
    entitlements,
    arrayMatch.index + arrayMatch[0].search(/<array/),
    "array",
  );
  return /<string>\s*[^<\s][^<]*<\/string>/.test(domains);
}

function capabilityCreateRequest(bundleId) {
  return {
    data: {
      type: "bundleIdCapabilities",
      attributes: { capabilityType: ASSOCIATED_DOMAINS_CAPABILITY },
      relationships: {
        bundleId: { data: { type: "bundleIds", id: bundleId } },
      },
    },
  };
}

function profileCreateRequest(bundleId, certificateId, name) {
  return {
    data: {
      type: "profiles",
      attributes: { name, profileType: APP_STORE_PROFILE_TYPE },
      relationships: {
        bundleId: { data: { type: "bundleIds", id: bundleId } },
        certificates: {
          data: [{ type: "certificates", id: certificateId }],
        },
      },
    },
  };
}

function authorizationToken(config) {
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
    key: config.privateKey,
    dsaEncoding: "ieee-p1363",
  });
  return `${unsigned}.${signature.toString("base64url")}`;
}

async function apiRequest(config, resource, { method = "GET", body } = {}) {
  const url = resource.startsWith("https://")
    ? new URL(resource)
    : resource.startsWith("/v1/")
      ? new URL(resource, "https://api.appstoreconnect.apple.com")
      : new URL(
          `${API_ROOT}${resource.startsWith("/") ? resource : `/${resource}`}`,
        );
  if (url.origin !== "https://api.appstoreconnect.apple.com") {
    throw new Error("Refusing an unexpected App Store Connect API host.");
  }

  for (let attempt = 1; attempt <= 5; attempt += 1) {
    const response = await fetch(url, {
      method,
      headers: {
        Authorization: `Bearer ${authorizationToken(config)}`,
        Accept: "application/json",
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

    let errors = [];
    try {
      errors = JSON.parse(responseText).errors || [];
    } catch {
      // Keep Apple's bounded plain-text response below.
    }
    const detail = errors.length
      ? errors
          .map(
            (error) =>
              `${error.code || response.status}: ${error.detail || error.title || "request failed"}`,
          )
          .join("; ")
      : responseText.slice(0, 1_500);
    const permissionHint =
      response.status === 403
        ? " Ensure this API key has Certificates, Identifiers & Profiles access and that Apple agreements are current."
        : "";
    throw new AppStoreConnectError(
      `App Store Connect ${method} ${url.pathname} failed (${response.status}): ${detail}.${permissionHint}`,
      response.status,
      errors,
    );
  }
  throw new Error(
    `App Store Connect ${method} ${url.pathname} exhausted retries.`,
  );
}

async function listAll(config, resource) {
  const resources = [];
  let next = resource;
  for (let page = 0; next && page < 20; page += 1) {
    const response = await apiRequest(config, next);
    if (!Array.isArray(response?.data)) {
      throw new Error("App Store Connect list response did not contain data.");
    }
    resources.push(...response.data);
    next = response.links?.next || null;
  }
  if (next) {
    throw new Error("App Store Connect pagination exceeded 20 pages.");
  }
  return resources;
}

function selectBundleId(entries, bundleIdentifier) {
  const matches = entries.filter(
    (entry) =>
      entry.attributes?.identifier === bundleIdentifier &&
      IOS_BUNDLE_ID_PLATFORMS.has(entry.attributes?.platform),
  );
  if (matches.length !== 1) {
    throw new Error(
      `Expected exactly one registered iOS-compatible bundle ID ${bundleIdentifier}; found ${matches.length}.`,
    );
  }
  return matches[0];
}

async function findBundleId(config) {
  const query = new URLSearchParams({
    "filter[identifier]": config.bundleIdentifier,
    "fields[bundleIds]": "name,identifier,platform",
    limit: "10",
  });
  const bundleIds = await listAll(config, `/bundleIds?${query}`);
  return selectBundleId(bundleIds, config.bundleIdentifier);
}

function capabilityListResource(bundleId) {
  const query = new URLSearchParams({
    "fields[bundleIdCapabilities]": "capabilityType,settings",
  });
  return `/bundleIds/${encodeURIComponent(bundleId)}/bundleIdCapabilities?${query}`;
}

async function listCapabilities(config, bundleId) {
  return listAll(config, capabilityListResource(bundleId));
}

async function ensureAssociatedDomainsCapability(config, bundleId) {
  const isEnabled = async () =>
    (await listCapabilities(config, bundleId)).some(
      (entry) =>
        entry.attributes?.capabilityType === ASSOCIATED_DOMAINS_CAPABILITY,
    );

  if (await isEnabled()) return "already-enabled";

  try {
    await apiRequest(config, "/bundleIdCapabilities", {
      method: "POST",
      body: capabilityCreateRequest(bundleId),
    });
  } catch (error) {
    if (!(error instanceof AppStoreConnectError) || error.status !== 409) {
      throw error;
    }
    // Another build may have enabled it between the GET and POST. Verify below.
  }

  for (let attempt = 1; attempt <= 6; attempt += 1) {
    if (await isEnabled()) return "enabled-now";
    if (attempt < 6) await sleep(attempt * 1_000);
  }
  throw new Error(
    "Apple did not expose the Associated Domains capability after enabling it.",
  );
}

async function findDistributionCertificate(config) {
  const localContent = await readFile(config.certificatePath);
  const localFingerprint = certificateFingerprint(localContent);
  const query = new URLSearchParams({
    "fields[certificates]":
      "name,certificateType,displayName,serialNumber,platform,expirationDate,certificateContent,activated",
    limit: "200",
  });
  const certificates = await listAll(config, `/certificates?${query}`);
  const now = Date.now();
  const matches = certificates.filter((entry) => {
    const attributes = entry.attributes || {};
    if (!DISTRIBUTION_CERTIFICATE_TYPES.has(attributes.certificateType))
      return false;
    if (attributes.activated === false) return false;
    const expiration = Date.parse(attributes.expirationDate || "");
    if (!Number.isFinite(expiration) || expiration <= now) return false;
    if (!attributes.certificateContent) return false;
    return (
      certificateFingerprint(
        Buffer.from(attributes.certificateContent, "base64"),
      ) === localFingerprint
    );
  });

  if (matches.length !== 1) {
    throw new Error(
      `The imported Apple Distribution certificate matched ${matches.length} active App Store Connect certificates by DER SHA-256. Refusing to guess a certificate or profile.`,
    );
  }
  return { certificate: matches[0], fingerprint: localFingerprint };
}

function profileMatches(profile, bundleId, certificateId) {
  const attributes = profile.attributes || {};
  if (attributes.profileType !== APP_STORE_PROFILE_TYPE) return false;
  if (attributes.profileState !== "ACTIVE") return false;
  const expiration = Date.parse(attributes.expirationDate || "");
  if (!Number.isFinite(expiration) || expiration <= Date.now()) return false;
  if (profile.relationships?.bundleId?.data?.id !== bundleId) return false;
  if (
    !profile.relationships?.certificates?.data?.some(
      (entry) => entry.id === certificateId,
    )
  )
    return false;
  if (!attributes.profileContent) return false;
  return profileSupportsAssociatedDomains(
    Buffer.from(attributes.profileContent, "base64"),
  );
}

async function listProfiles(config) {
  const query = new URLSearchParams({
    "filter[profileState]": "ACTIVE",
    "filter[profileType]": APP_STORE_PROFILE_TYPE,
    "fields[profiles]":
      "name,profileType,profileState,profileContent,uuid,createdDate,expirationDate,bundleId,certificates",
    include: "bundleId,certificates",
    "fields[bundleIds]": "identifier,platform",
    "fields[certificates]": "certificateType,serialNumber,expirationDate",
    limit: "200",
    "limit[certificates]": "50",
  });
  return listAll(config, `/profiles?${query}`);
}

async function reusableProfile(config, bundleId, certificateId) {
  const candidates = (await listProfiles(config))
    .filter((profile) => profileMatches(profile, bundleId, certificateId))
    .sort((left, right) =>
      String(right.attributes?.expirationDate).localeCompare(
        String(left.attributes?.expirationDate),
      ),
    );
  return candidates[0] || null;
}

function generatedProfileName() {
  const timestamp = new Date().toISOString().replace(/[-:.]/g, "");
  return `Otlobli TestFlight Associated Domains ${timestamp}-${randomBytes(4).toString("hex")}`;
}

async function createCompatibleProfile(config, bundleId, certificateId) {
  const response = await apiRequest(config, "/profiles", {
    method: "POST",
    body: profileCreateRequest(bundleId, certificateId, generatedProfileName()),
  });
  const profile = response?.data;
  const content = profile?.attributes?.profileContent
    ? Buffer.from(profile.attributes.profileContent, "base64")
    : null;
  if (!content || !profileSupportsAssociatedDomains(content)) {
    throw new Error(
      "Apple generated an App Store profile without the Associated Domains entitlement; refusing to install it. No certificate or profile was deleted or revoked.",
    );
  }
  return profile;
}

async function writeProfile(config, profile) {
  const encoded = profile.attributes?.profileContent;
  if (!encoded)
    throw new Error("Apple profile response omitted profileContent.");
  const content = Buffer.from(encoded, "base64");
  if (!profileSupportsAssociatedDomains(content)) {
    throw new Error(
      "Refusing to install a profile without Associated Domains support.",
    );
  }
  await mkdir(dirname(config.outputPath), { recursive: true });
  await writeFile(config.outputPath, content, { mode: 0o600 });
}

function requiredEnvironment(name) {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

async function loadConfig() {
  const keyId = requiredEnvironment("ASC_API_KEY_ID");
  const issuerId = requiredEnvironment("ASC_ISSUER_ID");
  const keyPath = requiredEnvironment("ASC_API_KEY_PATH");
  const bundleIdentifier = requiredEnvironment("OTLOBLI_ASC_BUNDLE_ID");
  const associatedDomain = requiredEnvironment("OTLOBLI_ASSOCIATED_DOMAIN");
  const certificatePath = requiredEnvironment(
    "OTLOBLI_DISTRIBUTION_CERTIFICATE_DER",
  );
  const outputPath = requiredEnvironment("OTLOBLI_PROFILE_OUTPUT");

  if (!/^[A-Z0-9]{10}$/.test(keyId))
    throw new Error("Invalid App Store Connect key ID.");
  if (!/^[0-9a-f-]{36}$/i.test(issuerId))
    throw new Error("Invalid App Store Connect issuer ID.");
  if (bundleIdentifier !== "com.otlobli.app")
    throw new Error("Unexpected iOS bundle identifier.");
  if (associatedDomain !== "applinks:talabieh.vercel.app")
    throw new Error("Unexpected Associated Domains entitlement.");
  if (!isAbsolute(certificatePath) || !isAbsolute(outputPath)) {
    throw new Error(
      "Certificate and provisioning-profile paths must be absolute.",
    );
  }

  return {
    keyId,
    issuerId,
    privateKey: createPrivateKey(await readFile(keyPath, "utf8")),
    bundleIdentifier,
    associatedDomain,
    certificatePath,
    outputPath,
  };
}

function runSelfTest() {
  const supported = Buffer.from(
    `<?xml version="1.0"?><plist><dict><key>Entitlements</key><dict><key>com.apple.developer.associated-domains</key><string>*</string></dict></dict></plist>`,
  );
  const supportedArray = Buffer.from(
    `<?xml version="1.0"?><plist><dict><key>Entitlements</key><dict><key>com.apple.developer.associated-domains</key><array><string>applinks:talabieh.vercel.app</string></array></dict></dict></plist>`,
  );
  const unsupported = Buffer.from(
    `<?xml version="1.0"?><plist><dict><key>Entitlements</key><dict><key>aps-environment</key><string>production</string></dict></dict></plist>`,
  );
  const falsePositive = Buffer.from(
    `<?xml version="1.0"?><plist><dict><key>Entitlements</key><dict><key>com.apple.developer.associated-domains</key><true/><key>unrelated</key><array><string>value</string></array></dict></dict></plist>`,
  );
  if (!profileSupportsAssociatedDomains(supported))
    throw new Error("Associated Domains profile fixture was not recognized.");
  if (!profileSupportsAssociatedDomains(supportedArray))
    throw new Error("Associated Domains array fixture was not recognized.");
  if (profileSupportsAssociatedDomains(unsupported))
    throw new Error("Profile fixture without Associated Domains was accepted.");
  if (profileSupportsAssociatedDomains(falsePositive))
    throw new Error("Invalid Associated Domains fixture was accepted.");
  const capability = capabilityCreateRequest("bundle-1");
  if (
    capability.data.attributes.capabilityType !==
      ASSOCIATED_DOMAINS_CAPABILITY ||
    capability.data.relationships.bundleId.data.id !== "bundle-1"
  )
    throw new Error("Capability request fixture is invalid.");
  const profile = profileCreateRequest("bundle-1", "certificate-1", "name");
  if (
    profile.data.attributes.profileType !== APP_STORE_PROFILE_TYPE ||
    profile.data.relationships.certificates.data[0].id !== "certificate-1"
  )
    throw new Error("Profile request fixture is invalid.");
  const capabilityResource = capabilityListResource("bundle/1");
  if (
    !capabilityResource.startsWith(
      "/bundleIds/bundle%2F1/bundleIdCapabilities?",
    ) ||
    !capabilityResource.includes(
      "fields%5BbundleIdCapabilities%5D=capabilityType%2Csettings",
    ) ||
    capabilityResource.includes("limit=")
  )
    throw new Error("Capability list request fixture is invalid.");
  const universalBundle = selectBundleId(
    [
      {
        id: "bundle-related-service",
        attributes: {
          identifier: "com.otlobli.app.signin",
          platform: "IOS",
        },
      },
      {
        id: "bundle-universal",
        attributes: {
          identifier: "com.otlobli.app",
          platform: "UNIVERSAL",
        },
      },
      {
        id: "bundle-macos",
        attributes: {
          identifier: "com.otlobli.app",
          platform: "MAC_OS",
        },
      },
    ],
    "com.otlobli.app",
  );
  if (universalBundle.id !== "bundle-universal")
    throw new Error("Universal iOS-compatible bundle ID was not selected.");
  const iosBundle = selectBundleId(
    [
      {
        id: "bundle-ios",
        attributes: { identifier: "com.otlobli.app", platform: "IOS" },
      },
    ],
    "com.otlobli.app",
  );
  if (iosBundle.id !== "bundle-ios")
    throw new Error("iOS bundle ID fixture was not selected.");
  let rejectedMacOnly = false;
  try {
    selectBundleId(
      [
        {
          id: "bundle-macos",
          attributes: {
            identifier: "com.otlobli.app",
            platform: "MAC_OS",
          },
        },
      ],
      "com.otlobli.app",
    );
  } catch {
    rejectedMacOnly = true;
  }
  if (!rejectedMacOnly)
    throw new Error("macOS-only bundle ID fixture was accepted.");
  let rejectedAmbiguous = false;
  try {
    selectBundleId(
      [
        {
          id: "bundle-ios",
          attributes: { identifier: "com.otlobli.app", platform: "IOS" },
        },
        {
          id: "bundle-universal",
          attributes: {
            identifier: "com.otlobli.app",
            platform: "UNIVERSAL",
          },
        },
      ],
      "com.otlobli.app",
    );
  } catch {
    rejectedAmbiguous = true;
  }
  if (!rejectedAmbiguous)
    throw new Error("Ambiguous iOS-compatible bundle IDs were accepted.");
  console.log("iOS App Store provisioning-profile helper self-test passed.");
}

async function main() {
  const config = await loadConfig();
  const bundle = await findBundleId(config);
  const capabilityState = await ensureAssociatedDomainsCapability(
    config,
    bundle.id,
  );
  const { certificate, fingerprint } =
    await findDistributionCertificate(config);
  let profile = await reusableProfile(config, bundle.id, certificate.id);
  const profileState = profile ? "reused" : "created";
  if (!profile) {
    profile = await createCompatibleProfile(config, bundle.id, certificate.id);
  }
  await writeProfile(config, profile);

  console.log(
    `Associated Domains capability: ${capabilityState}; bundle platform=${bundle.attributes?.platform}; profile: ${profileState} ${profile.attributes?.uuid || profile.id}; certificate matched by DER SHA-256 ${fingerprint.slice(0, 12)}…; expires=${profile.attributes?.expirationDate}.`,
  );
}

if (process.argv.includes("--self-test")) {
  runSelfTest();
} else {
  try {
    await main();
  } catch (error) {
    console.error(
      `Failed to prepare the Associated Domains App Store profile: ${error instanceof Error ? error.message : String(error)}`,
    );
    process.exitCode = 1;
  }
}
