import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/app.dart';
import 'package:driveops_mobile/services/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheService().init();
  runApp(const ProviderScope(child: DriveOpsMobileApp()));
}
