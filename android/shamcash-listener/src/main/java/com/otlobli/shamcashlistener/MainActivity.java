package com.otlobli.shamcashlistener;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.provider.Settings;
import android.view.Gravity;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setGravity(Gravity.CENTER_HORIZONTAL);
        int padding = dp(20);
        root.setPadding(padding, padding, padding, padding);

        TextView title = new TextView(this);
        title.setText("Otlobli ShamCash Listener");
        title.setTextSize(20);
        title.setGravity(Gravity.CENTER);
        root.addView(title, new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ));

        TextView status = new TextView(this);
        status.setText(buildStatusText());
        status.setTextSize(14);
        status.setPadding(0, dp(16), 0, dp(16));
        root.addView(status, new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ));

        Button settings = new Button(this);
        settings.setText("Open Notification Access");
        settings.setOnClickListener((view) -> startActivity(new Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)));
        root.addView(settings, new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ));

        setContentView(root);
    }

    private String buildStatusText() {
        String configured = ListenerConfig.webhookUrl(this).isEmpty() || ListenerConfig.secret(this).isEmpty()
            ? "Config: missing"
            : "Config: ready";
        return configured
            + "\nTarget: " + ListenerConfig.targetPackage(this)
            + "\nLast result: " + ListenerConfig.lastResult(this);
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }
}
