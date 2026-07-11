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
            123456789L
        );
        String second = EventIdentity.create(
            ListenerConfig.TARGET_PACKAGE,
            "0|com.shmacash.shamcash|42",
            123456789L
        );

        assertEquals(first, second);
        assertTrue(EventIdentity.isValid(first));
    }

    @Test
    public void notificationUpdatesKeepIdentityButNewPostsDoNot() {
        String base = EventIdentity.create("pkg", "key", 100L);
        String samePostedNotificationAfterContentUpdate = EventIdentity.create("pkg", "key", 100L);
        String changedTime = EventIdentity.create("pkg", "key", 101L);

        assertEquals(base, samePostedNotificationAfterContentUpdate);
        assertNotEquals(base, changedTime);
        assertFalse(EventIdentity.isValid("not-a-sha256-id"));
    }
}
