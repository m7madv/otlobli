package com.otlobli.shamcashlistener;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

public class ListenerConfigTest {
    @Test
    public void acceptsOnlyHttpsUrlsWithoutEmbeddedCredentials() {
        assertTrue(ListenerConfig.isValidHttpsUrl("https://example.com/payment-webhook"));
        assertFalse(ListenerConfig.isValidHttpsUrl("http://example.com/payment-webhook"));
        assertFalse(ListenerConfig.isValidHttpsUrl("https://user:password@example.com/payment-webhook"));
        assertFalse(ListenerConfig.isValidHttpsUrl("not a url"));
    }
}
