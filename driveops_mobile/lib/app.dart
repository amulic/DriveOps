import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/config/router.dart';
import 'package:driveops_mobile/config/theme.dart';

class DriveOpsMobileApp extends ConsumerWidget {
  const DriveOpsMobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = createAppRouter(ref);

    return MaterialApp.router(
      title: 'DriveOps',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
