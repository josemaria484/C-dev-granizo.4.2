import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:latlong2/latlong.dart';
import '../../data/models/storm_nucleus.dart';
import 'dart:math';

class TFLiteStormDetector {
  static Interpreter? _interpreter;
  static bool _initialized = false;

  static const int inputWidth = 640;
  static const int inputHeight = 480;

  static Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/storm_detector.tflite',
      );
      _interpreter!.allocateTensors();
      _initialized = true;
      print('✅ Modelo IA cargado');
      return true;
    } catch (e) {
      print('ℹ️  Modelo IA no encontrado - usando detección clásica');
      _initialized = false;
      return false;
    }
  }

  static Future<List<StormNucleus>> detectWithAI(
      img.Image radarImage,
      LatLng southWest,
      LatLng northEast,
      ) async {
    if (!_initialized) {
      await initialize();
      if (!_initialized) return [];
    }

    try {
      final input = _preprocessImage(radarImage);

      final output = List.generate(
        1,
            (_) => List.generate(
          inputHeight,
              (_) => List.generate(
            inputWidth,
                (_) => List.filled(4, 0.0),
          ),
        ),
      );

      _interpreter!.run(input, output);

      return _extractNuclei(output, radarImage.width, radarImage.height,
          southWest, northEast);
    } catch (e) {
      print('Error en IA: $e');
      return [];
    }
  }

  static List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    final resized = img.copyResize(
      image,
      width: inputWidth,
      height: inputHeight,
    );

    return List.generate(
      1,
          (_) => List.generate(
        inputHeight,
            (y) => List.generate(
          inputWidth,
              (x) {
            final color = resized.getPixel(x, y);
            return [
              img.getRed(color) / 255.0,
              img.getGreen(color) / 255.0,
              img.getBlue(color) / 255.0,
            ];
          },
        ),
      ),
    );
  }

  static List<StormNucleus> _extractNuclei(
      List<List<List<List<double>>>> output,
      int originalWidth,
      int originalHeight,
      LatLng southWest,
      LatLng northEast,
      ) {
    return [];
  }

  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _initialized = false;
  }
}
