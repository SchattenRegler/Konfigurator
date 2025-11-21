class MapTilesConfig {
  MapTilesConfig._();

  static const String _arcgisBaseUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  /// API key that can be provided via `--dart-define=ARCGIS_API_KEY=<key>`.
  static const String arcgisApiKey = String.fromEnvironment(
    'ARCGIS_API_KEY',
    defaultValue: '',
  );

  /// Returns the ArcGIS imagery template and appends the token if available.
  static String get arcgisUrlTemplate =>
      arcgisApiKey.isEmpty ? _arcgisBaseUrl : '$_arcgisBaseUrl?token=$arcgisApiKey';

  static bool get hasArcgisApiKey => arcgisApiKey.isNotEmpty;
}
