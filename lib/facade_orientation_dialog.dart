import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:latlong2/latlong.dart';

import 'config/map_tiles.dart';
import 'services/nominatim_service.dart';

class FacadeOrientationDialog extends StatefulWidget {
  final String initialAddress;
  final LatLng? start;
  final LatLng? end;

  const FacadeOrientationDialog({
    super.key,
    required this.initialAddress,
    this.start,
    this.end,
  });

  @override
  State<FacadeOrientationDialog> createState() => _FacadeOrientationDialogState();
}

class _FacadeOrientationDialogState extends State<FacadeOrientationDialog> {
  final MapController _mapController = MapController();
  List<Polyline> _polylines = [];
  double bearingAngle = 0;
  String address = '';
  LatLng? startPoint;
  LatLng? endPoint;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    address = widget.initialAddress;
    _addressController = TextEditingController(text: address);
    startPoint = widget.start == null ? null : LatLng(widget.start!.latitude, widget.start!.longitude);
    endPoint = widget.end == null ? null : LatLng(widget.end!.latitude, widget.end!.longitude);

    if (startPoint != null && endPoint != null) {
      _polylines = [
        Polyline(
          points: [startPoint!, endPoint!],
          strokeWidth: 3,
          color: Colors.red,
        ),
      ];
      // Calculate geodetic bearing between two coordinates
      final lat1 = startPoint!.latitude * pi / 180;
      final lat2 = endPoint!.latitude * pi / 180;
      final lon1 = startPoint!.longitude * pi / 180;
      final lon2 = endPoint!.longitude * pi / 180;
      final dLon = lon2 - lon1;
      final y = sin(dLon) * cos(lat2);
      final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
      var bearing = atan2(y, x) * 180 / pi;
      bearing = (bearing + 360) % 360 -90; // Adjust to make 0 degrees point north
      bearingAngle = bearing;
      // center map
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(startPoint!, 18.0);
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
      title: const Text('Fassadenausrichtung wählen'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        //height: 600,
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
                // Center map on the selected address without adding any points or markers
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
                  initialCenter: startPoint ?? LatLng(0, 0),
                  initialZoom: startPoint != null ? 18.0 : 2.0,
                  onTap: (tapPos, latlng) {
                    setState(() {
                      if (startPoint == null || (startPoint != null && endPoint != null)) {
                        startPoint = LatLng(latlng.latitude, latlng.longitude);
                        endPoint = null;
                        _polylines.clear();
                      } else {
                        endPoint = LatLng(latlng.latitude, latlng.longitude);
                        _polylines = [
                          Polyline(
                            points: [startPoint!, endPoint!],
                            strokeWidth: 3,
                            color: Colors.red,
                          ),
                        ];
                        // Calculate geodetic bearing between two coordinates
                        final lat1 = startPoint!.latitude * pi / 180;
                        final lat2 = endPoint!.latitude * pi / 180;
                        final lon1 = startPoint!.longitude * pi / 180;
                        final lon2 = endPoint!.longitude * pi / 180;
                        final dLon = lon2 - lon1;
                        final y = sin(dLon) * cos(lat2);
                        final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
                        var bearing = atan2(y, x) * 180 / pi;
                        bearing = (bearing + 360) % 360 -90; // Adjust to make 0 degrees point north
                        bearingAngle = bearing;
                      }
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapTilesConfig.arcgisUrlTemplate,
                    subdomains: ['a', 'b', 'c'],
                    userAgentPackageName: 'com.staerium.configurator',
                    tileSize: 256.0,
                  ),
                  PolylineLayer(polylines: _polylines),
                  MarkerLayer(
                    markers: [
                      if (startPoint != null)
                        Marker(
                          point: startPoint!,
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
                      if (endPoint != null)
                        Marker(
                          point: endPoint!,
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
                      if (startPoint != null && endPoint != null)
                        Marker(
                          // offset arrow marker slightly backward (opposite arrow direction)
                          point: LatLng(
                            ((startPoint!.latitude + endPoint!.latitude) / 2)
                                + 0.0001 * cos(bearingAngle * pi / 180),
                            ((startPoint!.longitude + endPoint!.longitude) / 2)
                                + 0.0001 * sin(bearingAngle * pi / 180),
                          ),
                          width: 64,
                          height: 64,
                          child: Transform.rotate(
                            angle: bearingAngle * pi / 180,
                            child: const Icon(Icons.arrow_downward, size: 64, color: Colors.yellow),
                          ),
                        ),
                      if (startPoint != null && endPoint != null)
                        Marker(
                          // offset sun marker more backward (opposite arrow direction)
                          point: LatLng(
                            ((startPoint!.latitude + endPoint!.latitude) / 2)
                                + 0.0002 * cos(bearingAngle * pi / 180),
                            ((startPoint!.longitude + endPoint!.longitude) / 2)
                                + 0.0002 * sin(bearingAngle * pi / 180),
                          ),
                          width: 64,
                          height: 64,
                          child: Transform.rotate(
                            angle: bearingAngle * pi / 180,
                            child: const Icon(Icons.wb_sunny, size: 64, color: Colors.yellow),
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Aktueller Winkel: ${bearingAngle.toStringAsFixed(1)}°',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (startPoint != null && endPoint != null) {
                        // Swap start and end points
                        final temp = startPoint;
                        startPoint = endPoint;
                        endPoint = temp;
                        // Redraw the line
                        _polylines = [
                          Polyline(
                            points: [startPoint!, endPoint!],
                            strokeWidth: 3,
                            color: Colors.red,
                          ),
                        ];
                        // Recalculate bearing
                        final lat1 = startPoint!.latitude * pi / 180;
                        final lat2 = endPoint!.latitude * pi / 180;
                        final lon1 = startPoint!.longitude * pi / 180;
                        final lon2 = endPoint!.longitude * pi / 180;
                        final dLon = lon2 - lon1;
                        final y = sin(dLon) * cos(lat2);
                        final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
                        var bearing = atan2(y, x) * 180 / pi;
                        bearing = (bearing + 360) % 360 - 90;
                        bearingAngle = bearing;
                      }
                    });
                  },
                  child: const Text('Fensterseite Tauschen'),
                ),
                TextButton(
                  onPressed: () {
                    // Clear the drawn line and reset points
                    setState(() {
                      _polylines.clear();
                      startPoint = null;
                      endPoint = null;
                    });
                  },
                  child: const Text('Linie löschen'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                TextButton(
                  onPressed: () {
                    if (startPoint != null && endPoint != null) {
                      Navigator.pop(context, {
                        'start': startPoint as LatLng,
                        'end': endPoint as LatLng,
                      });
                    } else {
                      showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Hinweis'),
                        content: const Text('Bitte wählen Sie Start- und Endpunkt aus.'),
                        actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                        ],
                      ),
                      );
                    }
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
