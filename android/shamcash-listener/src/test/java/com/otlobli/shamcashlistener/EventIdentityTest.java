package com.otlobli.shamcashlistener;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotEquals;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

public class EventIdentityTest {
    @Test
    public void sameNotificationProducesStableEventId() {
        String first = EventIdentity.create(
            ListenerConfig.TARGET_PACKAGE,
            "0|com.shmacash.shamcash|42",
            123456789L,
            "تم استلام حوالة",
            "25 USD",
            ""
        );
        String second = EventIdentity.create(
            ListenerConfig.TARGET_PACKAGE,
            "0|com.shmacash.shamcash|42",
            123456789L,
            "تم استلام حوالة",
            "25 USD",
            ""
        );

        assertEquals(first, second);
        assertTrue(EventIdentity.isValid(first));
    }

    @Test
    public void contentAndPostTimeAreBoundIntoEventId() {
        String base = EventIdentity.create("pkg", "key", 100L, "title", "10 USD", "");
        String changedBody = EventIdentity.create("pkg", "key", 100L, "title", "11 USD", "");
        String changedTime = EventIdentity.create("pkg", "key", 101L, "title", "10 USD", "");

        assertNotEquals(base, changedBody);
        assertNotEquals(base, changedTime);
        assertFalse(EventIdentity.isValid("not-a-sha256-id"));
    }
}
