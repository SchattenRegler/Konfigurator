import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'divider_with_text.dart';
import 'globals.dart';
import 'timezones.dart';

class GeneralPage extends StatelessWidget {
  const GeneralPage({
    super.key,
    required this.formKey,
    required this.latController,
    required this.lngController,
    required this.onPickLocation,
    required this.azElOption,
    required this.onAzElOptionChanged,
    required this.azElTimezoneController,
    required this.onAzElTimezoneChanged,
    required this.connectionType,
    required this.onConnectionTypeChanged,
    required this.individualAddressController,
    required this.gatewayIpController,
    required this.gatewayPortController,
    required this.multicastGroupController,
    required this.multicastPortController,
    required this.autoReconnect,
    required this.onAutoReconnectChanged,
    required this.autoReconnectWaitController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController latController;
  final TextEditingController lngController;
  final VoidCallback onPickLocation;
  final String azElOption;
  final ValueChanged<String> onAzElOptionChanged;
  final TextEditingController azElTimezoneController;
  final ValueChanged<String> onAzElTimezoneChanged;
  final String connectionType;
  final ValueChanged<String> onConnectionTypeChanged;
  final TextEditingController individualAddressController;
  final TextEditingController gatewayIpController;
  final TextEditingController gatewayPortController;
  final TextEditingController multicastGroupController;
  final TextEditingController multicastPortController;
  final bool autoReconnect;
  final ValueChanged<bool> onAutoReconnectChanged;
  final TextEditingController autoReconnectWaitController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Form(
        key: formKey,
        child: Column(
          children: [
            Material(
              color: theme.colorScheme.surface,
              child: TabBar(
                labelColor: theme.colorScheme.primary,
                indicatorColor: theme.colorScheme.primary,
                tabs: const [
                  Tab(text: 'Allgemein'),
                  Tab(text: 'KNX-Verbindung'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  SingleChildScrollView(
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
                        const DividerWithText(text: 'Standort'),
                        _LocationSection(
                          latController: latController,
                          lngController: lngController,
                          onPickLocation: onPickLocation,
                        ),
                        const DividerWithText(text: 'Azimut / Elevation'),
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
                          const SizedBox(height: 8),
                          TypeAheadFormField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: azElTimezoneController,
                              decoration: const InputDecoration(
                                labelText: 'Zeitzone',
                              ),
                            ),
                            suggestionsCallback: (pattern) {
                              final lowerPattern = pattern.toLowerCase();
                              if (lowerPattern.isEmpty) {
                                return kIanaTimeZones.take(20);
                              }
                              return kIanaTimeZones
                                  .where(
                                    (zone) => zone
                                        .toLowerCase()
                                        .contains(lowerPattern),
                                  )
                                  .take(20);
                            },
                            itemBuilder: (context, suggestion) => ListTile(
                              title: Text(suggestion),
                            ),
                            noItemsFoundBuilder: (context) => const SizedBox(
                              height: 48,
                              child: Center(
                                child: Text('Keine Zeitzone gefunden'),
                              ),
                            ),
                            onSuggestionSelected: (suggestion) {
                              azElTimezoneController.text = suggestion;
                              onAzElTimezoneChanged(suggestion);
                            },
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (!kIanaTimeZones.contains(trimmed)) {
                                return 'Bitte eine gültige Zeitzone auswählen';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (kIanaTimeZones.contains(trimmed)) {
                                onAzElTimezoneChanged(trimmed);
                              }
                            },
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
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _KnxConnectionSection(
                      connectionType: connectionType,
                      onConnectionTypeChanged: onConnectionTypeChanged,
                      individualAddressController: individualAddressController,
                      gatewayIpController: gatewayIpController,
                      gatewayPortController: gatewayPortController,
                      multicastGroupController: multicastGroupController,
                      multicastPortController: multicastPortController,
                      autoReconnect: autoReconnect,
                      onAutoReconnectChanged: onAutoReconnectChanged,
                      autoReconnectWaitController: autoReconnectWaitController,
                    ),
                  ),
                ],
              ),
            ),
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

class _KnxConnectionSection extends StatelessWidget {
  const _KnxConnectionSection({
    required this.connectionType,
    required this.onConnectionTypeChanged,
    required this.individualAddressController,
    required this.gatewayIpController,
    required this.gatewayPortController,
    required this.multicastGroupController,
    required this.multicastPortController,
    required this.autoReconnect,
    required this.onAutoReconnectChanged,
    required this.autoReconnectWaitController,
  });

  final String connectionType;
  final ValueChanged<String> onConnectionTypeChanged;
  final TextEditingController individualAddressController;
  final TextEditingController gatewayIpController;
  final TextEditingController gatewayPortController;
  final TextEditingController multicastGroupController;
  final TextEditingController multicastPortController;
  final bool autoReconnect;
  final ValueChanged<bool> onAutoReconnectChanged;
  final TextEditingController autoReconnectWaitController;

  @override
  Widget build(BuildContext context) {
    final requiresGateway =
        connectionType == 'TUNNELING' || connectionType == 'TUNNELING_TCP';
    final isRouting = connectionType == 'ROUTING';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DividerWithText(text: 'Verbindung'),
        DropdownButtonFormField<String>(
          value: connectionType,
          decoration: const InputDecoration(labelText: 'Verbindungstyp'),
          items: const [
            DropdownMenuItem(
              value: 'ROUTING',
              child: Text('ROUTING — KNX/IP Multicast Routing'),
            ),
            DropdownMenuItem(
              value: 'TUNNELING',
              child: Text('TUNNELING — KNX/IP Tunneling (UDP)'),
            ),
            DropdownMenuItem(
              value: 'TUNNELING_TCP',
              child: Text('TUNNELING_TCP — KNX/IP Tunneling v2 (TCP)'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              onConnectionTypeChanged(value);
            }
          },
          onSaved: (value) =>
              knxConnectionType = value == null || value.isEmpty
                  ? 'ROUTING'
                  : value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: individualAddressController,
          decoration: const InputDecoration(
            labelText: 'Physikalische Adresse',
            hintText: '0.0.0',
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) {
              return 'Bitte die physikalische Adresse angeben.';
            }
            if (!_isValidIndividualAddress(trimmed)) {
              return 'Ungültige Physikalische Adresse.';
            }
            return null;
          },
          onSaved: (value) => knxIndividualAddress = value?.trim() ?? '',
          onChanged: (value) => knxIndividualAddress = value.trim(),
        ),
        const SizedBox(height: 16),
        if (requiresGateway) ...[
          const DividerWithText(
            text: 'Gateway',
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
          TextFormField(
            controller: gatewayIpController,
            decoration: const InputDecoration(
              labelText: 'Gateway IP-Adresse',
              hintText: '192.168.1.10',
            ),
            keyboardType: TextInputType.number,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            inputFormatters: const [Ipv4TextInputFormatter()],
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return 'Bitte die Gateway IP-Adresse angeben.';
              }
              if (!_isValidIpv4(trimmed)) {
                return 'Bitte eine gültige IPv4-Adresse eingeben.';
              }
              return null;
            },
            onSaved: (value) => knxGatewayIp = value?.trim() ?? '',
            onChanged: (value) => knxGatewayIp = value.trim(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: gatewayPortController,
            decoration: const InputDecoration(labelText: 'Gateway Port'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return 'Bitte den Gateway-Port angeben.';
              }
              if (!_isValidPort(trimmed)) {
                return 'Port muss zwischen 1 und 65535 liegen.';
              }
              return null;
            },
            onSaved: (value) => knxGatewayPort = value?.trim() ?? '',
            onChanged: (value) => knxGatewayPort = value.trim(),
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto-Reconnect'),
            subtitle: const Text(
              'Verbindung automatisch erneut versuchen, wenn sie getrennt wurde.',
            ),
            value: autoReconnect,
            onChanged: onAutoReconnectChanged,
          ),
          if (autoReconnect) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: autoReconnectWaitController,
              decoration: const InputDecoration(
                labelText: 'Auto-Reconnect Wartezeit (s)',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return 'Bitte eine Wartezeit angeben.';
                }
                final wait = int.tryParse(trimmed);
                if (wait == null || wait < 1 || wait > 120) {
                  return 'Wert zwischen 1 und 120 angeben.';
                }
                return null;
              },
              onSaved: (value) => knxAutoReconnectWait = value?.trim() ?? '',
              onChanged: (value) => knxAutoReconnectWait = value.trim(),
            ),
            const SizedBox(height: 16),
          ] else
            const SizedBox(height: 16),
        ],
        if (isRouting) ...[
          const DividerWithText(
            text: 'Routing',
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
          TextFormField(
            controller: multicastGroupController,
            decoration: const InputDecoration(
              labelText: 'Multicast-Gruppe',
              hintText: '224.0.23.12',
            ),
            keyboardType: TextInputType.number,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            inputFormatters: const [Ipv4TextInputFormatter()],
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return 'Bitte die Multicast-Gruppe angeben.';
              }
              if (!_isValidIpv4(trimmed) || !_isMulticastIpv4(trimmed)) {
                return 'Multicast-Adressen müssen zwischen 224.0.0.0 und 239.255.255.255 liegen.';
              }
              return null;
            },
            onSaved: (value) => knxMulticastGroup = value?.trim() ?? '',
            onChanged: (value) => knxMulticastGroup = value.trim(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: multicastPortController,
            decoration: const InputDecoration(labelText: 'Multicast-Port'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return 'Bitte den Multicast-Port angeben.';
              }
              if (!_isValidPort(trimmed)) {
                return 'Port muss zwischen 1 und 65535 liegen.';
              }
              return null;
            },
            onSaved: (value) => knxMulticastPort = value?.trim() ?? '',
            onChanged: (value) => knxMulticastPort = value.trim(),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

bool _isValidIndividualAddress(String value) {
  final parts = value.split('.');
  if (parts.length != 3) return false;
  final area = int.tryParse(parts[0]);
  final line = int.tryParse(parts[1]);
  final device = int.tryParse(parts[2]);
  if (area == null || line == null || device == null) return false;
  return area >= 0 && area <= 15 && line >= 0 && line <= 15 && device >= 0 && device <= 255;
}

bool _isValidIpv4(String value) {
  final parts = value.split('.');
  if (parts.length != 4) return false;
  for (final part in parts) {
    if (part.isEmpty) return false;
    final octet = int.tryParse(part);
    if (octet == null || octet < 0 || octet > 255) {
      return false;
    }
  }
  return true;
}

bool _isMulticastIpv4(String value) {
  if (!_isValidIpv4(value)) return false;
  final firstOctet = int.parse(value.split('.').first);
  return firstOctet >= 224 && firstOctet <= 239;
}

bool _isValidPort(String value) {
  final port = int.tryParse(value);
  if (port == null) return false;
  return port >= 1 && port <= 65535;
}


class Ipv4TextInputFormatter extends TextInputFormatter {
  const Ipv4TextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }

    final parts = text.split('.');
    if (parts.length > 4) {
      return oldValue;
    }

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isEmpty) {
        if (i == parts.length - 1) {
          continue;
        }
        return oldValue;
      }
      if (!RegExp(r'^\d+$').hasMatch(part)) {
        return oldValue;
      }
      if (part.length > 3) {
        return oldValue;
      }
      final value = int.tryParse(part);
      if (value == null || value > 255) {
        return oldValue;
      }
    }

    return newValue;
  }
}
