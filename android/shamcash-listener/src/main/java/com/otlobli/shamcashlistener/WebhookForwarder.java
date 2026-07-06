package com.otlobli.shamcashlistener;

import android.content.Context;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.OutputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;

final class WebhookForwarder {
    private WebhookForwarder() {}

    static void forward(Context context, String packageName, String title, String text, String bigText) {
        String combinedText = join(title, text, bigText).trim();
        if (combinedText.isEmpty()) return;

        String hash = packageName + "|" + combinedText.hashCode();
        if (!ListenerConfig.rememberHash(context, hash)) return;

        new Thread(() -> send(context.getApplicationContext(), packageName, title, text, bigText, combinedText)).start();
    }

    private static String join(String title, String text, String bigText) {
        StringBuilder builder = new StringBuilder();
        if (title != null && !title.trim().isEmpty()) builder.append(title.trim()).append('\n');
        if (text != null && !text.trim().isEmpty()) builder.append(text.trim()).append('\n');
        if (bigText != null && !bigText.trim().isEmpty() && !bigText.equals(text)) builder.append(bigText.trim());
        return builder.toString();
    }

    private static void send(
        Context context,
        String packageName,
        String title,
        String text,
        String bigText,
        String combinedText
    ) {
        String webhookUrl = ListenerConfig.webhookUrl(context);
        String secret = ListenerConfig.secret(context);
        if (webhookUrl.isEmpty() || secret.isEmpty()) {
            ListenerConfig.saveLastResult(context, "missing_config");
            return;
        }

        HttpURLConnection connection = null;
        try {
            JSONObject payload = new JSONObject();
            payload.put("packageName", packageName);
            payload.put("title", title == null ? "" : title);
            payload.put("body", text == null ? "" : text);
            payload.put("bigText", bigText == null ? "" : bigText);
            payload.put("notificationText", combinedText);
            payload.put("sentAt", System.currentTimeMillis());

            byte[] body = payload.toString().getBytes(StandardCharsets.UTF_8);
            connection = (HttpURLConnection) new URL(webhookUrl).openConnection();
            connection.setRequestMethod("POST");
            connection.setConnectTimeout(15000);
            connection.setReadTimeout(15000);
            connection.setDoOutput(true);
            connection.setRequestProperty("content-type", "application/json; charset=utf-8");
            connection.setRequestProperty("x-payment-secret", secret);
            connection.setRequestProperty("content-length", String.valueOf(body.length));

            try (OutputStream output = connection.getOutputStream()) {
                output.write(body);
            }

            int status = connection.getResponseCode();
            String response = readResponse(connection, status);
            ListenerConfig.saveLastResult(context, status + " " + response);
        } catch (Exception err) {
            ListenerConfig.saveLastResult(context, "error " + err.getClass().getSimpleName() + ": " + err.getMessage());
        } finally {
            if (connection != null) connection.disconnect();
        }
    }

    private static String readResponse(HttpURLConnection connection, int status) {
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(
            status >= 400 ? connection.getErrorStream() : connection.getInputStream(),
            StandardCharsets.UTF_8
        ))) {
            StringBuilder builder = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) builder.append(line);
            return builder.toString();
        } catch (Exception ignored) {
            return "";
        }
    }
}
