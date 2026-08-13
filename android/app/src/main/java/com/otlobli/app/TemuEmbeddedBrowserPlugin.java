package com.otlobli.app;

import android.graphics.Color;
import android.graphics.PorterDuff;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowInsets;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.json.JSONObject;
import org.mozilla.geckoview.GeckoResult;
import org.mozilla.geckoview.GeckoRuntime;
import org.mozilla.geckoview.GeckoRuntimeSettings;
import org.mozilla.geckoview.GeckoSession;
import org.mozilla.geckoview.GeckoSessionSettings;
import org.mozilla.geckoview.GeckoView;
import org.mozilla.geckoview.WebExtension;

/**
 * Temu's persistent Gecko engine embedded in MainActivity's content area.
 *
 * The React Otlobli shell remains mounted and owns the real bottom navigation;
 * Gecko only covers the store-content area above it. This intentionally avoids
 * an Activity transition and avoids maintaining a second imitation of Otlobli.
 */
@CapacitorPlugin(name = "TemuEmbeddedBrowser")
public class TemuEmbeddedBrowserPlugin extends Plugin {

    private static final String HOME_URL = "https://www.temu.com/sa/";
    private static final String EXTENSION_URI = "resource://android/assets/temu_extension/";
    private static final String EXTENSION_ID = "otlobli-temu@otlobli.app";
    private static final int OTLBLI_NAV_RESERVE_DP = 90;
    // Permanent by design: changing this context discards the verified guest
    // session and makes Temu challenge the same phone as a new browser again.
    private static final String TEMU_SESSION_CONTEXT = "otlobli-temu-android-guest-v86160-final";
    private static GeckoRuntime runtime;

    private FrameLayout storeLayer;
    private GeckoView geckoView;
    private View loadingSurface;
    private TextView backButton;
    private GeckoSession session;
    private boolean extensionInstalling;
    private boolean extensionReady;
    private boolean canGoBack;
    private boolean onStoreHome = true;
    private String currentUrl = "";
    private String queuedUrl = HOME_URL;
    private String requestedDestinationUrl = HOME_URL;

    @PluginMethod
    public void open(PluginCall call) {
        final String rawUrl = call.getString("url", HOME_URL);
        final Uri uri;
        try {
            uri = Uri.parse(rawUrl);
        } catch (Exception error) {
            call.reject("Invalid Temu URL", error);
            return;
        }
        String host = uri.getHost();
        if (host == null || !(host.equalsIgnoreCase("temu.com") || host.toLowerCase().endsWith(".temu.com")) ||
            !"https".equalsIgnoreCase(uri.getScheme())) {
            call.reject("Only HTTPS Temu URLs are allowed");
            return;
        }

        getActivity().runOnUiThread(() -> {
            try {
                queuedUrl = uri.toString();
                ensureStoreLayer();
                showStoreLayer();
                ensureSessionAndOpen(queuedUrl);
                JSObject result = new JSObject();
                result.put("opened", true);
                call.resolve(result);
            } catch (Exception error) {
                call.reject("Unable to embed Temu", error);
            }
        });
    }

    @PluginMethod
    public void hide(PluginCall call) {
        getActivity().runOnUiThread(() -> {
            hideStoreLayer();
            call.resolve();
        });
    }

    @PluginMethod
    public void show(PluginCall call) {
        getActivity().runOnUiThread(() -> {
            JSObject result = new JSObject();
            boolean resumable = session != null && session.isOpen() && !currentUrl.isEmpty();
            if (resumable) {
                ensureStoreLayer();
                showStoreLayer();
            }
            result.put("shown", resumable);
            call.resolve(result);
        });
    }

    @PluginMethod
    public void goHome(PluginCall call) {
        getActivity().runOnUiThread(() -> {
            if (session != null && session.isOpen() && !onStoreHome) session.loadUri(HOME_URL);
            call.resolve();
        });
    }

    public boolean handleSystemBack() {
        if (!isStoreVisible()) return false;
        goBackOrExit();
        return true;
    }

    boolean isStoreVisible() {
        return storeLayer != null && storeLayer.getVisibility() == View.VISIBLE;
    }

