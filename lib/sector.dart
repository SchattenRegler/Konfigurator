import 'package:configurator/globals.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'facade_orientation_dialog.dart';
import 'package:latlong2/latlong.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:solar_calculator/solar_calculator.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Sector {
  String guid;
  String id;
  late final ValueNotifier<String> nameNotifier;
  double orientation;
  bool horizonLimit;
  List<Point> horizonPoints;
  List<Point> ceilingPoints;
  bool louvreTracking;
  double louvreSpacing;
  double louvreDepth;
  String brightnessAddress;
  bool useBrightness;
  bool useIrradiance;
  int? brightnessUpperThreshold;
  int? brightnessUpperDelay;
  int? brightnessLowerThreshold;
  int? brightnessLowerDelay;
  String irradianceAddress;
  int? irradianceUpperThreshold;
  int? irradianceUpperDelay;
  int? irradianceLowerThreshold;
  int? irradianceLowerDelay;
  String brightnessIrradianceLink;
  String facadeAddress;
  LatLng? facadeStart;
  LatLng? facadeEnd;

  Sector({
    String? guid,
    this.id = '',
    String name = '',
    this.orientation = 0,
    this.useBrightness = true,
    this.useIrradiance = true,
    this.horizonLimit = false,
    List<Point>? horizonPoints,
    List<Point>? ceilingPoints,
    this.louvreTracking = false,
    this.louvreSpacing = 0,
    this.louvreDepth = 0,
    this.brightnessAddress = '',
    this.irradianceAddress = '',
    this.brightnessIrradianceLink = 'Und',
    this.facadeAddress = '',
    this.facadeStart,
    this.facadeEnd,
  })  : guid = guid ?? const Uuid().v4(),
        horizonPoints = horizonPoints ?? [],
        ceilingPoints = ceilingPoints ?? [] {
    nameNotifier = ValueNotifier<String>(name);
  }

  String get name => nameNotifier.value;
  set name(String value) => nameNotifier.value = value;
}

class Point {
  double x;
  double y;
  Point({this.x = 0, this.y = 0});
}

class SectorWidget extends StatefulWidget {
  final Sector sector;
  final VoidCallback onRemove;
  const SectorWidget({super.key, required this.sector, required this.onRemove});

  @override
  State<SectorWidget> createState() => _SectorWidgetState();
}

class _SectorWidgetState extends State<SectorWidget> {
  Sector get sector => widget.sector;
  late TextEditingController _orientationController;
  // Controllers for horizon/ceiling point entry
  late TextEditingController _horizonAzController;
  late TextEditingController _horizonElController;
  late TextEditingController _ceilingAzController;
  late TextEditingController _ceilingElController;
  // Row editors: controllers mapped per Point for inline editing
  final Map<Point, TextEditingController> _horizonAzCtrls = {};
  final Map<Point, TextEditingController> _horizonElCtrls = {};
  final Map<Point, TextEditingController> _ceilingAzCtrls = {};
  final Map<Point, TextEditingController> _ceilingElCtrls = {};
  DateTime _selectedDate = DateTime.now();
  String? _orientationError;
  String? _horizonAzError;
  String? _horizonElError;
  String? _ceilingAzError;
  String? _ceilingElError;
  String? _brightnessAddressError;
  String? _brightnessUpperThresholdError;
  String? _brightnessUpperDelayError;
  String? _brightnessLowerThresholdError;
  String? _brightnessLowerDelayError;
  String? _irradianceAddressError;
  String? _irradianceUpperThresholdError;
  String? _irradianceUpperDelayError;
  String? _irradianceLowerThresholdError;
  String? _irradianceLowerDelayError;

  @override
  void initState() {
    super.initState();
    _orientationController = TextEditingController(
      text: sector.orientation.toStringAsFixed(1),
    );
    _horizonAzController = TextEditingController();
    _horizonElController = TextEditingController();
    _ceilingAzController = TextEditingController();
    _ceilingElController = TextEditingController();
    _syncPointEditors();
  }

