package com.otlobli.shamcashlistener;

import android.app.Notification;
import android.os.Bundle;
import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;

public class ShamCashNotificationListener extends NotificationListenerService {
    @Override
    public void onNotificationPosted(StatusBarNotification sbn) {
        if (sbn == null || !ListenerConfig.TARGET_PACKAGE.equals(sbn.getPackageName())) return;

        Notification notification = sbn.getNotification();
        if (notification == null || notification.extras == null) return;

        Bundle extras = notification.extras;
        String title = charSequenceToString(extras.getCharSequence(Notification.EXTRA_TITLE));
        String text = charSequenceToString(extras.getCharSequence(Notification.EXTRA_TEXT));
        String bigText = charSequenceToString(extras.getCharSequence(Notification.EXTRA_BIG_TEXT));
        long postedAt = sbn.getPostTime();
        String eventId = EventIdentity.create(
            ListenerConfig.TARGET_PACKAGE,
            sbn.getKey(),
            postedAt,
            title,
            text,
            bigText
        );

        WebhookForwarder.enqueue(
            getApplicationContext(),
            eventId,
            postedAt,
            ListenerConfig.TARGET_PACKAGE,
            title,
            text,
            bigText
        );
    }

    private static String charSequenceToString(CharSequence value) {
        return value == null ? "" : value.toString();
    }
}