    private void ensureStoreLayer() {
        if (storeLayer != null) return;
        FrameLayout activityContent = getActivity().findViewById(android.R.id.content);
        if (activityContent == null) throw new IllegalStateException("MainActivity content view is unavailable");

        storeLayer = new FrameLayout(getContext());
        storeLayer.setBackgroundColor(Color.WHITE);
        storeLayer.setClickable(true);
        storeLayer.setFocusable(true);

        int width = Math.min(getContext().getResources().getDisplayMetrics().widthPixels, dp(440));
        FrameLayout.LayoutParams layerParams = new FrameLayout.LayoutParams(
            width,
            ViewGroup.LayoutParams.MATCH_PARENT,
            Gravity.TOP | Gravity.CENTER_HORIZONTAL
        );
        // Reserve React's 74dp navigation plus its 16dp safe floor. The system
        // navigation inset is added below once WindowInsets are available;
        // MainActivity is edge-to-edge, so omitting it overlaps the top of the
        // React navigation. Keep this layer at zero elevation: a 24dp shadow
        // was measured darkening the otherwise-white navigation underneath.
        layerParams.bottomMargin = dp(OTLBLI_NAV_RESERVE_DP);
        activityContent.addView(storeLayer, layerParams);

        geckoView = new GeckoView(getContext());
        storeLayer.addView(geckoView, new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        ));

