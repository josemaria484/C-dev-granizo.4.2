import 'dart:ui' as ui;
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:latlong2/latlong.dart';
import '../../data/models/radar_data.dart';
import '../../data/models/storm_nucleus.dart';
import '../../data/models/analysis_result.dart';
import '../../services/synthetic_cloud_generator.dart';
import 'tflite_storm_detector.dart';

class ImageAnalyzer {
  static bool useAIDetection = false;

  static Future<AnalysisResult> analyzeRadarImage({
    required RadarData radarData,
    double minDbz = 30.0,
    int minPixels = 500,
    bool generateOverlay = true,
  }) async {
    try {
      final radarImage = img.decodeImage(radarData.imageBytes);
      if (radarImage == null) {
        throw Exception('No se pudo decodificar imagen del radar');
      }

      List<StormNucleus> nuclei;

      if (useAIDetection) {
        nuclei = await TFLiteStormDetector.detectWithAI(
          radarImage,
          radarData.bounds.southWest,
          radarData.bounds.northEast,
        );
      } else {
        nuclei = _detectNuclei(
          radarImage,
          radarData.bounds.southWest,
          radarData.bounds.northEast,
          minDbz,
          minPixels,
        );
      }

      ui.Image? overlayImage;
      if (generateOverlay && nuclei.isNotEmpty) {
        overlayImage = await SyntheticCloudGenerator.generateCloudOverlay(
          nuclei: nuclei,
          originalRadarImage: radarImage,
          southWest: radarData.bounds.southWest,
          northEast: radarData.bounds.northEast,
        );
      }

      final byLevel = {
        'red': nuclei.where((n) => n.maxDbz >= 55).length,
        'orange': nuclei.where((n) => n.maxDbz >= 45 && n.maxDbz < 55).length,
        'yellow': nuclei.where((n) => n.maxDbz >= 30 && n.maxDbz < 45).length,
      };

      return AnalysisResult(
        nuclei: nuclei,
        nucleiByLevel: byLevel,
        totalPixelsAnalyzed: radarImage.width * radarImage.height,
        uiOverlayImage: overlayImage,
      );
    } catch (e, stackTrace) {
      print('Error en análisis: $e\n$stackTrace');
      rethrow;
    }
  }

  static List<StormNucleus> _detectNuclei(
      img.Image radarImage,
      LatLng southWest,
      LatLng northEast,
      double minDbz,
      int minPixels,
      ) {
    final nuclei = <StormNucleus>[];
    final width = radarImage.width;
    final height = radarImage.height;
    final visited = List.generate(height, (_) => List.filled(width, false));

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (visited[y][x]) continue;

        final color = radarImage.getPixel(x, y);
        final dbz = _estimateDbzFromColor(color);

        if (dbz >= minDbz) {
          final region = _floodFill(radarImage, visited, x, y, minDbz);

          if (region.pixels.length >= minPixels) {
            int sumX = 0, sumY = 0;
            for (final p in region.pixels) {
              sumX += p.x;
              sumY += p.y;
            }
            final centerPixelX = sumX ~/ region.pixels.length;
            final centerPixelY = sumY ~/ region.pixels.length;

            final normalizedX = centerPixelX / width;
            final normalizedY = centerPixelY / height;

            double totalDistance = 0;
            for (final p in region.pixels) {
              final dx = p.x - centerPixelX;
              final dy = p.y - centerPixelY;
              totalDistance += sqrt(dx * dx + dy * dy);
            }
            final avgRadius = totalDistance / region.pixels.length;

            final lat = southWest.latitude +
                (1.0 - normalizedY) * (northEast.latitude - southWest.latitude);
            final lon = southWest.longitude +
                normalizedX * (northEast.longitude - southWest.longitude);

            nuclei.add(StormNucleus(
              location: LatLng(lat, lon),
              maxDbz: region.maxDbz,
              pixelCount: region.pixels.length,
              centerX: normalizedX,
              centerY: normalizedY,
              radiusPixels: avgRadius,
            ));
          }
        }
      }
    }

    return nuclei;
  }

  static double _estimateDbzFromColor(int color) {
    final r = img.getRed(color);
    final g = img.getGreen(color);
    final b = img.getBlue(color);

    if (r > 200 && g < 100 && b < 100) return 60.0;
    if (r > 200 && g > 150 && b < 100) return 50.0;
    if (r > 150 && g > 150 && b < 100) return 40.0;
    if (r < 100 && g > 150 && b < 100) return 35.0;
    if (r < 100 && g < 150 && b > 200) return 25.0;

    return 0.0;
  }

  static _Region _floodFill(
      img.Image image,
      List<List<bool>> visited,
      int startX,
      int startY,
      double minDbz,
      ) {
    final pixels = <_Pixel>[];
    final queue = <_Point>[_Point(startX, startY)];
    visited[startY][startX] = true;
    double maxDbz = 0;

    while (queue.isNotEmpty) {
      final point = queue.removeAt(0);
      final x = point.x;
      final y = point.y;

      final color = image.getPixel(x, y);
      final dbz = _estimateDbzFromColor(color);
      maxDbz = max(maxDbz, dbz);

      pixels.add(_Pixel(x: x, y: y));

      final neighbors = [
        _Point(x + 1, y),
        _Point(x - 1, y),
        _Point(x, y + 1),
        _Point(x, y - 1),
      ];

      for (final neighbor in neighbors) {
        final nx = neighbor.x;
        final ny = neighbor.y;

        if (nx >= 0 && nx < image.width && ny >= 0 && ny < image.height) {
          if (!visited[ny][nx]) {
            final neighborColor = image.getPixel(nx, ny);
            final neighborDbz = _estimateDbzFromColor(neighborColor);

            if (neighborDbz >= minDbz * 0.7) {
              visited[ny][nx] = true;
              queue.add(neighbor);
            }
          }
        }
      }
    }

    return _Region(pixels: pixels, maxDbz: maxDbz);
  }
}

class _Pixel {
  final int x, y;
  _Pixel({required this.x, required this.y});
}

class _Region {
  final List<_Pixel> pixels;
  final double maxDbz;
  _Region({required this.pixels, required this.maxDbz});
}

class _Point {
  final int x, y;
  _Point(this.x, this.y);
}
