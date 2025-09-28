import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

import 'globals.dart';
import 'models/time_program.dart';

class ConfigSnapshot {
  final String version;
  final String brightnessAddress;
  final String irradianceAddress;
  final String latitudeText;
  final String longitudeText;
  final double latitude;
  final double longitude;
  final String azElOption;
  final String timeAddress;
  final String azimuthAddress;
  final String elevationAddress;
  final bool linkBrightnessIrradiance;
  final List<SectorSnapshot> sectors;
  final List<TimeProgramSnapshot> timePrograms;

  const ConfigSnapshot({
    required this.version,
    required this.brightnessAddress,
    required this.irradianceAddress,
    required this.latitudeText,
    required this.longitudeText,
    required this.latitude,
    required this.longitude,
    required this.azElOption,
    required this.timeAddress,
    required this.azimuthAddress,
    required this.elevationAddress,
    required this.linkBrightnessIrradiance,
    required this.sectors,
    required this.timePrograms,
  });

  factory ConfigSnapshot.capture() {
    return ConfigSnapshot(
      version: version,
      brightnessAddress: brightnessAddress,
      irradianceAddress: irradianceAddress,
      latitudeText: latitudeInput,
      longitudeText: longitudeInput,
      latitude: latitude,
      longitude: longitude,
      azElOption: azElOption,
      timeAddress: timeAddress,
      azimuthAddress: azimuthAddress,
      elevationAddress: elevationAddress,
      linkBrightnessIrradiance: linkBrightnessIrradiance,
      sectors: sectors.map(SectorSnapshot.fromSector).toList(),
      timePrograms: timePrograms.map(TimeProgramSnapshot.fromProgram).toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ConfigSnapshot) return false;
    return version == other.version &&
        brightnessAddress == other.brightnessAddress &&
        irradianceAddress == other.irradianceAddress &&
        latitudeText == other.latitudeText &&
        longitudeText == other.longitudeText &&
        latitude == other.latitude &&
        longitude == other.longitude &&
        azElOption == other.azElOption &&
        timeAddress == other.timeAddress &&
        azimuthAddress == other.azimuthAddress &&
        elevationAddress == other.elevationAddress &&
        linkBrightnessIrradiance == other.linkBrightnessIrradiance &&
        const ListEquality<SectorSnapshot>().equals(sectors, other.sectors) &&
        const ListEquality<TimeProgramSnapshot>().equals(timePrograms, other.timePrograms);
  }

  @override
  int get hashCode => Object.hash(
        version,
        brightnessAddress,
        irradianceAddress,
        latitudeText,
        longitudeText,
        latitude,
        longitude,
        azElOption,
        timeAddress,
        azimuthAddress,
        elevationAddress,
        linkBrightnessIrradiance,
        const ListEquality<SectorSnapshot>().hash(sectors),
        const ListEquality<TimeProgramSnapshot>().hash(timePrograms),
      );
}

class SectorSnapshot {
  final String guid;
  final String id;
  final String name;
  final double orientation;
  final bool horizonLimit;
  final List<PointSnapshot> horizonPoints;
  final List<PointSnapshot> ceilingPoints;
  final bool louvreTracking;
  final double louvreSpacing;
  final double louvreDepth;
  final double louvreAngleAtZero;
  final double louvreAngleAtHundred;
  final double louvreMinimumChange;
  final double louvreBuffer;
  final String brightnessAddress;
  final String louvreAngleAddress;
  final String sunBoolAddress;
  final bool useBrightness;
  final bool useIrradiance;
  final int? brightnessUpperThreshold;
  final int? brightnessUpperDelay;
  final int? brightnessLowerThreshold;
  final int? brightnessLowerDelay;
  final String irradianceAddress;
  final int? irradianceUpperThreshold;
  final int? irradianceUpperDelay;
  final int? irradianceLowerThreshold;
  final int? irradianceLowerDelay;
  final String brightnessIrradianceLink;
  final String facadeAddress;
  final LatLngSnapshot? facadeStart;
  final LatLngSnapshot? facadeEnd;

