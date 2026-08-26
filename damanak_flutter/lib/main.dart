import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'data/supabase_repository.dart';
import 'state/app_controller.dart';
import 'services/store_billing_service.dart';
import 'screens/startup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _DamanakBootstrap());
}

class _DamanakBootstrap extends StatefulWidget {
  const _DamanakBootstrap();

  @override
  State<_DamanakBootstrap> createState() => _DamanakBootstrapState();
}

class _DamanakBootstrapState extends State<_DamanakBootstrap> {
  AppController? _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // ارسم أول إطار قبل أي تهيئة شبكية أو استعادة جلسة.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initialize());
    });
  }

  Future<void> _initialize() async {
    if (!mounted || _controller != null) return;
    setState(() => _errorMessage = null);

    try {
      final controller = await _createController();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } on Object {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'تعذّر تجهيز التطبيق. تحقق من الاتصال ثم حاول مرة أخرى.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller != null) return DamanakApp(controller: controller);

    return DamanakAppFrame(
      home: StartupScreen(
        errorMessage: _errorMessage,
        onRetry: _errorMessage == null ? null : _initialize,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

Future<AppController> _createController() async {
  final billingService = await createStoreBillingService();
  final appLinks = AppLinks();
  AppController? controller;

  try {
    if (AppConfig.hasCloudBackend) {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseKey,
        debug: false,
      );
      final cloudController = AppController.withRepository(
        SupabaseDamanakRepository(Supabase.instance.client),
        billingService: billingService,
      );
      controller = cloudController;
      Supabase.instance.client.auth.onAuthStateChange.listen((event) {
        if (event.event == AuthChangeEvent.signedIn) {
          unawaited(cloudController.initialize());
        }
      });
    } else {
      controller = AppController.unconfigured(billingService: billingService);
    }
    final readyController = controller;
    try {
      final initialLink = await appLinks.getInitialLink();
      if (initialLink != null) readyController.handleIncomingUri(initialLink);
    } on Object {
      // لا نمنع تشغيل التطبيق إذا تعذر على النظام قراءة رابط البداية.
    }
    appLinks.uriLinkStream.listen(readyController.handleIncomingUri);
    await readyController.initialize();

    return readyController;
  } on Object {
    if (controller != null) {
      controller.dispose();
    } else {
      await billingService.dispose();
    }
    rethrow;
  }
}
