package com.otlobli.shamcashlistener;

import android.app.Notification;
import android.os.Bundle;
import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;

public class ShamCashNotificationListener extends NotificationListenerService {
    @Override
    public void onNotificationPosted(StatusBarNotification sbn) {
        String targetPackage = ListenerConfig.targetPackage(this);
        if (!targetPackage.equals(sbn.getPackageName())) return;

        Notification notification = sbn.getNotification();
        if (notification == null) return;

        Bundle extras = notification.extras;
        String title = charSequenceToString(extras.getCharSequence(Notification.EXTRA_TITLE));
        String text = charSequenceToString(extras.getCharSequence(Notification.EXTRA_TEXT));
        String bigText = charSequenceToString(extras.getCharSequence(Notification.EXTRA_BIG_TEXT));

        WebhookForwarder.forward(this, sbn.getPackageName(), title, text, bigText);
    }

    private static String charSequenceToString(CharSequence value) {
        return value == null ? "" : value.toString();
    }
}
