import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'facade_orientation_dialog.dart';
import 'package:latlong2/latlong.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:solar_calculator/solar_calculator.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Sector {
  final String guid = const Uuid().v4();
  String id = '';
  String name = '';
  double orientation = 0;
  bool horizonLimit = false;
  List<Point> horizonPoints = [];
  List<Point> ceilingPoints = [];
  bool louvreTracking = false;
  double louvreSpacing = 0;
  double louvreDepth = 0;
  // ... additional sector fields
  String brightnessAddress = '';
  String irradianceAddress = '';
  String facadeAddress = '';
  LatLng? facadeStart;
  LatLng? facadeEnd;
}

class Point {
  double x;
  double y;
  Point({this.x = 0, this.y = 0});
}

class SectorWidget extends StatefulWidget {
  final Sector sector;
  final VoidCallback onRemove;
  const SectorWidget({Key? key, required this.sector, required this.onRemove}) : super(key: key);

  @override
  State<SectorWidget> createState() => _SectorWidgetState();
}

class _SectorWidgetState extends State<SectorWidget> {
  Sector get sector => widget.sector;
  late TextEditingController _orientationController;
  DateTime _selectedDate = DateTime.now();
  String? _orientationError;
  String? _brightnessError;
  String? _irradianceError;

  @override
  void initState() {
    super.initState();
    _orientationController = TextEditingController(
      text: sector.orientation.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _orientationController.dispose();
    super.dispose();
  }

  List<FlSpot> _computeSolarPath(DateTime date) {
    const double lat = 47.3769;
    const double lon = 8.5417;
    final spots = <FlSpot>[];
    for (int minute = 0; minute <= 24 * 60; minute++) {
      final hour = minute ~/ 60;
      final min = minute % 60;
      final dateTime = DateTime(date.year, date.month, date.day, hour, min);
      final instant = Instant.fromDateTime(dateTime);
      final calc = SolarCalculator(instant, lat, lon);
      final sunPos = calc.sunHorizontalPosition;
      final rawAz = sunPos.azimuth;
      var el = sunPos.elevation;
      // Normalize azimuth difference into [-180, 180] range
      final offset = (sector.orientation + 360) % 360;
      var az = rawAz - offset;
      az = (az + 360) % 360;
      if (az > 90 && az < 270) {
       spots.add(FlSpot.nullSpot);
      }
      else {
        if (az > 180) {
          az -= 360;
        }
        final adjustedAz = az;
        spots.add(FlSpot(adjustedAz, el));
      }
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    // Bildschirmhöhe für feste Höhen nutzen
    final screenHeight = MediaQuery.of(context).size.height;
    return DefaultTabController(
      length: 1 + (sector.horizonLimit ? 1 : 0) + (sector.louvreTracking ? 1 : 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            tabs: [
              const Tab(text: 'Einstellungen'),
              if (sector.louvreTracking) const Tab(text: 'Lamellennachführung'),
              if (sector.horizonLimit) const Tab(text: 'Horizontbegrenzung'),
            ],
          ),
          SizedBox(
            height: screenHeight * 0.75,
            child: TabBarView(
              children: [
                // Erster Tab: Einstellungen
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // GUID (readonly)
                      TextFormField(
                        initialValue: sector.guid,
                        decoration: const InputDecoration(labelText: 'GUID'),
                        enabled: false,
                      ),
                      const SizedBox(height: 16),
                      // Name
                      TextFormField(
                        initialValue: sector.name,
                        decoration: const InputDecoration(labelText: 'Name'),
                        onChanged: (v) => sector.name = v,
                      ),
                      const SizedBox(height: 16),
                      // Fassadenausrichtung
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _orientationController,
                        decoration: InputDecoration(
                          labelText: 'Ausrichtung',
                          errorText: _orientationError,
                        ),
                        onChanged: (v) {
                          final val = double.tryParse(v);
                          if (val == null || val < -180 || val > 180) {
                            setState(() {
                              _orientationError = 'Bitte Wert zwischen -180 und 180 eingeben';
                            });
                          } else {
                            setState(() {
                              _orientationError = null;
                              sector.orientation = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          // Open map dialog to pick two points
                          final result = await showDialog<Map<String, LatLng>>(
                            context: context,
                            builder: (_) => FacadeOrientationDialog(
                              initialAddress: sector.facadeAddress,
                              start: sector.facadeStart,
                              end: sector.facadeEnd,
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              sector.facadeStart = result['start'];
                              sector.facadeEnd = result['end'];
                              // Calculate geodetic bearing between two coordinates
                              final lat1 = result['start']!.latitude * pi / 180;
                              final lat2 = result['end']!.latitude * pi / 180;
                              final lon1 = result['start']!.longitude * pi / 180;
                              final lon2 = result['end']!.longitude * pi / 180;
                              final dLon = lon2 - lon1;
                              final y = sin(dLon) * cos(lat2);
                              final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
                              var bearing = atan2(y, x) * 180 / pi;
                              bearing = (bearing + 360) % 360 -90; // Adjust to make 0 degrees point north
                              sector.orientation = bearing;
                              _orientationController.text = sector.orientation.toStringAsFixed(1);
                            });
                          }
                        },
                        child: const Text('Ausrichtung auf Karte wählen'),
                      ),
                      // Gruppenadresse Helligkeit
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: sector.brightnessAddress,
                        decoration: InputDecoration(
                          labelText: 'Gruppenadresse Helligkeit',
                          errorText: _brightnessError,
                        ),
                        onChanged: (v) {
                          setState(() {
                            sector.brightnessAddress = v;
                            final parts = v.split('/');
                            final a = int.tryParse(parts.isNotEmpty ? parts[0] : '');
                            final b = int.tryParse(parts.length > 1 ? parts[1] : '');
                            final c = int.tryParse(parts.length > 2 ? parts[2] : '');
                            if (parts.length != 3 ||
                                a == null || a < 0 || a > 31 ||
                                b == null || b < 0 || b > 7 ||
                                c == null || c < 0 || c > 255 ||
                                (a == 0 && b == 0 && c == 0)) {
                              _brightnessError = 'Ungültiges Format, bitte dreistufige Gruppenadresse eingeben';
                            } else {
                              _brightnessError = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Gruppenadresse Globalstrahlung
                      TextFormField(
                        initialValue: sector.irradianceAddress,
                        decoration: InputDecoration(
                          labelText: 'Gruppenadresse Globalstrahlung',
                          errorText: _irradianceError,
                        ),
                        onChanged: (v) {
                          setState(() {
                            sector.irradianceAddress = v;
                            final parts = v.split('/');
                            final a = int.tryParse(parts.isNotEmpty ? parts[0] : '');
                            final b = int.tryParse(parts.length > 1 ? parts[1] : '');
                            final c = int.tryParse(parts.length > 2 ? parts[2] : '');
                            if (parts.length != 3 ||
                                a == null || a < 0 || a > 31 ||
                                b == null || b < 0 || b > 7 ||
                                c == null || c < 0 || c > 255 ||
                                (a == 0 && b == 0 && c == 0)) {
                              _irradianceError = 'Ungültiges Format, bitte dreistufige Gruppenadresse eingeben';
                            } else {
                              _irradianceError = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Lamellennachführung'),
                        value: sector.louvreTracking,
                        onChanged: (v) => setState(() { sector.louvreTracking = v; }),
                      ),
                      SwitchListTile(
                        title: const Text('Horizontbegrenzung'),
                        value: sector.horizonLimit,
                        onChanged: (v) => setState(() { sector.horizonLimit = v; }),
                      ),
                      const SizedBox(height: 24),
                      // Remove button
                      ElevatedButton.icon(
                        onPressed: widget.onRemove,
                        icon: const Icon(Icons.delete),
                        label: const Text('Sektor entfernen'),
                      ),
                    ],
                  ),
                ),
                if (sector.louvreTracking)
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: sector.louvreSpacing.toStringAsFixed(1),
                              decoration: const InputDecoration(labelText: 'Lamellenabstand (m)'),
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                              final val = double.tryParse(v);
                              if (val != null && val > 0) {
                                setState(() {
                                sector.louvreSpacing = val;
                                });
                              }
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: sector.louvreDepth.toStringAsFixed(1),
                              decoration: const InputDecoration(labelText: 'Lamellentiefe (m)'),
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                              final val = double.tryParse(v);
                              if (val != null && val > 0) {
                                setState(() {
                                sector.louvreDepth = val;
                                });
                              }
                              },
                            ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 160),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Empty'),
                      ),
                      ],
                    ),
                  ),
                if (sector.horizonLimit)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedDate = DateTime.now();
                              });
                            },
                            child: const Text('Heute'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedDate = picked;
                                });
                              }
                            },
                            child: const Text('Datum wählen'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: FractionallySizedBox(
                            heightFactor: 0.8,
                            child: LineChart(
                              LineChartData(
                                clipData: FlClipData.all(),
                                lineTouchData: LineTouchData(
                                  enabled: true,
                                  touchSpotThreshold: 3,
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                      return touchedSpots.map((LineBarSpot touchedSpot) {
                                          final az = touchedSpot.x;
                                          final el = touchedSpot.y;
                                        if (touchedSpot.barIndex != 5) {
                                          final hour = touchedSpot.spotIndex ~/ 60;
                                          final min = touchedSpot.spotIndex % 60;
                                          return LineTooltipItem(
                                            "Zeit: ${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}\nAzimut: ${az.toStringAsFixed(1)}°\nElevation: ${el.toStringAsFixed(1)}°",
                                            const TextStyle(color: Colors.black, fontSize: 12),
                                          );
                                        }
                                      }).toList();
                                    },
                                  ),
                                  getTouchedSpotIndicator: (
                                    _,
                                    indicators,
                                  ) {
                                    return indicators
                                        .map((int index) => const TouchedSpotIndicatorData(
                                              FlLine(color: Colors.transparent),
                                              FlDotData(show: false),
                                            ))
                                        .toList();
                                  },
                                  distanceCalculator:
                                      (Offset touchPoint, Offset spotPixelCoordinates) =>
                                          (touchPoint - spotPixelCoordinates).distance,
                                ),
                                minX: -90,
                                maxX: 90,
                                minY: 0,
                                maxY: 90,
                                gridData: FlGridData(show: true),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: true),
                                  ),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _computeSolarPath(_selectedDate),
                                    isCurved: true,
                                    dotData: FlDotData(show: false),
                                  ),
                                  LineChartBarData(
                                    spots: _computeSolarPath(DateTime(_selectedDate.year, 12, 21)),
                                    isCurved: true,
                                    dotData: FlDotData(show: false),
                                    color: Colors.blue[900],
                                  ),
                                  LineChartBarData(
                                    spots: _computeSolarPath(DateTime(_selectedDate.year, 6, 21)),
                                    isCurved: true,
                                    dotData: FlDotData(show: false),
                                    color: Colors.blue[200],
                                  ),
                                  LineChartBarData(
                                    spots: sector.horizonPoints.map((p) => FlSpot(p.x, p.y)).toList(),
                                    isCurved: false,
                                    dotData: FlDotData(show: true),
                                    barWidth: 2,
                                  ),
                                  LineChartBarData(
                                    spots: sector.ceilingPoints.map((p) => FlSpot(p.x, p.y)).toList(),
                                    isCurved: false,
                                    dotData: FlDotData(show: true),
                                    barWidth: 2,
                                  ),
                                  LineChartBarData(
                                    spots: [
                                    () {
                                      final now = DateTime.now();
                                      final instant = Instant.fromDateTime(now);
                                      const double lat = 47.3769;
                                      const double lon = 8.5417;
                                      final calc = SolarCalculator(instant, lat, lon);
                                      final sunPos = calc.sunHorizontalPosition;
                                      // Normalize azimuth difference into [-180, 180] range
                                      final offset = (sector.orientation + 360) % 360;
                                      var az = sunPos.azimuth - offset;
                                      az = (az + 360) % 360;
                                      if (az > 180) az -= 360;
                                      // Only show if sun is in front of facade
                                      if (az.abs() > 90) return null;
                                      return FlSpot(az, sunPos.elevation);
                                    }()
                                    ].whereType<FlSpot>().toList(),
                                    isCurved: false,
                                    dotData: FlDotData(show: true),
                                    color: Colors.yellow,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}