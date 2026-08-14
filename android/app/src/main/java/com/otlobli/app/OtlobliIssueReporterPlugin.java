package com.otlobli.app;

import android.app.Dialog;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.GradientDrawable;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import android.text.Editable;
import android.text.InputFilter;
import android.text.TextWatcher;
import android.util.Base64;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.PixelCopy;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import java.io.ByteArrayOutputStream;

@CapacitorPlugin(name = "OtlobliIssueReporter")
public class OtlobliIssueReporterPlugin extends Plugin implements SensorEventListener {

    private static final float STRONG_SHAKE_G = 2.65f;
    private static final float IMMEDIATE_SHAKE_G = 3.55f;
    private static final long PEAK_WINDOW_MS = 720L;
    private static final long COOLDOWN_MS = 4_000L;
    private static final int MAX_SCREENSHOT_WIDTH = 720;
    private static final int MAX_NOTE_LENGTH = 800;

    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private SensorManager sensorManager;
    private Sensor accelerometer;
    private long firstPeakAt;
    private long lastReportAt;
    private boolean captureInFlight;
    private Dialog reportDialog;

    @Override
    public void load() {
        sensorManager = (SensorManager) getContext().getSystemService(Context.SENSOR_SERVICE);
        accelerometer = sensorManager == null ? null : sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
        registerShakeSensor();
    }

    @Override
    protected void handleOnResume() {
        registerShakeSensor();
    }

    @Override
    protected void handleOnPause() {
        unregisterShakeSensor();
        firstPeakAt = 0L;
    }

    @Override
    protected void handleOnDestroy() {
        unregisterShakeSensor();
        if (reportDialog != null) reportDialog.dismiss();
        reportDialog = null;
    }

