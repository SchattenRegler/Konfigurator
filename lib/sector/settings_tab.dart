part of 'sector_widget.dart';

extension _SettingsTab on _SectorWidgetState {
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
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
                      _mutate(() {
                        _orientationError =
                            'Bitte Wert zwischen -180 und 180 eingeben';
                      });
                    } else {
                      _mutate(() {
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
                    _mutate(() {
                      sector.facadeStart = result['start'];
                      sector.facadeEnd = result['end'];
                      // Calculate geodetic bearing between two coordinates
                      final lat1 = result['start']!.latitude * pi / 180;
                      final lat2 = result['end']!.latitude * pi / 180;
                      final lon1 = result['start']!.longitude * pi / 180;
                      final lon2 = result['end']!.longitude * pi / 180;
                      final dLon = lon2 - lon1;
                      final y = sin(dLon) * cos(lat2);
                      final x =
                          cos(lat1) * sin(lat2) -
                          sin(lat1) * cos(lat2) * cos(dLon);
                      var bearing = atan2(y, x) * 180 / pi;
                      bearing =
                          (bearing + 360) % 360 -
                          90; // Adjust to make 0 degrees point north
                      sector.orientation = bearing;
                      _orientationController.text = sector.orientation
                          .toStringAsFixed(1);
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
            onChanged: sector.useIrradiance
                ? (v) => _mutate(() {
                    sector.useBrightness = v;
                  })
                : null,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Globalstrahlung verwenden'),
            value: sector.useIrradiance,
            onChanged: sector.useBrightness
                ? (v) => _mutate(() {
                    sector.useIrradiance = v;
                  })
                : null,
          ),

          //Helligkeit
          if (sector.useBrightness) const SizedBox(height: 16),
          if (sector.useBrightness)
            TextFormField(
              initialValue: sector.brightnessAddress,
              decoration: InputDecoration(
                labelText: 'Gruppenadresse Helligkeit',
                errorText: _brightnessAddressError,
              ),
              onChanged: (v) {
                _mutate(() {
                  sector.brightnessAddress = v;
                  final parts = v.split('/');
                  final a = int.tryParse(parts.isNotEmpty ? parts[0] : '');
                  final b = int.tryParse(parts.length > 1 ? parts[1] : '');
                  final c = int.tryParse(parts.length > 2 ? parts[2] : '');
                  if (parts.length != 3 ||
                      a == null ||
                      a < 0 ||
                      a > 31 ||
                      b == null ||
                      b < 0 ||
                      b > 7 ||
                      c == null ||
                      c < 0 ||
                      c > 255 ||
                      (a == 0 && b == 0 && c == 0)) {
                    _brightnessAddressError =
                        'Ungültiges Format, bitte dreistufige Gruppenadresse eingeben';
                  } else {
                    _brightnessAddressError = null;
                  }
                });
              },
            ),
          if (sector.useBrightness) const SizedBox(height: 16),
          if (sector.useBrightness)
            TextFormField(
              initialValue: sector.brightnessUpperThreshold?.toString() ?? '',
              decoration: InputDecoration(
                labelText: 'Helligkeitsschwellwert Dunkel --> Hell',
                suffixText: 'Lux',
                errorText: _brightnessUpperThresholdError,
              ),
              onChanged: (v) {
                final val = int.tryParse(v);
                if (val == null || val < 0) {
                  _mutate(() {
                    _brightnessUpperThresholdError =
                        'Bitte gültigen Wert eingeben';
                  });
                } else if (val <= (sector.brightnessLowerThreshold ?? -1)) {
                  _mutate(() {
                    _brightnessUpperThresholdError =
                        'Muss grösser als der Schwellwert Hell --> Dunkel sein';
                  });
                } else {
                  _mutate(() {
                    _brightnessUpperThresholdError = null;
                    sector.brightnessUpperThreshold = val;
                  });
                }
              },
            ),
          if (sector.useBrightness) const SizedBox(height: 16),
          if (sector.useBrightness)
            TextFormField(
              initialValue: sector.brightnessUpperDelay?.toString() ?? '',
              decoration: InputDecoration(
                labelText: 'Verzögerungszeit Dunkel --> Hell',
                suffixText: 's',
                errorText: _brightnessUpperDelayError,
              ),
              onChanged: (v) {
                final val = int.tryParse(v);
                if (val == null || val < 0 || val > 86400) {
                  _mutate(() {
                    _brightnessUpperDelayError = 'Bitte gültigen Wert eingeben';
                  });
                } else {
                  _mutate(() {
                    _brightnessUpperDelayError = null;
                    sector.brightnessUpperDelay = val;
                  });
                }
              },
            ),
          if (sector.useBrightness) const SizedBox(height: 16),
          if (sector.useBrightness)
            TextFormField(
              initialValue: sector.brightnessLowerThreshold?.toString() ?? '',
              decoration: InputDecoration(
                labelText: 'Helligkeitsschwellwert Hell --> Dunkel',
                suffixText: 'Lux',
                errorText: _brightnessLowerThresholdError,
              ),
              onChanged: (v) {
                final val = int.tryParse(v);
                if (val == null || val < 0) {
                  _mutate(() {
                    _brightnessLowerThresholdError =
                        'Bitte gültigen Wert eingeben';
                  });
                } else if (val >= (sector.brightnessUpperThreshold ?? -1)) {
                  _mutate(() {
                    _brightnessLowerThresholdError =
                        'Muss kleiner als der Schwellwert Dunkel --> Hell sein';
                  });
                } else {
                  _mutate(() {
                    _brightnessLowerThresholdError = null;
                    sector.brightnessLowerThreshold = val;
                  });
                }
              },
            ),
          if (sector.useBrightness) const SizedBox(height: 16),
          if (sector.useBrightness)
            TextFormField(
              initialValue: sector.brightnessLowerDelay?.toString() ?? '',
              decoration: InputDecoration(
                labelText: 'Verzögerungszeit Hell --> Dunkel',
                suffixText: 's',
                errorText: _brightnessLowerDelayError,
              ),
              onChanged: (v) {
                final val = int.tryParse(v);
                if (val == null || val < 0 || val > 86400) {
                  _mutate(() {
                    _brightnessLowerDelayError = 'Bitte gültigen Wert eingeben';
                  });
                } else {
                  _mutate(() {
                    _brightnessLowerDelayError = null;
                    sector.brightnessLowerDelay = val;
                  });
                }
              },
            ),

          //Globalstrahlung
          if (sector.useIrradiance) const SizedBox(height: 16),
          if (sector.useIrradiance)
            TextFormField(
              initialValue: sector.irradianceAddress,
              decoration: InputDecoration(
                labelText: 'Gruppenadresse Globalstrahlung',
                errorText: _irradianceAddressError,
              ),
              onChanged: (v) {
                _mutate(() {
                  sector.irradianceAddress = v;
                  final parts = v.split('/');
                  final a = int.tryParse(parts.isNotEmpty ? parts[0] : '');
                  final b = int.tryParse(parts.length > 1 ? parts[1] : '');
                  final c = int.tryParse(parts.length > 2 ? parts[2] : '');
                  if (parts.length != 3 ||
                      a == null ||
                      a < 0 ||
                      a > 31 ||
                      b == null ||
                      b < 0 ||
                      b > 7 ||
                      c == null ||
                      c < 0 ||
                      c > 255 ||
                      (a == 0 && b == 0 && c == 0)) {
                    _irradianceAddressError =
                        'Ungültiges Format, bitte dreistufige Gruppenadresse eingeben';
                  } else {
                    _irradianceAddressError = null;
                  }
                });
              },
            ),
          if (sector.useIrradiance) const SizedBox(height: 16),
          if (sector.useIrradiance)
            TextFormField(
              initialValue: sector.irradianceUpperThreshold?.toString() ?? '',
              decoration: InputDecoration(
                labelText: 'Globalstrahlungsschwellwert Tief --> Hoch',
                suffixText: 'Lux',
                errorText: _irradianceUpperThresholdError,
              ),
              onChanged: (v) {
                final val = int.tryParse(v);
                if (val == null || val < 0) {
                  _mutate(() {
                    _irradianceUpperThresholdError =
                        'Bitte gültigen Wert eingeben';
                  });
                } else if (val <= (sector.irradianceLowerThreshold ?? -1)) {
                  _mutate(() {
                    _irradianceUpperThresholdError =
                        'Muss grösser als der Schwellwert Hoch --> Tief sein';
                  });
                } else {
                  _mutate(() {
                    _irradianceUpperThresholdError = null;
                    sector.irradianceUpperThreshold = val;
                  });
                }
              },
            ),
          if (sector.useIrradiance) const SizedBox(height: 16),
          if (sector.useIrradiance)
            TextFormField(
              initialValue: sector.irradianceUpperDelay?.toString() ?? '',
              decoration: InputDecoration(
                labelText: 'Verzögerungszeit Tief --> Hoch',
                suffixText: 's',
                errorText: _irradianceUpperDelayError,
              ),
              onChanged: (v) {
                final val = int.tryParse(v);
                if (val == null || val < 0 || val > 86400) {
                  _mutate(() {
                    _irradianceUpperDelayError = 'Bitte gültigen Wert eingeben';
                  });
                } else {
                  _mutate(() {
                    _irradianceUpperDelayError = null;
                    sector.irradianceUpperDelay = val;
                  });
                }
              },
            ),
          if (sector.useIrradiance) const SizedBox(height: 16),
          if (sector.useIrradiance)
            TextFormField(
              initialValue: sector.irradianceLowerThreshold?.toString() ?? '',
              decoration: InputDecoration(
                labelText: 'Globalstrahlungsschwellwert Hoch --> Tief',
                suffixText: 'Lux',
                errorText: _irradianceLowerThresholdError,
              ),
              onChanged: (v) {
                final val = int.tryParse(v);
                if (val == null || val < 0) {
                  _mutate(() {
                    _irradianceLowerThresholdError =
                        'Bitte gültigen Wert eingeben';
                  });
                } else if (val >= (sector.irradianceUpperThreshold ?? -1)) {
                  _mutate(() {
                    _irradianceLowerThresholdError =
                        'Muss kleiner als der Schwellwert Tief --> Hoch sein';
                  });
                } else {
                  _mutate(() {
                    _irradianceLowerThresholdError = null;
                    sector.irradianceLowerThreshold = val;
                  });
                }
              },
            ),
          if (sector.useIrradiance) const SizedBox(height: 16),
          if (sector.useIrradiance)
            TextFormField(
              initialValue: sector.irradianceLowerDelay?.toString() ?? '',
              decoration: InputDecoration(
                labelText: 'Verzögerungszeit Hoch --> Tief',
                suffixText: 's',
                errorText: _irradianceLowerDelayError,
              ),
              onChanged: (v) {
                final val = int.tryParse(v);
                if (val == null || val < 0 || val > 86400) {
                  _mutate(() {
                    _irradianceLowerDelayError = 'Bitte gültigen Wert eingeben';
                  });
                } else {
                  _mutate(() {
                    _irradianceLowerDelayError = null;
                    sector.irradianceLowerDelay = val;
                  });
                }
              },
            ),
          if (sector.useBrightness && sector.useIrradiance)
            const SizedBox(height: 16),
          if (sector.useBrightness && sector.useIrradiance)
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
                _mutate(() {
                  sector.brightnessIrradianceLink = v;
                });
              },
            ),
          if (sector.useBrightness && sector.useIrradiance)
            const SizedBox(height: 16),
          if (sector.useBrightness && sector.useIrradiance)
            TextFormField(
              initialValue: sector.brightnessOnAutoAddress,
              decoration: InputDecoration(
                labelText: 'Gruppenadresse Ein/Auto',
                errorText: _brightnessOnAutoAddressError,
              ),
              onChanged: (v) {
                _mutate(() {
                  sector.brightnessOnAutoAddress = v;
                  final parts = v.split('/');
                  final a = int.tryParse(parts.isNotEmpty ? parts[0] : '');
                  final b = int.tryParse(parts.length > 1 ? parts[1] : '');
                  final c = int.tryParse(parts.length > 2 ? parts[2] : '');
                  if (parts.length != 3 ||
                      a == null ||
                      a < 0 ||
                      a > 31 ||
                      b == null ||
                      b < 0 ||
                      b > 7 ||
                      c == null ||
                      c < 0 ||
                      c > 255 ||
                      (a == 0 && b == 0 && c == 0)) {
                    _brightnessOnAutoAddressError =
                        'Ungültiges Format, bitte dreistufige Gruppenadresse eingeben';
                  } else {
                    _brightnessOnAutoAddressError = null;
                  }
                });
              },
            ),
          if (sector.useBrightness && sector.useIrradiance)
            const SizedBox(height: 16),
          if (sector.useBrightness && sector.useIrradiance)
            DropdownButtonFormField<String>(
              value: sector.brightnessOnAutoBehavior,
              decoration: const InputDecoration(
                labelText: 'Verhalten bei logischer 1',
              ),
              items: const [
                DropdownMenuItem(value: 'Ein', child: Text('Ein')),
                DropdownMenuItem(value: 'Auto', child: Text('Auto')),
              ],
              onChanged: (value) {
                if (value == null) return;
                _mutate(() {
                  sector.brightnessOnAutoBehavior = value;
                });
              },
            ),
          if (sector.useBrightness && sector.useIrradiance)
            const SizedBox(height: 16),
          if (sector.useBrightness && sector.useIrradiance)
            TextFormField(
              initialValue: sector.brightnessOffAutoAddress,
              decoration: InputDecoration(
                labelText: 'Gruppenadresse Aus/Auto',
                errorText: _brightnessOffAutoAddressError,
              ),
              onChanged: (v) {
                _mutate(() {
                  sector.brightnessOffAutoAddress = v;
                  final parts = v.split('/');
                  final a = int.tryParse(parts.isNotEmpty ? parts[0] : '');
                  final b = int.tryParse(parts.length > 1 ? parts[1] : '');
                  final c = int.tryParse(parts.length > 2 ? parts[2] : '');
                  if (parts.length != 3 ||
                      a == null ||
                      a < 0 ||
                      a > 31 ||
                      b == null ||
                      b < 0 ||
                      b > 7 ||
                      c == null ||
                      c < 0 ||
                      c > 255 ||
                      (a == 0 && b == 0 && c == 0)) {
                    _brightnessOffAutoAddressError =
                        'Ungültiges Format, bitte dreistufige Gruppenadresse eingeben';
                  } else {
                    _brightnessOffAutoAddressError = null;
                  }
                });
              },
            ),
          if (sector.useBrightness && sector.useIrradiance)
            const SizedBox(height: 16),
          if (sector.useBrightness && sector.useIrradiance)
            DropdownButtonFormField<String>(
              value: sector.brightnessOffAutoBehavior,
              decoration: const InputDecoration(
                labelText: 'Verhalten bei logischer 1',
              ),
              items: const [
                DropdownMenuItem(value: 'Aus', child: Text('Aus')),
                DropdownMenuItem(value: 'Auto', child: Text('Auto')),
              ],
              onChanged: (value) {
                if (value == null) return;
                _mutate(() {
                  sector.brightnessOffAutoBehavior = value;
                });
              },
            ),

          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Lamellennachführung'),
            value: sector.louvreTracking,
            onChanged: (v) => _mutate(() {
              sector.louvreTracking = v;
            }),
          ),
          SwitchListTile(
            title: const Text('Horizontbegrenzung'),
            value: sector.horizonLimit,
            onChanged: (v) => _mutate(() {
              sector.horizonLimit = v;
            }),
          ),
          if (sector.useBrightness && sector.louvreTracking)
            const SizedBox(height: 16),
          if (sector.useBrightness && sector.louvreTracking)
            TextFormField(
              initialValue: sector.louvreAngleAddress,
              decoration: InputDecoration(
                labelText: 'Gruppenadresse Lamellenwinkel',
                errorText: _louvreAngleAddressError,
              ),
              onChanged: (v) {
                _mutate(() {
                  sector.louvreAngleAddress = v;
                  final parts = v.split('/');
                  final a = int.tryParse(parts.isNotEmpty ? parts[0] : '');
                  final b = int.tryParse(parts.length > 1 ? parts[1] : '');
                  final c = int.tryParse(parts.length > 2 ? parts[2] : '');
                  if (parts.length != 3 ||
                      a == null ||
                      a < 0 ||
                      a > 31 ||
                      b == null ||
                      b < 0 ||
                      b > 7 ||
                      c == null ||
                      c < 0 ||
                      c > 255 ||
                      (a == 0 && b == 0 && c == 0)) {
                    _louvreAngleAddressError =
                        'Ungültiges Format, bitte dreistufige Gruppenadresse eingeben';
                  } else {
                    _louvreAngleAddressError = null;
                  }
                });
              },
            ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: sector.sunBoolAddress,
            decoration: InputDecoration(
              labelText: 'Gruppenadresse Sonne',
              errorText: _sunBoolAddressError,
            ),
            onChanged: (v) {
              _mutate(() {
                sector.sunBoolAddress = v;
                final parts = v.split('/');
                final a = int.tryParse(parts.isNotEmpty ? parts[0] : '');
                final b = int.tryParse(parts.length > 1 ? parts[1] : '');
                final c = int.tryParse(parts.length > 2 ? parts[2] : '');
                if (parts.length != 3 ||
                    a == null ||
                    a < 0 ||
                    a > 31 ||
                    b == null ||
                    b < 0 ||
                    b > 7 ||
                    c == null ||
                    c < 0 ||
                    c > 255 ||
                    (a == 0 && b == 0 && c == 0)) {
                  _sunBoolAddressError =
                      'Ungültiges Format, bitte dreistufige Gruppenadresse eingeben';
                } else {
                  _sunBoolAddressError = null;
                }
              });
            },
          ),
          const SizedBox(height: 24),
          // Remove button (match time program delete style)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.onRemove,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text(
                'Sektor löschen',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
