import {
  AudioCleanupError,
  type AudioCleanupGateway,
  cleanupExpiredAudio,
  configuredSecretKeys,
  parseCleanupClaim,
  parseCleanupCompletion,
} from "./core.ts";

const claimId = "11111111-1111-4111-8111-111111111111";
const storagePath =
  "22222222-2222-4222-8222-222222222222/33333333-3333-4333-8333-333333333333/input.m4a";

function assert(condition: boolean, message: string) {
  if (!condition) throw new Error(message);
}

async function expectCleanupError(
  action: () => Promise<unknown>,
  code: string,
) {
  try {
    await action();
  } catch (error) {
    if (!(error instanceof AudioCleanupError)) {
      throw new Error("unexpected error type");
    }
    assert(error.code === code, `expected ${code}, received ${error.code}`);
    return;
  }
  throw new Error(`expected ${code}`);
}

Deno.test("cleanupExpiredAudio returns without touching Storage for an empty claim", async () => {
  let touchedStorage = false;
  const gateway: AudioCleanupGateway = {
    claim: () => Promise.resolve({ claimId: null, storagePaths: [] }),
    remove: () => {
      touchedStorage = true;
      return Promise.resolve();
    },
    complete: () => Promise.resolve({ staged: 0, deleted: 0 }),
    release: () => Promise.resolve(),
  };

  const result = await cleanupExpiredAudio(gateway);
  assert(
    result.claimed === 0 && result.staged === 0 && result.deleted === 0,
    "unexpected summary",
  );
  assert(!touchedStorage, "Storage should not be called for an empty claim");
});

Deno.test("cleanupExpiredAudio keeps the first removal as a staged tombstone", async () => {
  const calls: string[] = [];
  const gateway: AudioCleanupGateway = {
    claim: (limit) => {
      calls.push(`claim:${limit}`);
      return Promise.resolve({ claimId, storagePaths: [storagePath] });
    },
    remove: (paths) => {
      calls.push(`remove:${paths.length}`);
      return Promise.resolve();
    },
    complete: (completedClaimId, paths) => {
      calls.push(`complete:${completedClaimId}:${paths.length}`);
      return Promise.resolve({ staged: 1, deleted: 0 });
    },
    release: () => {
      calls.push("release");
      return Promise.resolve();
    },
  };

  const result = await cleanupExpiredAudio(gateway, 25);
  assert(
    result.claimed === 1 && result.staged === 1 && result.deleted === 0,
    "first removal deleted its reservation pointer",
  );
  assert(
    JSON.stringify(calls) ===
      JSON.stringify([`claim:25`, "remove:1", `complete:${claimId}:1`]),
    `unexpected call order: ${calls.join(",")}`,
  );
});

Deno.test("cleanupExpiredAudio deletes only after a second claimed removal", async () => {
  let pass = 0;
  let removeCalls = 0;
  const gateway: AudioCleanupGateway = {
    claim: () => Promise.resolve({ claimId, storagePaths: [storagePath] }),
    remove: () => {
      removeCalls += 1;
      return Promise.resolve();
    },
    complete: () => {
      pass += 1;
      return Promise.resolve(
        pass === 1 ? { staged: 1, deleted: 0 } : { staged: 0, deleted: 1 },
      );
    },
    release: () => Promise.resolve(),
  };

  const first = await cleanupExpiredAudio(gateway);
  const second = await cleanupExpiredAudio(gateway);
  assert(
    first.staged === 1 && first.deleted === 0,
    "first pass did not preserve the tombstone",
  );
  assert(
    second.staged === 0 && second.deleted === 1,
    "verification pass did not finalize the tombstone",
  );
  assert(removeCalls === 2, "Storage was not removed once per cleanup pass");
});

Deno.test("cleanupExpiredAudio releases the lease when Storage deletion fails", async () => {
  let releasedClaimId: string | null = null;
  const gateway: AudioCleanupGateway = {
    claim: () => Promise.resolve({ claimId, storagePaths: [storagePath] }),
    remove: () => Promise.reject(new Error("unavailable")),
    complete: () => Promise.resolve({ staged: 0, deleted: 0 }),
    release: (value) => {
      releasedClaimId = value;
      return Promise.resolve();
    },
  };

  await expectCleanupError(
    () => cleanupExpiredAudio(gateway),
    "storage_cleanup_failed",
  );
  assert(releasedClaimId === claimId, "failed cleanup claim was not released");
});

Deno.test("parseCleanupCompletion requires every claimed path to be accounted for", () => {
  try {
    parseCleanupCompletion({ staged: 0, deleted: 0 }, 1);
  } catch (error) {
    if (!(error instanceof AudioCleanupError)) {
      throw new Error("unexpected error type");
    }
    assert(error.code === "invalid_cleanup_result", "unexpected error code");
    return;
  }
  throw new Error("expected invalid cleanup completion");
});

Deno.test("cleanupExpiredAudio leaves the lease recoverable when finalize fails", async () => {
  let released = false;
  const gateway: AudioCleanupGateway = {
    claim: () => Promise.resolve({ claimId, storagePaths: [storagePath] }),
    remove: () => Promise.resolve(),
    complete: () => Promise.reject(new Error("database unavailable")),
    release: () => {
      released = true;
      return Promise.resolve();
    },
  };

  await expectCleanupError(
    () => cleanupExpiredAudio(gateway),
    "cleanup_finalize_failed",
  );
  assert(!released, "a post-delete claim must stay leased for retry");
});

Deno.test("parseCleanupClaim rejects paths outside reserved audio shape", () => {
  try {
    parseCleanupClaim({
      claimId,
      storagePaths: ["another-bucket/object.txt"],
    });
  } catch (error) {
    if (!(error instanceof AudioCleanupError)) {
      throw new Error("unexpected error type");
    }
    assert(error.code === "invalid_cleanup_claim", "unexpected error code");
    return;
  }
  throw new Error("expected invalid cleanup claim");
});

Deno.test("configuredSecretKeys supports current and legacy server keys", () => {
  const keys = configuredSecretKeys(
    JSON.stringify({
      default: "sb_secret_default",
      automations: "sb_secret_jobs",
    }),
    "legacy-service-role",
  );
  assert(
    JSON.stringify(keys) ===
      JSON.stringify([
        "sb_secret_default",
        "sb_secret_jobs",
        "legacy-service-role",
      ]),
    "configured service keys were not parsed",
  );
});

Deno.test("configuredSecretKeys fails closed on malformed current keys", () => {
  const keys = configuredSecretKeys("not-json", undefined);
  assert(keys.length === 0, "malformed secret configuration was accepted");
});
