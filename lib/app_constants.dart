import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Granizo';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.josecastillo.granizo';

  static const int primaryColorValue = 0xFF2196F3; // Azul Material

  // Centro del mapa: San Rafael, Mendoza
  static const LatLng sanRafaelCenter = LatLng(-34.6177, -68.3301);
  static const double defaultZoom = 9.0;
}
