import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/shell/app_shell.dart';

class TollGateApp extends StatelessWidget {
  const TollGateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TollGate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}
