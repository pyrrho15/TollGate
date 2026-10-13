import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/services/blocker_platform_service.dart';
import 'features/home/home_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider<HomeController>(
      create: (_) => HomeController(const BlockerPlatformService())..init(),
      child: const TollGateApp(),
    ),
  );
}
