import {
  uploadedObjectMatchesReservation,
  UploadTicketStorageError,
} from "./core.ts";

function assert(condition: boolean, message: string) {
  if (!condition) throw new Error(message);
}

function expectStorageError(action: () => unknown, code: string) {
  try {
    action();
  } catch (error) {
    if (!(error instanceof UploadTicketStorageError)) {
      throw new Error("unexpected error type");
    }
    assert(error.code === code, `expected ${code}, received ${error.code}`);
    return;
  }
  throw new Error(`expected ${code}`);
}

Deno.test("matching stored object can skip a duplicate upload", () => {
  assert(
    uploadedObjectMatchesReservation(
      { size: 4096, contentType: "audio/mp4; charset=binary" },
      null,
      4096,
      "audio/mp4",
    ),
    "matching object was not accepted",
  );
});

Deno.test("an explicit not-found result requires a new upload", () => {
  assert(
    !uploadedObjectMatchesReservation(
      null,
      { status: 404, statusCode: "NoSuchKey" },
      4096,
      "audio/mp4",
    ),
    "missing object was treated as uploaded",
  );
});

Deno.test("storage failures never bypass upload", () => {
  expectStorageError(
    () =>
      uploadedObjectMatchesReservation(
        null,
        { status: 503, statusCode: "503" },
        4096,
        "audio/mp4",
      ),
    "storage_info_failed",
  );
});

Deno.test("mismatched object metadata never bypasses upload", () => {
  expectStorageError(
    () =>
      uploadedObjectMatchesReservation(
        { size: 2048, contentType: "audio/mpeg" },
        null,
        4096,
        "audio/mp4",
      ),
    "uploaded_object_mismatch",
  );
});