  @override
  void dispose() {
    _orientationController.dispose();
    _horizonAzController.dispose();
    _horizonElController.dispose();
    _ceilingAzController.dispose();
    _ceilingElController.dispose();
    for (final c in _horizonAzCtrls.values) { c.dispose(); }
    for (final c in _horizonElCtrls.values) { c.dispose(); }
    for (final c in _ceilingAzCtrls.values) { c.dispose(); }
    for (final c in _ceilingElCtrls.values) { c.dispose(); }
    super.dispose();
  }

  // Ensure we have text controllers for each existing point
  void _syncPointEditors() {
    for (final p in sector.horizonPoints) {
      _horizonAzCtrls.putIfAbsent(p, () => TextEditingController(text: _fmt(p.x)));
      _horizonElCtrls.putIfAbsent(p, () => TextEditingController(text: _fmt(p.y)));
    }
    for (final p in sector.ceilingPoints) {
      _ceilingAzCtrls.putIfAbsent(p, () => TextEditingController(text: _fmt(p.x)));
      _ceilingElCtrls.putIfAbsent(p, () => TextEditingController(text: _fmt(p.y)));
    }
  }


  void _addHorizonPoint() {
    setState(() {
      final p = Point(x: 0, y: 0);
      sector.horizonPoints.add(p);
      sector.horizonPoints.sort((a, b) => a.x.compareTo(b.x));
      _horizonAzCtrls[p] = TextEditingController(text: '0');
      _horizonElCtrls[p] = TextEditingController(text: '0');
    });
  }

  void _addCeilingPoint() {
    setState(() {
      final p = Point(x: 0, y: 0);
      sector.ceilingPoints.add(p);
      sector.ceilingPoints.sort((a, b) => a.x.compareTo(b.x));
      _ceilingAzCtrls[p] = TextEditingController(text: '0');
      _ceilingElCtrls[p] = TextEditingController(text: '0');
    });
  }

