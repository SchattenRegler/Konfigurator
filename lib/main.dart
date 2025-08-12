import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'sector.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['sunproj'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      try {
        final content = await file.readAsString();
        // TODO: parse .sunproj content and initialize project
      } catch (e) {
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
          ],
        ),
      ),
    );
  }
}

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({Key? key}) : super(key: key);

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();

  // General settings
  String version = '';
  String brightnessAddress = '';
  String irradianceAddress = '';

  // Azimuth/Elevation settings
  String azElOption = 'Internet';
  String timeAddress = '';
  String azimuthAddress = '';
  String elevationAddress = '';

  // Sector list
  List<Sector> sectors = [];

  // Function toggles
  bool horizonLimit = false;
  bool louvreTracking = false;
  bool shadowEdgeTracking = false;

  // Threshold linkage
  bool linkBrightnessIrradiance = false;

  // State for navigation and sector editing
  int? editingSectorIndex;
  String selectedPage = 'Allgemein';
  Sector? _copiedSector;
  int? _hoveredSectorIndex;

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
              child: Text('Navigation', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            ListTile(
              title: const Text('Allgemein'),
              selected: editingSectorIndex == null && selectedPage == 'Allgemein',
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
                    child: ListTile(
                      title: Text(s.name.isEmpty ? 'Neuer Sektor' : s.name),
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
                      }),
                    ),
                  );
                }).toList(),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Sektor hinzufügen'),
                  tileColor: Colors.grey.shade200,
                  onTap: () {
                    setState(() {
                      sectors.add(Sector());
                      editingSectorIndex = sectors.length - 1;
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
                                    sectors.add(Sector()
                                    ..name = _copiedSector!.name
                                    ..orientation = _copiedSector!.orientation
                                    ..horizonLimit = _copiedSector!.horizonLimit
                                    ..horizonPoints = _copiedSector!.horizonPoints
                                    ..ceilingPoints = _copiedSector!.ceilingPoints
                                    ..louvreTracking = _copiedSector!.louvreTracking
                                    ..louvreSpacing = _copiedSector!.louvreSpacing
                                    ..louvreDepth = _copiedSector!.louvreDepth
                                    ..brightnessAddress = _copiedSector!.brightnessAddress
                                    ..irradianceAddress = _copiedSector!.irradianceAddress
                                    ..facadeAddress = _copiedSector!.facadeAddress
                                    ..facadeStart = _copiedSector!.facadeStart
                                    ..facadeEnd = _copiedSector!.facadeEnd
                                    );
                                  editingSectorIndex = sectors.length - 1;
                                });
                              }
                            : null,
                ),
              ],
            ),
            ListTile(
              title: const Text('Zeitschaltuhren'),
              selected: editingSectorIndex == null && selectedPage == 'Zeitschaltuhren',
              selectedTileColor: Colors.blue.shade100,
              tileColor: Colors.grey.shade200,
              onTap: () {
                setState(() {
                  editingSectorIndex = null;
                  selectedPage = 'Zeitschaltuhren';
                });
              },
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Konfiguration')),
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
                        child: Text('Navigation', style: TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                    ),
                  ),
                  ListTile(
                    title: const Text('Allgemein'),
                    selected: editingSectorIndex == null && selectedPage == 'Allgemein',
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
                          onEnter: (_) => setState(() => _hoveredSectorIndex = i),
                          onExit: (_) => setState(() => _hoveredSectorIndex = null),
                          child: ListTile(
                            title: Text(s.name.isEmpty ? 'Neuer Sektor' : s.name),
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
                              });
                            },
                          ),
                        );
                      }).toList(),
                      ListTile(
                        leading: const Icon(Icons.add),
                        title: const Text('Sektor hinzufügen'),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => selectedPage = 'Sektoren');
                          setState(() {
                            sectors.add(Sector());
                            editingSectorIndex = sectors.length - 1;
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
                                    sectors.add(Sector()
                                    ..name = _copiedSector!.name
                                    ..orientation = _copiedSector!.orientation
                                    ..horizonLimit = _copiedSector!.horizonLimit
                                    ..horizonPoints = _copiedSector!.horizonPoints
                                    ..ceilingPoints = _copiedSector!.ceilingPoints
                                    ..louvreTracking = _copiedSector!.louvreTracking
                                    ..louvreSpacing = _copiedSector!.louvreSpacing
                                    ..louvreDepth = _copiedSector!.louvreDepth
                                    ..brightnessAddress = _copiedSector!.brightnessAddress
                                    ..irradianceAddress = _copiedSector!.irradianceAddress
                                    ..facadeAddress = _copiedSector!.facadeAddress
                                    ..facadeStart = _copiedSector!.facadeStart
                                    ..facadeEnd = _copiedSector!.facadeEnd
                                    );
                                  editingSectorIndex = sectors.length - 1;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                  ListTile(
                    title: const Text('Zeitschaltuhren'),
                    selected: editingSectorIndex == null && selectedPage == 'Zeitschaltuhren',
                    selectedTileColor: Colors.blue.shade100,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        editingSectorIndex = null;
                        selectedPage = 'Zeitschaltuhren';
                      });
                    },
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
                          ? Form(
                              key: _formKey,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Version
                                    TextFormField(
                                      decoration: const InputDecoration(labelText: 'Version'),
                                      onSaved: (v) => version = v ?? '',
                                    ),
                                    const SizedBox(height: 16),
                                    // Gruppenadresse Helligkeit
                                    TextFormField(
                                      decoration: const InputDecoration(labelText: 'Gruppenadresse Helligkeit'),
                                      onSaved: (v) => brightnessAddress = v ?? '',
                                    ),
                                    const SizedBox(height: 16),
                                    // Gruppenadresse Globalstrahlung
                                    TextFormField(
                                      decoration: const InputDecoration(labelText: 'Gruppenadresse Globalstrahlung'),
                                      onSaved: (v) => irradianceAddress = v ?? '',
                                    ),
                                    const SizedBox(height: 24),
                                    // Azimut/Elevation section
                                    const Text('Azimut/Elevation'),
                                    DropdownButtonFormField<String>(
                                      value: azElOption,
                                      items: const [
                                        DropdownMenuItem(value: 'Internet', child: Text('Zeit aus dem Internet beziehen')),
                                        DropdownMenuItem(value: 'BusTime', child: Text('Zeit vom Bus beziehen')),
                                        DropdownMenuItem(value: 'BusAzEl', child: Text('Azimut / Elevation vom Bus beziehen')),
                                      ],
                                      onChanged: (v) => setState(() => azElOption = v!),
                                    ),
                                    if (azElOption == 'BusTime') ...[
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        decoration: const InputDecoration(labelText: 'Gruppenadresse Zeit'),
                                        onSaved: (v) => timeAddress = v ?? '',
                                      ),
                                    ],
                                    if (azElOption == 'BusAzEl') ...[
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        decoration: const InputDecoration(labelText: 'Gruppenadresse Azimut'),
                                        onSaved: (v) => azimuthAddress = v ?? '',
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        decoration: const InputDecoration(labelText: 'Gruppenadresse Elevation'),
                                        onSaved: (v) => elevationAddress = v ?? '',
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                          : selectedPage == 'Sektoren'
                              ? SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Sektoren', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: () => setState(() => sectors.add(Sector())),
                                          ),
                                        ],
                                      ),
                                      for (int i = 0; i < sectors.length; i++)
                                        SectorWidget(
                                          key: ValueKey(i),
                                          sector: sectors[i],
                                          onRemove: () => setState(() => sectors.removeAt(i)),
                                        ),
                                    ],
                                  ),
                                )
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      const Text('Zeitschaltuhren Section'),
                                      // TODO: implement Zeitschaltuhren UI
                                    ],
                                  ),
                                ),
                ),
              ],
            )
          : selectedPage == 'Allgemein'
              ? Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Version
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Version'),
                          onSaved: (v) => version = v ?? '',
                        ),
                        const SizedBox(height: 16),
                        // Gruppenadresse Helligkeit
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Gruppenadresse Helligkeit'),
                          onSaved: (v) => brightnessAddress = v ?? '',
                        ),
                        const SizedBox(height: 16),
                        // Gruppenadresse Globalstrahlung
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Gruppenadresse Globalstrahlung'),
                          onSaved: (v) => irradianceAddress = v ?? '',
                        ),
                        const SizedBox(height: 24),
                        // Azimut/Elevation section
                        const Text('Azimut/Elevation'),
                        DropdownButtonFormField<String>(
                          value: azElOption,
                          items: const [
                            DropdownMenuItem(value: 'Internet', child: Text('Zeit aus dem Internet beziehen')),
                            DropdownMenuItem(value: 'BusTime', child: Text('Zeit vom Bus beziehen')),
                            DropdownMenuItem(value: 'BusAzEl', child: Text('Azimut / Elevation vom Bus beziehen')),
                          ],
                          onChanged: (v) => setState(() => azElOption = v!),
                        ),
                        if (azElOption == 'BusTime') ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: const InputDecoration(labelText: 'Gruppenadresse Zeit'),
                            onSaved: (v) => timeAddress = v ?? '',
                          ),
                        ],
                        if (azElOption == 'BusAzEl') ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: const InputDecoration(labelText: 'Gruppenadresse Azimut'),
                            onSaved: (v) => azimuthAddress = v ?? '',
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: const InputDecoration(labelText: 'Gruppenadresse Elevation'),
                            onSaved: (v) => elevationAddress = v ?? '',
                          ),
                        ],
                      ],
                    ),
                  ),
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
                        )
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('Zeitschaltuhren Section'),
                          // TODO: implement Zeitschaltuhren UI
                        ],
                      ),
                    ),
    );
  }
}

// Data models and helper widgets (to be implemented)

class Point {
  double x;
  double y;
  Point({this.x = 0, this.y = 0});
}

class Threshold {
  // TODO: define fields for address, DPT, thresholds, delays, dynamic
}

class Release {
  // TODO: define fields for group address and value
}

class Override {
  // TODO: define fields for group address and value
}