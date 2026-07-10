package com.otlobli.shamcashlistener;

import android.content.Context;
import android.content.SharedPreferences;

import org.json.JSONObject;

import java.net.URI;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.UUID;

final class ListenerConfig {
    static final String ACTION_SET_CONFIG = "com.otlobli.shamcashlistener.SET_CONFIG";
    static final String ACTION_TEST_NOTIFICATION = "com.otlobli.shamcashlistener.TEST_NOTIFICATION";
    static final String TARGET_PACKAGE = "com.shmacash.shamcash";

    private static final String PREFS = "shamcash-listener";
    private static final String KEY_WEBHOOK_URL = "webhook_url";
    private static final String KEY_ENCRYPTED_SECRET = "secret_encrypted";
    private static final String KEY_LEGACY_SECRET = "secret";
    private static final String KEY_LEGACY_TARGET_PACKAGE = "target_package";
    private static final String KEY_LEGACY_LAST_HASH = "last_hash";
    private static final String KEY_DEVICE_ID = "device_id";
    private static final String KEY_DELIVERED_EVENTS = "delivered_events";
    private static final String KEY_LAST_RESULT = "last_result";
    private static final long DELIVERED_EVENT_TTL_MS = 30L * 24L * 60L * 60L * 1000L;
    private static final int MAX_DELIVERED_EVENTS = 512;
    private static final int MAX_RESULT_LENGTH = 768;

    private ListenerConfig() {}

