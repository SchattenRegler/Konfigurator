import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class NominatimService {
  NominatimService._();

  static const Duration _throttleDuration = Duration(seconds: 1);
  static const Duration _cacheTtl = Duration(minutes: 10);

  static final Map<String, _CachedResult> _cache = {};
  static DateTime _lastRequestAt = DateTime.fromMillisecondsSinceEpoch(0);

  static Future<List<Map<String, dynamic>>> fetchSuggestions(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final now = DateTime.now();
    final cached = _cache[query];
    if (cached != null && now.difference(cached.timestamp) < _cacheTtl) {
      return cached.results;
    }

    final elapsed = now.difference(_lastRequestAt);
    if (elapsed < _throttleDuration) {
      await Future.delayed(_throttleDuration - elapsed);
    }
    _lastRequestAt = DateTime.now();

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5',
    );
    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'staerium-configurator/1.0 (info@staerium.com)',
      });
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        final results = data.cast<Map<String, dynamic>>();
        _cache[query] = _CachedResult(results, DateTime.now());
        return results;
      }
    } catch (_) {
      // ignore network errors and return empty list below
    }

    return const <Map<String, dynamic>>[];
  }
}

class _CachedResult {
  _CachedResult(this.results, this.timestamp);

  final List<Map<String, dynamic>> results;
  final DateTime timestamp;
}
