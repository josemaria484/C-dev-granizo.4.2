import 'dart:typed_data';
import 'package:latlong2/latlong.dart';

class RadarBounds {
  final LatLng southWest;
  final LatLng northEast;

  const RadarBounds({
    required this.southWest,
    required this.northEast,
  });

  static const RadarBounds defaultMendoza = RadarBounds(
    southWest: LatLng(-36.0, -70.0),
    northEast: LatLng(-33.0, -66.5),
  );
}

class RadarData {
  final Uint8List imageBytes;
  final DateTime timestamp;
  final String source;
  final RadarBounds bounds;

  const RadarData({
    required this.imageBytes,
    required this.timestamp,
    this.source = 'DACC',
    this.bounds = RadarBounds.defaultMendoza,
  });

  factory RadarData.fromCache({
    required Uint8List imageBytes,
    required DateTime downloadedAt,
    required String sourceUrl,
    RadarBounds bounds = RadarBounds.defaultMendoza,
  }) {
    return RadarData(
      imageBytes: imageBytes,
      timestamp: downloadedAt,
      source: sourceUrl,
      bounds: bounds,
    );
  }

  RadarData copyWith({
    Uint8List? imageBytes,
    DateTime? timestamp,
    String? source,
    RadarBounds? bounds,
  }) {
    return RadarData(
      imageBytes: imageBytes ?? this.imageBytes,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      bounds: bounds ?? this.bounds,
    );
  }

  int get sizeInBytes => imageBytes.lengthInBytes;

  String get sizeFormatted {
    final kb = sizeInBytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  int get ageInMinutes {
    final diff = DateTime.now().difference(timestamp);
    return diff.inMinutes;
  }

  bool isExpired(int ttlMinutes) {
    return DateTime.now().difference(timestamp) > Duration(minutes: ttlMinutes);
  }

  DateTime get downloadedAt => timestamp;

  String get sourceUrl => source;
}