    static SharedPreferences prefs(Context context) {
        return context.getApplicationContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    static String webhookUrl(Context context) {
        return prefs(context).getString(KEY_WEBHOOK_URL, "");
    }

    static boolean hasStoredSecret(Context context) {
        SharedPreferences preferences = prefs(context);
        return !preferences.getString(KEY_ENCRYPTED_SECRET, "").isEmpty()
            || !preferences.getString(KEY_LEGACY_SECRET, "").isEmpty();
    }

    static synchronized String secret(Context context) {
        SharedPreferences preferences = prefs(context);
        String encrypted = preferences.getString(KEY_ENCRYPTED_SECRET, "");
        if (!encrypted.isEmpty()) {
            try {
                return SecretStore.decrypt(encrypted);
            } catch (Exception error) {
                saveLastResult(context, "secret_unavailable " + error.getClass().getSimpleName());
                return "";
            }
        }

        // One-time migration for version 1, which kept the shared secret as plaintext.
        String legacy = preferences.getString(KEY_LEGACY_SECRET, "");
        if (legacy.isEmpty()) return "";
        try {
            String sealed = SecretStore.encrypt(legacy);
            if (preferences.edit()
                .putString(KEY_ENCRYPTED_SECRET, sealed)
                .remove(KEY_LEGACY_SECRET)
                .remove(KEY_LEGACY_TARGET_PACKAGE)
                .remove(KEY_LEGACY_LAST_HASH)
                .commit()) {
                return legacy;
            }
            saveLastResult(context, "secret_migration_commit_failed");
        } catch (Exception error) {
            saveLastResult(context, "secret_migration_failed " + error.getClass().getSimpleName());
        }
        return "";
    }

    static synchronized boolean saveConfig(Context context, String webhookUrl, String secret) {
        String normalizedUrl = webhookUrl == null ? "" : webhookUrl.trim();
        String normalizedSecret = secret == null ? "" : secret;
        if (!isValidHttpsUrl(normalizedUrl) || normalizedSecret.isEmpty()) return false;

        try {
            String sealedSecret = SecretStore.encrypt(normalizedSecret);
            return prefs(context).edit()
                .putString(KEY_WEBHOOK_URL, normalizedUrl)
                .putString(KEY_ENCRYPTED_SECRET, sealedSecret)
                .remove(KEY_LEGACY_SECRET)
                .remove(KEY_LEGACY_TARGET_PACKAGE)
                .remove(KEY_LEGACY_LAST_HASH)
                .commit();
        } catch (Exception error) {
            saveLastResult(context, "config_secret_store_failed " + error.getClass().getSimpleName());
            return false;
        }
    }

    static boolean isValidHttpsUrl(String value) {
        try {
            URI uri = URI.create(value);
            return "https".equalsIgnoreCase(uri.getScheme())
                && uri.getHost() != null
                && !uri.getHost().isEmpty()
                && uri.getUserInfo() == null;
        } catch (RuntimeException ignored) {
            return false;
        }
    }

    static synchronized String deviceId(Context context) {
        SharedPreferences preferences = prefs(context);
        String existing = preferences.getString(KEY_DEVICE_ID, "");
        if (!existing.isEmpty()) return existing;

        String generated = UUID.randomUUID().toString();
        if (!preferences.edit().putString(KEY_DEVICE_ID, generated).commit()) {
            saveLastResult(context, "device_id_commit_failed");
        }
        return generated;
    }

    static synchronized boolean wasDelivered(Context context, String eventId) {
        if (eventId == null || eventId.isEmpty()) return false;
        long now = System.currentTimeMillis();
        JSONObject ledger = readDeliveryLedger(context);
        boolean changed = pruneDeliveryLedger(ledger, now);
        boolean delivered = ledger.optLong(eventId, 0L) > 0L;
        if (changed) writeDeliveryLedger(context, ledger);
        return delivered;
    }

    static synchronized void markDelivered(Context context, String eventId) {
        if (eventId == null || eventId.isEmpty()) return;
        long now = System.currentTimeMillis();
        JSONObject ledger = readDeliveryLedger(context);
        pruneDeliveryLedger(ledger, now);
        try {
            ledger.put(eventId, now);
        } catch (Exception ignored) {
            return;
        }

        while (ledger.length() > MAX_DELIVERED_EVENTS) {
            String oldestEventId = null;
            long oldestTimestamp = Long.MAX_VALUE;
            Iterator<String> keys = ledger.keys();
            while (keys.hasNext()) {
                String key = keys.next();
                long timestamp = ledger.optLong(key, 0L);
                if (timestamp < oldestTimestamp) {
                    oldestTimestamp = timestamp;
                    oldestEventId = key;
                }
            }
            if (oldestEventId == null) break;
            ledger.remove(oldestEventId);
        }

        if (!writeDeliveryLedger(context, ledger)) {
            saveLastResult(context, "delivery_ledger_commit_failed");
        }
    }

    private static JSONObject readDeliveryLedger(Context context) {
        String raw = prefs(context).getString(KEY_DELIVERED_EVENTS, "{}");
        try {
            return new JSONObject(raw);
        } catch (Exception ignored) {
            return new JSONObject();
        }
    }

    private static boolean pruneDeliveryLedger(JSONObject ledger, long now) {
        List<String> expired = new ArrayList<>();
        Iterator<String> keys = ledger.keys();
        while (keys.hasNext()) {
            String key = keys.next();
            long deliveredAt = ledger.optLong(key, 0L);
            if (deliveredAt <= 0L || now - deliveredAt > DELIVERED_EVENT_TTL_MS) {
                expired.add(key);
            }
        }
        for (String key : expired) ledger.remove(key);
        return !expired.isEmpty();
    }

    private static boolean writeDeliveryLedger(Context context, JSONObject ledger) {
        return prefs(context).edit().putString(KEY_DELIVERED_EVENTS, ledger.toString()).commit();
    }

    static void saveLastResult(Context context, String result) {
        String safe = result == null ? "" : result.replaceAll("[\\r\\n]+", " ").trim();
        if (safe.length() > MAX_RESULT_LENGTH) safe = safe.substring(0, MAX_RESULT_LENGTH);
        prefs(context).edit().putString(KEY_LAST_RESULT, safe).apply();
    }

    static String lastResult(Context context) {
        return prefs(context).getString(KEY_LAST_RESULT, "");
    }
}
