package com.otlobli.app;

import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

@CapacitorPlugin(name = "OtlobliLaunchSurface")
public class OtlobliLaunchSurfacePlugin extends Plugin {

    @PluginMethod
    public void ready(PluginCall call) {
        if (getActivity() instanceof MainActivity) {
            ((MainActivity) getActivity()).dismissOtlobliLaunchSurface();
        }
        call.resolve();
    }
}
