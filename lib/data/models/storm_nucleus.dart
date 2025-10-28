import 'package:latlong2/latlong.dart';

enum StormSeverity { rain, electric, hail }

typedef StormSeverityResolver = StormSeverity Function(double dbz);

class StormNucleus {
  final LatLng location;
  final double maxDbz;
  final int pixelCount;
  final double centerX;
  final double centerY;
  final double radiusPixels;
  final double radiusKm;
  final StormSeverity type;
  final double confidence;

  StormNucleus({
    required this.location,
    required this.maxDbz,
    required this.pixelCount,
    required this.centerX,
    required this.centerY,
    required this.radiusPixels,
    double? radiusKm,
    StormSeverity? type,
    this.confidence = 0.0,
  })  : radiusKm = radiusKm ?? 0.0,
        type = type ?? _severityFromDbz(maxDbz);

  LatLng get center => location;

  String get severityLabel {
    switch (type) {
      case StormSeverity.hail:
        return 'GRANIZO SEVERO';
      case StormSeverity.electric:
        return 'TORMENTA FUERTE';
      case StormSeverity.rain:
        return 'TORMENTA MODERADA';
    }
  }

  String get colorLevel {
    switch (type) {
      case StormSeverity.hail:
        return 'ROJA';
      case StormSeverity.electric:
        return 'NARANJA';
      case StormSeverity.rain:
        return maxDbz >= 30 ? 'AMARILLA' : 'AZUL';
    }
  }

  static StormSeverity _severityFromDbz(double dbz) {
    if (dbz >= 55) return StormSeverity.hail;
    if (dbz >= 40) return StormSeverity.electric;
    return StormSeverity.rain;
  }
}
