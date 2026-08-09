package com.otlobli.app;

import android.graphics.Color;
import android.graphics.PorterDuff;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import androidx.annotation.Nullable;
import androidx.core.splashscreen.SplashScreen;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {

    private static final int OTLBLI_NAV_RESERVE_DP = 120;
    private FrameLayout otlobliLaunchSurface;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        registerPlugin(OtlobliLaunchSurfacePlugin.class);
        // Android 12+ owns the first system frame. Install its documented
        // splash handoff before BridgeActivity initialises; Android 9 on the
        // connected Note 8 keeps the custom full navigation preview theme.
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            SplashScreen.installSplashScreen(this);
        }
        super.onCreate(savedInstanceState);
    }

    @Override
    protected void load() {
        // BridgeActivity calls this after its root view exists but before it
        // creates/parses the Capacitor WebView. Showing here covers the actual
        // white gap on slow Android devices, not just the later store dialog.
        showOtlobliLaunchSurface();
        super.load();
    }

    void dismissOtlobliLaunchSurface() {
        runOnUiThread(() -> {
            if (otlobliLaunchSurface == null) return;
            final FrameLayout surface = otlobliLaunchSurface;
            surface.animate().cancel();
            // React calls this only after two rendered frames. Fading this
            // already-matched native surface over that ready app frame paints
            // the wordmark and tabs twice on a slow device. Remove it in one
            // transaction so Otlobli opens first as one stable interface;
            // SHEIN/Temu can then load above the ready app separately.
            if (surface.getParent() instanceof ViewGroup) {
                ((ViewGroup) surface.getParent()).removeView(surface);
            }
            if (otlobliLaunchSurface == surface) otlobliLaunchSurface = null;
        });
    }

    private void showOtlobliLaunchSurface() {
        FrameLayout surface = new FrameLayout(this);
        surface.setBackgroundColor(Color.rgb(247, 249, 251));
        surface.setClickable(true);
        surface.setFocusable(true);
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
            surface.setElevation(1000f);
        }

        TextView brand = new TextView(this);
        brand.setText("otlobli");
        brand.setTextColor(Color.rgb(0, 105, 72));
        brand.setTextSize(TypedValue.COMPLEX_UNIT_SP, 24);
        brand.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        brand.setGravity(Gravity.CENTER);
        brand.setTranslationY(-78f * getResources().getDisplayMetrics().density);
        surface.addView(brand, centeredParams());

        TextView copy = new TextView(this);
        copy.setText("جاري تجهيز المتجر…");
        copy.setTextColor(Color.rgb(84, 98, 90));
        copy.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14);
        copy.setGravity(Gravity.CENTER);
        copy.setMaxLines(2);
        copy.setPadding(dp(28), 0, dp(28), 0);
        copy.setTranslationY(-42f * getResources().getDisplayMetrics().density);
        surface.addView(copy, centeredParams());

        surface.addView(otlobliNavigation(), new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            dp(OTLBLI_NAV_RESERVE_DP),
            Gravity.BOTTOM
        ));

        addContentView(surface, new ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        ));
        otlobliLaunchSurface = surface;
    }

    private FrameLayout.LayoutParams centeredParams() {
        FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        );
        params.gravity = Gravity.CENTER;
        return params;
    }

    private LinearLayout otlobliNavigation() {
        LinearLayout navigation = new LinearLayout(this);
        navigation.setOrientation(LinearLayout.HORIZONTAL);
        navigation.setGravity(Gravity.TOP);
        navigation.setLayoutDirection(View.LAYOUT_DIRECTION_RTL);
        navigation.setBackgroundColor(Color.WHITE);

        String[] labels = { "الرئيسية", "طلباتي", "السلة", "حسابي" };
        int[] icons = {
            R.drawable.otlobli_nav_home,
            R.drawable.otlobli_nav_orders,
            R.drawable.otlobli_nav_cart,
            R.drawable.otlobli_nav_profile
        };
        for (int index = 0; index < labels.length; index++) {
            boolean selected = index == 0;
            int color = selected ? Color.rgb(0, 105, 72) : Color.rgb(61, 74, 66);
            LinearLayout tab = new LinearLayout(this);
            tab.setOrientation(LinearLayout.VERTICAL);
            tab.setGravity(Gravity.CENTER_HORIZONTAL);
            tab.setPadding(0, dp(4), 0, 0);

            View indicator = new View(this);
            if (selected) {
                GradientDrawable background = new GradientDrawable();
                background.setColor(color);
                background.setCornerRadius(dp(999));
                indicator.setBackground(background);
            }
            tab.addView(indicator, new LinearLayout.LayoutParams(dp(32), dp(4)));

            ImageView icon = new ImageView(this);
            icon.setImageResource(icons[index]);
            icon.setColorFilter(color, PorterDuff.Mode.SRC_IN);
            icon.setScaleType(ImageView.ScaleType.FIT_CENTER);
            LinearLayout.LayoutParams iconParams = new LinearLayout.LayoutParams(dp(22), dp(22));
            iconParams.topMargin = dp(7);
            tab.addView(icon, iconParams);

            TextView label = new TextView(this);
            label.setText(labels[index]);
            label.setTextColor(color);
            label.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
            label.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
            label.setGravity(Gravity.CENTER);
            label.setIncludeFontPadding(false);
            LinearLayout.LayoutParams labelParams = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            );
            labelParams.topMargin = dp(5);
            tab.addView(label, labelParams);

            navigation.addView(tab, new LinearLayout.LayoutParams(0, dp(74), 1f));
        }
        return navigation;
    }

    private int dp(float value) {
        return Math.round(TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value,
            getResources().getDisplayMetrics()
        ));
    }
}
