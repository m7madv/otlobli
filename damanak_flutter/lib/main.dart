import 'package:flutter/material.dart';

import 'app.dart';
import 'data/local_repository.dart';
import 'state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = AppController(LocalRepository());
  await controller.initialize();

  runApp(DamanakApp(controller: controller));
}