  const SectorSnapshot({
    required this.guid,
    required this.id,
    required this.name,
    required this.orientation,
    required this.horizonLimit,
    required this.horizonPoints,
    required this.ceilingPoints,
    required this.louvreTracking,
    required this.louvreSpacing,
    required this.louvreDepth,
    required this.louvreAngleAtZero,
    required this.louvreAngleAtHundred,
    required this.louvreMinimumChange,
    required this.louvreBuffer,
    required this.brightnessAddress,
    required this.louvreAngleAddress,
    required this.sunBoolAddress,
    required this.useBrightness,
    required this.useIrradiance,
    required this.brightnessUpperThreshold,
    required this.brightnessUpperDelay,
    required this.brightnessLowerThreshold,
    required this.brightnessLowerDelay,
    required this.irradianceAddress,
    required this.irradianceUpperThreshold,
    required this.irradianceUpperDelay,
    required this.irradianceLowerThreshold,
    required this.irradianceLowerDelay,
    required this.brightnessIrradianceLink,
    required this.facadeAddress,
    required this.facadeStart,
    required this.facadeEnd,
  });

  factory SectorSnapshot.fromSector(Sector sector) {
    return SectorSnapshot(
      guid: sector.guid,
      id: sector.id,
      name: sector.name,
      orientation: sector.orientation,
      horizonLimit: sector.horizonLimit,
      horizonPoints: sector.horizonPoints
          .map((p) => PointSnapshot(x: p.x, y: p.y))
          .toList(),
      ceilingPoints: sector.ceilingPoints
          .map((p) => PointSnapshot(x: p.x, y: p.y))
          .toList(),
      louvreTracking: sector.louvreTracking,
      louvreSpacing: sector.louvreSpacing,
      louvreDepth: sector.louvreDepth,
      louvreAngleAtZero: sector.louvreAngleAtZero,
      louvreAngleAtHundred: sector.louvreAngleAtHundred,
      louvreMinimumChange: sector.louvreMinimumChange,
      louvreBuffer: sector.louvreBuffer,
      brightnessAddress: sector.brightnessAddress,
      louvreAngleAddress: sector.louvreAngleAddress,
      sunBoolAddress: sector.sunBoolAddress,
      useBrightness: sector.useBrightness,
      useIrradiance: sector.useIrradiance,
      brightnessUpperThreshold: sector.brightnessUpperThreshold,
      brightnessUpperDelay: sector.brightnessUpperDelay,
      brightnessLowerThreshold: sector.brightnessLowerThreshold,
      brightnessLowerDelay: sector.brightnessLowerDelay,
      irradianceAddress: sector.irradianceAddress,
      irradianceUpperThreshold: sector.irradianceUpperThreshold,
      irradianceUpperDelay: sector.irradianceUpperDelay,
      irradianceLowerThreshold: sector.irradianceLowerThreshold,
      irradianceLowerDelay: sector.irradianceLowerDelay,
      brightnessIrradianceLink: sector.brightnessIrradianceLink,
      facadeAddress: sector.facadeAddress,
      facadeStart: sector.facadeStart == null
          ? null
          : LatLngSnapshot.fromLatLng(sector.facadeStart!),
      facadeEnd: sector.facadeEnd == null
          ? null
          : LatLngSnapshot.fromLatLng(sector.facadeEnd!),
    );
  }