    private void registerShakeSensor() {
        if (sensorManager != null && accelerometer != null) {
            sensorManager.unregisterListener(this);
            sensorManager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_GAME);
        }
    }

    private void unregisterShakeSensor() {
        if (sensorManager != null) sensorManager.unregisterListener(this);
    }

    @Override
    public void onSensorChanged(SensorEvent event) {
        if (event.sensor.getType() != Sensor.TYPE_ACCELEROMETER || event.values.length < 3) return;
        if (captureInFlight || (reportDialog != null && reportDialog.isShowing())) return;

        float x = event.values[0] / SensorManager.GRAVITY_EARTH;
        float y = event.values[1] / SensorManager.GRAVITY_EARTH;
        float z = event.values[2] / SensorManager.GRAVITY_EARTH;
        float force = (float) Math.sqrt(x * x + y * y + z * z);
        if (force < STRONG_SHAKE_G) return;

        long now = SystemClock.elapsedRealtime();
        if (now - lastReportAt < COOLDOWN_MS) return;
        if (force >= IMMEDIATE_SHAKE_G || (firstPeakAt > 0L && now - firstPeakAt <= PEAK_WINDOW_MS)) {
            firstPeakAt = 0L;
            lastReportAt = now;
            mainHandler.post(this::captureCurrentWindow);
        } else {
            firstPeakAt = now;
        }
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
        // No calibration is needed for a threshold-only gesture.
    }

    @PluginMethod
    public void openForTesting(PluginCall call) {
        if (!BuildConfig.DEBUG) {
            call.reject("debug_only");
            return;
        }
        mainHandler.post(this::captureCurrentWindow);
        call.resolve();
    }

    @PluginMethod
    public void showResult(PluginCall call) {
        boolean success = call.getBoolean("success", false);
        String message = call.getString(
            "message",
            success ? "تم إرسال البلاغ للإدارة" : "تعذر إرسال البلاغ. سنحاول مرة أخرى."
        );
        mainHandler.post(() -> Toast.makeText(getContext(), message, Toast.LENGTH_LONG).show());
        call.resolve();
    }

    private void captureCurrentWindow() {
        if (captureInFlight || getActivity() == null || getActivity().isFinishing()) return;
        captureInFlight = true;
        Window window = getActivity().getWindow();
        View decor = window.getDecorView();
        SurfaceView storeSurface = findLargestVisibleSurface(decor, null);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && storeSurface != null &&
            storeSurface.getHolder().getSurface().isValid()) {
            Bitmap surfaceBitmap = Bitmap.createBitmap(
                Math.max(1, storeSurface.getWidth()),
                Math.max(1, storeSurface.getHeight()),
                Bitmap.Config.ARGB_8888
            );
            try {
                PixelCopy.request(storeSurface, surfaceBitmap, result -> {
                    if (result == PixelCopy.SUCCESS) {
                        finishCapture(surfaceBitmap);
                    } else {
                        surfaceBitmap.recycle();
                        captureWindow(window, decor);
                    }
                }, mainHandler);
                return;
            } catch (Throwable ignored) {
                surfaceBitmap.recycle();
            }
        }
        captureWindow(window, decor);
    }

    private void captureWindow(Window window, View decor) {
        int width = Math.max(1, decor.getWidth());
        int height = Math.max(1, decor.getHeight());
        Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                PixelCopy.request(window, bitmap, result -> {
                    if (result == PixelCopy.SUCCESS) {
                        finishCapture(bitmap);
                    } else {
                        drawFallback(decor, bitmap);
                    }
                }, mainHandler);
                return;
            } catch (Throwable ignored) {
                // Fall through to View.draw on devices that reject PixelCopy.
            }
        }
        drawFallback(decor, bitmap);
    }

    private SurfaceView findLargestVisibleSurface(View view, SurfaceView current) {
        SurfaceView best = current;
        if (view instanceof SurfaceView && view.getVisibility() == View.VISIBLE && view.getWidth() > 0 && view.getHeight() > 0) {
            SurfaceView candidate = (SurfaceView) view;
            long candidateArea = (long) candidate.getWidth() * candidate.getHeight();
            long bestArea = best == null ? 0L : (long) best.getWidth() * best.getHeight();
            if (candidateArea > bestArea) best = candidate;
        }
        if (view instanceof ViewGroup) {
            ViewGroup group = (ViewGroup) view;
            for (int index = 0; index < group.getChildCount(); index++) {
                best = findLargestVisibleSurface(group.getChildAt(index), best);
            }
        }
        return best;
    }

    private void drawFallback(View decor, Bitmap bitmap) {
        try {
            decor.draw(new Canvas(bitmap));
            finishCapture(bitmap);
        } catch (Throwable error) {
            captureInFlight = false;
            bitmap.recycle();
            Toast.makeText(getContext(), "تعذر التقاط الشاشة", Toast.LENGTH_SHORT).show();
        }
    }

    private void finishCapture(Bitmap original) {
        try {
            Bitmap output = original;
            if (original.getWidth() > MAX_SCREENSHOT_WIDTH) {
                int height = Math.max(1, Math.round(original.getHeight() * (MAX_SCREENSHOT_WIDTH / (float) original.getWidth())));
                output = Bitmap.createScaledBitmap(original, MAX_SCREENSHOT_WIDTH, height, true);
            }
            ByteArrayOutputStream bytes = new ByteArrayOutputStream();
            output.compress(Bitmap.CompressFormat.JPEG, 70, bytes);
            String dataUrl = "data:image/jpeg;base64," + Base64.encodeToString(bytes.toByteArray(), Base64.NO_WRAP);
            if (output != original) output.recycle();
            original.recycle();
            showReportDialog(dataUrl);
        } catch (Throwable error) {
            Toast.makeText(getContext(), "تعذر تجهيز لقطة المشكلة", Toast.LENGTH_SHORT).show();
        } finally {
            captureInFlight = false;
        }
    }

    private void showReportDialog(String screenshotDataUrl) {
        if (getActivity() == null || getActivity().isFinishing()) return;
        if (reportDialog != null && reportDialog.isShowing()) return;

        Dialog dialog = new Dialog(getActivity());
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        dialog.setCancelable(true);

        LinearLayout card = new LinearLayout(getActivity());
        card.setOrientation(LinearLayout.VERTICAL);
        card.setGravity(Gravity.END);
        card.setPadding(dp(18), dp(18), dp(18), dp(16));
        card.setLayoutDirection(View.LAYOUT_DIRECTION_RTL);
        card.setBackground(rounded(Color.WHITE, 24, 0, Color.TRANSPARENT));

        TextView eyebrow = text("إبلاغ سريع", 12, Color.rgb(0, 105, 72), true);
        card.addView(eyebrow, matchWrap());

        TextView title = text("شو المشكلة اللي واجهتك؟", 21, Color.rgb(18, 31, 25), true);
        LinearLayout.LayoutParams titleParams = matchWrap();
        titleParams.topMargin = dp(3);
        card.addView(title, titleParams);

        TextView subtitle = text("أرفقنا لقطة الشاشة تلقائياً. اكتب ملاحظة قصيرة وواضحة.", 13, Color.rgb(93, 104, 98), false);
        LinearLayout.LayoutParams subtitleParams = matchWrap();
        subtitleParams.topMargin = dp(5);
        subtitleParams.bottomMargin = dp(12);
        card.addView(subtitle, subtitleParams);

        ImageView preview = new ImageView(getActivity());
        preview.setScaleType(ImageView.ScaleType.CENTER_CROP);
        preview.setContentDescription("لقطة الشاشة المرفقة مع البلاغ");
        preview.setBackground(rounded(Color.rgb(245, 247, 246), 16, 1, Color.rgb(222, 229, 225)));
        byte[] imageBytes = Base64.decode(screenshotDataUrl.substring(screenshotDataUrl.indexOf(',') + 1), Base64.DEFAULT);
        preview.setImageBitmap(android.graphics.BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.length));
        LinearLayout.LayoutParams previewParams = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(190));
        previewParams.bottomMargin = dp(12);
        card.addView(preview, previewParams);

        EditText note = new EditText(getActivity());
        note.setHint("مثلاً: المقاس ما انحفظ بعد ما اخترته...");
        note.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15);
        note.setTextColor(Color.rgb(18, 31, 25));
        note.setHintTextColor(Color.rgb(128, 139, 133));
        note.setGravity(Gravity.TOP | Gravity.RIGHT);
        note.setMinLines(3);
        note.setMaxLines(5);
        note.setPadding(dp(13), dp(11), dp(13), dp(11));
        note.setFilters(new InputFilter[]{ new InputFilter.LengthFilter(MAX_NOTE_LENGTH) });
        note.setBackground(rounded(Color.rgb(248, 250, 249), 14, 1, Color.rgb(208, 219, 213)));
        note.setLayoutDirection(View.LAYOUT_DIRECTION_RTL);
        card.addView(note, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        TextView counter = text("0 / " + MAX_NOTE_LENGTH, 11, Color.rgb(118, 129, 123), false);
        LinearLayout.LayoutParams counterParams = matchWrap();
        counterParams.topMargin = dp(5);
        counterParams.bottomMargin = dp(12);
        card.addView(counter, counterParams);

        LinearLayout actions = new LinearLayout(getActivity());
        actions.setOrientation(LinearLayout.HORIZONTAL);
        actions.setLayoutDirection(View.LAYOUT_DIRECTION_RTL);
        actions.setGravity(Gravity.CENTER_VERTICAL);

        Button send = actionButton("إرسال للإدارة", Color.WHITE, Color.rgb(0, 105, 72));
        send.setEnabled(false);
        send.setAlpha(0.48f);
        Button cancel = actionButton("إلغاء", Color.rgb(52, 66, 58), Color.rgb(239, 243, 241));
        LinearLayout.LayoutParams sendParams = new LinearLayout.LayoutParams(0, dp(48), 1.35f);
        LinearLayout.LayoutParams cancelParams = new LinearLayout.LayoutParams(0, dp(48), 0.8f);
        cancelParams.setMarginStart(dp(9));
        actions.addView(send, sendParams);
        actions.addView(cancel, cancelParams);
        card.addView(actions, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        note.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override public void onTextChanged(CharSequence s, int start, int before, int count) {
                String value = s == null ? "" : s.toString().trim();
                counter.setText((s == null ? 0 : s.length()) + " / " + MAX_NOTE_LENGTH);
                send.setEnabled(value.length() >= 3);
                send.setAlpha(value.length() >= 3 ? 1f : 0.48f);
            }
            @Override public void afterTextChanged(Editable s) {}
        });

        cancel.setOnClickListener(view -> dialog.dismiss());
        send.setOnClickListener(view -> {
            String value = note.getText().toString().trim();
            if (value.length() < 3) return;
            JSObject payload = new JSObject();
            payload.put("note", value);
            payload.put("screenshotDataUrl", screenshotDataUrl);
            payload.put("capturedAt", System.currentTimeMillis());
            notifyListeners("issueReportSubmitted", payload, true);
            dialog.dismiss();
            Toast.makeText(getContext(), "جاري إرسال البلاغ…", Toast.LENGTH_SHORT).show();
        });

        dialog.setContentView(card);
        dialog.setOnDismissListener(ignored -> {
            if (reportDialog == dialog) reportDialog = null;
        });
        dialog.show();
        Window dialogWindow = dialog.getWindow();
        if (dialogWindow != null) {
            dialogWindow.setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
            dialogWindow.addFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND);
            WindowManager.LayoutParams params = dialogWindow.getAttributes();
            params.width = getContext().getResources().getDisplayMetrics().widthPixels - dp(28);
            params.height = WindowManager.LayoutParams.WRAP_CONTENT;
            params.dimAmount = 0.58f;
            dialogWindow.setAttributes(params);
            dialogWindow.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE);
        }
        reportDialog = dialog;
        note.requestFocus();
    }

    private TextView text(String value, int sizeSp, int color, boolean bold) {
        TextView view = new TextView(getActivity());
        view.setText(value);
        view.setTextSize(TypedValue.COMPLEX_UNIT_SP, sizeSp);
        view.setTextColor(color);
        view.setGravity(Gravity.RIGHT);
        view.setTextDirection(View.TEXT_DIRECTION_RTL);
        if (bold) view.setTypeface(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.BOLD);
        return view;
    }

    private Button actionButton(String value, int textColor, int backgroundColor) {
        Button button = new Button(getActivity());
        button.setText(value);
        button.setTextColor(textColor);
        button.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14);
        button.setAllCaps(false);
        button.setTypeface(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.BOLD);
        button.setBackground(rounded(backgroundColor, 999, 0, Color.TRANSPARENT));
        return button;
    }

    private GradientDrawable rounded(int fill, int radiusDp, int strokeDp, int strokeColor) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(fill);
        drawable.setCornerRadius(dp(radiusDp));
        if (strokeDp > 0) drawable.setStroke(dp(strokeDp), strokeColor);
        return drawable;
    }

    @NonNull
    private LinearLayout.LayoutParams matchWrap() {
        return new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
    }

    private int dp(float value) {
        return Math.round(TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value,
            getContext().getResources().getDisplayMetrics()
        ));
    }
}
