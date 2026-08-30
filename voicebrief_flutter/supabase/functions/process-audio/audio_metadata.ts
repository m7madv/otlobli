import { parseBuffer } from "music-metadata";

export class AudioMetadataError extends Error {
  constructor(public code: "invalid_audio" | "duration_mismatch") {
    super(code);
  }
}

export async function trustedAudioDurationSeconds(
  bytes: Uint8Array,
  mimeType: string,
  clientDurationSeconds: number,
  maximumDurationSeconds: number,
): Promise<number> {
  try {
    const metadata = await parseBuffer(
      bytes,
      { mimeType, size: bytes.byteLength },
      { duration: true, skipCovers: true },
    );
    const duration = metadata.format.duration;
    if (
      typeof duration !== "number" || !Number.isFinite(duration) ||
      duration <= 0 || duration > maximumDurationSeconds
    ) {
      throw new AudioMetadataError("invalid_audio");
    }
    const trusted = Math.ceil(duration);
    const tolerance = Math.max(3, Math.ceil(duration * 0.03));
    if (Math.abs(clientDurationSeconds - trusted) > tolerance) {
      throw new AudioMetadataError("duration_mismatch");
    }
    return trusted;
  } catch (error) {
    if (error instanceof AudioMetadataError) throw error;
    throw new AudioMetadataError("invalid_audio");
  }
}
