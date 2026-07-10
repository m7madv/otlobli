package com.otlobli.shamcashlistener;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public class ConfigReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent == null || intent.getAction() == null) return;
        String action = intent.getAction();
        if (!ListenerConfig.ACTION_SET_CONFIG.equals(action)
            && !ListenerConfig.ACTION_TEST_NOTIFICATION.equals(action)) {
            return;
        }

        // Keystore access can be slow on older hardware. Keep it off the receiver's
        // main thread while goAsync() keeps the process alive until provisioning ends.
        PendingResult pendingResult = goAsync();
        Context appContext = context.getApplicationContext();
        new Thread(() -> {
            try {
                if (ListenerConfig.ACTION_SET_CONFIG.equals(action)) {
                    boolean saved = ListenerConfig.saveConfig(
                        appContext,
                        intent.getStringExtra("webhook_url"),
                        intent.getStringExtra("secret")
                    );
                    ListenerConfig.saveLastResult(appContext, saved ? "config_saved_securely" : "config_rejected");
                    return;
                }

                enqueueProtectedTest(appContext, intent);
            } finally {
                pendingResult.finish();
            }
        }, "shamcash-config").start();
    }

    private static void enqueueProtectedTest(Context context, Intent intent) {
        String title = intent.getStringExtra("title");
        String text = intent.getStringExtra("text");
        String bigText = intent.getStringExtra("big_text");
        long postedAt = intent.getLongExtra("sent_at", System.currentTimeMillis());
        String requestedEventId = intent.getStringExtra("event_id");
        String eventId = EventIdentity.isValid(requestedEventId)
            ? requestedEventId
            : EventIdentity.create(
                ListenerConfig.TARGET_PACKAGE,
                "protected-adb-test",
                postedAt,
                title,
                text,
                bigText
            );

        WebhookForwarder.enqueue(
            context,
            eventId,
            postedAt,
            ListenerConfig.TARGET_PACKAGE,
            title,
            text,
            bigText
        );
    }
}
