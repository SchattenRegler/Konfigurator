part of 'sector_widget.dart';

extension _HorizonLimitTab on _SectorWidgetState {
  Widget _buildHorizonLimitTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                _mutate(() {
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
                  _mutate(() {
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
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Horizontpunkte',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
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
                              azErrors: _horizonAzErrors,
                              elErrors: _horizonElErrors,
                              color: Colors.red.shade100,
                              onRemove: (p) {
                                _mutate(() {
                                  _horizonAzCtrls.remove(p)?.dispose();
                                  _horizonElCtrls.remove(p)?.dispose();
                                  _horizonAzErrors.remove(p);
                                  _horizonElErrors.remove(p);
                                  sector.horizonPoints.remove(p);
                                });
                              },
                              onChanged: (p) {
                                _mutate(() {
                                  sector.ensureDefaultPoints();
                                });
                              },
                              onAzErrorChange: (p, err) =>
                                  _mutate(() => _horizonAzErrors[p] = err),
                              onElErrorChange: (p, err) =>
                                  _mutate(() => _horizonElErrors[p] = err),
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Deckenpunkte',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
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
                              azErrors: _ceilingAzErrors,
                              elErrors: _ceilingElErrors,
                              color: Colors.green.shade100,
                              onRemove: (p) {
                                _mutate(() {
                                  _ceilingAzCtrls.remove(p)?.dispose();
                                  _ceilingElCtrls.remove(p)?.dispose();
                                  _ceilingAzErrors.remove(p);
                                  _ceilingElErrors.remove(p);
                                  sector.ceilingPoints.remove(p);
                                });
                              },
                              onChanged: (p) {
                                _mutate(() {
                                  sector.ensureDefaultPoints();
                                });
                              },
                              onAzErrorChange: (p, err) =>
                                  _mutate(() => _ceilingAzErrors[p] = err),
                              onElErrorChange: (p, err) =>
                                  _mutate(() => _ceilingElErrors[p] = err),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: _isImporting ? null : _importCsv,
                              icon: const Icon(Icons.upload_file),
                              label: Text(
                                _isImporting
                                    ? 'Importiert…'
                                    : 'CSV importieren',
                              ),
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
                            getTooltipColor: (LineBarSpot touchedSpot) =>
                                Colors.yellow.shade200,
                            getTooltipItems: (List<LineBarSpot> touchedSpots) {
                              return touchedSpots.map((
                                LineBarSpot touchedSpot,
                              ) {
                                final az = touchedSpot.x;
                                final el = touchedSpot.y;
                                if (touchedSpot.barIndex < 3) {
                                  final hour = touchedSpot.spotIndex ~/ 60;
                                  final min = touchedSpot.spotIndex % 60;
                                  return LineTooltipItem(
                                    "Zeit: ${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}\nAzimut: ${az.toStringAsFixed(1)}°\nElevation: ${el.toStringAsFixed(1)}°",
                                    const TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                    ),
                                  );
                                }
                              }).toList();
                            },
                          ),
                          getTouchedSpotIndicator: (_, indicators) {
                            return indicators
                                .map(
                                  (int index) => const TouchedSpotIndicatorData(
                                    FlLine(color: Colors.transparent),
                                    FlDotData(show: false),
                                  ),
                                )
                                .toList();
                          },
                          distanceCalculator:
                              (
                                Offset touchPoint,
                                Offset spotPixelCoordinates,
                              ) => (touchPoint - spotPixelCoordinates).distance,
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
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                            ),
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
                            spots: _computeSolarPath(
                              DateTime(_selectedDate.year, 12, 21),
                            ),
                            isCurved: true,
                            dotData: FlDotData(show: false),
                            color: Colors.orange,
                          ),
                          LineChartBarData(
                            spots: _computeSolarPath(
                              DateTime(_selectedDate.year, 6, 21),
                            ),
                            isCurved: true,
                            dotData: FlDotData(show: false),
                            color: Colors.yellow,
                          ),
                          LineChartBarData(
                            spots: sector.horizonPoints
                                .map((p) => FlSpot(p.x, p.y))
                                .toList(),
                            isCurved: false,
                            dotData: FlDotData(show: true),
                            barWidth: 2,
                            color: Colors.red,
                          ),
                          LineChartBarData(
                            spots: sector.ceilingPoints
                                .map((p) => FlSpot(p.x, p.y))
                                .toList(),
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
                                final calc = SolarCalculator(
                                  instant,
                                  latitude,
                                  longitude,
                                );
                                final sunPos = calc.sunHorizontalPosition;
                                // Normalize azimuth difference into [-180, 180] range
                                final offset = (sector.orientation + 360) % 360;
                                var az = sunPos.azimuth - offset;
                                az = (az + 360) % 360;
                                if (az > 180) az -= 360;
                                // Only show if sun is in front of facade
                                if (az.abs() > 90) return null;
                                return FlSpot(az, sunPos.elevation);
                              }(),
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
    );
  }

  Widget _buildPointsTable({
    required List<Point> points,
    required Map<Point, TextEditingController> azCtrls,
    required Map<Point, TextEditingController> elCtrls,
    required Map<Point, String?> azErrors,
    required Map<Point, String?> elErrors,
    required Color color,
    required void Function(Point) onRemove,
    required void Function(Point) onChanged,
    required void Function(Point, String?) onAzErrorChange,
    required void Function(Point, String?) onElErrorChange,
  }) {
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
              SizedBox(
                width: 120,
                child: Text(
                  'Azimut (°)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: Text(
                  'Elevation (°)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Spacer(),
              SizedBox(width: 32),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ...points.map((p) {
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
                    enabled: !p.isAzimuthLocked,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '-90 .. 90',
                      errorText: azErrors[p],
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      if (parsed == null) {
                        onAzErrorChange(p, 'Zahl eingeben');
                        return;
                      }
                      if (parsed < -90 || parsed > 90) {
                        onAzErrorChange(p, '-90..90°');
                        return;
                      }
                      onAzErrorChange(p, null);
                      p.x = parsed;
                      onChanged(p);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: elCtrl,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '0 .. 90',
                      errorText: elErrors[p],
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      if (parsed == null) {
                        onElErrorChange(p, 'Zahl eingeben');
                        return;
                      }
                      if (parsed < 0 || parsed > 90) {
                        onElErrorChange(p, '0..90°');
                        return;
                      }
                      onElErrorChange(p, null);
                      p.y = parsed;
                      onChanged(p);
                    },
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    p.isDefault ? Icons.lock_outline : Icons.delete_outline,
                  ),
                  tooltip: p.isDefault ? 'Fester Punkt' : 'Entfernen',
                  onPressed: p.isDefault ? null : () => onRemove(p),
                ),
              ],
            ),
          );
        }),
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
}
