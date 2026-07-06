package com.otlobli.shamcashlistener;

import android.content.Context;
import android.content.SharedPreferences;

final class ListenerConfig {
    static final String ACTION_SET_CONFIG = "com.otlobli.shamcashlistener.SET_CONFIG";
    static final String ACTION_TEST_NOTIFICATION = "com.otlobli.shamcashlistener.TEST_NOTIFICATION";
    static final String DEFAULT_TARGET_PACKAGE = "com.shmacash.shamcash";

    private static final String PREFS = "shamcash-listener";
    private static final String KEY_WEBHOOK_URL = "webhook_url";
    private static final String KEY_SECRET = "secret";
    private static final String KEY_TARGET_PACKAGE = "target_package";
    private static final String KEY_LAST_HASH = "last_hash";
    private static final String KEY_LAST_RESULT = "last_result";

    private ListenerConfig() {}

    static SharedPreferences prefs(Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    static String webhookUrl(Context context) {
        return prefs(context).getString(KEY_WEBHOOK_URL, "");
    }

    static String secret(Context context) {
        return prefs(context).getString(KEY_SECRET, "");
    }

    static String targetPackage(Context context) {
        return prefs(context).getString(KEY_TARGET_PACKAGE, DEFAULT_TARGET_PACKAGE);
    }

    static void saveConfig(Context context, String webhookUrl, String secret, String targetPackage) {
        prefs(context).edit()
            .putString(KEY_WEBHOOK_URL, webhookUrl == null ? "" : webhookUrl.trim())
            .putString(KEY_SECRET, secret == null ? "" : secret.trim())
            .putString(KEY_TARGET_PACKAGE, targetPackage == null || targetPackage.trim().isEmpty()
                ? DEFAULT_TARGET_PACKAGE
                : targetPackage.trim())
            .apply();
    }

    static boolean rememberHash(Context context, String hash) {
        SharedPreferences preferences = prefs(context);
        String previous = preferences.getString(KEY_LAST_HASH, "");
        if (hash.equals(previous)) return false;
        preferences.edit().putString(KEY_LAST_HASH, hash).apply();
        return true;
    }

    static void saveLastResult(Context context, String result) {
        prefs(context).edit().putString(KEY_LAST_RESULT, result).apply();
    }

    static String lastResult(Context context) {
        return prefs(context).getString(KEY_LAST_RESULT, "");
    }
}
