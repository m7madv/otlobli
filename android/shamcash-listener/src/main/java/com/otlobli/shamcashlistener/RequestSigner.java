package com.otlobli.shamcashlistener;

import java.nio.charset.StandardCharsets;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

final class RequestSigner {
    private static final String ALGORITHM = "HmacSHA256";

    private RequestSigner() {}

    static String sign(String secret, String deviceId, String eventId, long timestamp, byte[] body) throws Exception {
        String prefix = safe(deviceId) + "\n" + safe(eventId) + "\n" + timestamp + "\n";
        byte[] prefixBytes = prefix.getBytes(StandardCharsets.UTF_8);
        byte[] message = new byte[prefixBytes.length + body.length];
        System.arraycopy(prefixBytes, 0, message, 0, prefixBytes.length);
        System.arraycopy(body, 0, message, prefixBytes.length, body.length);
        return hmacHex(secret.getBytes(StandardCharsets.UTF_8), message);
    }

    static String hmacHex(byte[] key, byte[] message) throws Exception {
        Mac mac = Mac.getInstance(ALGORITHM);
        mac.init(new SecretKeySpec(key, ALGORITHM));
        return EventIdentity.toHex(mac.doFinal(message));
    }

    private static String safe(String value) {
        return value == null ? "" : value;
    }
}
