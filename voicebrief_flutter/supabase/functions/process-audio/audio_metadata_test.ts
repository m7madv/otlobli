import {
  AudioMetadataError,
  trustedAudioDurationSeconds,
} from "./audio_metadata.ts";

function assertEquals(actual: unknown, expected: unknown) {
  if (actual !== expected) {
    throw new Error(`Expected ${expected}, received ${actual}`);
  }
}

async function assertRejects(
  action: () => Promise<unknown>,
  errorType: typeof AudioMetadataError,
  message: string,
) {
  try {
    await action();
  } catch (error) {
    if (error instanceof errorType && error.message.includes(message)) return;
    throw error;
  }
  throw new Error("Expected action to reject");
}

function pcmWav(seconds: number): Uint8Array {
  const sampleRate = 8_000;
  const dataSize = sampleRate * seconds;
  const bytes = new Uint8Array(44 + dataSize);
  const view = new DataView(bytes.buffer);
  const write = (offset: number, value: string) => {
    for (let index = 0; index < value.length; index += 1) {
      bytes[offset + index] = value.charCodeAt(index);
    }
  };
  write(0, "RIFF");
  view.setUint32(4, 36 + dataSize, true);
  write(8, "WAVE");
  write(12, "fmt ");
  view.setUint32(16, 16, true);
  view.setUint16(20, 1, true);
  view.setUint16(22, 1, true);
  view.setUint32(24, sampleRate, true);
  view.setUint32(28, sampleRate, true);
  view.setUint16(32, 1, true);
  view.setUint16(34, 8, true);
  write(36, "data");
  view.setUint32(40, dataSize, true);
  return bytes;
}

Deno.test("server-derived audio duration accepts a close client estimate", async () => {
  const duration = await trustedAudioDurationSeconds(
    pcmWav(5),
    "audio/wav",
    5,
    60,
  );
  assertEquals(duration, 5);
});

Deno.test("server-derived audio duration rejects a forged short estimate", async () => {
  await assertRejects(
    () => trustedAudioDurationSeconds(pcmWav(30), "audio/wav", 1, 60),
    AudioMetadataError,
    "duration_mismatch",
  );
});

Deno.test("invalid media fails closed", async () => {
  await assertRejects(
    () =>
      trustedAudioDurationSeconds(
        new Uint8Array([1, 2, 3, 4]),
        "audio/wav",
        1,
        60,
      ),
    AudioMetadataError,
    "invalid_audio",
  );
});
