part of 'sector_widget.dart';

extension _LouvreTab on _SectorWidgetState {
  Widget _buildLouvreTrackingTab() {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 960;
        final fields = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              TextFormField(
                key: ValueKey('louvre-spacing-${sector.guid}'),
                initialValue: _formatNumber(sector.louvreSpacing, fractionDigits: 1),
                decoration: const InputDecoration(
                  labelText: 'Lamellenabstand',
                  suffixText: 'mm',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                initialValue: _formatNumber(sector.louvreDepth, fractionDigits: 1),
                decoration: const InputDecoration(
                  labelText: 'Lamellentiefe',
                  suffixText: 'mm',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              const SizedBox(height: 24),
              TextFormField(
                key: ValueKey('louvre-angle-zero-${sector.guid}'),
                initialValue: _formatNumber(sector.louvreAngleAtZero),
                decoration: InputDecoration(
                  labelText: 'Lamellenwinkel bei 0%',
                  suffixText: '°',
                  helperText: '90° = Offen',
                  errorText: _louvreAngleZeroError,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_decimalInputFormatter],
                onChanged: (v) {
                  final val = _parseLocalizedDouble(v);
                  if (val == null) {
                    _mutate(() => _louvreAngleZeroError = 'Bitte einen gültigen Winkel eingeben');
                    return;
                  }
                  if (val < 0 || val > 90) {
                    _mutate(() => _louvreAngleZeroError = 'Wert muss zwischen 0° und 90° liegen');
                    return;
                  }
                  if (val <= sector.louvreAngleAtHundred) {
                    _mutate(() => _louvreAngleZeroError = 'Wert muss grösser als Winkel bei 100% sein');
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_decimalInputFormatter],
                onChanged: (v) {
                  final val = _parseLocalizedDouble(v);
                  if (val == null) {
                    _mutate(() => _louvreAngleHundredError = 'Bitte einen gültigen Winkel eingeben');
                    return;
                  }
                  if (val < 0 || val > 90) {
                    _mutate(() => _louvreAngleHundredError = 'Wert muss zwischen 0° und 90° liegen');
                    return;
                  }
                  if (val >= sector.louvreAngleAtZero) {
                    _mutate(() => _louvreAngleHundredError = 'Wert muss kleiner als Winkel bei 0% sein');
                    return;
                  }
                  _mutate(() {
                    sector.louvreAngleAtHundred = val;
                    _louvreAngleHundredError = null;
                    if (sector.louvreAngleAtHundred < sector.louvreAngleAtZero) {
                      _louvreAngleZeroError = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                key: ValueKey('louvre-min-change-${sector.guid}'),
                initialValue: _formatNumber(sector.louvreMinimumChange),
                decoration: InputDecoration(
                  labelText: 'Minimale auszuführende Änderung',
                  suffixText: '%',
                  helperText: 'Standard: 20%',
                  errorText: _louvreMinimumChangeError,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_decimalInputFormatter],
                onChanged: (v) {
                  final val = _parseLocalizedDouble(v);
                  if (val == null) {
                    _mutate(() => _louvreMinimumChangeError = 'Bitte eine Zahl zwischen 0% und 100% eingeben');
                    return;
                  }
                  if (val < 0 || val > 100) {
                    _mutate(() => _louvreMinimumChangeError = 'Wert muss zwischen 0% und 100% liegen');
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_decimalInputFormatter],
                onChanged: (v) {
                  final val = _parseLocalizedDouble(v);
                  if (val == null) {
                    _mutate(() => _louvreBufferError = 'Bitte eine Zahl zwischen 0% und 100% eingeben');
                    return;
                  }
                  if (val < 0 || val > 100) {
                    _mutate(() => _louvreBufferError = 'Wert muss zwischen 0% und 100% liegen');
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

        const formMaxWidth = 420.0;
        final availableForPreview =
            constraints.maxWidth - formMaxWidth - (isNarrow ? 0 : 32);
        final previewWidth = isNarrow
            ? constraints.maxWidth
            : max(280.0, min(420.0, availableForPreview));
        final currentAngle = _currentLouvreAngle();

        final preview = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 3 / 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.25)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: CustomPaint(
                      painter: _LamellaPainter(
                        spacing: sector.louvreSpacing,
                        depth: sector.louvreDepth,
                        angleDegrees: currentAngle,
                        slatCount: 7,
                        color: colorScheme.primary.withOpacity(0.55),
                        accentColor: colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Text('0%'),
                  Spacer(),
                  Text('100%'),
                ],
              ),
              Slider(
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
        final previewContainer = SizedBox(
          width: isNarrow ? double.infinity : previewWidth,
          child: preview,
        );

        final content = isNarrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fields,
                  const SizedBox(height: 32),
                  previewContainer,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fields,
                  const SizedBox(width: 32),
                  previewContainer,
                ],
              );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: content,
        );
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

class _LamellaPainter extends CustomPainter {
  _LamellaPainter({
    required this.spacing,
    required this.depth,
    required this.angleDegrees,
    this.slatCount = 6,
    required this.color,
    required this.accentColor,
  });

  final double spacing;
  final double depth;
  final double angleDegrees;
  final int slatCount;
  final Color color;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final safeDepth = depth.isFinite && depth > 0 ? depth : 40.0;
    final safeSpacing = spacing.isFinite && spacing >= 0 ? spacing : safeDepth * 0.6;
    final totalHeight =
        (slatCount - 1) * safeSpacing + slatCount * safeDepth;
    final usableHeight = size.height * 0.85;
    final scale = totalHeight > 0 ? usableHeight / totalHeight : 1;
    final slatHeight = safeDepth * scale;
    final gap = safeSpacing * scale;
    final slatWidth = size.width * 0.8;
    final double rotationRadians = ((90 - angleDegrees).clamp(-90, 90)) * pi / 180;

    final Paint slatPaint = Paint()..color = color;
    final Paint highlightPaint = Paint()..color = accentColor;

    final totalDrawHeight = slatHeight * slatCount + gap * (slatCount - 1);
    final startY = (size.height - totalDrawHeight) / 2;
    final centerX = size.width / 2;
    final borderRadius = Radius.circular(slatHeight * 0.2);

    for (int i = 0; i < slatCount; i++) {
      final baseCenterY = startY + i * (slatHeight + gap) + slatHeight / 2;
      canvas.save();
      canvas.translate(centerX, baseCenterY);
      canvas.rotate(rotationRadians);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: slatWidth,
        height: slatHeight,
      );
      final roundedRect = RRect.fromRectAndRadius(rect, borderRadius);
      canvas.drawRRect(roundedRect, slatPaint);

      final highlightRect = Rect.fromLTWH(
        rect.left,
        rect.top,
        rect.width,
        slatHeight * 0.35,
      );
      final highlight = RRect.fromRectAndCorners(
        highlightRect,
        topLeft: borderRadius,
        topRight: borderRadius,
      );
      canvas.drawRRect(highlight, highlightPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LamellaPainter oldDelegate) {
    return spacing != oldDelegate.spacing ||
        depth != oldDelegate.depth ||
        angleDegrees != oldDelegate.angleDegrees ||
        color != oldDelegate.color ||
        accentColor != oldDelegate.accentColor ||
        slatCount != oldDelegate.slatCount;
  }
}