        loadingSurface = createLoadingSurface();
        storeLayer.addView(loadingSurface, new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        ));

        backButton = createBackButton();
        FrameLayout.LayoutParams backParams = new FrameLayout.LayoutParams(dp(42), dp(42), Gravity.TOP | Gravity.RIGHT);
        backParams.rightMargin = dp(10);
        backParams.topMargin = dp(42);
        storeLayer.addView(backButton, backParams);
        storeLayer.setOnApplyWindowInsetsListener((view, insets) -> {
            int statusBarInset;
            int navigationBarInset;
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                statusBarInset = insets.getInsets(WindowInsets.Type.statusBars()).top;
                navigationBarInset = insets.getInsets(WindowInsets.Type.navigationBars()).bottom;
            } else {
                statusBarInset = insets.getSystemWindowInsetTop();
                navigationBarInset = insets.getSystemWindowInsetBottom();
            }
            int desiredBottomMargin = dp(OTLBLI_NAV_RESERVE_DP) + Math.max(0, navigationBarInset);
            if (layerParams.bottomMargin != desiredBottomMargin) {
                layerParams.bottomMargin = desiredBottomMargin;
                view.setLayoutParams(layerParams);
            }
            backParams.topMargin = Math.max(dp(12), statusBarInset + dp(12));
            backButton.setLayoutParams(backParams);
            return insets;
        });
        storeLayer.requestApplyInsets();
    }

    private void showStoreLayer() {
        storeLayer.animate().cancel();
        // Keep the same GeckoView and GeckoSession attached across Otlobli
        // screens. Temu's verification token is tied to this live browsing
        // context; rebuilding its surface on every Cart visit can make the
        // server challenge the same phone again.
        if (session != null && session.isOpen() && geckoView.getSession() != session) {
            geckoView.setSession(session);
        }
        storeLayer.setVisibility(View.VISIBLE);
        if (session != null && session.isOpen()) {
            session.setActive(true);
            session.setFocused(true);
        }
        if (currentUrl.isEmpty()) loadingSurface.setVisibility(View.VISIBLE);
        storeLayer.setAlpha(0f);
        storeLayer.animate().alpha(1f).setDuration(110L).start();
    }

    private void hideStoreLayer() {
        if (storeLayer == null) return;
        storeLayer.animate().cancel();
        storeLayer.setAlpha(1f);
        storeLayer.setVisibility(View.GONE);
        if (session != null && session.isOpen()) {
            session.setFocused(false);
            // Visibility GONE stops drawing and touch dispatch. Deliberately
            // retain the active attached document so an in-progress security
            // hand-off and its session storage are not discarded.
        }
    }

    private void ensureSessionAndOpen(String requestedUrl) {
        if (runtime == null) {
            // Debug builds expose Gecko's remote debugging socket so the real
            // DOM and JS state of a Temu page can be read on the device instead
            // of inferred from screenshots. Release builds never enable it.
            GeckoRuntimeSettings settings = new GeckoRuntimeSettings.Builder()
                .remoteDebuggingEnabled(BuildConfig.DEBUG)
                .build();
            runtime = GeckoRuntime.create(getContext().getApplicationContext(), settings);
        }
        if (session == null) {
            GeckoSessionSettings settings = new GeckoSessionSettings.Builder()
                .contextId(TEMU_SESSION_CONTEXT)
                .usePrivateMode(false)
                .build();
            session = new GeckoSession(settings);
            session.setContentDelegate(new GeckoSession.ContentDelegate() {});
            session.setNavigationDelegate(new GeckoSession.NavigationDelegate() {
                @Override
                public void onCanGoBack(@NonNull GeckoSession activeSession, boolean value) {
                    canGoBack = value;
                }

                @Override
                public void onLocationChange(
                    @NonNull GeckoSession activeSession,
                    @Nullable String url,
                    @NonNull List<GeckoSession.PermissionDelegate.ContentPermission> permissions,
                    @NonNull Boolean hasUserGesture
                ) {
                    currentUrl = url == null ? "" : url;
                    onStoreHome = isStoreHomeUrl(currentUrl);
                }
            });
            session.setProgressDelegate(new GeckoSession.ProgressDelegate() {
                @Override
                public void onPageStop(@NonNull GeckoSession activeSession, boolean success) {
                    if (loadingSurface != null) loadingSurface.setVisibility(View.GONE);
                }
            });
            session.open(runtime);
            geckoView.setSession(session);
        }

        if (!extensionReady) {
            installExtension();
            return;
        }
        loadIfNeeded(requestedUrl);
    }

    private void installExtension() {
        if (extensionInstalling) return;
        extensionInstalling = true;
        runtime.getWebExtensionController()
            .ensureBuiltIn(EXTENSION_URI, EXTENSION_ID)
            .accept(
                extension -> {
                    extensionInstalling = false;
                    extensionReady = true;
                    session.getWebExtensionController().setMessageDelegate(
                        extension,
                        new WebExtension.MessageDelegate() {
                            @Nullable
                            @Override
                            public GeckoResult<Object> onMessage(
                                @NonNull String nativeApp,
                                @NonNull Object message,
                                @NonNull WebExtension.MessageSender sender
                            ) {
                                handleExtensionMessage(message, sender);
                                return null;
                            }
                        },
                        "otlobli"
                    );
                    loadIfNeeded(queuedUrl);
                },
                error -> {
                    extensionInstalling = false;
                    // Never strand the user on a loading surface. The page can
                    // still open while the logged error identifies the guard.
                    android.util.Log.e("OtlobliTemu", "extension install failed", error);
                    loadIfNeeded(queuedUrl);
                }
            );
    }

    private void loadIfNeeded(String requestedUrl) {
        if (session == null || !session.isOpen()) return;
        if (sameDestination(currentUrl, requestedUrl) ||
            (isSecurityVerificationUrl(currentUrl) && sameProduct(requestedDestinationUrl, requestedUrl))) {
            if (loadingSurface != null) loadingSurface.setVisibility(View.GONE);
            return;
        }
        if (loadingSurface != null && currentUrl.isEmpty()) loadingSurface.setVisibility(View.VISIBLE);
        requestedDestinationUrl = requestedUrl;
        session.loadUri(requestedUrl);
    }

    private boolean sameDestination(String first, String second) {
        if (first == null || first.isEmpty() || second == null || second.isEmpty()) return false;
        if (isStoreHomeUrl(first) && isStoreHomeUrl(second)) return true;
        return first.equals(second) || sameProduct(first, second);
    }

    private boolean sameProduct(String first, String second) {
        String firstId = productId(first);
        String secondId = productId(second);
        return !firstId.isEmpty() && firstId.equals(secondId);
    }

    private String productId(String rawUrl) {
        if (rawUrl == null || rawUrl.isEmpty()) return "";
        try {
            Uri uri = Uri.parse(rawUrl);
            for (String key : new String[] { "goods_id", "goodsId", "product_id", "productId" }) {
                String value = uri.getQueryParameter(key);
                if (value != null && value.matches("\\d{5,}")) return value;
            }
            Matcher pathId = Pattern.compile("(?:-g-|goods[_-]?id[^0-9]*)(\\d{5,})", Pattern.CASE_INSENSITIVE)
                .matcher(uri.getPath() == null ? "" : uri.getPath());
            if (pathId.find()) return pathId.group(1);
            // Temu login/verification routes often embed the destination in a
            // decoded `from` or redirect parameter. Read one bounded level so
            // reopening that cart row does not restart the same challenge.
            for (String key : new String[] { "from", "redirect", "redirect_url", "redirectUrl", "url" }) {
                String nested = uri.getQueryParameter(key);
                if (nested == null || nested.equals(rawUrl)) continue;
                Matcher nestedId = Pattern.compile("(?:-g-|goods[_-]?id[^0-9]*)(\\d{5,})", Pattern.CASE_INSENSITIVE)
                    .matcher(nested);
                if (nestedId.find()) return nestedId.group(1);
            }
        } catch (Exception ignored) {
            return "";
        }
        return "";
    }

    private boolean isSecurityVerificationUrl(String rawUrl) {
        if (rawUrl == null || rawUrl.isEmpty()) return false;
        String normalized = rawUrl.toLowerCase();
        return normalized.contains("challenge") || normalized.contains("verification") ||
            normalized.contains("captcha") || normalized.contains("bgn_verification") ||
            normalized.contains("/risk/");
    }

    private void handleExtensionMessage(Object message, WebExtension.MessageSender sender) {
        if (!sender.isTopLevel() || !(message instanceof JSONObject)) return;
        String senderUrl = sender.url;
        if (senderUrl == null || !senderUrl.startsWith("https://") || !senderUrl.contains("temu.com/")) return;
        JSONObject detail = ((JSONObject) message).optJSONObject("detail");
        if (detail == null) {
            android.util.Log.w("OtlobliTemu", "ignored native message without detail");
            return;
        }
        String type = detail.optString("type", "");
        if (!(type.equals("openHome") || type.equals("openCart") || type.equals("backToCart") ||
              type.equals("openOrders") || type.equals("openProfile") || type.equals("addToCart"))) return;

        getActivity().runOnUiThread(() -> {
            if (type.equals("openHome")) {
                if (!onStoreHome && session != null) session.loadUri(HOME_URL);
                return;
            }
            if (!type.equals("addToCart")) hideStoreLayer();
            notifyDetail(detail);
        });
    }

    private void notifyDetail(JSONObject detail) {
        try {
            JSObject payload = new JSObject();
            payload.put("detail", JSObject.fromJSONObject(detail));
            notifyListeners("messageFromWebview", payload, false);
        } catch (Exception error) {
            android.util.Log.e("OtlobliTemu", "invalid extension detail", error);
        }
    }

    private void goBackOrExit() {
        if (onStoreHome) {
            // Let the React shell own the decision so Temu and SHEIN share the
            // same branded, accessible confirmation instead of an OS alert.
            hideStoreLayer();
            JSONObject detail = new JSONObject();
            try {
                detail.put("type", "requestStoreExit");
                detail.put("store", "temu");
            } catch (Exception ignored) {}
            notifyDetail(detail);
        } else if (canGoBack && session != null) {
            session.goBack();
        } else if (session != null) {
            session.loadUri(HOME_URL);
        }
    }

    private boolean isStoreHomeUrl(@Nullable String url) {
        if (url == null || url.isEmpty()) return false;
        try {
            Uri parsed = Uri.parse(url);
            String host = parsed.getHost();
            String path = parsed.getPath();
            return host != null && (host.equalsIgnoreCase("temu.com") || host.equalsIgnoreCase("www.temu.com")) &&
                ("/sa".equals(path) || "/sa/".equals(path));
        } catch (Exception ignored) {
            return false;
        }
    }

    private TextView createBackButton() {
        TextView button = new TextView(getContext());
        button.setText("›");
        button.setTextColor(Color.WHITE);
        button.setTextSize(TypedValue.COMPLEX_UNIT_SP, 30);
        button.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        button.setGravity(Gravity.CENTER);
        GradientDrawable background = new GradientDrawable();
        background.setColor(Color.argb(190, 20, 24, 22));
        background.setCornerRadius(dp(11));
        button.setBackground(background);
        button.setContentDescription("رجوع");
        button.setOnClickListener(view -> goBackOrExit());
        return button;
    }

    private View createLoadingSurface() {
        FrameLayout surface = new FrameLayout(getContext());
        surface.setBackgroundColor(Color.rgb(247, 249, 251));

        LinearLayout content = new LinearLayout(getContext());
        content.setOrientation(LinearLayout.VERTICAL);
        content.setGravity(Gravity.CENTER);

        TextView brand = new TextView(getContext());
        brand.setText("otlobli");
        brand.setTextColor(Color.rgb(0, 105, 72));
        brand.setTextSize(TypedValue.COMPLEX_UNIT_SP, 24);
        brand.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        brand.setGravity(Gravity.CENTER);
        content.addView(brand);

        ProgressBar progress = new ProgressBar(getContext());
        progress.getIndeterminateDrawable().setColorFilter(Color.rgb(0, 105, 72), PorterDuff.Mode.SRC_IN);
        LinearLayout.LayoutParams progressParams = new LinearLayout.LayoutParams(dp(30), dp(30));
        progressParams.topMargin = dp(16);
        content.addView(progress, progressParams);

        TextView copy = new TextView(getContext());
        copy.setText("جاري فتح Temu…");
        copy.setTextColor(Color.rgb(84, 98, 90));
        copy.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14);
        copy.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams copyParams = new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        );
        copyParams.topMargin = dp(10);
        content.addView(copy, copyParams);

        FrameLayout.LayoutParams contentParams = new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
            Gravity.CENTER
        );
        surface.addView(content, contentParams);
        return surface;
    }

    @Override
    protected void handleOnDestroy() {
        if (geckoView != null) geckoView.releaseSession();
        if (session != null) session.close();
        session = null;
        geckoView = null;
        storeLayer = null;
    }

    private int dp(float value) {
        return Math.round(TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value,
            getContext().getResources().getDisplayMetrics()
        ));
    }
}
