import {
  Environment,
  SignedDataVerifier,
  VerificationException,
  VerificationStatus,
} from "@apple/app-store-server-library";
import { importPKCS8, SignJWT } from "jose";
import type { JWTHeaderParameters } from "jose";
import { Buffer } from "node:buffer";
import { X509Certificate } from "node:crypto";
import {
  AppleJwsCompatibilityError,
  verifyAppleTransactionJwsCompatibility,
} from "./apple_jws_compat.ts";
import {
  appleTestRootDerBase64,
  appleTestTransactionJws,
} from "./apple_jws_compat_fixture_test.ts";
import {
  damanakTestIntermediateDerBase64,
  damanakTestLeafDerBase64,
  damanakTestLeafPrivateKeyPem,
  damanakTestRootDerBase64,
} from "./damanak_jws_generated_fixture_test.ts";
import { verifyAppleRecoveryTransactionWithFallback } from "./index.ts";

const fixtureSignedDate = 1_672_956_154_000;
const damanakTestSignedDate = Date.UTC(2026, 8, 2);

function fixtureHeader() {
  const [headerSegment] = appleTestTransactionJws.split(".");
  return JSON.parse(
    Buffer.from(headerSegment, "base64url").toString("utf8"),
  ) as JWTHeaderParameters & { x5c: string[] };
}

function verifyFixture(candidate: string, bundleId = "com.example") {
  return verifyAppleTransactionJwsCompatibility(candidate, {
    bundleId,
    environment: "sandbox",
    trustedRoots: [Buffer.from(appleTestRootDerBase64, "base64")],
  });
}

function nodeX509CertificateVerificationAvailable() {
  try {
    const chain = fixtureHeader().x5c;
    const leaf = new X509Certificate(Buffer.from(chain[0], "base64"));
    const intermediate = new X509Certificate(
      Buffer.from(chain[1], "base64"),
    );
    leaf.toString();
    void leaf.raw;
    void leaf.ca;
    return leaf.verify(intermediate.publicKey);
  } catch {
    return false;
  }
}

function damanakTestHeader(): JWTHeaderParameters {
  return {
    alg: "ES256",
    typ: "JWT",
    x5c: [
      damanakTestLeafDerBase64,
      damanakTestIntermediateDerBase64,
      damanakTestRootDerBase64,
    ],
  };
}

function verifyDamanakTestChain(
  candidate: string,
  bundleId = "com.damanak.damanak",
) {
  return verifyAppleTransactionJwsCompatibility(candidate, {
    bundleId,
    environment: "sandbox",
    trustedRoots: [Buffer.from(damanakTestRootDerBase64, "base64")],
  });
}

async function signFixturePayload(
  payload: Record<string, unknown>,
  header: JWTHeaderParameters = damanakTestHeader(),
) {
  const key = await importPKCS8(damanakTestLeafPrivateKeyPem, "ES256");
  return await new SignJWT(payload)
    .setProtectedHeader(header)
    .sign(key);
}

async function expectCompatibilityRejection(
  run: () => unknown | Promise<unknown>,
) {
  try {
    await run();
  } catch (error) {
    if (error instanceof AppleJwsCompatibilityError) return;
    throw error;
  }
  throw new Error("an invalid Apple JWS reached compatibility acceptance");
}

Deno.test("Apple compatibility verifies the official public JWS fixture", async () => {
  const payload = verifyFixture(appleTestTransactionJws);
  if (
    payload.bundleId !== "com.example" ||
    payload.environment !== "Sandbox" ||
    payload.signedDate !== fixtureSignedDate
  ) {
    throw new Error("Apple's official fixture was decoded incorrectly");
  }
  if (nodeX509CertificateVerificationAvailable()) {
    const official = await new SignedDataVerifier(
      [Buffer.from(appleTestRootDerBase64, "base64")],
      false,
      Environment.SANDBOX,
      "com.example",
      undefined,
    ).verifyAndDecodeTransaction(appleTestTransactionJws);
    if (official.bundleId !== payload.bundleId) {
      throw new Error("compatibility diverged from Apple's verifier");
    }
  }
  const presentedRoot = (fixtureHeader().x5c as string[])[2];
  if (presentedRoot === appleTestRootDerBase64) {
    throw new Error("the fixture no longer proves that x5c[2] is untrusted");
  }
});

