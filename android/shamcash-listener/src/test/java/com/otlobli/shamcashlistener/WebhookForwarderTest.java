package com.otlobli.shamcashlistener;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;

import org.junit.Test;

import java.nio.charset.StandardCharsets;

public class WebhookForwarderTest {
    @Test
    public void truncatesByUtf8BytesWithoutSplittingUnicodeCodePoints() {
        String value = "دفعة-💳-123";
        String truncated = WebhookForwarder.truncateUtf8(value, 12);

        assertEquals("دفعة-", truncated);
        assertFalse(truncated.contains("�"));
        assertEquals(9, truncated.getBytes(StandardCharsets.UTF_8).length);
    }

    @Test
    public void leavesShortUtf8TextUnchanged() {
        assertEquals("شام كاش", WebhookForwarder.truncateUtf8("شام كاش", 64));
    }
}
