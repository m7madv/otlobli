package com.otlobli.shamcashlistener;

import android.content.Context;

import androidx.work.BackoffPolicy;
import androidx.work.Constraints;
import androidx.work.Data;
import androidx.work.ExistingWorkPolicy;
import androidx.work.NetworkType;
import androidx.work.OneTimeWorkRequest;
import androidx.work.WorkManager;

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
        if (!NotificationClassifier.looksLikeIncomingPayment(title, text, bigText)) return false;
        if (ListenerConfig.wasDelivered(appContext, eventId)) return false;

        // WorkManager Data is limited to 10 KB. These caps keep worst-case UTF-8
        // notification input below that limit without losing normal payment text.
        Data input = new Data.Builder()
            .putString(KEY_EVENT_ID, eventId)
            .putLong(KEY_POSTED_AT, postedAt)
            .putString(KEY_PACKAGE_NAME, packageName)
            .putString(KEY_TITLE, truncate(title, 256))
            .putString(KEY_TEXT, truncate(text, 1024))
            .putString(KEY_BIG_TEXT, truncate(bigText, 1400))
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

        try {
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

    private static String truncate(String value, int maxLength) {
        String safe = safe(value);
        return safe.length() <= maxLength ? safe : safe.substring(0, maxLength);
    }

    private static String safe(String value) {
        return value == null ? "" : value;
    }
}
