import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/config/theme.dart';
import 'package:driveops_management/config/router.dart';

class DriveOpsApp extends ConsumerWidget {
  const DriveOpsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = createAppRouter(ref);

    return MaterialApp.router(
      title: 'DriveOps Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}