package com.otlobli.shamcashlistener;

import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

final class EventIdentity {
    private EventIdentity() {}

    static String create(
        String packageName,
        String notificationKey,
        long postedAt,
        String title,
        String text,
        String bigText
    ) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            addPart(digest, packageName);
            addPart(digest, notificationKey);
            digest.update(ByteBuffer.allocate(Long.BYTES).putLong(postedAt).array());
            addPart(digest, title);
            addPart(digest, text);
            addPart(digest, bigText);
            return toHex(digest.digest());
        } catch (Exception error) {
            throw new IllegalStateException("SHA-256 unavailable", error);
        }
    }

    static boolean isValid(String value) {
        return value != null && value.matches("[0-9a-f]{64}");
    }

    private static void addPart(MessageDigest digest, String value) {
        byte[] bytes = safe(value).getBytes(StandardCharsets.UTF_8);
        digest.update(ByteBuffer.allocate(Integer.BYTES).putInt(bytes.length).array());
        digest.update(bytes);
    }

    static String toHex(byte[] bytes) {
        StringBuilder builder = new StringBuilder(bytes.length * 2);
        for (byte value : bytes) builder.append(String.format("%02x", value & 0xff));
        return builder.toString();
    }

    private static String safe(String value) {
        return value == null ? "" : value;
    }
}
