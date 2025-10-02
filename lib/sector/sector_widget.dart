import 'dart:io';
import 'dart:math';

import 'package:configurator/facade_orientation_dialog.dart';
import 'package:configurator/globals.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:solar_calculator/solar_calculator.dart';

part 'settings_tab.dart';
part 'louvre_tab.dart';
part 'horizon_tab.dart';

// Data model for parsed CSV per sector
class _CsvSectorData {
  _CsvSectorData({required this.horizon, required this.ceiling});
  final List<Point> horizon;
  final List<Point> ceiling;
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
  // Validation errors per field
  final Map<Point, String?> _horizonAzErrors = {};
  final Map<Point, String?> _horizonElErrors = {};
  final Map<Point, String?> _ceilingAzErrors = {};
  final Map<Point, String?> _ceilingElErrors = {};
  DateTime _selectedDate = DateTime.now();
  String? _orientationError;
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
  String? _onAutoAddressError;
  String? _offAutoAddressError;
  String? _louvreAngleZeroError;
  String? _louvreAngleHundredError;
  String? _louvreAngleAddressError;
  String? _louvreMinimumChangeError;
  String? _louvreBufferError;
  String? _sunBoolAddressError;
  double _louvrePreviewPercent = 0;

  // CSV import state
  bool _isImporting = false;

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
    sector.ensureDefaultPoints();
    _syncPointEditors();
  }

  @override
  void dispose() {
    _orientationController.dispose();
    _horizonAzController.dispose();
    _horizonElController.dispose();
    _ceilingAzController.dispose();
    _ceilingElController.dispose();
    for (final c in _horizonAzCtrls.values) {
      c.dispose();
    }
    for (final c in _horizonElCtrls.values) {
      c.dispose();
    }
    for (final c in _ceilingAzCtrls.values) {
      c.dispose();
    }
    for (final c in _ceilingElCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Ensure we have text controllers for each existing point
  void _syncPointEditors() {
    for (final p in sector.horizonPoints) {
      _horizonAzCtrls.putIfAbsent(
        p,
        () => TextEditingController(text: _fmt(p.x)),
      );
      _horizonElCtrls.putIfAbsent(
        p,
        () => TextEditingController(text: _fmt(p.y)),
      );
    }
    for (final p in sector.ceilingPoints) {
      _ceilingAzCtrls.putIfAbsent(
        p,
        () => TextEditingController(text: _fmt(p.x)),
      );
      _ceilingElCtrls.putIfAbsent(
        p,
        () => TextEditingController(text: _fmt(p.y)),
      );
    }
  }

  void _mutate(VoidCallback update) => setState(update);

  void _addHorizonPoint() {
    setState(() {
      final p = Point(x: 0, y: 0);
      sector.horizonPoints.add(p);
      sector.ensureDefaultPoints();
      _horizonAzCtrls[p] = TextEditingController(text: '0');
      _horizonElCtrls[p] = TextEditingController(text: '0');
      _horizonAzErrors[p] = null;
      _horizonElErrors[p] = null;
    });
  }

  void _addCeilingPoint() {
    setState(() {
      final p = Point(x: 0, y: 0);
      sector.ceilingPoints.add(p);
      sector.ensureDefaultPoints();
      _ceilingAzCtrls[p] = TextEditingController(text: '0');
      _ceilingElCtrls[p] = TextEditingController(text: '0');
      _ceilingAzErrors[p] = null;
      _ceilingElErrors[p] = null;
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
      } else {
        if (az > 180) {
          az -= 360;
        }
        final adjustedAz = az;
        spots.add(FlSpot(adjustedAz, el));
      }
    }
    return spots;
  }

  Future<void> _importCsv() async {
    if (_isImporting) return;
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );
      if (result == null) return; // canceled

      String content = '';
      if (result.files.single.bytes != null) {
        content = String.fromCharCodes(result.files.single.bytes!);
      } else if (!kIsWeb && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        content = await file.readAsString();
      } else {
        throw Exception('Datei konnte nicht gelesen werden.');
      }

      // Parse CSV into sector -> horizon/ceiling points
      final parsed = _parseCsv(content);
      final sectorIds = parsed.keys.where((k) => k != 0).toList()..sort();
      if (sectorIds.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Keine gültigen Sektoren in der CSV gefunden.'),
            ),
          );
        }
        return;
      }

      final selected = await _pickSectorFromCsv(sectorIds, parsed);
      if (selected == null) return; // canceled

      final data = parsed[selected]!;
      setState(() {
        final previousHorizon = sector.horizonPoints.map(clonePoint).toList();
        final previousCeiling = sector.ceilingPoints.map(clonePoint).toList();
        // Replace existing points with imported ones
        // Clear controllers to avoid leaks for removed points
        for (final c in _horizonAzCtrls.values) {
          c.dispose();
        }
        for (final c in _horizonElCtrls.values) {
          c.dispose();
        }
        _horizonAzCtrls.clear();
        _horizonElCtrls.clear();
        _horizonAzErrors.clear();
        _horizonElErrors.clear();

        for (final c in _ceilingAzCtrls.values) {
          c.dispose();
        }
        for (final c in _ceilingElCtrls.values) {
          c.dispose();
        }
        _ceilingAzCtrls.clear();
        _ceilingElCtrls.clear();
        _ceilingAzErrors.clear();
        _ceilingElErrors.clear();

        sector.horizonPoints = _buildPointsFromImport(
          imported: data.horizon,
          existing: previousHorizon,
          specs: horizonLockedPointSpecs,
          ensureFn: ensureDefaultHorizonPoints,
        );
        sector.ceilingPoints = _buildPointsFromImport(
          imported: data.ceiling,
          existing: previousCeiling,
          specs: ceilingLockedPointSpecs,
          ensureFn: ensureDefaultCeilingPoints,
        );
        _syncPointEditors();
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sektor $selected importiert.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV Import fehlgeschlagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Map<int, _CsvSectorData> _parseCsv(String content) {
    final horizon = <int, List<Point>>{};
    final ceiling = <int, List<Point>>{};

    final lines = content.split(RegExp(r'\r?\n'));
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      // Decide delimiter: prefer semicolon, then tab, then comma
      List<String> parts;
      if (line.contains(';')) {
        parts = _splitLine(line, ';');
      } else if (line.contains('\t')) {
        parts = line.split('\t');
      } else {
        parts = _splitLine(line, ',');
      }
      if (parts.isEmpty) continue;

      String c0 = parts.elementAt(0).trim().replaceAll('"', '');
      final sectorNo = int.tryParse(c0);
      if (sectorNo == null || sectorNo < 1 || sectorNo > 1024) {
        // ignore non-sector lines (e.g., date headers)
        continue;
      }
      String c1 = (parts.length > 1 ? parts[1] : '').trim().replaceAll('"', '');
      final type = c1.toLowerCase();
      final isHorizon = type == 'kurveunten';
      final isCeiling = type == 'kurveoben';
      if (!isHorizon && !isCeiling) {
        // Ignore other rows (e.g., Ausrichtung)
        continue;
      }

      for (int i = 2; i + 1 < parts.length; i += 2) {
        final azStr = parts[i].trim().replaceAll('"', '');
        final elStr = parts[i + 1].trim().replaceAll('"', '');
        final az = double.tryParse(azStr.replaceAll(',', '.'));
        final el = double.tryParse(elStr.replaceAll(',', '.'));
        if (az == null || el == null) {
          continue;
        }
        final p = Point(x: az, y: el);
        if (isHorizon) {
          horizon.putIfAbsent(sectorNo, () => <Point>[]).add(p);
        } else {
          ceiling.putIfAbsent(sectorNo, () => <Point>[]).add(p);
        }
      }
    }

    final ids = <int>{...horizon.keys, ...ceiling.keys};
    final out = <int, _CsvSectorData>{};
    for (final id in ids) {
      out[id] = _CsvSectorData(
        horizon: horizon[id] ?? <Point>[],
        ceiling: ceiling[id] ?? <Point>[],
      );
    }
    return out;
  }

  List<Point> _buildPointsFromImport({
    required List<Point> imported,
    required List<Point> existing,
    required List<LockedPointSpec> specs,
    required List<Point> Function(List<Point>) ensureFn,
  }) {
    final consumed = <double, bool>{
      for (final spec in specs) spec.azimuth: false,
    };
    final anchors = <Point>[];
    for (final spec in specs) {
      final existingAnchor = _findExistingAnchor(existing, spec);
      anchors.add(
        Point(
          x: spec.azimuth,
          y: existingAnchor?.y ?? spec.defaultElevation,
          isAzimuthLocked: true,
          isDefault: true,
        ),
      );
    }

    final result = <Point>[...anchors];
    for (final point in imported) {
      final spec = _matchSpec(point.x, specs);
      if (spec != null && consumed[spec.azimuth] == false) {
        final anchorIndex = specs.indexOf(spec);
        result[anchorIndex].y = point.y;
        consumed[spec.azimuth] = true;
      } else {
        result.add(Point(x: point.x, y: point.y));
      }
    }

    return ensureFn(result);
  }

  Point? _findExistingAnchor(List<Point> existing, LockedPointSpec spec) {
    Point? defaultMatch;
    Point? firstMatch;
    for (final point in existing) {
      if (!isAzimuthClose(point.x, spec.azimuth)) {
        continue;
      }
      firstMatch ??= point;
      if (point.isDefault) {
        defaultMatch = point;
        break;
      }
    }
    return defaultMatch ?? firstMatch;
  }

  LockedPointSpec? _matchSpec(double azimuth, List<LockedPointSpec> specs) {
    for (final spec in specs) {
      if (isAzimuthClose(azimuth, spec.azimuth)) {
        return spec;
      }
    }
    return null;
  }

  // Simple CSV splitter handling quoted delimiters
  List<String> _splitLine(String line, String sep) {
    final result = <String>[];
    var sb = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == sep && !inQuotes) {
        result.add(sb.toString());
        sb = StringBuffer();
      } else {
        sb.write(ch);
      }
    }
    result.add(sb.toString());
    return result;
  }

  Future<int?> _pickSectorFromCsv(
    List<int> sectorIds,
    Map<int, _CsvSectorData> data,
  ) async {
    int selected = sectorIds.first;
    return showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Sektor aus CSV wählen'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selected,
                  items: sectorIds
                      .map(
                        (id) => DropdownMenuItem<int>(
                          value: id,
                          child: Text('Sektor $id'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      selected = v;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(selected),
              child: const Text('Importieren'),
            ),
          ],
        );
      },
    );
  }

  String _fmt(double v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    _syncPointEditors();
    sector.ensureDefaultPoints();

    final tabs = <Tab>[
      const Tab(text: 'Einstellungen'),
      if (sector.louvreTracking) const Tab(text: 'Lamellennachführung'),
      if (sector.horizonLimit) const Tab(text: 'Horizontbegrenzung'),
    ];

    final tabViews = <Widget>[
      _buildSettingsTab(),
      if (sector.louvreTracking) _buildLouvreTrackingTab(),
      if (sector.horizonLimit) _buildHorizonLimitTab(),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(tabs: tabs),
          Expanded(child: TabBarView(children: tabViews)),
        ],
      ),
    );
  }
}
