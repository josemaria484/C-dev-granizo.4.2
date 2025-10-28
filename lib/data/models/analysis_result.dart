import 'dart:ui' as ui;
import 'storm_nucleus.dart';

class AnalysisResult {
  final List<StormNucleus> nuclei;
  final Map<String, int> nucleiByLevel;
  final int totalPixelsAnalyzed;
  final ui.Image? uiOverlayImage;

  AnalysisResult({
    required this.nuclei,
    required this.nucleiByLevel,
    required this.totalPixelsAnalyzed,
    this.uiOverlayImage,
  });
}
