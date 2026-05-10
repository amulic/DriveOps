import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String _boxName = 'api_cache';
  static const Duration _defaultListTtl = Duration(minutes: 5);
  static const Duration _defaultSingleTtl = Duration(minutes: 15);

  late Box<String> _box;

  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
  }

  dynamic get(String key) {
    final entry = _box.get(key);
    if (entry == null) return null;

    try {
      final Map<String, dynamic> decoded = jsonDecode(entry);
      final expiresAt = DateTime.tryParse(decoded['_expiresAt'] ?? '');
      if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
        _box.delete(key);
        return null;
      }
      return decoded['data'];
    } catch (_) {
      return null;
    }
  }

  Future<void> set<T>(String key, T value, {Duration? ttl}) async {
    final effectiveTtl = ttl ?? _defaultListTtl;
    final expiresAt = DateTime.now().add(effectiveTtl).toIso8601String();
    final encoded = jsonEncode({
      'data': value,
      '_expiresAt': expiresAt,
    });
    await _box.put(key, encoded);
  }

  Future<void> setSingle<T>(String key, T value) => set(key, value, ttl: _defaultSingleTtl);

  Future<void> setList<T>(String key, T value) => set(key, value, ttl: _defaultListTtl);

  bool isValid(String key) => get(key) != null;

  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> remove(String key) async {
    await _box.delete(key);
  }

  static const String driversAll = 'drivers_all';
  static const String driversActive = 'drivers_active';
  static const String driversAvailable = 'drivers_available';
  static String driver(String id) => 'driver_$id';
  static const String tripsAll = 'trips_all';
  static String trip(String id) => 'trip_$id';
  static String tripsDriver(String driverId) => 'trips_driver_$driverId';
  static String tripsCustomer(String customerId) => 'trips_customer_$customerId';
  static const String vehiclesAll = 'vehicles_all';
  static const String vehiclesAvailable = 'vehicles_available';
  static String vehicle(String id) => 'vehicle_$id';
  static const String vehiclesNeedingService = 'vehicles_needing_service';
  static const String userCurrent = 'user_current';
  static String user(String id) => 'user_$id';
}