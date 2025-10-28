import 'package:latlong2/latlong.dart';

class StormNucleus {
  final LatLng location;  // ⭐ Cambió de 'center' a 'location'
  final double maxDbz;
  final int pixelCount;
  final double centerX;
  final double centerY;
  final double radiusPixels;

  StormNucleus({
    required this.location,
    required this.maxDbz,
    required this.pixelCount,
    required this.centerX,
    required this.centerY,
    required this.radiusPixels,
  });

  // Alias para compatibilidad
  LatLng get center => location;

  String get severityLabel {
    if (maxDbz >= 55) return 'GRANIZO SEVERO';
    if (maxDbz >= 45) return 'TORMENTA FUERTE';
    if (maxDbz >= 30) return 'TORMENTA MODERADA';
    return 'LLUVIA';
  }

  String get colorLevel {
    if (maxDbz >= 55) return 'ROJA';
    if (maxDbz >= 45) return 'NARANJA';
    if (maxDbz >= 30) return 'AMARILLA';
    return 'AZUL';
  }
}
