package com.otlobli.shamcashlistener;

import android.content.Context;

import androidx.work.BackoffPolicy;
import androidx.work.Constraints;
import androidx.work.Data;
import androidx.work.ExistingWorkPolicy;
import androidx.work.NetworkType;
import androidx.work.OneTimeWorkRequest;
import androidx.work.WorkManager;

import java.nio.charset.StandardCharsets;
import java.util.concurrent.TimeUnit;

final class WebhookForwarder {
    static final String KEY_EVENT_ID = "event_id";
    static final String KEY_POSTED_AT = "posted_at";
    static final String KEY_PACKAGE_NAME = "package_name";
    static final String KEY_TITLE = "title";
    static final String KEY_TEXT = "text";
    static final String KEY_BIG_TEXT = "big_text";

    private static final String UNIQUE_WORK_PREFIX = "shamcash-delivery-";
    private static final String WORK_TAG = "shamcash-payment-delivery";
    private static final int TITLE_UTF8_BYTES = 384;
    private static final int TEXT_UTF8_BYTES = 2_048;
    private static final int BIG_TEXT_UTF8_BYTES = 3_072;

    private WebhookForwarder() {}

    static boolean enqueue(
        Context context,
        String eventId,
        long postedAt,
        String packageName,
        String title,
        String text,
        String bigText
    ) {
        Context appContext = context.getApplicationContext();
        if (!ListenerConfig.TARGET_PACKAGE.equals(packageName) || !EventIdentity.isValid(eventId)) return false;
        if (!NotificationClassifier.shouldForwardCandidate(title, text, bigText)) return false;
        if (ListenerConfig.wasDelivered(appContext, eventId)) return false;

        try {
            // WorkManager Data is limited to 10 KiB after serialization. Limit actual
            // UTF-8 bytes (not Java chars), leave ample envelope overhead, and keep the
            // build itself inside the guarded path so oversized vendor extras cannot
            // crash the listener callback.
            Data input = new Data.Builder()
                .putString(KEY_EVENT_ID, eventId)
                .putLong(KEY_POSTED_AT, postedAt)
                .putString(KEY_PACKAGE_NAME, packageName)
                .putString(KEY_TITLE, truncateUtf8(title, TITLE_UTF8_BYTES))
                .putString(KEY_TEXT, truncateUtf8(text, TEXT_UTF8_BYTES))
                .putString(KEY_BIG_TEXT, truncateUtf8(bigText, BIG_TEXT_UTF8_BYTES))
                .build();

            Constraints constraints = new Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build();

            OneTimeWorkRequest request = new OneTimeWorkRequest.Builder(PaymentDeliveryWorker.class)
                .setInputData(input)
                .setConstraints(constraints)
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
                .addTag(WORK_TAG)
                .build();

            WorkManager.getInstance(appContext).enqueueUniqueWork(
                UNIQUE_WORK_PREFIX + eventId,
                ExistingWorkPolicy.KEEP,
                request
            );
            ListenerConfig.saveLastResult(appContext, "queued " + eventId.substring(0, 12));
            return true;
        } catch (RuntimeException error) {
            ListenerConfig.saveLastResult(appContext, "queue_error " + error.getClass().getSimpleName());
            return false;
        }
    }

    static String join(String title, String text, String bigText) {
        StringBuilder builder = new StringBuilder();
        appendLine(builder, title);
        appendLine(builder, text);
        if (bigText != null && !bigText.trim().isEmpty() && !bigText.trim().equals(safe(text).trim())) {
            appendLine(builder, bigText);
        }
        return builder.toString().trim();
    }

    private static void appendLine(StringBuilder builder, String value) {
        if (value == null || value.trim().isEmpty()) return;
        if (builder.length() > 0) builder.append('\n');
        builder.append(value.trim());
    }

    static String truncateUtf8(String value, int maxBytes) {
        String safe = safe(value);
        if (safe.getBytes(StandardCharsets.UTF_8).length <= maxBytes) return safe;

        StringBuilder result = new StringBuilder();
        int usedBytes = 0;
        for (int offset = 0; offset < safe.length();) {
            int codePoint = safe.codePointAt(offset);
            String character = new String(Character.toChars(codePoint));
            int characterBytes = character.getBytes(StandardCharsets.UTF_8).length;
            if (usedBytes + characterBytes > maxBytes) break;
            result.append(character);
            usedBytes += characterBytes;
            offset += Character.charCount(codePoint);
        }
        return result.toString();
    }

    private static String safe(String value) {
        return value == null ? "" : value;
    }
}
