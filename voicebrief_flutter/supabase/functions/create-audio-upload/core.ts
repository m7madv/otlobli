export class UploadTicketStorageError extends Error {
  constructor(public readonly code: string) {
    super(code);
    this.name = "UploadTicketStorageError";
  }
}

type StorageInfo = {
  size?: unknown;
  contentType?: unknown;
};

type StorageFailure = {
  status?: unknown;
  statusCode?: unknown;
};

function normalizedMimeType(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const normalized = value.split(";", 1)[0].trim().toLowerCase();
  return normalized.length > 0 ? normalized : null;
}

function storageStatus(error: unknown): number | null {
  if (!error || typeof error !== "object") return null;
  const failure = error as StorageFailure;
  if (typeof failure.status === "number") return failure.status;
  if (typeof failure.statusCode === "string") {
    const parsed = Number(failure.statusCode);
    if (Number.isInteger(parsed)) return parsed;
  }
  return null;
}

export function uploadedObjectMatchesReservation(
  data: StorageInfo | null,
  error: unknown,
  expectedSizeBytes: number,
  expectedMimeType: string,
): boolean {
  if (error != null) {
    if (storageStatus(error) === 404) return false;
    throw new UploadTicketStorageError("storage_info_failed");
  }
  if (data == null) {
    throw new UploadTicketStorageError("storage_info_failed");
  }
  if (
    data.size !== expectedSizeBytes ||
    normalizedMimeType(data.contentType) !==
      normalizedMimeType(expectedMimeType)
  ) {
    throw new UploadTicketStorageError("uploaded_object_mismatch");
  }
  return true;
}
