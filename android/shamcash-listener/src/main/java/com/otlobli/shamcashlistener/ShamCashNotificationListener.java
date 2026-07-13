package com.otlobli.shamcashlistener;

import android.app.Notification;
import android.content.ComponentName;
import android.os.Bundle;
import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;

public class ShamCashNotificationListener extends NotificationListenerService {
    private static final long RECOVERY_MAX_AGE_MS = 5L * 60L * 1000L;

    @Override
    public void onListenerConnected() {
        super.onListenerConnected();
        ListenerConfig.saveLastResult(getApplicationContext(), "listener_connected");
        try {
            StatusBarNotification[] active = getActiveNotifications();
            if (active == null) return;
            long now = System.currentTimeMillis();
            for (StatusBarNotification notification : active) {
                long age = now - notification.getPostTime();
                if (age >= 0L && age <= RECOVERY_MAX_AGE_MS) {
                    processNotification(notification);
                }
            }
        } catch (RuntimeException error) {
            ListenerConfig.saveLastResult(
                getApplicationContext(),
                "listener_recovery_failed " + error.getClass().getSimpleName()
            );
        }
    }

    @Override
    public void onListenerDisconnected() {
        ListenerConfig.saveLastResult(getApplicationContext(), "listener_disconnected_rebind_requested");
        requestRebind(new ComponentName(this, ShamCashNotificationListener.class));
        super.onListenerDisconnected();
    }

    @Override
    public void onNotificationPosted(StatusBarNotification sbn) {
        processNotification(sbn);
    }

    private void processNotification(StatusBarNotification sbn) {
        if (sbn == null || !ListenerConfig.TARGET_PACKAGE.equals(sbn.getPackageName())) return;

        Notification notification = sbn.getNotification();
        if (notification == null || notification.extras == null) return;
        // Group summaries can repeat an amount already present in a child
        // notification. Only individual ShamCash notifications may enter the
        // payment pipeline.
        if ((notification.flags & Notification.FLAG_GROUP_SUMMARY) != 0) return;

        Bundle extras = notification.extras;
        String title = charSequenceToString(extras.getCharSequence(Notification.EXTRA_TITLE));
        if (title.isEmpty()) {
            title = charSequenceToString(extras.getCharSequence(Notification.EXTRA_TITLE_BIG));
        }
        String text = collectTextExtras(extras);
        String bigText = charSequenceToString(extras.getCharSequence(Notification.EXTRA_BIG_TEXT));
        long postedAt = sbn.getPostTime();
        String eventId = EventIdentity.create(
            ListenerConfig.TARGET_PACKAGE,
            sbn.getKey(),
            postedAt
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

    private static String collectTextExtras(Bundle extras) {
        StringBuilder result = new StringBuilder();
        appendUnique(result, extras.getCharSequence(Notification.EXTRA_TEXT));
        appendUnique(result, extras.getCharSequence(Notification.EXTRA_SUB_TEXT));
        appendUnique(result, extras.getCharSequence(Notification.EXTRA_INFO_TEXT));
        appendUnique(result, extras.getCharSequence(Notification.EXTRA_SUMMARY_TEXT));

        CharSequence[] lines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES);
        if (lines != null) {
            for (CharSequence line : lines) appendUnique(result, line);
        }
        return result.toString();
    }

    private static void appendUnique(StringBuilder result, CharSequence value) {
        String text = charSequenceToString(value).trim();
        if (text.isEmpty()) return;
        for (String existing : result.toString().split("\\n")) {
            if (existing.equals(text)) return;
        }
        if (result.length() > 0) result.append('\n');
        result.append(text);
    }
}
