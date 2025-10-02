import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:xml/xml.dart' as xml;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:async';
import 'package:universal_html/html.dart' as html;
import 'package:universal_html/js_util.dart' as js_util;
import 'sector.dart';
import 'globals.dart';
import 'location_dialog.dart';
import 'general.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart';
import 'timeswitch.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Konfigurator',
      restorationScopeId: "Test",
      // Force German UI for built-in widgets (e.g., pickers)
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MyHomePage(title: 'Home'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<void> _openProject() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['sunproj'],
      withData: kIsWeb,
    );
    if (result != null) {
      try {
        String content;
        if (kIsWeb) {
          final bytes = result.files.single.bytes;
          if (bytes == null) {
            throw Exception('Datei konnte nicht gelesen werden.');
          }
          content = String.fromCharCodes(bytes);
        } else {
          final path = result.files.single.path;
          if (path == null) throw Exception('Dateipfad fehlt.');
          final file = File(path);
          content = await file.readAsString();
        }
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfigScreen(initialXmlContent: content),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Datei: $e')),
        );
      }
    }
  }

  void _createProject() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConfigScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _openProject,
              child: const Text('Projekt öffnen'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createProject,
              child: const Text('Projekt erstellen'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: null,
              child: const Text('mit Staerium-Server verbinden (demnächst)'),
            ),
          ],
        ),
      ),
    );
  }
}

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key, this.initialXmlContent});

  final String? initialXmlContent;

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class SaveIntent extends Intent {
  const SaveIntent();
}