Deno.test("Apple compatibility accepts a fully bound transaction payload", async () => {
  const token = "33333333-3333-4333-8333-333333333333";
  const signedTransaction = await signFixturePayload({
    bundleId: "com.damanak.damanak",
    environment: "Sandbox",
    signedDate: damanakTestSignedDate,
    transactionId: "2000000123456790",
    originalTransactionId: "2000000123456789",
    productId: "com.damanak.subscription.scale.yearly",
    appAccountToken: token,
  });
  const payload = verifyDamanakTestChain(signedTransaction);
  if (
    payload.transactionId !== "2000000123456790" ||
    payload.originalTransactionId !== "2000000123456789" ||
    payload.productId !== "com.damanak.subscription.scale.yearly" ||
    payload.appAccountToken !== token
  ) {
    throw new Error("verified transaction identity was not preserved");
  }
  if (nodeX509CertificateVerificationAvailable()) {
    const official = await new SignedDataVerifier(
      [Buffer.from(damanakTestRootDerBase64, "base64")],
      false,
      Environment.SANDBOX,
      "com.damanak.damanak",
      undefined,
    ).verifyAndDecodeTransaction(signedTransaction);
    if (official.transactionId !== payload.transactionId) {
      throw new Error("compatibility diverged from Apple's verifier");
    }
  }
});

Deno.test("Apple compatibility never calls Node X509Certificate", () => {
  const prototype = X509Certificate.prototype;
  const properties = ["raw", "verify", "ca", "publicKey"] as const;
  const descriptors = properties.map((property) => {
    const descriptor = Object.getOwnPropertyDescriptor(prototype, property);
    if (descriptor == null || descriptor.configurable !== true) {
      throw new Error(`cannot guard X509Certificate.${property}`);
    }
    return [property, descriptor] as const;
  });
  const forbidden = () => {
    throw new Error("compatibility called Node X509Certificate");
  };
  try {
    for (const [property, descriptor] of descriptors) {
      Object.defineProperty(
        prototype,
        property,
        "value" in descriptor
          ? { ...descriptor, value: forbidden }
          : { ...descriptor, get: forbidden },
      );
    }
    const payload = verifyFixture(appleTestTransactionJws);
    if (payload.bundleId !== "com.example") {
      throw new Error("fixture was not verified while Node X509 was blocked");
    }
  } finally {
    for (const [property, descriptor] of descriptors) {
      Object.defineProperty(prototype, property, descriptor);
    }
  }
});

Deno.test("Apple compatibility rejects signature, chain, and identity changes", async () => {
  const parts = appleTestTransactionJws.split(".");
  const tamperedSignature = Buffer.from(parts[2], "base64url");
  tamperedSignature[0] ^= 0x01;
  await expectCompatibilityRejection(() =>
    verifyFixture(
      `${parts[0]}.${parts[1]}.${tamperedSignature.toString("base64url")}`,
    )
  );

  const wrongRoot = Buffer.from((fixtureHeader().x5c as string[])[2], "base64");
  await expectCompatibilityRejection(() =>
    verifyAppleTransactionJwsCompatibility(appleTestTransactionJws, {
      bundleId: "com.example",
      environment: "sandbox",
      trustedRoots: [wrongRoot],
    })
  );

  const invalidHeader = { ...fixtureHeader(), alg: "none" };
  await expectCompatibilityRejection(() =>
    verifyFixture(
      `${Buffer.from(JSON.stringify(invalidHeader)).toString("base64url")}.${
        parts[1]
      }.${parts[2]}`,
    )
  );

  const criticalHeader = { ...fixtureHeader(), crit: ["unknown"] };
  await expectCompatibilityRejection(() =>
    verifyFixture(
      `${Buffer.from(JSON.stringify(criticalHeader)).toString("base64url")}.${
        parts[1]
      }.${parts[2]}`,
    )
  );

  const shortChainHeader = {
    ...fixtureHeader(),
    x5c: (fixtureHeader().x5c as string[]).slice(0, 2),
  };
  await expectCompatibilityRejection(() =>
    verifyFixture(
      `${Buffer.from(JSON.stringify(shortChainHeader)).toString("base64url")}.${
        parts[1]
      }.${parts[2]}`,
    )
  );

  await expectCompatibilityRejection(async () =>
    verifyDamanakTestChain(
      await signFixturePayload({
        bundleId: "com.example.invalid",
        environment: "Sandbox",
        signedDate: damanakTestSignedDate,
      }),
    )
  );
  await expectCompatibilityRejection(async () =>
    verifyDamanakTestChain(
      await signFixturePayload({
        bundleId: "com.damanak.damanak",
        environment: "Sandbox",
        signedDate: Date.UTC(2040, 0, 1),
      }),
    )
  );
});

