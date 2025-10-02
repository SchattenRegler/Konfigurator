import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'globals.dart';

class GeneralPage extends StatelessWidget {
  const GeneralPage({
    super.key,
    required this.formKey,
    required this.latController,
    required this.lngController,
    required this.onPickLocation,
    required this.azElOption,
    required this.onAzElOptionChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController latController;
  final TextEditingController lngController;
  final VoidCallback onPickLocation;
  final String azElOption;
  final ValueChanged<String> onAzElOptionChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Version',
              ),
              initialValue: version,
              enabled: false,
            ),
            const SizedBox(height: 24),
            _LocationSection(
              latController: latController,
              lngController: lngController,
              onPickLocation: onPickLocation,
            ),
            const SizedBox(height: 24),
            const Text('Azimut/Elevation'),
            DropdownButtonFormField<String>(
              value: azElOption,
              items: const [
                DropdownMenuItem(
                  value: 'Internet',
                  child: Text('Zeit aus dem Internet beziehen'),
                ),
                DropdownMenuItem(
                  value: 'BusTime',
                  child: Text('Zeit vom Bus beziehen'),
                ),
                DropdownMenuItem(
                  value: 'BusAzEl',
                  child: Text('Azimut / Elevation vom Bus beziehen'),
                ),
              ],
              onChanged: (v) {
                if (v != null) {
                  onAzElOptionChanged(v);
                }
              },
            ),
            if (azElOption == 'BusTime') ...[
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Gruppenadresse Zeit',
                ),
                onSaved: (v) => timeAddress = v ?? '',
              ),
            ],
            if (azElOption == 'BusAzEl') ...[
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Gruppenadresse Azimut',
                ),
                onSaved: (v) => azimuthAddress = v ?? '',
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Gruppenadresse Elevation',
                ),
                onSaved: (v) => elevationAddress = v ?? '',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  const _LocationSection({
    required this.latController,
    required this.lngController,
    required this.onPickLocation,
  });

  final TextEditingController latController;
  final TextEditingController lngController;
  final VoidCallback onPickLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Standort'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: latController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Breitengrad (Lat)',
                ),
                onSaved: (v) => latitude = double.tryParse(v ?? '') ?? 0,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: lngController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(labelText: 'Längengrad'),
                onSaved: (v) => longitude = double.tryParse(v ?? '') ?? 0,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: onPickLocation,
              icon: const Icon(Icons.map),
              label: const Text('Auf Karte wählen'),
            ),
          ],
        ),
      ],
    );
  }
}
