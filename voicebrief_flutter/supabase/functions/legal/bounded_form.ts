export class BoundedBodyError extends Error {
  constructor(public status: 400 | 413 | 415) {
    super(`bounded_body_${status}`);
  }
}

export async function boundedFormData(
  request: Request,
  maximumBytes: number,
): Promise<FormData> {
  const contentType = request.headers.get("content-type")?.toLowerCase() ?? "";
  if (
    !contentType.startsWith("application/x-www-form-urlencoded") &&
    !contentType.startsWith("multipart/form-data")
  ) {
    throw new BoundedBodyError(415);
  }
  const declaredLength = request.headers.get("content-length");
  if (declaredLength != null) {
    const parsed = Number(declaredLength);
    if (!Number.isFinite(parsed) || parsed < 0) {
      throw new BoundedBodyError(400);
    }
    if (parsed > maximumBytes) throw new BoundedBodyError(413);
  }
  if (request.body == null) throw new BoundedBodyError(400);

  const reader = request.body.getReader();
  const chunks: Uint8Array[] = [];
  let total = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    total += value.byteLength;
    if (total > maximumBytes) {
      await reader.cancel();
      throw new BoundedBodyError(413);
    }
    chunks.push(value);
  }
  const body = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    body.set(chunk, offset);
    offset += chunk.byteLength;
  }
  const boundedRequest = new Request(request.url, {
    method: "POST",
    headers: { "content-type": contentType },
    body,
  });
  try {
    return await boundedRequest.formData();
  } catch {
    throw new BoundedBodyError(400);
  }
}