Deno.test("Apple compatibility rejects a certificate with a changed private OID", async () => {
  const header = damanakTestHeader();
  const chain = [...(header.x5c as string[])];
  const leaf = Buffer.from(chain[0], "base64");
  const oid = Buffer.from("060a2a864886f76364060b01", "hex");
  const oidOffset = leaf.indexOf(oid);
  if (oidOffset < 0) throw new Error("Apple leaf OID fixture was not found");
  leaf[oidOffset + oid.length - 1] ^= 0x01;
  chain[0] = leaf.toString("base64");
  const candidate = await signFixturePayload(
    {
      bundleId: "com.damanak.damanak",
      environment: "Sandbox",
      signedDate: damanakTestSignedDate,
    },
    { ...header, x5c: chain },
  );
  await expectCompatibilityRejection(() => verifyDamanakTestChain(candidate));
});

Deno.test("Apple runtime compatibility is gated by two status-1 failures", async () => {
  const officialCalls: boolean[] = [];
  let compatibilityCalls = 0;
  const originalWarn = console.warn;
  console.warn = () => {};
  try {
    const payload = await verifyAppleRecoveryTransactionWithFallback(
      appleTestTransactionJws,
      "sandbox",
      (_candidate, _environment, online) => {
        officialCalls.push(online);
        return Promise.reject(
          new VerificationException(VerificationStatus.VERIFICATION_FAILURE),
        );
      },
      (candidate) => {
        compatibilityCalls += 1;
        return Promise.resolve(verifyFixture(candidate));
      },
    );
    if (
      payload.bundleId !== "com.example" ||
      officialCalls.join(",") !== "true,false" ||
      compatibilityCalls !== 1
    ) {
      throw new Error("runtime compatibility escaped its narrow gate");
    }

    compatibilityCalls = 0;
    let rejectedMessage = "";
    try {
      await verifyAppleRecoveryTransactionWithFallback(
        appleTestTransactionJws,
        "sandbox",
        () =>
          Promise.reject(
            new VerificationException(
              VerificationStatus.VERIFICATION_FAILURE,
            ),
          ),
        () => {
          compatibilityCalls += 1;
          return Promise.reject(new Error("compatibility rejected"));
        },
      );
    } catch (error) {
      rejectedMessage = error instanceof Error ? error.message : "";
    }
    if (
      compatibilityCalls !== 1 ||
      rejectedMessage !== "APPLE_RECOVERY_PROOF_INVALID"
    ) {
      throw new Error(
        "a failed runtime compatibility check did not fail closed",
      );
    }

    for (
      const [onlineStatus, offlineStatus] of [
        [
          VerificationStatus.INVALID_CERTIFICATE,
          VerificationStatus.VERIFICATION_FAILURE,
        ],
        [VerificationStatus.VERIFICATION_FAILURE, VerificationStatus.FAILURE],
      ] as const
    ) {
      compatibilityCalls = 0;
      let call = 0;
      try {
        await verifyAppleRecoveryTransactionWithFallback(
          appleTestTransactionJws,
          "sandbox",
          () =>
            Promise.reject(
              new VerificationException(
                call++ === 0 ? onlineStatus : offlineStatus,
              ),
            ),
          () => {
            compatibilityCalls += 1;
            return Promise.resolve({});
          },
        );
      } catch {
        // The expected result remains fail-closed.
      }
      if (compatibilityCalls !== 0) {
        throw new Error("a non-status-1 pair reached runtime compatibility");
      }
    }
  } finally {
    console.warn = originalWarn;
  }
});
