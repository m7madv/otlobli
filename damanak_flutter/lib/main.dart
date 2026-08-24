import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'data/supabase_repository.dart';
import 'state/app_controller.dart';
import 'services/store_billing_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final billingService = createStoreBillingService();
  final appLinks = AppLinks();

  late final AppController controller;
  if (AppConfig.hasCloudBackend) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseKey,
      debug: false,
    );
    controller = AppController.withRepository(
      SupabaseDamanakRepository(Supabase.instance.client),
      billingService: billingService,
    );
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn) {
        controller.initialize();
      }
    });
  } else {
    controller = AppController.unconfigured(billingService: billingService);
  }
  try {
    final initialLink = await appLinks.getInitialLink();
    if (initialLink != null) controller.handleIncomingUri(initialLink);
  } on Object {
    // لا نمنع تشغيل التطبيق إذا تعذر على النظام قراءة رابط البداية.
  }
  appLinks.uriLinkStream.listen(controller.handleIncomingUri);
  await controller.initialize();

  runApp(DamanakApp(controller: controller));
}
