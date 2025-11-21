class ProviderAttributions {
  ProviderAttributions._();

  static const String esriImageryText =
      'Imagery: Esri World Imagery — © Esri, Maxar, Earthstar Geographics, and the GIS User Community';

  static const String nominatimMapOverlayText =
      'Search & Geocoding: Powered by Nominatim — © OpenStreetMap contributors (ODbL)';

  static const String nominatimNoticeText =
      'Powered by Nominatim (© OpenStreetMap contributors, ODbL)';

  static final Uri esriDataAttributionUri =
      Uri.parse('https://www.esri.com/en-us/legal/terms/data-attribution');
  static final Uri esriServicesUri =
      Uri.parse('https://www.esri.com/en-us/legal/terms/services');
  static final Uri osmCopyrightUri =
      Uri.parse('https://www.openstreetmap.org/copyright');
  static final Uri nominatimSiteUri = Uri.parse('https://nominatim.org/');
  static final Uri nominatimUsagePolicyUri =
      Uri.parse('https://operations.osmfoundation.org/policies/nominatim/');
  static final Uri odblLicenseUri =
      Uri.parse('https://opendatacommons.org/licenses/odbl/');
}
