package com.otlobli.shamcashlistener;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public class ConfigReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent == null || !ListenerConfig.ACTION_SET_CONFIG.equals(intent.getAction())) return;

        // Keystore access can be slow on older hardware. Keep it off the receiver's
        // main thread while goAsync() keeps the process alive until provisioning ends.
        PendingResult pendingResult = goAsync();
        Context appContext = context.getApplicationContext();
        new Thread(() -> {
            try {
                boolean saved = ListenerConfig.saveConfig(
                    appContext,
                    intent.getStringExtra("webhook_url"),
                    intent.getStringExtra("secret")
                );
                ListenerConfig.saveLastResult(appContext, saved ? "config_saved_securely" : "config_rejected");
            } finally {
                pendingResult.finish();
            }
        }, "shamcash-config").start();
    }
}
