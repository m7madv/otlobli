const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const reservedAudioPathPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\/[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\/input\.(flac|mp3|mp4|mpeg|mpga|m4a|ogg|wav|webm)$/i;

export const maxCleanupBatchSize = 100;

export class AudioCleanupError extends Error {
  constructor(public readonly code: string) {
    super(code);
    this.name = "AudioCleanupError";
  }
}

export type CleanupClaim = {
  claimId: string | null;
  storagePaths: string[];
};

export type AudioCleanupGateway = {
  claim(limit: number): Promise<unknown>;
  remove(storagePaths: string[]): Promise<void>;
  complete(claimId: string, storagePaths: string[]): Promise<unknown>;
  release(claimId: string): Promise<void>;
};

export type AudioCleanupSummary = {
  claimed: number;
  staged: number;
  deleted: number;
};

type CleanupCompletion = {
  staged: number;
  deleted: number;
};

export function configuredSecretKeys(
  secretKeysJson: string | undefined,
  legacyServiceRoleKey: string | undefined,
): string[] {
  const keys: string[] = [];
  if (secretKeysJson) {
    try {
      const parsed = JSON.parse(secretKeysJson) as unknown;
      if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
        for (const value of Object.values(parsed)) {
          if (typeof value === "string" && value.length > 0) keys.push(value);
        }
      }
    } catch {
      // Invalid platform configuration fails closed unless the legacy key exists.
    }
  }
  if (legacyServiceRoleKey) keys.push(legacyServiceRoleKey);
  return [...new Set(keys)];
}

export function parseCleanupClaim(value: unknown): CleanupClaim {
  if (!value || typeof value !== "object") {
    throw new AudioCleanupError("invalid_cleanup_claim");
  }
  const candidate = value as Partial<CleanupClaim>;
  if (!Array.isArray(candidate.storagePaths)) {
    throw new AudioCleanupError("invalid_cleanup_claim");
  }
  if (candidate.storagePaths.length > maxCleanupBatchSize) {
    throw new AudioCleanupError("invalid_cleanup_claim");
  }
  const storagePaths = candidate.storagePaths.filter((path): path is string =>
    typeof path === "string" && reservedAudioPathPattern.test(path)
  );
  if (
    storagePaths.length !== candidate.storagePaths.length ||
    new Set(storagePaths).size !== storagePaths.length
  ) {
    throw new AudioCleanupError("invalid_cleanup_claim");
  }
  if (storagePaths.length === 0) {
    if (candidate.claimId !== null) {
      throw new AudioCleanupError("invalid_cleanup_claim");
    }
    return { claimId: null, storagePaths };
  }
  if (
    typeof candidate.claimId !== "string" ||
    !uuidPattern.test(candidate.claimId)
  ) {
    throw new AudioCleanupError("invalid_cleanup_claim");
  }
  return { claimId: candidate.claimId, storagePaths };
}

export function parseCleanupCompletion(
  value: unknown,
  claimed: number,
): CleanupCompletion {
  if (!value || typeof value !== "object") {
    throw new AudioCleanupError("invalid_cleanup_result");
  }
  const candidate = value as Partial<CleanupCompletion>;
  if (
    !Number.isInteger(candidate.staged) || !Number.isInteger(candidate.deleted)
  ) {
    throw new AudioCleanupError("invalid_cleanup_result");
  }
  const staged = candidate.staged as number;
  const deleted = candidate.deleted as number;
  if (staged < 0 || deleted < 0 || staged + deleted !== claimed) {
    throw new AudioCleanupError("invalid_cleanup_result");
  }
  return { staged, deleted };
}

export async function cleanupExpiredAudio(
  gateway: AudioCleanupGateway,
  batchSize = maxCleanupBatchSize,
): Promise<AudioCleanupSummary> {
  if (
    !Number.isInteger(batchSize) || batchSize < 1 ||
    batchSize > maxCleanupBatchSize
  ) {
    throw new AudioCleanupError("invalid_cleanup_batch_size");
  }

  const claim = parseCleanupClaim(await gateway.claim(batchSize));
  if (claim.claimId === null) return { claimed: 0, staged: 0, deleted: 0 };

  try {
    await gateway.remove(claim.storagePaths);
  } catch {
    try {
      await gateway.release(claim.claimId);
    } catch {
      // A bounded database lease makes the claim retryable if release also fails.
    }
    throw new AudioCleanupError("storage_cleanup_failed");
  }

  let completionValue: unknown;
  try {
    completionValue = await gateway.complete(claim.claimId, claim.storagePaths);
  } catch {
    // Keep the claim leased; a later run repeats remove after the lease expires.
    throw new AudioCleanupError("cleanup_finalize_failed");
  }
  const completion = parseCleanupCompletion(
    completionValue,
    claim.storagePaths.length,
  );
  return {
    claimed: claim.storagePaths.length,
    staged: completion.staged,
    deleted: completion.deleted,
  };
}
