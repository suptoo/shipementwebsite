import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local JSON cache for offline-first data access.
/// Uses SharedPreferences for lightweight key-value storage with TTL expiry.
class CacheService {
  static CacheService? _instance;
  late SharedPreferences _prefs;

  CacheService._();

  static Future<CacheService> getInstance() async {
    if (_instance == null) {
      _instance = CacheService._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // ── TTL Durations ──
  static const Duration productsTTL = Duration(hours: 1);
  static const Duration categoriesTTL = Duration(hours: 6);
  static const Duration homeTTL = Duration(minutes: 30);

  // ── Core cache operations ──

  /// Save JSON data with a TTL timestamp
  Future<void> cacheData(String key, dynamic data, Duration ttl) async {
    final entry = {
      'data': data,
      'cachedAt': DateTime.now().millisecondsSinceEpoch,
      'ttlMs': ttl.inMilliseconds,
    };
    await _prefs.setString(key, jsonEncode(entry));
  }

  /// Retrieve cached data, returns null if expired or missing
  dynamic getCachedData(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;

    try {
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = entry['cachedAt'] as int;
      final ttlMs = entry['ttlMs'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - cachedAt > ttlMs) {
        // Cache expired
        return null;
      }

      return entry['data'];
    } catch (_) {
      return null;
    }
  }

  /// Force-get cached data regardless of TTL (for offline fallback)
  dynamic getCachedDataForce(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;

    try {
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      return entry['data'];
    } catch (_) {
      return null;
    }
  }

  /// Check if cache has valid (non-expired) data
  bool hasValidCache(String key) {
    return getCachedData(key) != null;
  }

  // ── Convenience methods ──

  /// Cache home data (featured + new arrivals + categories)
  Future<void> cacheHomeData({
    required List<Map<String, dynamic>> featured,
    required List<Map<String, dynamic>> newArrivals,
    required List<Map<String, dynamic>> categories,
  }) async {
    await cacheData('home_featured', featured, homeTTL);
    await cacheData('home_new_arrivals', newArrivals, homeTTL);
    await cacheData('home_categories', categories, categoriesTTL);
  }

  /// Cache product list for a specific filter key
  Future<void> cacheProducts(
      String filterKey, List<Map<String, dynamic>> products) async {
    await cacheData('products_$filterKey', products, productsTTL);
  }

  /// Cache categories
  Future<void> cacheCategories(List<Map<String, dynamic>> categories) async {
    await cacheData('categories', categories, categoriesTTL);
  }

  /// Get cached product list
  List<Map<String, dynamic>>? getCachedProducts(String filterKey,
      {bool force = false}) {
    final data = force
        ? getCachedDataForce('products_$filterKey')
        : getCachedData('products_$filterKey');
    if (data == null) return null;
    return (data as List).cast<Map<String, dynamic>>();
  }

  /// Get cached categories
  List<Map<String, dynamic>>? getCachedCategories({bool force = false}) {
    final data =
        force ? getCachedDataForce('categories') : getCachedData('categories');
    if (data == null) return null;
    return (data as List).cast<Map<String, dynamic>>();
  }

  /// Get cached home data
  Map<String, List<Map<String, dynamic>>?> getCachedHomeData(
      {bool force = false}) {
    final getter = force ? getCachedDataForce : getCachedData;
    return {
      'featured': (getter('home_featured') as List?)
          ?.cast<Map<String, dynamic>>(),
      'newArrivals': (getter('home_new_arrivals') as List?)
          ?.cast<Map<String, dynamic>>(),
      'categories': (getter('home_categories') as List?)
          ?.cast<Map<String, dynamic>>(),
    };
  }

  /// Clear all caches
  Future<void> clearAll() async {
    final keys = _prefs.getKeys().toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}
