import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:latlong2/latlong.dart';
import '../data/models/storm_nucleus.dart';
import 'dart:math';

class SyntheticCloudGenerator {
  static Future<ui.Image> generateCloudOverlay({
    required List<StormNucleus> nuclei,
    required img.Image originalRadarImage,
    required LatLng southWest,
    required LatLng northEast,
  }) async {
    final width = originalRadarImage.width;
    final height = originalRadarImage.height;

    final activeArea = _calculateActiveArea(originalRadarImage);
    if (activeArea == null) {
      return _createEmptyImage(width, height);
    }

    final image = img.Image(width, height);
    img.fill(image, img.getColor(0, 0, 0, 0));

    int validClouds = 0;
    for (final nucleus in nuclei) {
      final centerPixelX = (nucleus.centerX * width).toInt();
      final centerPixelY = (nucleus.centerY * height).toInt();

      if (_isInsideActiveArea(centerPixelX, centerPixelY, activeArea)) {
        _drawSyntheticCloud(image, nucleus, width, height, activeArea);
        validClouds++;
      }
    }

    if (validClouds == 0) {
      return _createEmptyImage(width, height);
    }

    final pngBytes = img.encodePng(image);
    final codec = await ui.instantiateImageCodec(
      Uint8List.fromList(pngBytes),
    );
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static _ActiveArea? _calculateActiveArea(img.Image radarImage) {
    int? minX, minY, maxX, maxY;

    for (int y = 0; y < radarImage.height; y++) {
      for (int x = 0; x < radarImage.width; x++) {
        final color = radarImage.getPixel(x, y);
        final alpha = img.getAlpha(color);

        if (alpha > 50 && !_isBackgroundColor(color)) {
          minX = minX == null ? x : (x < minX ? x : minX);
          maxX = maxX == null ? x : (x > maxX ? x : maxX);
          minY = minY == null ? y : (y < minY ? y : minY);
          maxY = maxY == null ? y : (y > maxY ? y : maxY);
        }
      }
    }

    if (minX == null) return null;

    final margin = 0.1;
    final expandX = ((maxX! - minX!) * margin).toInt();
    final expandY = ((maxY! - minY!) * margin).toInt();

    return _ActiveArea(
      minX: ((minX - expandX).clamp(0, radarImage.width - 1)).toInt(),
      maxX: ((maxX + expandX).clamp(0, radarImage.width - 1)).toInt(),
      minY: ((minY - expandY).clamp(0, radarImage.height - 1)).toInt(),
      maxY: ((maxY + expandY).clamp(0, radarImage.height - 1)).toInt(),
    );
  }

  static bool _isBackgroundColor(int color) {
    final r = img.getRed(color);
    final g = img.getGreen(color);
    final b = img.getBlue(color);

    if (r < 30 && g < 30 && b < 30) return true;
    if (r > 200 && g > 200 && b > 200) return true;
    if ((r - g).abs() < 20 && (g - b).abs() < 20) return true;

    return false;
  }

  static bool _isInsideActiveArea(int x, int y, _ActiveArea area) {
    return x >= area.minX && x <= area.maxX && y >= area.minY && y <= area.maxY;
  }

  static void _drawSyntheticCloud(
      img.Image canvas,
      StormNucleus nucleus,
      int canvasWidth,
      int canvasHeight,
      _ActiveArea activeArea,
      ) {
    final centerX = (nucleus.centerX * canvasWidth).toInt();
    final centerY = (nucleus.centerY * canvasHeight).toInt();
    final radiusPixels = (nucleus.radiusPixels * 1.5).toInt();
    final cloudColor = _getColorForDbz(nucleus.maxDbz);

    for (int dy = -radiusPixels; dy <= radiusPixels; dy++) {
      for (int dx = -radiusPixels; dx <= radiusPixels; dx++) {
        final x = centerX + dx;
        final y = centerY + dy;

        if (x < 0 || x >= canvasWidth || y < 0 || y >= canvasHeight) continue;
        if (!_isInsideActiveArea(x, y, activeArea)) continue;

        final distanceSq = (dx * dx + dy * dy).toDouble();
        final radiusSq = radiusPixels * radiusPixels.toDouble();

        if (distanceSq > radiusSq) continue;

        final normalizedDistance = distanceSq / radiusSq;
        final gradientFactor = 1.0 - normalizedDistance;
        final smoothFactor = gradientFactor * gradientFactor;
        final alpha = (cloudColor.a * smoothFactor).toInt().clamp(0, 255);

        final currentColor = canvas.getPixel(x, y);
        final currentAlpha = img.getAlpha(currentColor);

        if (currentAlpha < alpha) {
          canvas.setPixel(
            x,
            y,
            img.getColor(cloudColor.r, cloudColor.g, cloudColor.b, alpha),
          );
        }
      }
    }
  }

  static _CloudColor _getColorForDbz(double dbz) {
    int r, g, b, a;

    if (dbz < 30) {
      r = 100; g = 150; b = 255; a = 100;
    } else if (dbz < 45) {
      final t = (dbz - 30) / 15;
      r = (200 + t * 55).toInt();
      g = (200 + t * 55).toInt();
      b = (100 - t * 100).toInt();
      a = (140 + t * 60).toInt();
    } else if (dbz < 55) {
      final t = (dbz - 45) / 10;
      r = 255;
      g = (255 - t * 100).toInt();
      b = 0;
      a = (200 + t * 40).toInt();
    } else {
      final t = ((dbz - 55) / 20).clamp(0.0, 1.0);
      r = 255;
      g = (155 - t * 155).toInt();
      b = (0 + t * 100).toInt();
      a = (240 + t * 15).toInt();
    }

    return _CloudColor(r: r, g: g, b: b, a: a);
  }

  static Future<ui.Image> _createEmptyImage(int width, int height) async {
    final image = img.Image(width, height);
    img.fill(image, img.getColor(0, 0, 0, 0));
    final pngBytes = img.encodePng(image);
    final codec = await ui.instantiateImageCodec(
      Uint8List.fromList(pngBytes),
    );
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}

class _CloudColor {
  final int r, g, b, a;
  _CloudColor({required this.r, required this.g, required this.b, required this.a});
}

class _ActiveArea {
  final int minX, maxX, minY, maxY;
  _ActiveArea({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });
}
