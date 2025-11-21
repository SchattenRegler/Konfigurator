import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:latlong2/latlong.dart';

import 'config/map_tiles.dart';
import 'services/nominatim_service.dart';

class LocationPickerDialog extends StatefulWidget {
  final String initialAddress;
  final LatLng? start; // used as initial point if provided
  final LatLng? end; // ignored in single-point mode, kept for backward compatibility

  const LocationPickerDialog({
    super.key,
    required this.initialAddress,
    this.start,
    this.end,
  });

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  final MapController _mapController = MapController();
  String address = '';
  LatLng? selectedPoint;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    address = widget.initialAddress;
    _addressController = TextEditingController(text: address);

    // Use `start` as initial point if provided (ignore `end` in single-point mode)
    if (widget.start != null) {
      selectedPoint = LatLng(widget.start!.latitude, widget.start!.longitude);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(selectedPoint!, 18.0);
      });
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Standort wählen'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        //height: 520,
        child: Column(
          children: [
            TypeAheadFormField<Map<String, dynamic>>(
              textFieldConfiguration: TextFieldConfiguration(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Adresse'),
              ),
              suggestionsCallback: NominatimService.fetchSuggestions,
              itemBuilder: (context, suggestion) => ListTile(
                title: Text(suggestion['display_name'] as String),
              ),
              onSuggestionSelected: (suggestion) {
                final displayName = suggestion['display_name'] as String;
                _addressController.text = displayName;
                // Karte auf die gewählte Adresse zentrieren (ohne Marker zu setzen)
                final lat = double.parse(suggestion['lat'] as String);
                final lon = double.parse(suggestion['lon'] as String);
                final pos = LatLng(lat, lon);
                _mapController.move(pos, 18.0);
              },
              noItemsFoundBuilder: (context) => const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Keine Vorschläge gefunden'),
              ),
            ),
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: selectedPoint ?? LatLng(0, 0),
                  initialZoom: selectedPoint != null ? 18.0 : 2.0,
                  onTap: (tapPos, latlng) {
                    setState(() {
                      selectedPoint = LatLng(latlng.latitude, latlng.longitude);
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapTilesConfig.arcgisUrlTemplate,
                    subdomains: ['a', 'b', 'c'],
                    userAgentPackageName: 'com.staerium.configurator',
                    tileDimension: 256,
                  ),
                  MarkerLayer(
                    markers: [
                      if (selectedPoint != null)
                        Marker(
                          point: selectedPoint!,
                          width: 16,
                          height: 16,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Required attributions for Esri World Imagery tiles and Nominatim/OSM search
                  RichAttributionWidget(
                    // Display required data source credits
                    showFlutterMapAttribution: false,
                    attributions: const [
                      TextSourceAttribution(
                        'Imagery: Esri World Imagery — © Esri, Maxar, Earthstar Geographics, and the GIS User Community',
                      ),
                      TextSourceAttribution(
                        'Search: Nominatim (OpenStreetMap) — © OpenStreetMap contributors',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                TextButton(
                  onPressed: () {
                    // Ausgewählten Punkt löschen
                    setState(() {
                      selectedPoint = null;
                    });
                  },
                  child: const Text('Punkt löschen'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  child: const Text('Abbrechen'),
                ),
                TextButton(
                  onPressed: selectedPoint == null
                      ? null
                      : () {
                          // The dialog now returns a LatLng directly
                          Navigator.of(context, rootNavigator: true).pop(selectedPoint);
                        },
                  child: const Text('Fertig'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