class SaveAsIntent extends Intent {
  const SaveAsIntent();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  // Remember last save destination
  String? _lastXmlPath; // Native/Desktop last path
  Object? _webFileHandle; // Web File System Access API handle
  // Web: intercept browser Ctrl/⌘+S to prevent the default "Save page" dialog
  StreamSubscription<html.KeyboardEvent>? _keyDownSub;
  // --- XML Parsing ---
  void fromXml(String xmlString) {
    final doc = xml.XmlDocument.parse(xmlString);
    final root = doc.getElement('Konfiguration');
    if (root == null) return;

    bool? parseBool(String? value) {
      if (value == null) return null;
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
      return null;
    }

    int? parseInt(String? value) {
      if (value == null) return null;
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return int.tryParse(trimmed);
    }

    setState(() {
      version = root.getElement('Version')?.innerText ?? '';
      _latController.text = root.getElement('Latitude')?.innerText ?? '';
      _lngController.text = root.getElement('Longitude')?.innerText ?? '';
      azElOption = root.getElement('AzElOption')?.innerText ?? 'Internet';
      timeAddress = root.getElement('TimeAddress')?.innerText ?? '';
      azimuthAddress = root.getElement('AzimuthAddress')?.innerText ?? '';
      elevationAddress = root.getElement('ElevationAddress')?.innerText ?? '';
      final connectionTypeRaw =
          root.getElement('KnxConnectionType')?.innerText;
      final connectionTypeStr = connectionTypeRaw?.trim();
      if (connectionTypeStr != null && connectionTypeStr.isNotEmpty) {
        knxConnectionType = connectionTypeStr;
      } else {
        knxConnectionType = 'ROUTING';
      }
      knxIndividualAddress =
          root.getElement('KnxIndividualAddress')?.innerText ?? '';
      knxGatewayIp = root.getElement('KnxGatewayIp')?.innerText ?? '';
      knxGatewayPort = root.getElement('KnxGatewayPort')?.innerText ?? '';
      knxMulticastGroup =
          root.getElement('KnxMulticastGroup')?.innerText ?? '';
      knxMulticastPort =
          root.getElement('KnxMulticastPort')?.innerText ?? '';
      final autoReconnectStr =
          root.getElement('KnxAutoReconnect')?.innerText;
      if (autoReconnectStr != null) {
        knxAutoReconnect = autoReconnectStr.toLowerCase() == 'true';
      }
      final autoReconnectWaitStr =
          root.getElement('KnxAutoReconnectWait')?.innerText;
      if (autoReconnectWaitStr != null && autoReconnectWaitStr.isNotEmpty) {
        knxAutoReconnectWait = autoReconnectWaitStr;
      } else if (knxAutoReconnectWait.isEmpty) {
        knxAutoReconnectWait = '5';
      }
      _knxIndividualAddressController.text = knxIndividualAddress;
      _knxGatewayIpController.text = knxGatewayIp;
      _knxGatewayPortController.text = knxGatewayPort;
      _knxMulticastGroupController.text = knxMulticastGroup;
      _knxMulticastPortController.text = knxMulticastPort;
      _knxAutoReconnectWaitController.text = knxAutoReconnectWait;
      // Sectors
      sectors.clear();
      final sectorsElem =
          root.getElement('Sektoren') ?? root.getElement('Sectors');
      if (sectorsElem != null) {
        for (final sElem
            in sectorsElem.findElements('Sektor').isNotEmpty
                ? sectorsElem.findElements('Sektor')
                : sectorsElem.findElements('Sector')) {
          final s = Sector();
          s.name = sElem.getElement('Name')?.innerText ?? '';
          s.orientation =
              double.tryParse(
                sElem.getElement('Orientation')?.innerText ?? '',
              ) ??
              0;
          s.horizonLimit =
              sElem.getElement('HorizonLimit')?.innerText == 'true';
          s.louvreTracking =
              sElem.getElement('LouvreTracking')?.innerText == 'true';
          s.louvreSpacing =
              double.tryParse(
                sElem.getElement('LouvreSpacing')?.innerText ?? '',
              ) ??
              0;
          s.louvreDepth =
              double.tryParse(
                sElem.getElement('LouvreDepth')?.innerText ?? '',
              ) ??
              0;
          s.louvreAngleAtZero =
              double.tryParse(
                sElem.getElement('LouvreAngleAtZero')?.innerText ?? '',
              ) ??
              90;
          s.louvreAngleAtHundred =
              double.tryParse(
                sElem.getElement('LouvreAngleAtHundred')?.innerText ?? '',
              ) ??
              0;
          s.louvreMinimumChange =
              double.tryParse(
                sElem.getElement('LouvreMinimumChange')?.innerText ?? '',
              ) ??
              20;
          s.louvreBuffer =
              double.tryParse(
                sElem.getElement('LouvreBuffer')?.innerText ?? '',
              ) ??
              5;
          s.brightnessAddress =
              sElem.getElement('BrightnessAddress')?.innerText ?? '';
          s.louvreAngleAddress =
              sElem.getElement('LouvreAngleAddress')?.innerText ?? '';
          final sunBoolAddress = sElem.getElement('SunBoolAddress')?.innerText;
          if (sunBoolAddress != null) {
            s.sunBoolAddress = sunBoolAddress;
          } else {
            s.sunBoolAddress = sElem.getElement('SunAddress')?.innerText ?? '';
          }
          final useBrightness = parseBool(
            sElem.getElement('UseBrightness')?.innerText,
          );
          if (useBrightness != null) {
            s.useBrightness = useBrightness;
          }
          final useIrradiance = parseBool(
            sElem.getElement('UseIrradiance')?.innerText,
          );
          if (useIrradiance != null) {
            s.useIrradiance = useIrradiance;
          }
          s.brightnessUpperThreshold = parseInt(
            sElem.getElement('BrightnessUpperThreshold')?.innerText,
          );
          s.brightnessUpperDelay = parseInt(
            sElem.getElement('BrightnessUpperDelay')?.innerText,
          );
          s.brightnessLowerThreshold = parseInt(
            sElem.getElement('BrightnessLowerThreshold')?.innerText,
          );
          s.brightnessLowerDelay = parseInt(
            sElem.getElement('BrightnessLowerDelay')?.innerText,
          );
          s.irradianceAddress =
              sElem.getElement('IrradianceAddress')?.innerText ?? '';
          s.irradianceUpperThreshold = parseInt(
            sElem.getElement('IrradianceUpperThreshold')?.innerText,
          );
          s.irradianceUpperDelay = parseInt(
            sElem.getElement('IrradianceUpperDelay')?.innerText,
          );
          s.irradianceLowerThreshold = parseInt(
            sElem.getElement('IrradianceLowerThreshold')?.innerText,
          );
          s.irradianceLowerDelay = parseInt(
            sElem.getElement('IrradianceLowerDelay')?.innerText,
          );
          final link = sElem.getElement('BrightnessIrradianceLink')?.innerText;
          if (link != null && link.isNotEmpty) {
            s.brightnessIrradianceLink = link;
          }
          s.onAutoAddress =
              sElem.getElement('OnAutoAddress')?.innerText ?? '';
          final onAutoBehavior = sElem
              .getElement('OnAutoBehavior')
              ?.innerText;
          if (onAutoBehavior != null && onAutoBehavior.isNotEmpty) {
            if (onAutoBehavior == 'Ein' || onAutoBehavior == 'Auto') {
              s.onAutoBehavior = onAutoBehavior;
            }
          }
          s.offAutoAddress =
              sElem.getElement('OffAutoAddress')?.innerText ?? '';
          final offAutoBehavior = sElem
              .getElement('OffAutoBehavior')
              ?.innerText;
          if (offAutoBehavior != null && offAutoBehavior.isNotEmpty) {
            if (offAutoBehavior == 'Aus' || offAutoBehavior == 'Auto') {
              s.offAutoBehavior = offAutoBehavior;
            }
          }
          s.facadeAddress = sElem.getElement('FacadeAddress')?.innerText ?? '';
          // GUID
          final guid = sElem.getElement('GUID')?.innerText;
          if (guid != null) {
            // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
            s.guid = guid;
          }
          // FacadeStart/End
          final fs = sElem.getElement('FacadeStart')?.innerText;
          if (fs != null && fs.contains(',')) {
            final parts = fs.split(',');
            if (parts.length == 2) {
              final lat = double.tryParse(parts[0]);
              final lng = double.tryParse(parts[1]);
              if (lat != null && lng != null) {
                s.facadeStart = LatLng(lat, lng);
              }
            }
          }
          final fe = sElem.getElement('FacadeEnd')?.innerText;
          if (fe != null && fe.contains(',')) {
            final parts = fe.split(',');
            if (parts.length == 2) {
              final lat = double.tryParse(parts[0]);
              final lng = double.tryParse(parts[1]);
              if (lat != null && lng != null) {
                s.facadeEnd = LatLng(lat, lng);
              }
            }
          }
          // HorizonPoints
          s.horizonPoints = [];
          final hpElem = sElem.getElement('HorizonPoints');
          if (hpElem != null) {
            for (final pElem in hpElem.findElements('Point')) {
              final x =
                  double.tryParse(pElem.getElement('X')?.innerText ?? '') ?? 0;
              final y =
                  double.tryParse(pElem.getElement('Y')?.innerText ?? '') ?? 0;
              s.horizonPoints.add(Point(x: x, y: y));
            }
          }
          // CeilingPoints
          s.ceilingPoints = [];
          final cpElem = sElem.getElement('CeilingPoints');
          if (cpElem != null) {
            for (final pElem in cpElem.findElements('Point')) {
              final x =
                  double.tryParse(pElem.getElement('X')?.innerText ?? '') ?? 0;
              final y =
                  double.tryParse(pElem.getElement('Y')?.innerText ?? '') ?? 0;
              s.ceilingPoints.add(Point(x: x, y: y));
            }
          }
          s.ensureDefaultPoints();
          sectors.add(s);
        }
      }
      // TimePrograms
      timePrograms.clear();
      final timersElem = root.getElement('TimePrograms');
      if (timersElem != null) {
        for (final pElem in timersElem.findElements('TimeProgram')) {
          final p = TimeProgram();
          p.name = pElem.getElement('Name')?.innerText ?? '';
          final programGA = pElem
              .getElement('GroupAddress')
              ?.innerText; // legacy fallback
          final guid = pElem.getElement('GUID')?.innerText;
          if (guid != null) {
            p.guid = guid;
          }
          final cmdsElem = pElem.getElement('Commands');
          if (cmdsElem != null) {
            for (final cElem in cmdsElem.findElements('Command')) {
              final typeStr = cElem.getElement('Type')?.innerText ?? '1bit';
              final mask =
                  int.tryParse(
                    cElem.getElement('Weekdays')?.innerText ?? '0',
                  ) ??
                  0;
              final time = cElem.getElement('Time')?.innerText ?? '08:00';
              final val =
                  int.tryParse(cElem.getElement('Value')?.innerText ?? '0') ??
                  0;
              final cGa =
                  cElem.getElement('GroupAddress')?.innerText ??
                  (programGA ?? '');
              p.commands.add(
                TimeCommand(
                  type: typeStr.toLowerCase() == '1byte'
                      ? CommandType.oneByte
                      : CommandType.oneBit,
                  weekdaysMask: mask,
                  time: time,
                  value: val,
                  groupAddress: cGa,
                ),
              );
            }
          }
          timePrograms.add(p);
        }
      }
    });
  }

