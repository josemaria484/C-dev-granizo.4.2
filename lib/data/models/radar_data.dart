import 'dart:typed_data';
import 'package:latlong2/latlong.dart';

class RadarBounds {
  final LatLng southWest;
  final LatLng northEast;

  RadarBounds({
    required this.southWest,
    required this.northEast,
  });
}

class RadarData {
  final Uint8List imageBytes;
  final DateTime timestamp;
  final RadarBounds bounds;
  final int ageInMinutes;

  RadarData({
    required this.imageBytes,
    required this.timestamp,
    required this.bounds,
    required this.ageInMinutes,
  });
}
