package com.otlobli.shamcashlistener;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotEquals;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;

import org.junit.Test;

public class RequestSignerTest {
    @Test
    public void hmacSha256MatchesRfc4231Vector() throws Exception {
        byte[] key = new byte[20];
        Arrays.fill(key, (byte) 0x0b);
        String result = RequestSigner.hmacHex(key, "Hi There".getBytes(StandardCharsets.UTF_8));
        assertEquals(
            "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7",
            result
        );
    }

    @Test
    public void signatureBindsDeviceEventTimestampAndBody() throws Exception {
        byte[] body = "{\"amount\":25}".getBytes(StandardCharsets.UTF_8);
        String first = RequestSigner.sign("secret", "device-a", "event-a", 123L, body);
        String same = RequestSigner.sign("secret", "device-a", "event-a", 123L, body);
        String changedEvent = RequestSigner.sign("secret", "device-a", "event-b", 123L, body);
        String changedBody = RequestSigner.sign(
            "secret",
            "device-a",
            "event-a",
            123L,
            "{\"amount\":26}".getBytes(StandardCharsets.UTF_8)
        );

        assertEquals(first, same);
        assertNotEquals(first, changedEvent);
        assertNotEquals(first, changedBody);
    }

    @Test
    public void signatureMatchesCrossPlatformUtf8ProtocolVector() throws Exception {
        String eventId = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
        byte[] body = (
            "{\"packageName\":\"com.shmacash.shamcash\","
                + "\"body\":\"تم استلام ٢٥ دولار\"}"
        ).getBytes(StandardCharsets.UTF_8);

        assertEquals(
            "a695f62636d49b94a8dea0eea4ae95ebe3ca5e1e28aefddee1d9ced35c6fa210",
            RequestSigner.sign("secret-شام", "note8-terminal", eventId, 1770000000123L, body)
        );
    }
}
