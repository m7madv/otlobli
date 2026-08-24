import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'data/supabase_repository.dart';
import 'state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  late final AppController controller;
  if (AppConfig.hasCloudBackend) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseKey,
      debug: false,
    );
    controller = AppController.withRepository(
      SupabaseDamanakRepository(Supabase.instance.client),
    );
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn) {
        controller.initialize();
      }
    });
  } else {
    controller = AppController.unconfigured();
  }
  await controller.initialize();

  runApp(DamanakApp(controller: controller));
}