  Future<void> _openXml() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['sunproj'],
      withData: kIsWeb,
    );
    if (result != null) {
      try {
        String content;
        if (kIsWeb) {
          // On web, read from bytes
          final bytes = result.files.single.bytes;
          if (bytes == null) {
            throw Exception('Datei konnte nicht gelesen werden.');
          }
          content = String.fromCharCodes(bytes);
        } else {
          // On native, read from file path
          final path = result.files.single.path;
          if (path == null) throw Exception('Dateipfad fehlt.');
          final file = File(path);
          content = await file.readAsString();
        }
        _loadXmlContent(content);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Laden der Datei: $e')),
          );
        }
      }
    }
  }

  // State for navigation and sector editing
  int? editingSectorIndex;
  int? editingTimerIndex;
  String selectedPage = 'Allgemein';
  Sector? _copiedSector;
  int? _hoveredSectorIndex;
  TimeProgram? _copiedProgram;
  int? _hoveredProgramIndex;

  // Standort (Lat/Lng)
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _knxIndividualAddressController =
      TextEditingController();
  final TextEditingController _knxGatewayIpController = TextEditingController();
  final TextEditingController _knxGatewayPortController =
      TextEditingController();
  final TextEditingController _knxMulticastGroupController =
      TextEditingController();
  final TextEditingController _knxMulticastPortController =
      TextEditingController();
  final TextEditingController _knxAutoReconnectWaitController =
      TextEditingController();

  void _loadXmlContent(String content, {bool showSuccess = true}) {
    fromXml(content);
    if (mounted && showSuccess) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Konfiguration geladen.')));
    }
  }

  @override
  void initState() {
    super.initState();
    _knxIndividualAddressController.text = knxIndividualAddress;
    _knxGatewayIpController.text = knxGatewayIp;
    _knxGatewayPortController.text = knxGatewayPort;
    _knxMulticastGroupController.text = knxMulticastGroup;
    _knxMulticastPortController.text = knxMulticastPort;
    _knxAutoReconnectWaitController.text = knxAutoReconnectWait;
    if (kIsWeb) {
      _keyDownSub = html.window.onKeyDown.listen((e) {
        final key = (e.key ?? '').toLowerCase();
        final isS = key == 's' || e.code == 'KeyS';
        if ((e.ctrlKey || e.metaKey) && isS) {
          // Stop the browser from opening its own save dialog
          e.preventDefault();
          js_util.callMethod(e, 'stopImmediatePropagation', []);
          if (e.shiftKey) {
            _saveAsXml();
          } else {
            _saveXml();
          }
        }
      });
    }

    final initialContent = widget.initialXmlContent;
    if (initialContent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadXmlContent(initialContent);
        }
      });
    }
  }

  @override
  void dispose() {
    _keyDownSub?.cancel();
    super.dispose();
  }

  // --- XML Serialization ---
  String toXml() {
    final builder = xml.XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(
      'Konfiguration',
      nest: () {
        builder.element('Version', nest: version);
        builder.element('Latitude', nest: _latController.text);
        builder.element('Longitude', nest: _lngController.text);
        builder.element('AzElOption', nest: azElOption);
        builder.element('TimeAddress', nest: timeAddress);
        builder.element('AzimuthAddress', nest: azimuthAddress);
        builder.element('ElevationAddress', nest: elevationAddress);
        builder.element('KnxConnectionType', nest: knxConnectionType);
        builder.element('KnxIndividualAddress', nest: knxIndividualAddress);
        builder.element('KnxGatewayIp', nest: knxGatewayIp);
        builder.element('KnxGatewayPort', nest: knxGatewayPort);
        builder.element('KnxMulticastGroup', nest: knxMulticastGroup);
        builder.element('KnxMulticastPort', nest: knxMulticastPort);
        builder.element(
          'KnxAutoReconnect',
          nest: knxAutoReconnect.toString(),
        );
        builder.element(
          'KnxAutoReconnectWait',
          nest: knxAutoReconnectWait,
        );
        builder.element(
          'Sectors',
          nest: () {
            for (final s in sectors) {
              builder.element(
                'Sector',
                nest: () {
                  builder.element('GUID', nest: s.guid);
                  builder.element('Name', nest: s.name);
                  builder.element(
                    'Orientation',
                    nest: s.orientation.toString(),
                  );
                  builder.element(
                    'HorizonLimit',
                    nest: s.horizonLimit.toString(),
                  );
                  builder.element(
                    'LouvreTracking',
                    nest: s.louvreTracking.toString(),
                  );
                  builder.element(
                    'LouvreSpacing',
                    nest: s.louvreSpacing.toString(),
                  );
                  builder.element(
                    'LouvreDepth',
                    nest: s.louvreDepth.toString(),
                  );
                  builder.element(
                    'LouvreAngleAtZero',
                    nest: s.louvreAngleAtZero.toString(),
                  );
                  builder.element(
                    'LouvreAngleAtHundred',
                    nest: s.louvreAngleAtHundred.toString(),
                  );
                  builder.element(
                    'LouvreMinimumChange',
                    nest: s.louvreMinimumChange.toString(),
                  );
                  builder.element(
                    'LouvreBuffer',
                    nest: s.louvreBuffer.toString(),
                  );
                  builder.element(
                    'UseBrightness',
                    nest: s.useBrightness.toString(),
                  );
                  builder.element(
                    'UseIrradiance',
                    nest: s.useIrradiance.toString(),
                  );
                  builder.element(
                    'BrightnessAddress',
                    nest: s.brightnessAddress,
                  );
                  builder.element(
                    'LouvreAngleAddress',
                    nest: s.louvreAngleAddress,
                  );
                  builder.element('SunBoolAddress', nest: s.sunBoolAddress);
                  builder.element(
                    'BrightnessUpperThreshold',
                    nest: s.brightnessUpperThreshold?.toString() ?? '',
                  );
                  builder.element(
                    'BrightnessUpperDelay',
                    nest: s.brightnessUpperDelay?.toString() ?? '',
                  );
                  builder.element(
                    'BrightnessLowerThreshold',
                    nest: s.brightnessLowerThreshold?.toString() ?? '',
                  );
                  builder.element(
                    'BrightnessLowerDelay',
                    nest: s.brightnessLowerDelay?.toString() ?? '',
                  );
                  builder.element(
                    'IrradianceAddress',
                    nest: s.irradianceAddress,
                  );
                  builder.element(
                    'IrradianceUpperThreshold',
                    nest: s.irradianceUpperThreshold?.toString() ?? '',
                  );
                  builder.element(
                    'IrradianceUpperDelay',
                    nest: s.irradianceUpperDelay?.toString() ?? '',
                  );
                  builder.element(
                    'IrradianceLowerThreshold',
                    nest: s.irradianceLowerThreshold?.toString() ?? '',
                  );
                  builder.element(
                    'IrradianceLowerDelay',
                    nest: s.irradianceLowerDelay?.toString() ?? '',
                  );
                  builder.element(
                    'BrightnessIrradianceLink',
                    nest: s.brightnessIrradianceLink,
                  );
                  builder.element(
                    'OnAutoAddress',
                    nest: s.onAutoAddress,
                  );
                  builder.element(
                    'OnAutoBehavior',
                    nest: s.onAutoBehavior,
                  );
                  builder.element(
                    'OffAutoAddress',
                    nest: s.offAutoAddress,
                  );
                  builder.element(
                    'OffAutoBehavior',
                    nest: s.offAutoBehavior,
                  );
                  builder.element('FacadeAddress', nest: s.facadeAddress);
                  builder.element(
                    'FacadeStart',
                    nest: s.facadeStart != null
                        ? '${s.facadeStart!.latitude},${s.facadeStart!.longitude}'
                        : '',
                  );
                  builder.element(
                    'FacadeEnd',
                    nest: s.facadeEnd != null
                        ? '${s.facadeEnd!.latitude},${s.facadeEnd!.longitude}'
                        : '',
                  );
                  builder.element(
                    'HorizonPoints',
                    nest: () {
                      for (final p in s.horizonPoints) {
                        builder.element(
                          'Point',
                          nest: () {
                            builder.element('X', nest: p.x.toString());
                            builder.element('Y', nest: p.y.toString());
                          },
                        );
                      }
                    },
                  );
                  builder.element(
                    'CeilingPoints',
                    nest: () {
                      for (final p in s.ceilingPoints) {
                        builder.element(
                          'Point',
                          nest: () {
                            builder.element('X', nest: p.x.toString());
                            builder.element('Y', nest: p.y.toString());
                          },
                        );
                      }
                    },
                  );
                },
              );
            }
          },
        );
        builder.element(
          'TimePrograms',
          nest: () {
            for (final p in timePrograms) {
              builder.element(
                'TimeProgram',
                nest: () {
                  builder.element('GUID', nest: p.guid);
                  builder.element('Name', nest: p.name);
                  builder.element(
                    'Commands',
                    nest: () {
                      for (final c in p.commands) {
                        builder.element(
                          'Command',
                          nest: () {
                            builder.element(
                              'Type',
                              nest: c.type == CommandType.oneByte
                                  ? '1byte'
                                  : '1bit',
                            );
                            builder.element(
                              'Weekdays',
                              nest: c.weekdaysMask.toString(),
                            );
                            builder.element('Time', nest: c.time);
                            builder.element('Value', nest: c.value.toString());
                            builder.element(
                              'GroupAddress',
                              nest: c.groupAddress,
                            );
                          },
                        );
                      }
                    },
                  );
                },
              );
            }
          },
        );
      },
    );
    return builder.buildDocument().toXmlString(pretty: true);
  }

  String? _prepareXml() {
    final formState = _formKey.currentState;
    if (formState == null) {
      return null;
    }
    if (!formState.validate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitte Eingaben prüfen.')),
        );
      }
      return null;
    }
    formState.save();
    return toXml();
  }

  Future<void> _saveAsXml({String? xmlString}) async {
    final xml = xmlString ?? _prepareXml();
    if (xml == null) {
      return;
    }
    if (kIsWeb) {
      // Prefer the File System Access API when available so we can overwrite next time
      final hasFileSystem = js_util.hasProperty(
        html.window,
        'showSaveFilePicker',
      );
      if (hasFileSystem) {
        try {
          final pickerOptions = js_util.jsify({
            'suggestedName': 'konfiguration.sunproj',
            'types': [
              {
                'description': 'sunproj Files',
                'accept': {
                  'text/xml': ['.sunproj'],
                },
              },
            ],
          });
          final fileHandle = await js_util.promiseToFuture(
            js_util.callMethod(html.window, 'showSaveFilePicker', [
              pickerOptions,
            ]),
          );
          final writable = await js_util.promiseToFuture(
            js_util.callMethod(fileHandle, 'createWritable', []),
          );
          await js_util.promiseToFuture(
            js_util.callMethod(writable, 'write', [xml]),
          );
          await js_util.promiseToFuture(
            js_util.callMethod(writable, 'close', []),
          );

          // Remember handle for future quick saves
          _webFileHandle = fileHandle;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Konfiguration gespeichert.')),
            );
          }
          return;
        } catch (e) {
          // Fall back to download below
        }
      }

      // Fallback: trigger download using AnchorElement (cannot overwrite automatically later)
      final bytes = utf8.encode(xml);
      final blob = html.Blob([bytes], 'text/xml');
      final url = html.Url.createObjectUrlFromBlob(blob);
      //final anchor = html.AnchorElement(href: url)
      //  ..setAttribute('download', 'konfiguration.sunproj')
      //  ..click();
      html.Url.revokeObjectUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Projekt gespeichert.')));
      }
    } else {
      // Native/Desktop: let the user choose a location and remember it
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Projekt speichern',
        fileName: 'konfiguration',
        type: FileType.custom,
        allowedExtensions: ['sunproj'],
      );
      if (result != null) {
        final file = File(result);
        await file.writeAsString(xml);
        _lastXmlPath = result; // remember for quick save
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konfiguration gespeichert.')),
          );
        }
      }
    }
  }

  Future<void> _saveXml() async {
    final xmlString = _prepareXml();
    if (xmlString == null) {
      return;
    }

    if (kIsWeb) {
      final hasFileSystem = js_util.hasProperty(
        html.window,
        'showSaveFilePicker',
      );
      // If we have a remembered handle, write directly. Otherwise fall back to Save As.
      if (hasFileSystem && _webFileHandle != null) {
        try {
          final writable = await js_util.promiseToFuture(
            js_util.callMethod(_webFileHandle!, 'createWritable', []),
          );
          await js_util.promiseToFuture(
            js_util.callMethod(writable, 'write', [xmlString]),
          );
          await js_util.promiseToFuture(
            js_util.callMethod(writable, 'close', []),
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Konfiguration gespeichert.')),
            );
          }
          return;
        } catch (e) {
          // If writing fails (e.g., permission revoked), forget handle and do Save As
          _webFileHandle = null;
        }
      }
      await _saveAsXml(xmlString: xmlString);
      return;
    } else {
      // Native/Desktop: overwrite the last path if we have one; otherwise Save As
      if (_lastXmlPath != null) {
        final file = File(_lastXmlPath!);
        await file.writeAsString(xmlString);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konfiguration gespeichert.')),
          );
        }
      } else {
        await _saveAsXml(xmlString: xmlString);
      }
    }
  }

  Future<void> _pickLocation() async {
    LatLng? initial;
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    if (lat != null && lng != null) {
      initial = LatLng(lat, lng);
    }

    final LatLng? picked = await showDialog<LatLng>(
      context: context,
      builder: (ctx) =>
          LocationPickerDialog(initialAddress: '', start: initial),
    );

    if (picked != null) {
      setState(() {
        _latController.text = picked.latitude.toStringAsFixed(6);
        _lngController.text = picked.longitude.toStringAsFixed(6);
        latitude = picked.latitude;
        longitude = picked.longitude;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    // Navigation pane for desktop
    final navPane = Drawer(
      child: SizedBox(
        width: 250,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Navigation',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            ListTile(
              title: const Text('Allgemein'),
              selected:
                  editingSectorIndex == null && selectedPage == 'Allgemein',
              selectedTileColor: Colors.blue.shade100,
              tileColor: Colors.grey.shade200,
              onTap: () {
                setState(() {
                  editingSectorIndex = null;
                  selectedPage = 'Allgemein';
                });
              },
            ),
            ExpansionTile(
              title: const Text('Sektoren'),
              children: [
                ...sectors.asMap().entries.map((e) {
                  final i = e.key;
                  final s = e.value;
                  return MouseRegion(
                    onEnter: (_) => setState(() => _hoveredSectorIndex = i),
                    onExit: (_) => setState(() => _hoveredSectorIndex = null),
                    child: ValueListenableBuilder<String>(
                      valueListenable: s.nameNotifier,
                      builder: (context, name, _) {
                        return ListTile(
                          title: Text(name.isEmpty ? 'Neuer Sektor' : name),
                          trailing: _hoveredSectorIndex == i
                              ? IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () => setState(() {
                                    _copiedSector = s;
                                  }),
                                )
                              : null,
                          selected: editingSectorIndex == i,
                          selectedTileColor: Colors.blue.shade100,
                          tileColor: Colors.grey.shade200,
                          onTap: () => setState(() {
                            editingSectorIndex = i;
                            editingTimerIndex = null;
                          }),
                        );
                      },
                    ),
                  );
                }),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Sektor hinzufügen'),
                  tileColor: Colors.grey.shade200,
                  onTap: () {
                    setState(() {
                      sectors.add(Sector());
                      editingSectorIndex = sectors.length - 1;
                      editingTimerIndex = null;
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.paste),
                  title: const Text('Einfügen'),
                  tileColor: Colors.grey.shade200,
                  enabled: _copiedSector != null,
                  onTap: _copiedSector != null
                      ? () {
                          setState(() => selectedPage = 'Sektoren');
                          setState(() {
                            sectors.add(
                              Sector()
                                ..name = _copiedSector!.name
                                ..orientation = _copiedSector!.orientation
                                ..horizonLimit = _copiedSector!.horizonLimit
                                ..horizonPoints = _copiedSector!.horizonPoints
                                ..ceilingPoints = _copiedSector!.ceilingPoints
                                ..louvreTracking = _copiedSector!.louvreTracking
                                ..louvreSpacing = _copiedSector!.louvreSpacing
                                ..louvreDepth = _copiedSector!.louvreDepth
                                ..louvreAngleAtZero =
                                    _copiedSector!.louvreAngleAtZero
                                ..louvreAngleAtHundred =
                                    _copiedSector!.louvreAngleAtHundred
                                ..louvreMinimumChange =
                                    _copiedSector!.louvreMinimumChange
                                ..louvreBuffer = _copiedSector!.louvreBuffer
                                ..brightnessAddress =
                                    _copiedSector!.brightnessAddress
                                ..irradianceAddress =
                                    _copiedSector!.irradianceAddress
                                ..facadeAddress = _copiedSector!.facadeAddress
                                ..facadeStart = _copiedSector!.facadeStart
                                ..facadeEnd = _copiedSector!.facadeEnd,
                            );
                            editingSectorIndex = sectors.length - 1;
                            editingTimerIndex = null;
                          });
                        }
                      : null,
                ),
              ],
            ),
            ExpansionTile(
              title: const Text('Zeitschaltuhren'),
              children: [
                ...timePrograms.asMap().entries.map((e) {
                  final i = e.key;
                  final p = e.value;
                  return MouseRegion(
                    onEnter: (_) => setState(() => _hoveredProgramIndex = i),
                    onExit: (_) => setState(() => _hoveredProgramIndex = null),
                    child: ValueListenableBuilder<String>(
                      valueListenable: p.nameNotifier,
                      builder: (context, name, _) {
                        return ListTile(
                          title: Text(name.isEmpty ? 'Neues Programm' : name),
                          trailing: _hoveredProgramIndex == i
                              ? IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () => setState(() {
                                    _copiedProgram = p;
                                  }),
                                )
                              : null,
                          selected:
                              editingTimerIndex == i &&
                              selectedPage == 'Zeitschaltuhren',
                          selectedTileColor: Colors.blue.shade100,
                          tileColor: Colors.grey.shade200,
                          onTap: () => setState(() {
                            selectedPage = 'Zeitschaltuhren';
                            editingTimerIndex = i;
                            editingSectorIndex = null;
                          }),
                        );
                      },
                    ),
                  );
                }),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Programm hinzufügen'),
                  tileColor: Colors.grey.shade200,
                  onTap: () {
                    setState(() {
                      timePrograms.add(TimeProgram());
                      selectedPage = 'Zeitschaltuhren';
                      editingTimerIndex = timePrograms.length - 1;
                      editingSectorIndex = null;
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.paste),
                  title: const Text('Einfügen'),
                  tileColor: Colors.grey.shade200,
                  enabled: _copiedProgram != null,
                  onTap: _copiedProgram != null
                      ? () {
                          setState(() => selectedPage = 'Zeitschaltuhren');
                          setState(() {
                            timePrograms.add(
                              TimeProgram()
                                ..name = _copiedProgram!.name
                                ..commands = _copiedProgram!.commands
                                    .map(
                                      (c) => TimeCommand(
                                        type: c.type,
                                        weekdaysMask: c.weekdaysMask,
                                        time: c.time,
                                        value: c.value,
                                        groupAddress: c.groupAddress,
                                      ),
                                    )
                                    .toList(),
                            );
                            editingTimerIndex = timePrograms.length - 1;
                            editingSectorIndex = null;
                          });
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        // Windows/Linux: Ctrl+S / Ctrl+Shift+S
        SingleActivator(LogicalKeyboardKey.keyS, control: true):
            const SaveIntent(),
        SingleActivator(LogicalKeyboardKey.keyS, control: true, shift: true):
            const SaveAsIntent(),
        // macOS: ⌘S / ⌘⇧S
        SingleActivator(LogicalKeyboardKey.keyS, meta: true):
            const SaveIntent(),
        SingleActivator(LogicalKeyboardKey.keyS, meta: true, shift: true):
            const SaveAsIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SaveIntent: CallbackAction<SaveIntent>(
            onInvoke: (intent) {
              _saveXml();
              return null;
            },
          ),
          SaveAsIntent: CallbackAction<SaveAsIntent>(
            onInvoke: (intent) {
              _saveAsXml();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Konfiguration'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  tooltip: 'Projekt öffnen',
                  onPressed: _openXml,
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'Speichern (Strg/⌘+S)',
                  onPressed: _saveXml,
                ),
                IconButton(
                  icon: const Icon(Icons.save_as),
                  tooltip: 'Speichern unter… (Strg/⌘+Umschalt+S)',
                  onPressed: _saveAsXml,
                ),
              ],
            ),
            drawer: isDesktop
                ? null
                : Drawer(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        SizedBox(
                          height: 80,
                          child: DrawerHeader(
                            margin: EdgeInsets.zero,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.blue),
                            child: const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Navigation',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                        ListTile(
                          title: const Text('Allgemein'),
                          selected:
                              editingSectorIndex == null &&
                              selectedPage == 'Allgemein',
                          selectedTileColor: Colors.blue.shade100,
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              editingSectorIndex = null;
                              selectedPage = 'Allgemein';
                            });
                          },
                        ),
                        ExpansionTile(
                          title: const Text('Sektoren'),
                          children: [
                            ...sectors.asMap().entries.map((e) {
                              final i = e.key;
                              final s = e.value;
                              return MouseRegion(
                                onEnter: (_) =>
                                    setState(() => _hoveredSectorIndex = i),
                                onExit: (_) =>
                                    setState(() => _hoveredSectorIndex = null),
                                child: ListTile(
                                  title: Text(
                                    s.name.isEmpty ? 'Neuer Sektor' : s.name,
                                  ),
                                  trailing: _hoveredSectorIndex == i
                                      ? IconButton(
                                          icon: const Icon(Icons.copy),
                                          onPressed: () => setState(() {
                                            _copiedSector = s;
                                          }),
                                        )
                                      : null,
                                  selected: editingSectorIndex == i,
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(() => selectedPage = 'Sektoren');
                                    setState(() {
                                      editingSectorIndex = i;
                                      editingTimerIndex = null;
                                    });
                                  },
                                ),
                              );
                            }),
                            ListTile(
                              leading: const Icon(Icons.add),
                              title: const Text('Sektor hinzufügen'),
                              onTap: () {
                                Navigator.pop(context);
                                setState(() => selectedPage = 'Sektoren');
                                setState(() {
                                  sectors.add(Sector());
                                  editingSectorIndex = sectors.length - 1;
                                  editingTimerIndex = null;
                                });
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.paste),
                              title: const Text('Einfügen'),
                              enabled: _copiedSector != null,
                              onTap: _copiedSector != null
                                  ? () {
                                      Navigator.pop(context);
                                      setState(() => selectedPage = 'Sektoren');
                                      setState(() {
                                        sectors.add(
                                          Sector()
                                            ..name = _copiedSector!.name
                                            ..orientation =
                                                _copiedSector!.orientation
                                            ..horizonLimit =
                                                _copiedSector!.horizonLimit
                                            ..horizonPoints =
                                                _copiedSector!.horizonPoints
                                            ..ceilingPoints =
                                                _copiedSector!.ceilingPoints
                                            ..louvreTracking =
                                                _copiedSector!.louvreTracking
                                            ..louvreSpacing =
                                                _copiedSector!.louvreSpacing
                                            ..louvreDepth =
                                                _copiedSector!.louvreDepth
                                            ..louvreAngleAtZero =
                                                _copiedSector!.louvreAngleAtZero
                                            ..louvreAngleAtHundred =
                                                _copiedSector!
                                                    .louvreAngleAtHundred
                                            ..louvreMinimumChange =
                                                _copiedSector!
                                                    .louvreMinimumChange
                                            ..louvreBuffer =
                                                _copiedSector!.louvreBuffer
                                            ..brightnessAddress =
                                                _copiedSector!.brightnessAddress
                                            ..irradianceAddress =
                                                _copiedSector!.irradianceAddress
                                            ..facadeAddress =
                                                _copiedSector!.facadeAddress
                                            ..facadeStart =
                                                _copiedSector!.facadeStart
                                            ..facadeEnd =
                                                _copiedSector!.facadeEnd,
                                        );
                                        editingSectorIndex = sectors.length - 1;
                                        editingTimerIndex = null;
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                        ExpansionTile(
                          title: const Text('Zeitschaltuhren'),
                          children: [
                            ...timePrograms.asMap().entries.map((e) {
                              final i = e.key;
                              final p = e.value;
                              return MouseRegion(
                                onEnter: (_) =>
                                    setState(() => _hoveredProgramIndex = i),
                                onExit: (_) =>
                                    setState(() => _hoveredProgramIndex = null),
                                child: ValueListenableBuilder<String>(
                                  valueListenable: p.nameNotifier,
                                  builder: (context, name, _) {
                                    return ListTile(
                                      title: Text(
                                        name.isEmpty ? 'Neues Programm' : name,
                                      ),
                                      trailing: _hoveredProgramIndex == i
                                          ? IconButton(
                                              icon: const Icon(Icons.copy),
                                              onPressed: () => setState(() {
                                                _copiedProgram = p;
                                              }),
                                            )
                                          : null,
                                      selected:
                                          editingTimerIndex == i &&
                                          selectedPage == 'Zeitschaltuhren',
                                      onTap: () {
                                        Navigator.pop(context);
                                        setState(
                                          () =>
                                              selectedPage = 'Zeitschaltuhren',
                                        );
                                        setState(() {
                                          editingTimerIndex = i;
                                          editingSectorIndex = null;
                                        });
                                      },
                                    );
                                  },
                                ),
                              );
                            }),
                            ListTile(
                              leading: const Icon(Icons.add),
                              title: const Text('Programm hinzufügen'),
                              onTap: () {
                                Navigator.pop(context);
                                setState(
                                  () => selectedPage = 'Zeitschaltuhren',
                                );
                                setState(() {
                                  timePrograms.add(TimeProgram());
                                  editingTimerIndex = timePrograms.length - 1;
                                  editingSectorIndex = null;
                                });
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.paste),
                              title: const Text('Einfügen'),
                              enabled: _copiedProgram != null,
                              onTap: _copiedProgram != null
                                  ? () {
                                      Navigator.pop(context);
                                      setState(
                                        () => selectedPage = 'Zeitschaltuhren',
                                      );
                                      setState(() {
                                        timePrograms.add(
                                          TimeProgram()
                                            ..name = _copiedProgram!.name
                                            ..commands = _copiedProgram!
                                                .commands
                                                .map(
                                                  (c) => TimeCommand(
                                                    type: c.type,
                                                    weekdaysMask:
                                                        c.weekdaysMask,
                                                    time: c.time,
                                                    value: c.value,
                                                    groupAddress:
                                                        c.groupAddress,
                                                  ),
                                                )
                                                .toList(),
                                        );
                                        editingTimerIndex =
                                            timePrograms.length - 1;
                                        editingSectorIndex = null;
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
            body: isDesktop
                ? Row(
                    children: [
                      navPane,
                      Expanded(
                        child: editingSectorIndex != null
                            ? SectorWidget(
                                key: ValueKey(editingSectorIndex),
                                sector: sectors[editingSectorIndex!],
                                onRemove: () => setState(() {
                                  sectors.removeAt(editingSectorIndex!);
                                  editingSectorIndex = null;
                                }),
                              )
                            : selectedPage == 'Allgemein'
                                ? GeneralPage(
                                    formKey: _formKey,
                                    latController: _latController,
                                    lngController: _lngController,
                                    onPickLocation: _pickLocation,
                                    azElOption: azElOption,
                                    onAzElOptionChanged: (value) =>
                                        setState(() => azElOption = value),
                                    connectionType: knxConnectionType,
                                    onConnectionTypeChanged: (value) =>
                                        setState(() {
                                          knxConnectionType = value;
                                          if (value == 'ROUTING') {
                                            knxAutoReconnect = false;
                                          }
                                        }),
                                    individualAddressController:
                                        _knxIndividualAddressController,
                                    gatewayIpController:
                                        _knxGatewayIpController,
                                    gatewayPortController:
                                        _knxGatewayPortController,
                                    multicastGroupController:
                                        _knxMulticastGroupController,
                                    multicastPortController:
                                        _knxMulticastPortController,
                                    autoReconnect: knxAutoReconnect,
                                    onAutoReconnectChanged: (value) =>
                                        setState(() {
                                          knxAutoReconnect = value;
                                          if (value &&
                                              _knxAutoReconnectWaitController
                                                  .text.isEmpty) {
                                            final fallback =
                                                knxAutoReconnectWait
                                                        .isNotEmpty
                                                    ? knxAutoReconnectWait
                                                    : '5';
                                            _knxAutoReconnectWaitController
                                                .text = fallback;
                                            knxAutoReconnectWait = fallback;
                                          }
                                        }),
                                    autoReconnectWaitController:
                                        _knxAutoReconnectWaitController,
                                  )
                            : selectedPage == 'Sektoren'
                            ? SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Sektoren',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () => setState(
                                            () => sectors.add(Sector()),
                                          ),
                                        ),
                                      ],
                                    ),
                                    for (int i = 0; i < sectors.length; i++)
                                      SectorWidget(
                                        key: ValueKey(i),
                                        sector: sectors[i],
                                        onRemove: () =>
                                            setState(() => sectors.removeAt(i)),
                                      ),
                                  ],
                                ),
                              )
                            : selectedPage == 'Zeitschaltuhren'
                            ? (editingTimerIndex != null
                                  ? TimeProgramWidget(
                                      key: ValueKey('tp_$editingTimerIndex'),
                                      program: timePrograms[editingTimerIndex!],
                                      onRemove: () => setState(() {
                                        timePrograms.removeAt(
                                          editingTimerIndex!,
                                        );
                                        editingTimerIndex = null;
                                      }),
                                    )
                                  : Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          'Bitte ein Zeitschaltprogramm auswählen',
                                        ),
                                      ),
                                    ))
                            : const SizedBox.shrink(),
                      ),
                    ],
                  )
                : selectedPage == 'Allgemein'
                ? GeneralPage(
                    formKey: _formKey,
                    latController: _latController,
                    lngController: _lngController,
                    onPickLocation: _pickLocation,
                    azElOption: azElOption,
                    onAzElOptionChanged:
                        (value) => setState(() => azElOption = value),
                    connectionType: knxConnectionType,
                    onConnectionTypeChanged: (value) => setState(() {
                      knxConnectionType = value;
                      if (value == 'ROUTING') {
                        knxAutoReconnect = false;
                      }
                    }),
                    individualAddressController:
                        _knxIndividualAddressController,
                    gatewayIpController: _knxGatewayIpController,
                    gatewayPortController: _knxGatewayPortController,
                    multicastGroupController: _knxMulticastGroupController,
                    multicastPortController: _knxMulticastPortController,
                    autoReconnect: knxAutoReconnect,
                    onAutoReconnectChanged: (value) => setState(() {
                      knxAutoReconnect = value;
                      if (value &&
                          _knxAutoReconnectWaitController.text.isEmpty) {
                        final fallback = knxAutoReconnectWait.isNotEmpty
                            ? knxAutoReconnectWait
                            : '5';
                        _knxAutoReconnectWaitController.text = fallback;
                        knxAutoReconnectWait = fallback;
                      }
                    }),
                    autoReconnectWaitController:
                        _knxAutoReconnectWaitController,
                  )
                : selectedPage == 'Sektoren'
                ? (editingSectorIndex != null
                      ? SectorWidget(
                          key: ValueKey(editingSectorIndex),
                          sector: sectors[editingSectorIndex!],
                          onRemove: () => setState(() {
                            sectors.removeAt(editingSectorIndex!);
                            editingSectorIndex = null;
                          }),
                        )
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Bitte einen Sektor auswählen'),
                          ),
                        ))
                : (editingTimerIndex != null
                      ? TimeProgramWidget(
                          key: ValueKey('tp_m_$editingTimerIndex'),
                          program: timePrograms[editingTimerIndex!],
                          onRemove: () => setState(() {
                            timePrograms.removeAt(editingTimerIndex!);
                            editingTimerIndex = null;
                          }),
                        )
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Bitte ein Zeitschaltprogramm auswählen',
                            ),
                          ),
                        )),
          ),
        ),
      ),
    );
  }
}
