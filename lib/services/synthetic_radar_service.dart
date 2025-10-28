import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../data/models/storm_nucleus.dart';

class SyntheticRadarPoint {
  final LatLng coordinate;
  final double dbz;
  final Color color;
  final StormSeverity severity;

  const SyntheticRadarPoint({
    required this.coordinate,
    required this.dbz,
    required this.color,
    required this.severity,
  });
}

class SyntheticRadarService {
  static Color? dbzToColor(double dbz) {
    if (dbz < 25) return null;

    int r, g, b;
    double alpha;

    if (dbz < 35) {
      final t = (dbz - 25) / 10;
      r = (100 + t * 30).round();
      g = (150 + t * 50).round();
      b = 255;
      alpha = 0.5 + (t * 0.15);
    } else if (dbz < 45) {
      final t = (dbz - 35) / 10;
      r = (130 + t * 125).round();
      g = (200 + t * 55).round();
      b = (255 - t * 155).round();
      alpha = 0.65 + (t * 0.15);
    } else if (dbz < 55) {
      final t = (dbz - 45) / 10;
      r = 255;
      g = (255 - t * 100).round();
      b = (100 - t * 100).round();
      alpha = 0.8 + (t * 0.1);
    } else {
      final t = math.min((dbz - 55) / 20, 1.0);
      r = 255;
      g = (155 - t * 155).round();
      b = (0 + t * 200).round();
      alpha = 0.9 + (t * 0.1);
    }

    return Color.fromRGBO(r, g, b, alpha);
  }

  static StormSeverity getSeverity(double dbz) {
    if (dbz >= 55) return StormSeverity.hail;
    if (dbz >= 40) return StormSeverity.electric;
    return StormSeverity.rain;
  }

  static List<SyntheticRadarPoint> convertRealRadarData(
    List<StormNucleus> nuclei,
    Map<LatLng, double> intensityMap,
  ) {
    if (nuclei.isEmpty || intensityMap.isEmpty) {
      return const [];
    }

    final points = <SyntheticRadarPoint>[];
    for (final entry in intensityMap.entries) {
      final dbz = entry.value;
      if (dbz < 25) continue;

      final color = dbzToColor(dbz);
      if (color == null) continue;

      points.add(
        SyntheticRadarPoint(
          coordinate: entry.key,
          dbz: dbz,
          color: color,
          severity: getSeverity(dbz),
        ),
      );
    }
    return points;
  }

  static (List<SyntheticRadarPoint>, List<StormNucleus>) generateTestData() {
    return (const [], const []);
  }
}
