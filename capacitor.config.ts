import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.otlobli.app',
  appName: 'otlobli',
  webDir: 'dist',
  plugins: {
    PushNotifications: {
      presentationOptions: ['badge', 'sound', 'alert'],
    },
    SocialLogin: {
      providers: {
        google: true,
        facebook: false,
        apple: false,
        twitter: false,
      },
    },
    CapgoInAppBrowser: {
      // Store navigation is rendered inside the native WebView. Let its own
      // bottom bar hide that layer immediately on tap instead of waiting for
      // the background React WebView to render and then run an effect.
      allowWebViewJsVisibilityControl: true,
    },
  },
};

export default config;
