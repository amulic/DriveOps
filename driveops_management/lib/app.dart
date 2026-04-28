import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'config/router.dart';

class DriveOpsApp extends StatelessWidget {
  const DriveOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DriveOps Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}
