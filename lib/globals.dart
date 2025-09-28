import 'timeswitch.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'history.dart';

double latitude = 0;
double longitude = 0;

String version = '0.8.0';
String brightnessAddress = '';
String irradianceAddress = '';

// Azimuth/Elevation settings
String azElOption = 'Internet';
String timeAddress = '';
String azimuthAddress = '';
String elevationAddress = '';

// Threshold linkage
bool linkBrightnessIrradiance = false;

List<Sector> sectors = [];

// Weekly time switch programs
List<TimeProgram> timePrograms = [];

class Sector {
  String guid;
  String id;
  late final ValueNotifier<String> nameNotifier;
  double orientation;
  bool horizonLimit;
  List<Point> horizonPoints;
  List<Point> ceilingPoints;
  bool louvreTracking;
  double louvreSpacing;
  double louvreDepth;
  double louvreAngleAtZero;
  double louvreAngleAtHundred;
  double louvreMinimumChange;
  double louvreBuffer;
  String brightnessAddress;
  String louvreAngleAddress;
  String sunBoolAddress;
  bool useBrightness;
  bool useIrradiance;
  int? brightnessUpperThreshold;
  int? brightnessUpperDelay;
  int? brightnessLowerThreshold;
  int? brightnessLowerDelay;
  String irradianceAddress;
  int? irradianceUpperThreshold;
  int? irradianceUpperDelay;
  int? irradianceLowerThreshold;
  int? irradianceLowerDelay;
  String brightnessIrradianceLink;
  String facadeAddress;
  LatLng? facadeStart;
  LatLng? facadeEnd;

  Sector({
    String? guid,
    this.id = '',
    String name = '',
    this.orientation = 0,
    this.useBrightness = true,
    this.useIrradiance = true,
    this.horizonLimit = false,
    List<Point>? horizonPoints,
    List<Point>? ceilingPoints,
    this.louvreTracking = false,
    this.louvreSpacing = 0,
    this.louvreDepth = 0,
    this.louvreAngleAtZero = 90,
    this.louvreAngleAtHundred = 0,
    this.louvreMinimumChange = 20,
    this.louvreBuffer = 5,
    this.brightnessAddress = '',
    this.louvreAngleAddress = '',
    this.sunBoolAddress = '',
    this.irradianceAddress = '',
    this.brightnessIrradianceLink = 'Und',
    this.facadeAddress = '',
    this.facadeStart,
    this.facadeEnd,
  }) : guid = guid ?? const Uuid().v4(),
       horizonPoints = horizonPoints ?? [],
       ceilingPoints = ceilingPoints ?? [] {
    nameNotifier = ValueNotifier<String>(name);
  }

  String get name => nameNotifier.value;
  set name(String value) {
    if (nameNotifier.value == value) {
      return;
    }
    nameNotifier.value = value;
    HistoryBinding.requestCapture();
  }
}

class Point {
  double x;
  double y;
  Point({this.x = 0, this.y = 0});
}