  Sector toSector() {
    final sector = Sector(
      guid: guid,
      id: id,
      name: name,
      orientation: orientation,
      useBrightness: useBrightness,
      useIrradiance: useIrradiance,
      horizonLimit: horizonLimit,
      horizonPoints: horizonPoints.map((p) => p.toPoint()).toList(),
      ceilingPoints: ceilingPoints.map((p) => p.toPoint()).toList(),
      louvreTracking: louvreTracking,
      louvreSpacing: louvreSpacing,
      louvreDepth: louvreDepth,
      louvreAngleAtZero: louvreAngleAtZero,
      louvreAngleAtHundred: louvreAngleAtHundred,
      louvreMinimumChange: louvreMinimumChange,
      louvreBuffer: louvreBuffer,
      brightnessAddress: brightnessAddress,
      louvreAngleAddress: louvreAngleAddress,
      sunBoolAddress: sunBoolAddress,
      irradianceAddress: irradianceAddress,
      brightnessIrradianceLink: brightnessIrradianceLink,
      facadeAddress: facadeAddress,
      facadeStart: facadeStart?.toLatLng(),
      facadeEnd: facadeEnd?.toLatLng(),
    );
    sector.brightnessUpperThreshold = brightnessUpperThreshold;
    sector.brightnessUpperDelay = brightnessUpperDelay;
    sector.brightnessLowerThreshold = brightnessLowerThreshold;
    sector.brightnessLowerDelay = brightnessLowerDelay;
    sector.irradianceUpperThreshold = irradianceUpperThreshold;
    sector.irradianceUpperDelay = irradianceUpperDelay;
    sector.irradianceLowerThreshold = irradianceLowerThreshold;
    sector.irradianceLowerDelay = irradianceLowerDelay;
    return sector;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SectorSnapshot) return false;
    return guid == other.guid &&
        id == other.id &&
        name == other.name &&
        orientation == other.orientation &&
        horizonLimit == other.horizonLimit &&
        const ListEquality<PointSnapshot>().equals(horizonPoints, other.horizonPoints) &&
        const ListEquality<PointSnapshot>().equals(ceilingPoints, other.ceilingPoints) &&
        louvreTracking == other.louvreTracking &&
        louvreSpacing == other.louvreSpacing &&
        louvreDepth == other.louvreDepth &&
        louvreAngleAtZero == other.louvreAngleAtZero &&
        louvreAngleAtHundred == other.louvreAngleAtHundred &&
        louvreMinimumChange == other.louvreMinimumChange &&
        louvreBuffer == other.louvreBuffer &&
        brightnessAddress == other.brightnessAddress &&
        louvreAngleAddress == other.louvreAngleAddress &&
        sunBoolAddress == other.sunBoolAddress &&
        useBrightness == other.useBrightness &&
        useIrradiance == other.useIrradiance &&
        brightnessUpperThreshold == other.brightnessUpperThreshold &&
        brightnessUpperDelay == other.brightnessUpperDelay &&
        brightnessLowerThreshold == other.brightnessLowerThreshold &&
        brightnessLowerDelay == other.brightnessLowerDelay &&
        irradianceAddress == other.irradianceAddress &&
        irradianceUpperThreshold == other.irradianceUpperThreshold &&
        irradianceUpperDelay == other.irradianceUpperDelay &&
        irradianceLowerThreshold == other.irradianceLowerThreshold &&
        irradianceLowerDelay == other.irradianceLowerDelay &&
        brightnessIrradianceLink == other.brightnessIrradianceLink &&
        facadeAddress == other.facadeAddress &&
        facadeStart == other.facadeStart &&
        facadeEnd == other.facadeEnd;
  }

  @override
  int get hashCode => Object.hash(
        guid,
        id,
        name,
        orientation,
        horizonLimit,
        const ListEquality<PointSnapshot>().hash(horizonPoints),
        const ListEquality<PointSnapshot>().hash(ceilingPoints),
        louvreTracking,
        louvreSpacing,
        louvreDepth,
        louvreAngleAtZero,
        louvreAngleAtHundred,
        louvreMinimumChange,
        louvreBuffer,
        brightnessAddress,
        louvreAngleAddress,
        sunBoolAddress,
        useBrightness,
        useIrradiance,
        brightnessUpperThreshold,
        brightnessUpperDelay,
        brightnessLowerThreshold,
        brightnessLowerDelay,
        irradianceAddress,
        irradianceUpperThreshold,
        irradianceUpperDelay,
        irradianceLowerThreshold,
        irradianceLowerDelay,
        brightnessIrradianceLink,
        facadeAddress,
        facadeStart,
        facadeEnd,
      );
}

class PointSnapshot {
  final double x;
  final double y;

  const PointSnapshot({required this.x, required this.y});

  Point toPoint() => Point(x: x, y: y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PointSnapshot && x == other.x && y == other.y);

  @override
  int get hashCode => Object.hash(x, y);
}

class LatLngSnapshot {
  final double latitude;
  final double longitude;

  const LatLngSnapshot({required this.latitude, required this.longitude});

  factory LatLngSnapshot.fromLatLng(LatLng value) =>
      LatLngSnapshot(latitude: value.latitude, longitude: value.longitude);

  LatLng toLatLng() => LatLng(latitude, longitude);

  @override
  bool operator ==(Object other) => identical(this, other) ||
      (other is LatLngSnapshot && latitude == other.latitude && longitude == other.longitude);

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

class TimeProgramSnapshot {
  final String guid;
  final String name;
  final List<TimeCommandSnapshot> commands;

  const TimeProgramSnapshot({
    required this.guid,
    required this.name,
    required this.commands,
  });

  factory TimeProgramSnapshot.fromProgram(TimeProgram program) {
    return TimeProgramSnapshot(
      guid: program.guid,
      name: program.name,
      commands: program.commands.map(TimeCommandSnapshot.fromCommand).toList(),
    );
  }

