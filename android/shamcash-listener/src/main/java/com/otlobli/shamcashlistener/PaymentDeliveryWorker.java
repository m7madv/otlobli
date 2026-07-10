package com.otlobli.shamcashlistener;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.work.Data;
import androidx.work.Worker;
import androidx.work.WorkerParameters;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;

public final class PaymentDeliveryWorker extends Worker {
    private static final int CONNECT_TIMEOUT_MS = 15_000;
    private static final int READ_TIMEOUT_MS = 20_000;
    private static final int MAX_RESPONSE_CHARS = 768;

    public PaymentDeliveryWorker(@NonNull Context context, @NonNull WorkerParameters parameters) {
        super(context, parameters);
    }

    @NonNull
    @Override
    public Result doWork() {
        Context context = getApplicationContext();
        Data input = getInputData();
        String eventId = safe(input.getString(WebhookForwarder.KEY_EVENT_ID));
        String packageName = safe(input.getString(WebhookForwarder.KEY_PACKAGE_NAME));
        String title = safe(input.getString(WebhookForwarder.KEY_TITLE));
        String text = safe(input.getString(WebhookForwarder.KEY_TEXT));
        String bigText = safe(input.getString(WebhookForwarder.KEY_BIG_TEXT));
        long postedAt = input.getLong(WebhookForwarder.KEY_POSTED_AT, 0L);

        if (!EventIdentity.isValid(eventId) || !ListenerConfig.TARGET_PACKAGE.equals(packageName)) {
            ListenerConfig.saveLastResult(context, "delivery_rejected invalid_event");
            return Result.failure();
        }
        if (!NotificationClassifier.looksLikeIncomingPayment(title, text, bigText)) {
            ListenerConfig.saveLastResult(context, "delivery_rejected classifier");
            return Result.failure();
        }
        if (ListenerConfig.wasDelivered(context, eventId)) return Result.success();

        String webhookUrl = ListenerConfig.webhookUrl(context);
        String secret = ListenerConfig.secret(context);
        if (!ListenerConfig.isValidHttpsUrl(webhookUrl) || secret.isEmpty()) {
            return retry(context, "missing_config");
        }

        try {
            String deviceId = ListenerConfig.deviceId(context);
            byte[] body = createBody(
                packageName,
                title,
                text,
                bigText,
                WebhookForwarder.join(title, text, bigText),
                postedAt,
                eventId,
                deviceId
            );
            long signatureTimestamp = System.currentTimeMillis();
            String signature = RequestSigner.sign(secret, deviceId, eventId, signatureTimestamp, body);
            HttpResult response = post(
                webhookUrl,
                secret,
                deviceId,
                eventId,
                signatureTimestamp,
                signature,
                body
            );

            String summary = response.status + " " + response.body;
            if (response.status >= 200 && response.status < 300) {
                // The delivery ledger is intentionally written only after the server
                // accepted the request. Network/config failures remain retryable work.
                ListenerConfig.markDelivered(context, eventId);
                ListenerConfig.saveLastResult(context, "delivered " + eventId.substring(0, 12) + " " + summary);
                return Result.success();
            }

            if (response.status == 404 && getRunAttemptCount() >= 12) {
                ListenerConfig.saveLastResult(context, "delivery_expired_unmatched " + summary);
                return Result.failure();
            }
            if (shouldRetry(response.status)) return retry(context, summary);
            ListenerConfig.saveLastResult(context, "delivery_failed " + summary);
            return Result.failure();
        } catch (Exception error) {
            return retry(context, "exception " + error.getClass().getSimpleName());
        }
    }

    private Result retry(Context context, String reason) {
        ListenerConfig.saveLastResult(
            context,
            "retry " + (getRunAttemptCount() + 1) + " " + reason
        );
        return Result.retry();
    }

    private static byte[] createBody(
        String packageName,
        String title,
        String text,
        String bigText,
        String notificationText,
        long postedAt,
        String eventId,
        String deviceId
    ) throws Exception {
        JSONObject payload = new JSONObject();
        payload.put("packageName", packageName);
        payload.put("title", title);
        payload.put("body", text);
        payload.put("bigText", bigText);
        payload.put("notificationText", notificationText);
        payload.put("sentAt", postedAt);
        payload.put("eventId", eventId);
        payload.put("deviceId", deviceId);
        return payload.toString().getBytes(StandardCharsets.UTF_8);
    }

    private static HttpResult post(
        String webhookUrl,
        String secret,
        String deviceId,
        String eventId,
        long timestamp,
        String signature,
        byte[] body
    ) throws Exception {
        HttpURLConnection connection = null;
        try {
            connection = (HttpURLConnection) new URL(webhookUrl).openConnection();
            connection.setRequestMethod("POST");
            connection.setConnectTimeout(CONNECT_TIMEOUT_MS);
            connection.setReadTimeout(READ_TIMEOUT_MS);
            connection.setDoOutput(true);
            connection.setUseCaches(false);
            connection.setInstanceFollowRedirects(false);
            connection.setFixedLengthStreamingMode(body.length);
            connection.setRequestProperty("content-type", "application/json; charset=utf-8");
            // Kept for compatibility with the current endpoint. The HMAC headers let
            // the server migrate to replay-resistant verification without another APK.
            connection.setRequestProperty("x-payment-secret", secret);
            connection.setRequestProperty("x-payment-device", deviceId);
            connection.setRequestProperty("x-payment-event", eventId);
            connection.setRequestProperty("x-payment-timestamp", Long.toString(timestamp));
            connection.setRequestProperty("x-payment-signature", "v1=" + signature);

            try (OutputStream output = connection.getOutputStream()) {
                output.write(body);
            }

            int status = connection.getResponseCode();
            return new HttpResult(status, readResponse(connection, status));
        } finally {
            if (connection != null) connection.disconnect();
        }
    }

    private static boolean shouldRetry(int status) {
        return status == 401
            || status == 403
            || status == 404
            || status == 408
            || status == 409
            || status == 425
            || status == 429
            || status >= 500;
    }

    private static String readResponse(HttpURLConnection connection, int status) {
        InputStream stream = null;
        try {
            stream = status >= 400 ? connection.getErrorStream() : connection.getInputStream();
            if (stream == null) return "";
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(stream, StandardCharsets.UTF_8))) {
                StringBuilder builder = new StringBuilder();
                int next;
                while (builder.length() < MAX_RESPONSE_CHARS && (next = reader.read()) != -1) {
                    char value = (char) next;
                    builder.append(value == '\r' || value == '\n' ? ' ' : value);
                }
                return builder.toString().trim();
            }
        } catch (Exception ignored) {
            if (stream != null) {
                try {
                    stream.close();
                } catch (Exception ignoredClose) {
                    // Nothing else to do while reporting an HTTP result.
                }
            }
            return "";
        }
    }

    private static String safe(String value) {
        return value == null ? "" : value;
    }

    private static final class HttpResult {
        final int status;
        final String body;

        HttpResult(int status, String body) {
            this.status = status;
            this.body = body;
        }
    }
}
