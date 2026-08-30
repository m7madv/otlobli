export class BoundedJsonError extends Error {
  constructor(public status: 400 | 413 | 415) {
    super(`bounded_json_${status}`);
  }
}

export async function boundedJson(
  request: Request,
  maximumBytes: number,
): Promise<unknown> {
  const contentType = request.headers.get("content-type")?.toLowerCase() ?? "";
  if (!contentType.startsWith("application/json")) {
    throw new BoundedJsonError(415);
  }

  const declaredLength = request.headers.get("content-length");
  if (declaredLength != null) {
    const parsed = Number(declaredLength);
    if (!Number.isFinite(parsed) || parsed < 0) {
      throw new BoundedJsonError(400);
    }
    if (parsed > maximumBytes) throw new BoundedJsonError(413);
  }
  if (request.body == null) throw new BoundedJsonError(400);

  const reader = request.body.getReader();
  const chunks: Uint8Array[] = [];
  let total = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    total += value.byteLength;
    if (total > maximumBytes) {
      await reader.cancel();
      throw new BoundedJsonError(413);
    }
    chunks.push(value);
  }

  const bytes = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.byteLength;
  }
  try {
    return JSON.parse(new TextDecoder("utf-8", { fatal: true }).decode(bytes));
  } catch {
    throw new BoundedJsonError(400);
  }
}
