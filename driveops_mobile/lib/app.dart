import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/config/router.dart';
import 'package:driveops_mobile/config/theme.dart';
import 'package:driveops_mobile/shared/models/driver.dart';
import 'package:driveops_mobile/shared/providers/auth_provider.dart';
import 'package:driveops_mobile/shared/providers/repository_providers.dart';

class DriveOpsMobileApp extends ConsumerStatefulWidget {
  const DriveOpsMobileApp({super.key});

  @override
  ConsumerState<DriveOpsMobileApp> createState() => _DriveOpsMobileAppState();
}

class _DriveOpsMobileAppState extends ConsumerState<DriveOpsMobileApp> {
  bool _wasBackgrounded = false;

  late final AppLifecycleListener _lifecycleListener = AppLifecycleListener(
    onStateChange: _onLifecycleStateChanged,
  );

  // Silent role refresh: when the app resumes from the background, refresh the
  // token and rebuild the user so a role granted in Keycloak (e.g. a driver
  // promotion done while the app was open) is picked up without a re-login.
  void _onLifecycleStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _wasBackgrounded = true;
    } else if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      final isAuthenticated =
          ref.read(authProvider).value?.isAuthenticated ?? false;
      if (isAuthenticated) {
        ref.read(authProvider.notifier).reloadUser();
        // Approval gate: if the driver is still Pending, re-fetch the profile so
        // an admin activation done while the app was backgrounded unlocks it on
        // return — without forcing a manual refresh or a re-login.
        final driverStatus = ref.read(currentDriverProvider).value?.status;
        if (driverStatus == DriverStatus.pending) {
          ref.invalidate(currentDriverProvider);
        }
      }
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
