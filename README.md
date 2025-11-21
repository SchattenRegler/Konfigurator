

# Konfigurator

**Konfigurator** is a cross-platform Flutter application for configuring, visualizing, and managing facade sectors and solar control logic. It is designed for building automation, facade planning, and smart shading projects, supporting import/export, mapping, and bus address configuration.

## Key Features

- **Facade Sector Management:** Create, edit, and remove facade sectors with custom properties (orientation, horizon, louvre, bus addresses, etc.).
- **Mapping & Geolocation:** Select facade points and visualize sectors on an interactive map (OpenStreetMap imagery).
- **Solar Calculations:** Calculate and visualize solar paths and angles for each sector using `solar_calculator` and `fl_chart`.
- **Bus Address Integration:** Configure KNX/field bus addresses for brightness, irradiance, azimuth, elevation, and more.
- **File Import/Export:** Save and load project files (`.sunproj`) for easy sharing and backup.
- **Modern UI:** Responsive navigation, dialogs for orientation and location, and address autocomplete.
- **Cross-Platform:** Runs on Windows, macOS, Linux, Android, iOS, and Web.

## Screenshots

<!-- Add screenshots here, e.g.: -->
<!-- ![Main UI](assets/screenshots/main.png) -->

## Getting Started

1. **Clone the repository:**
	```sh
	git clone https://github.com/SchattenRegler/Konfigurator.git
	cd Konfigurator
	```
2. **Install dependencies:**
	```sh
	flutter pub get
	```
3. **Run the app:**
	```sh
	flutter run
	```

## ArcGIS API Key

The facade and location dialogs use Esri World Imagery tiles that now expect an ArcGIS API key. Provide your key at build/run time via Dart defines; the app reads it through `MapTilesConfig.arcgisApiKey`.

- **Development run:**
  ```sh
  flutter run --dart-define=ARCGIS_API_KEY=<YOUR_ARCGIS_API_KEY>
  ```
- **Building (example for macOS):**
  ```sh
  flutter build macos --dart-define=ARCGIS_API_KEY=<YOUR_ARCGIS_API_KEY>
  ```

- **GitHub Actions:** Add the key as a repository secret named `ARCGIS_API_KEY` (Settings → Secrets and variables → Actions → New repository secret). The workflow consumes it automatically for every build via `--dart-define`.

If you omit the define the app still loads the public tiles (suitable only for quick testing), so keep the define in your IDE run configurations for compliant production usage.

## Project Structure

- `lib/main.dart` – App entry point, navigation, and main configuration logic
- `lib/sector.dart` – Sector data model and sector editing widget
- `lib/facade_orientation_dialog.dart` – Dialog for selecting and visualizing facade orientation
- `lib/location_dialog.dart` – Dialog for selecting a single point (lat/lng) on the map
- `assets/` – App assets (SVGs, icons, etc.)
- `test/` – Widget and unit tests

## Main Dependencies

- [Flutter](https://flutter.dev/) (cross-platform UI)
- [file_picker](https://pub.dev/packages/file_picker) (file import/export)
- [uuid](https://pub.dev/packages/uuid) (unique IDs)
- [geocoding](https://pub.dev/packages/geocoding) (address lookup)
- [flutter_map](https://pub.dev/packages/flutter_map) (map UI)
- [latlong2](https://pub.dev/packages/latlong2) (lat/lng types)
- [flutter_typeahead](https://pub.dev/packages/flutter_typeahead) (address autocomplete)
- [http](https://pub.dev/packages/http) (API calls)
- [fl_chart](https://pub.dev/packages/fl_chart) (charts)
- [solar_calculator](https://pub.dev/packages/solar_calculator) (solar position)
- [flutter_svg](https://pub.dev/packages/flutter_svg) (SVG rendering)

See `pubspec.yaml` for the full list.

## Usage Overview

1. **Create or open a project**: Start a new configuration or load an existing `.sunproj` file.
2. **Configure general settings**: Set version, bus addresses, and azimuth/elevation options.
3. **Manage sectors**: Add, edit, or remove facade sectors. Set orientation, horizon, louvre, and bus addresses for each sector.
4. **Map & solar tools**: Use dialogs to select facade points on the map and visualize solar paths.
5. **Save/export**: Export your configuration for use in building automation systems.

## Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss your ideas.

## License

MIT License. See [LICENSE](LICENSE) for details.