  TimeProgram toProgram() {
    final program = TimeProgram(guid: guid, name: name);
    program.commands = commands.map((c) => c.toCommand()).toList();
    return program;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TimeProgramSnapshot) return false;
    return guid == other.guid &&
        name == other.name &&
        const ListEquality<TimeCommandSnapshot>().equals(commands, other.commands);
  }

  @override
  int get hashCode => Object.hash(
        guid,
        name,
        const ListEquality<TimeCommandSnapshot>().hash(commands),
      );
}

class TimeCommandSnapshot {
  final CommandType type;
  final int weekdaysMask;
  final String time;
  final int value;
  final String groupAddress;

  const TimeCommandSnapshot({
    required this.type,
    required this.weekdaysMask,
    required this.time,
    required this.value,
    required this.groupAddress,
  });

  factory TimeCommandSnapshot.fromCommand(TimeCommand command) {
    return TimeCommandSnapshot(
      type: command.type,
      weekdaysMask: command.weekdaysMask,
      time: command.time,
      value: command.value,
      groupAddress: command.groupAddress,
    );
  }

  TimeCommand toCommand() => TimeCommand(
        type: type,
        weekdaysMask: weekdaysMask,
        time: time,
        value: value,
        groupAddress: groupAddress,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TimeCommandSnapshot) return false;
    return type == other.type &&
        weekdaysMask == other.weekdaysMask &&
        time == other.time &&
        value == other.value &&
        groupAddress == other.groupAddress;
  }

  @override
  int get hashCode => Object.hash(type, weekdaysMask, time, value, groupAddress);
}

class UndoRedoController extends ChangeNotifier {
  final List<ConfigSnapshot> _undoStack = <ConfigSnapshot>[];
  final List<ConfigSnapshot> _redoStack = <ConfigSnapshot>[];
  bool _isRestoring = false;

  bool get isRestoring => _isRestoring;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void recordChange(ConfigSnapshot before, ConfigSnapshot after) {
    if (_isRestoring || before == after) {
      return;
    }
    _undoStack.add(before);
    _redoStack.clear();
    notifyListeners();
  }

  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  ConfigSnapshot? undo() {
    if (_undoStack.isEmpty) {
      return null;
    }
    final previous = _undoStack.removeLast();
    _redoStack.add(ConfigSnapshot.capture());
    notifyListeners();
    return previous;
  }

  ConfigSnapshot? redo() {
    if (_redoStack.isEmpty) {
      return null;
    }
    final next = _redoStack.removeLast();
    _undoStack.add(ConfigSnapshot.capture());
    notifyListeners();
    return next;
  }

  void beginRestoration() {
    _isRestoring = true;
  }

  void endRestoration() {
    _isRestoring = false;
  }
}

class UndoRedoScope extends InheritedWidget {
  final UndoRedoController controller;

  const UndoRedoScope({
    super.key,
    required this.controller,
    required super.child,
  });

  static UndoRedoController? maybeControllerOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<UndoRedoScope>()?.controller;
  }

  static UndoRedoController controllerOf(BuildContext context) {
    final controller = maybeControllerOf(context);
    assert(controller != null, 'No UndoRedoScope found in context');
    return controller!;
  }

  @override
  bool updateShouldNotify(covariant UndoRedoScope oldWidget) => controller != oldWidget.controller;
}

mixin UndoAwareState<T extends StatefulWidget> on State<T> {
  void recordChange(VoidCallback change) {
    final controller = UndoRedoScope.maybeControllerOf(context);
    if (controller == null || controller.isRestoring) {
      change();
      return;
    }
    final before = ConfigSnapshot.capture();
    change();
    final after = ConfigSnapshot.capture();
    controller.recordChange(before, after);
  }

  @override
  void setState(VoidCallback fn) {
    final controller = UndoRedoScope.maybeControllerOf(context);
    if (controller == null || controller.isRestoring) {
      super.setState(fn);
      return;
    }
    final before = ConfigSnapshot.capture();
    super.setState(fn);
    final after = ConfigSnapshot.capture();
    controller.recordChange(before, after);
  }

  @protected
  void setUiState(VoidCallback fn) {
    final controller = UndoRedoScope.maybeControllerOf(context);
    if (controller == null) {
      super.setState(fn);
      return;
    }
    final wasRestoring = controller.isRestoring;
    if (!wasRestoring) {
      controller.beginRestoration();
    }
    try {
      super.setState(fn);
    } finally {
      if (!wasRestoring) {
        controller.endRestoration();
      }
    }
  }
}