  List<FlSpot> _computeSolarPath(DateTime date) {
    final spots = <FlSpot>[];
    for (int minute = 0; minute <= 24 * 60; minute++) {
      final hour = minute ~/ 60;
      final min = minute % 60;
      final dateTime = DateTime(date.year, date.month, date.day, hour, min);
      final instant = Instant.fromDateTime(dateTime);
      final calc = SolarCalculator(instant, latitude, longitude);
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
    // Keep editors in sync and ensure sorted view by azimuth
    _syncPointEditors();
    sector.horizonPoints.sort((a, b) => a.x.compareTo(b.x));
    sector.ceilingPoints.sort((a, b) => a.x.compareTo(b.x));
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
          Expanded(
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
                      ValueListenableBuilder<String>(
                        valueListenable: sector.nameNotifier,
                        builder: (context, name, _) {
                          return TextFormField(
                            initialValue: name,
                            decoration: const InputDecoration(labelText: 'Name'),
                            onChanged: (v) {
                              sector.name = v;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Fassadenausrichtung
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _orientationController,
                              decoration: InputDecoration(
                                labelText: 'Ausrichtung',
                                suffixText: '°',
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
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
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
                            icon: const Icon(Icons.map),
                            label: const Text('Auf Karte wählen'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Helligkeit verwenden'),
                        value: sector.useBrightness,
                        onChanged: sector.useIrradiance ? (v) => setState(() { sector.useBrightness = v; }) : null,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Globalstrahlung verwenden'),
                        value: sector.useIrradiance,
                        onChanged: sector.useBrightness ? (v) => setState(() { sector.useIrradiance = v; }) : null,
                      ),

                      //Helligkeit
                      if(sector.useBrightness)
                        const SizedBox(height: 16),
                      if(sector.useBrightness)
                        TextFormField(
                          initialValue: sector.brightnessAddress,
                          decoration: InputDecoration(
                            labelText: 'Gruppenadresse Helligkeit',
                            errorText: _brightnessAddressError,
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
                                _brightnessAddressError = 'Ungültiges Format, bitte dreistufige Gruppenadresse eingeben';
                              } else {
                                _brightnessAddressError = null;
                              }
                            });
                          },
                        ),
                      if(sector.useBrightness)
                        const SizedBox(height: 16),
                      if(sector.useBrightness)
                        TextFormField(
                          initialValue: '',
                          decoration: InputDecoration(
                            labelText: 'Helligkeitsschwellwert Dunkel --> Hell',
                            suffixText: 'Lux',
                            errorText: _brightnessUpperThresholdError,
                          ),
                          onChanged: (v) {
                            final val = int.tryParse(v);
                              if (val == null || val < 0) {
                                setState(() {
                                  _brightnessUpperThresholdError = 'Bitte gültigen Wert eingeben';
                                });
                              } else {
                                setState(() {
                                  _brightnessUpperThresholdError = null;
                                  sector.brightnessUpperThreshold = val;
                                });
                              }
                          },
                        ),
                      if(sector.useBrightness)
                        const SizedBox(height: 16),
                      if(sector.useBrightness)
                        TextFormField(
                          initialValue: '',
                          decoration: InputDecoration(
                            labelText: 'Verzögerungszeit Dunkel --> Hell',
                            suffixText: 's',
                            errorText: _brightnessUpperDelayError,
                          ),
                          onChanged: (v) {
                            final val = int.tryParse(v);
                              if (val == null || val < 0) {
                                setState(() {
                                  _brightnessUpperDelayError = 'Bitte gültigen Wert eingeben';
                                });
                              } else {
                                setState(() {
                                  _brightnessUpperDelayError = null;
                                  sector.brightnessUpperDelay = val;
                                });
                              }
                          },
                        ),
                      if(sector.useBrightness)
                        const SizedBox(height: 16),
                      if(sector.useBrightness)
                        TextFormField(
                          initialValue: '',
                          decoration: InputDecoration(
                            labelText: 'Helligkeitsschwellwert Hell --> Dunkel',
                            suffixText: 'Lux',
                            errorText: _brightnessLowerThresholdError,
                          ),
                          onChanged: (v) {
                            final val = int.tryParse(v);
                              if (val == null || val < 0) {
                                setState(() {
                                  _brightnessLowerThresholdError = 'Bitte gültigen Wert eingeben';
                                });
                              } else {
                                setState(() {
                                  _brightnessLowerThresholdError = null;
                                  sector.brightnessLowerThreshold = val;
                                });
                              }
                          },
                        ),
                      if(sector.useBrightness)
                        const SizedBox(height: 16),
                      if(sector.useBrightness)
                        TextFormField(
                          initialValue: '',
                          decoration: InputDecoration(
                            labelText: 'Verzögerungszeit Hell --> Dunkel',
                            suffixText: 's',
                            errorText: _brightnessLowerDelayError,
                          ),
                          onChanged: (v) {
                            final val = int.tryParse(v);
                            if (val == null || val < 0) {
                              setState(() {
                                _brightnessLowerDelayError = 'Bitte gültigen Wert eingeben';
                              });
                            } else {
                              setState(() {
                                _brightnessLowerDelayError = null;
                                sector.brightnessLowerDelay = val;
                              });
                            }
                          },
                        ),
                     //TODO
                     /* Not Ready yet
                      Text(
                        'Verzögerungszeit Hell --> Dunkel',
                        style: const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          height: 260,
                          width: 1000,
                          child: LineChart(
                            LineChartData(
                              lineTouchData: LineTouchData(enabled: false),
                              clipData: FlClipData.all(),
                              // swap ranges: X shows lux, Y shows time (seconds)
                              minX: 0,
                              maxX: (sector.brightnessLowerThreshold ?? 100000).toDouble(),
                              minY: 0,
                              maxY: 3600,
                              gridData: FlGridData(
                                show: true,
                                // horizontal lines reflect Y (time)
                                horizontalInterval: 600,
                                // vertical lines reflect X (lux)
                                verticalInterval: ((sector.brightnessLowerThreshold ?? 100000).toDouble()) / ((MediaQuery.of(context).size.width / 160).clamp(2, 10).round()),
                              ),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: ((sector.brightnessLowerThreshold ?? 100000).toDouble()) / ((MediaQuery.of(context).size.width / 160).clamp(2, 10).round()),
                                    getTitlesWidget: (value, meta) {
                                      return SideTitleWidget(
                                        meta: meta,
                                        space: 4,
                                        child: Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                          ),
                                        ),
                                      );
                                    },
                                    reservedSize: 30,
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 600,
                                    reservedSize: 60,
                                    getTitlesWidget: (value, meta) {
                                      final hours = (value / 3600).floor();
                                      final minutes = ((value % 3600) / 60).floor();
                                      return SideTitleWidget(
                                        meta: meta,
                                        space: 4,
                                        child: Text(
                                          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  // swap each spot's x/y; keep null spots as separators
                                  spots: _computeSolarPath(_selectedDate).map((s) {
                                    final isNull = s.x.isNaN || s.y.isNaN;
                                    if (isNull) return FlSpot.nullSpot;
                                    return FlSpot(s.y, s.x);
                                  }).toList(),
                                  isCurved: false,
                                  dotData: FlDotData(show: true),
                                  color: Colors.orange.shade200,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      */
                      //Globalstrahlung
                      if(sector.useIrradiance)
                        const SizedBox(height: 16),
                      if(sector.useIrradiance)
                        TextFormField(
                          initialValue: sector.irradianceAddress,
                          decoration: InputDecoration(
                            labelText: 'Gruppenadresse Globalstrahlung',
                            errorText: _irradianceAddressError,
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
                                _irradianceAddressError = 'Ungültiges Format, bitte dreistufige Gruppenadresse eingeben';
                              } else {
                                _irradianceAddressError = null;
                              }
                            });
                          },
                        ),
                      if(sector.useIrradiance)
                        const SizedBox(height: 16),
                      if(sector.useIrradiance)
                        TextFormField(
                          initialValue: '',
                          decoration: InputDecoration(
                            labelText: 'Globalstrahlungsschwellwert Tief --> Hoch',
                            suffixText: 'Lux',
                            errorText: _irradianceUpperThresholdError,
                          ),
                          onChanged: (v) {
                            final val = int.tryParse(v);
                              if (val == null || val < 0) {
                                setState(() {
                                  _irradianceUpperThresholdError = 'Bitte gültigen Wert eingeben';
                                });
                              } else {
                                setState(() {
                                  _irradianceUpperThresholdError = null;
                                  sector.irradianceUpperThreshold = val;
                                });
                              }
                          },
                        ),
                      if(sector.useIrradiance)
                        const SizedBox(height: 16),
                      if(sector.useIrradiance)
                        TextFormField(
                          initialValue: '',
                          decoration: InputDecoration(
                            labelText: 'Verzögerungszeit Tief --> Hoch',
                            suffixText: 's',
                            errorText: _irradianceUpperDelayError,
                          ),
                          onChanged: (v) {
                            final val = int.tryParse(v);
                              if (val == null || val < 0) {
                                setState(() {
                                  _irradianceUpperDelayError = 'Bitte gültigen Wert eingeben';
                                });
                              } else {
                                setState(() {
                                  _irradianceUpperDelayError = null;
                                  sector.irradianceUpperDelay = val;
                                });
                              }
                          },
                        ),
                      if(sector.useIrradiance)
                        const SizedBox(height: 16),
                      if(sector.useIrradiance)
                        TextFormField(
                          initialValue: '',
                          decoration: InputDecoration(
                            labelText: 'Globalstrahlungsschwellwert Hoch --> Tief',
                            suffixText: 'Lux',
                            errorText: _irradianceLowerThresholdError,
                          ),
                          onChanged: (v) {
                            final val = int.tryParse(v);
                              if (val == null || val < 0) {
                                setState(() {
                                  _irradianceLowerThresholdError = 'Bitte gültigen Wert eingeben';
                                });
                              } else {
                                setState(() {
                                  _irradianceLowerThresholdError = null;
                                  sector.irradianceLowerThreshold = val;
                                });
                              }
                          },
                        ),
                      if(sector.useIrradiance)
                        const SizedBox(height: 16),
                      if(sector.useIrradiance)
                        TextFormField(
                          initialValue: '',
                          decoration: InputDecoration(
                            labelText: 'Verzögerungszeit Hoch --> Tief',
                            suffixText: 's',
                            errorText: _irradianceLowerDelayError,
                          ),
                          onChanged: (v) {
                            final val = int.tryParse(v);
                            if (val == null || val < 0) {
                              setState(() {
                                _irradianceLowerDelayError = 'Bitte gültigen Wert eingeben';
                              });
                            } else {
                              setState(() {
                                _irradianceLowerDelayError = null;
                                sector.irradianceLowerDelay = val;
                              });
                            }
                          },
                        ),
                      if(sector.useBrightness && sector.useIrradiance)
                        const SizedBox(height: 16),
                      if(sector.useBrightness && sector.useIrradiance)
                        DropdownButtonFormField(
                          value: sector.brightnessIrradianceLink,
                          decoration: const InputDecoration(
                            labelText: 'Verknüpfung Helligkeit und Globalstrahlung',
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Und', child: Text('Und')),
                            DropdownMenuItem(value: 'Oder', child: Text('Oder')),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              sector.brightnessIrradianceLink = v;
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
                      // Remove button (match time program delete style)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: widget.onRemove,
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                          label: const Text('Sektor löschen', style: TextStyle(color: Colors.red)),
                        ),
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
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 12),
                      // Legend Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          alignment: WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _buildLegendItem(Colors.orange.shade200, 'Ausgewähltes Datum'),
                            _buildLegendItem(Colors.orange, '21. Dezember'),
                            _buildLegendItem(Colors.yellow, '21. Juni'),
                            _buildLegendItem(Colors.red, 'Horizont'),
                            _buildLegendItem(Colors.green, 'Decke'),
                            _buildLegendItem(Colors.blue.shade200, 'Sonnenposition jetzt'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Left: editable lists
                              SizedBox(
                                width: 380,
                                child: Card(
                                  elevation: 0,
                                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Horizontpunkte', style: TextStyle(fontWeight: FontWeight.bold)),
                                              TextButton.icon(
                                                onPressed: _addHorizonPoint,
                                                icon: const Icon(Icons.add),
                                                label: const Text('Neuer Punkt'),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          _buildPointsTable(
                                            points: sector.horizonPoints,
                                            azCtrls: _horizonAzCtrls,
                                            elCtrls: _horizonElCtrls,
                                            color: Colors.red.shade100,
                                            onRemove: (p) {
                                              setState(() {
                                                _horizonAzCtrls.remove(p)?.dispose();
                                                _horizonElCtrls.remove(p)?.dispose();
                                                sector.horizonPoints.remove(p);
                                              });
                                            },
                                            onChanged: (p) {
                                              setState(() {
                                                sector.horizonPoints.sort((a, b) => a.x.compareTo(b.x));
                                              });
                                            },
                                          ),
                                          const Divider(height: 24),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Deckenpunkte', style: TextStyle(fontWeight: FontWeight.bold)),
                                              TextButton.icon(
                                                onPressed: _addCeilingPoint,
                                                icon: const Icon(Icons.add),
                                                label: const Text('Neuer Punkt'),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          _buildPointsTable(
                                            points: sector.ceilingPoints,
                                            azCtrls: _ceilingAzCtrls,
                                            elCtrls: _ceilingElCtrls,
                                            color: Colors.green.shade100,
                                            onRemove: (p) {
                                              setState(() {
                                                _ceilingAzCtrls.remove(p)?.dispose();
                                                _ceilingElCtrls.remove(p)?.dispose();
                                                sector.ceilingPoints.remove(p);
                                              });
                                            },
                                            onChanged: (p) {
                                              setState(() {
                                                sector.ceilingPoints.sort((a, b) => a.x.compareTo(b.x));
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Right: chart
                              Expanded(
                                child: FractionallySizedBox(
                                  heightFactor: 0.95,
                                  child: LineChart(
                                    LineChartData(
                                      clipData: FlClipData.all(),
                                      lineTouchData: LineTouchData(
                                        enabled: true,
                                        touchSpotThreshold: 3,
                                        touchTooltipData: LineTouchTooltipData(
                                          getTooltipColor: (LineBarSpot touchedSpot) => Colors.yellow.shade200,
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
                                          color: Colors.orange.shade200,
                                        ),
                                        LineChartBarData(
                                          spots: _computeSolarPath(DateTime(_selectedDate.year, 12, 21)),
                                          isCurved: true,
                                          dotData: FlDotData(show: false),
                                          color: Colors.orange,
                                        ),
                                        LineChartBarData(
                                          spots: _computeSolarPath(DateTime(_selectedDate.year, 6, 21)),
                                          isCurved: true,
                                          dotData: FlDotData(show: false),
                                          color: Colors.yellow,
                                        ),
                                        LineChartBarData(
                                          spots: sector.horizonPoints.map((p) => FlSpot(p.x, p.y)).toList(),
                                          isCurved: false,
                                          dotData: FlDotData(show: true),
                                          barWidth: 2,
                                          color: Colors.red,
                                        ),
                                        LineChartBarData(
                                          spots: sector.ceilingPoints.map((p) => FlSpot(p.x, p.y)).toList(),
                                          isCurved: false,
                                          dotData: FlDotData(show: true),
                                          barWidth: 2,
                                          color: Colors.green,
                                        ),
                                        LineChartBarData(
                                          spots: [
                                          () {
                                            final now = DateTime.now();
                                            final instant = Instant.fromDateTime(now);
                                            final calc = SolarCalculator(instant, latitude, longitude);
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
                                          color: Colors.blue.shade200,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
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

String _fmt(double v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);

  Widget _buildPointsTable({
    required List<Point> points,
    required Map<Point, TextEditingController> azCtrls,
    required Map<Point, TextEditingController> elCtrls,
    required Color color,
    required void Function(Point) onRemove,
    required void Function(Point) onChanged,
  }) {
    // Headers + rows
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            children: [
              SizedBox(width: 120, child: Text('Azimut (°)', style: TextStyle(fontWeight: FontWeight.w600))),
              SizedBox(width: 12),
              SizedBox(width: 120, child: Text('Elevation (°)', style: TextStyle(fontWeight: FontWeight.w600))),
              Spacer(),
              SizedBox(width: 32),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ...points.map((p) {
          // Ensure controllers exist for this point
          azCtrls.putIfAbsent(p, () => TextEditingController(text: _fmt(p.x)));
          elCtrls.putIfAbsent(p, () => TextEditingController(text: _fmt(p.y)));
          final azCtrl = azCtrls[p]!;
          final elCtrl = elCtrls[p]!;
          return Padding(
            key: ObjectKey(p),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: azCtrl,
                    decoration: const InputDecoration(isDense: true, hintText: '-90 .. 90'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    onChanged: (v) {
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      if (parsed == null) return; // keep last valid
                      var clamped = parsed.clamp(-90, 90).toDouble();
                      if (clamped != parsed) {
                        final txt = _fmt(clamped);
                        azCtrl.value = TextEditingValue(
                          text: txt,
                          selection: TextSelection.collapsed(offset: txt.length),
                        );
                      }
                      p.x = clamped;
                      onChanged(p);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: elCtrl,
                    decoration: const InputDecoration(isDense: true, hintText: '0 .. 90'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                    onChanged: (v) {
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      if (parsed == null) return;
                      var clamped = parsed.clamp(0, 90).toDouble();
                      if (clamped != parsed) {
                        final txt = _fmt(clamped);
                        elCtrl.value = TextEditingValue(
                          text: txt,
                          selection: TextSelection.collapsed(offset: txt.length),
                        );
                      }
                      p.y = clamped;
                      onChanged(p);
                    },
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Entfernen',
                  onPressed: () => onRemove(p),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
