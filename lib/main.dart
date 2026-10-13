import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/services/blocker_platform_service.dart';
import 'features/home/home_controller.dart';
import 'features/stats/stats_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const service = BlockerPlatformService();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<HomeController>(
          create: (_) => HomeController(service)..init(),
        ),
        ChangeNotifierProvider<StatsController>(
          create: (_) => StatsController(service),
        ),
      ],
      child: const TollGateApp(),
    ),
  );
}
