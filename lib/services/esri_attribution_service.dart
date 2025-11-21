import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/map_tiles.dart';

class EsriAttributionService {
  EsriAttributionService._();

  static const String fallbackAttribution =
      'Imagery: Esri World Imagery — © Esri, Maxar, Earthstar Geographics, and the GIS User Community';

  static Future<String>? _copyrightFuture;

  static Future<String> get copyrightText =>
      _copyrightFuture ??= _fetchCopyrightText();

  static Future<String> _fetchCopyrightText() async {
    try {
      final response = await http.get(
        MapTilesConfig.arcgisMetadataUri,
        headers: const {
          'User-Agent': 'staerium-configurator/1.0 (info@staerium.com)',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(response.body) as Map<String, dynamic>;
        final text = data['copyrightText'] as String?;
        if (text != null && text.trim().isNotEmpty) {
          return text.trim();
        }
      }
    } catch (_) {
      // Ignore network errors and fall back to the default attribution text.
    }
    return fallbackAttribution;
  }
}
