import 'sector.dart';
import 'timeswitch.dart';

double latitude = 0;
double longitude = 0;

String version = '';
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
