package com.otlobli.shamcashlistener;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public class ConfigReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent == null || intent.getAction() == null) return;

        if (ListenerConfig.ACTION_SET_CONFIG.equals(intent.getAction())) {
            ListenerConfig.saveConfig(
                context,
                intent.getStringExtra("webhook_url"),
                intent.getStringExtra("secret"),
                intent.getStringExtra("target_package")
            );
            ListenerConfig.saveLastResult(context, "config_saved");
            return;
        }

        if (ListenerConfig.ACTION_TEST_NOTIFICATION.equals(intent.getAction())) {
            String title = intent.getStringExtra("title");
            String text = intent.getStringExtra("text");
            String bigText = intent.getStringExtra("big_text");
            WebhookForwarder.forward(context, ListenerConfig.DEFAULT_TARGET_PACKAGE, title, text, bigText);
        }
    }
}
