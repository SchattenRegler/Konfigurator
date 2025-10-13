part of 'sector_widget.dart';

extension _LouvreTab on _SectorWidgetState {
  Widget _buildLouvreTrackingTab() {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 960;
        final fields = SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DividerWithText(
                text: 'Lamellengeometrie',
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              TextFormField(
                key: ValueKey('louvre-spacing-${sector.guid}'),
                initialValue: _formatNumber(
                  sector.louvreSpacing,
                  fractionDigits: 1,
                ),
                decoration: const InputDecoration(
                  labelText: 'Lamellenabstand',
                  suffixText: 'mm',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_decimalInputFormatter],
                onChanged: (v) {
                  final val = _parseLocalizedDouble(v);
                  if (val != null && val > 0) {
                    _mutate(() {
                      sector.louvreSpacing = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: ValueKey('louvre-depth-${sector.guid}'),
                initialValue: _formatNumber(
                  sector.louvreDepth,
                  fractionDigits: 1,
                ),
                decoration: const InputDecoration(
                  labelText: 'Lamellenbreite',
                  suffixText: 'mm',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_decimalInputFormatter],
                onChanged: (v) {
                  final val = _parseLocalizedDouble(v);
                  if (val != null && val > 0) {
                    _mutate(() {
                      sector.louvreDepth = val;
                    });
                  }
                },
              ),
              const DividerWithText(
                text: 'Winkelbegrenzungen',
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              TextFormField(
                key: ValueKey('louvre-angle-zero-${sector.guid}'),
                initialValue: _formatNumber(sector.louvreAngleAtZero),
                decoration: InputDecoration(
                  labelText: 'Lamellenwinkel bei 0%',
                  suffixText: '°',
                  helperText: '90° = Offen',
                  errorText: _louvreAngleZeroError,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_decimalInputFormatter],
                onChanged: (v) {
                  final val = _parseLocalizedDouble(v);
                  if (val == null) {
                    _mutate(
                      () => _louvreAngleZeroError =
                          'Bitte einen gültigen Winkel eingeben',
                    );
                    return;
                  }
                  if (val < 0 || val > 90) {
                    _mutate(
                      () => _louvreAngleZeroError =
                          'Wert muss zwischen 0° und 90° liegen',
                    );
                    return;
                  }
                  if (val <= sector.louvreAngleAtHundred) {
                    _mutate(
                      () => _louvreAngleZeroError =
                          'Wert muss grösser als Winkel bei 100% sein',
                    );
                    return;
                  }
                  _mutate(() {
                    sector.louvreAngleAtZero = val;
                    _louvreAngleZeroError = null;
                    if (sector.louvreAngleAtHundred < val) {
                      _louvreAngleHundredError = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: ValueKey('louvre-angle-hundred-${sector.guid}'),
                initialValue: _formatNumber(sector.louvreAngleAtHundred),
                decoration: InputDecoration(
                  labelText: 'Lamellenwinkel bei 100%',
                  suffixText: '°',
                  helperText: '0° = Geschlossen',
                  errorText: _louvreAngleHundredError,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_decimalInputFormatter],
                onChanged: (v) {
                  final val = _parseLocalizedDouble(v);
                  if (val == null) {
                    _mutate(
                      () => _louvreAngleHundredError =
                          'Bitte einen gültigen Winkel eingeben',
                    );
                    return;
                  }
                  if (val < 0 || val > 90) {
                    _mutate(
                      () => _louvreAngleHundredError =
                          'Wert muss zwischen 0° und 90° liegen',
                    );
                    return;
                  }
                  if (val >= sector.louvreAngleAtZero) {
                    _mutate(
                      () => _louvreAngleHundredError =
                          'Wert muss kleiner als Winkel bei 0% sein',
                    );
                    return;
                  }
                  _mutate(() {
                    sector.louvreAngleAtHundred = val;
                    _louvreAngleHundredError = null;
                    if (sector.louvreAngleAtHundred <
                        sector.louvreAngleAtZero) {
                      _louvreAngleZeroError = null;
                    }
                  });
                },
              ),
              const DividerWithText(
                text: 'Verhalten',
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              TextFormField(
                key: ValueKey('louvre-min-change-${sector.guid}'),
                initialValue: _formatNumber(sector.louvreMinimumChange),
                decoration: InputDecoration(
                  labelText: 'Minimale auszuführende Änderung',
                  suffixText: '%',
                  helperText: 'Standard: 20%',
                  errorText: _louvreMinimumChangeError,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_decimalInputFormatter],
                onChanged: (v) {
                  final val = _parseLocalizedDouble(v);
                  if (val == null) {
                    _mutate(
                      () => _louvreMinimumChangeError =
                          'Bitte eine Zahl zwischen 0% und 100% eingeben',
                    );
                    return;
                  }
                  if (val < 0 || val > 100) {
                    _mutate(
                      () => _louvreMinimumChangeError =
                          'Wert muss zwischen 0% und 100% liegen',
                    );
                    return;
                  }
                  _mutate(() {
                    sector.louvreMinimumChange = val;
                    _louvreMinimumChangeError = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: ValueKey('louvre-buffer-${sector.guid}'),
                initialValue: _formatNumber(sector.louvreBuffer),
                decoration: InputDecoration(
                  labelText: 'Puffer',
                  suffixText: '%',
                  helperText: 'Standard: 5%',
                  errorText: _louvreBufferError,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_decimalInputFormatter],
                onChanged: (v) {
                  final val = _parseLocalizedDouble(v);
                  if (val == null) {
                    _mutate(
                      () => _louvreBufferError =
                          'Bitte eine Zahl zwischen 0% und 100% eingeben',
                    );
                    return;
                  }
                  if (val < 0 || val > 100) {
                    _mutate(
                      () => _louvreBufferError =
                          'Wert muss zwischen 0% und 100% liegen',
                    );
                    return;
                  }
                  _mutate(() {
                    sector.louvreBuffer = val;
                    _louvreBufferError = null;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );

        final currentAngle = _currentLouvreAngle();

        final preview = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DividerWithText(
              text: 'Vorschau',
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: constraints.maxHeight - 190),
              child: AspectRatio(
                aspectRatio: 1 / 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.25),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: _LouvreSlatPreview(
                      spacing: sector.louvreSpacing,
                      depth: sector.louvreDepth,
                      angleDegrees: currentAngle,
                      slatCount: 10,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: const [Text('0%'), Spacer(), Text('100%')]),
            Slider.adaptive(
              value: _louvrePreviewPercent.clamp(0, 100).toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              label: '${_louvrePreviewPercent.round()}%',
              onChanged: (value) {
                _mutate(() {
                  _louvrePreviewPercent = value;
                });
              },
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                '${_louvrePreviewPercent.round()}% → ${currentAngle.toStringAsFixed(1)}°',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        );
        final previewContainer = Align(
          alignment: Alignment.topCenter,
          child: preview,
        );

        final content = isNarrow
            ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fields,
                  const SizedBox(height: 32),
                  previewContainer,
                ],
              )
            )
            : Padding(
                padding: const EdgeInsets.all(16), 
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Align(alignment: Alignment.topLeft, child: fields),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: previewContainer,
                    ),
                  ],
                ),
            );

        return content;
      },
    );
  }

  double _currentLouvreAngle() {
    final progress = (_louvrePreviewPercent.clamp(0, 100)) / 100;
    return sector.louvreAngleAtZero +
        (sector.louvreAngleAtHundred - sector.louvreAngleAtZero) * progress;
  }

  double? _parseLocalizedDouble(String value) {
    final sanitized = value.trim().replaceAll(',', '.');
    if (sanitized.isEmpty) return null;
    return double.tryParse(sanitized);
  }

  String _formatNumber(double value, {int fractionDigits = 0}) {
    if (!value.isFinite) return '0';
    if (fractionDigits <= 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(fractionDigits);
  }
}

final TextInputFormatter _decimalInputFormatter =
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));

class _LouvreSlatPreview extends StatelessWidget {
  const _LouvreSlatPreview({
    required this.spacing,
    required this.depth,
    required this.angleDegrees,
    this.slatCount = 10,
  });

  final double spacing;
  final double depth;
  final double angleDegrees;
  final int slatCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slatWidth = constraints.maxWidth * 0.8;
        final safeDepth = depth.isFinite && depth > 0 ? depth : 40.0;
        final safeSpacing = spacing.isFinite && spacing >= 0
            ? spacing
            : safeDepth * 0.6;
        final scale = (slatWidth / safeDepth) * safeSpacing * 3 < constraints.maxHeight ? (slatWidth / safeDepth) : constraints.maxHeight/(safeSpacing*3.5);
        final slatHeight = (safeDepth / 264.8 * 18.2) * scale;
        final verticalOffset = max(0.0, safeDepth * scale / 4);
        final horizontalOffset = max(
          0.0,
          (constraints.maxWidth - safeDepth * scale) / 2,
        );
        final rotationRadians = ((90 - angleDegrees).clamp(-90, 90)) * pi / 180;

        return ClipRect(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              for (int i = 0; i < slatCount; i++)
                Positioned(
                  top:  i * (safeSpacing * scale) - verticalOffset,
                  left: horizontalOffset,
                  width: safeDepth * scale,
                  height: slatHeight,
                  child: Transform.rotate(
                    angle: rotationRadians,
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      'assets/blind/slat.svg',
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
