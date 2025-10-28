import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/ai/image_analyzer.dart';
import 'core/dacc/dacc_downloader.dart';
import 'data/models/analysis_result.dart';
import 'data/models/radar_data.dart';
import 'data/models/storm_nucleus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GranizoApp());
}

class GranizoApp extends StatelessWidget {
  const GranizoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Granizo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blueGrey,
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(-34.6177, -68.3301);
  double _zoom = 9.5;

  Uint8List? _overlayBytes;
  LatLngBounds _overlayBounds = LatLngBounds.fromPoints(const [
    LatLng(-36.0, -70.0),
    LatLng(-36.0, -66.5),
    LatLng(-33.0, -66.5),
    LatLng(-33.0, -70.0),
  ]);

  bool _isLoading = false;
  String? _statusMessage;
  List<StormNucleus> _nuclei = const [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _refreshRadar(forceRefresh: false);
  }

  Future<void> _refreshRadar({required bool forceRefresh}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Actualizando radar...';
    });

    try {
      final (radarData, result) =
          await DACCDownloader.getLatestRadar(forceRefresh: forceRefresh);

      final RadarData effectiveData = radarData ?? await _loadFallbackRadar();

      final AnalysisResult analysis = await ImageAnalyzer.analyzeRadarImage(
        radarData: effectiveData,
        minDbz: 30,
        minPixels: 400,
        generateOverlay: true,
      );

      _nuclei = analysis.nuclei;
      _overlayBounds = _boundsFromRadar(effectiveData.bounds);

      if (analysis.uiOverlayImage != null) {
        _overlayBytes = await _encodeOverlay(analysis.uiOverlayImage!);
      } else {
        _overlayBytes = null;
      }

      _statusMessage = _buildStatusMessage(effectiveData, result, _nuclei.length);
    } catch (e) {
      _statusMessage = 'No se pudo actualizar el radar';
      if (_overlayBytes == null) {
        final fallback = await _loadFallbackRadar();
        final analysis = await ImageAnalyzer.analyzeRadarImage(
          radarData: fallback,
          minDbz: 30,
          minPixels: 400,
          generateOverlay: true,
        );
        if (analysis.uiOverlayImage != null) {
          _overlayBytes = await _encodeOverlay(analysis.uiOverlayImage!);
          _overlayBounds = _boundsFromRadar(fallback.bounds);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<RadarData> _loadFallbackRadar() async {
    final data = await rootBundle.load('assets/testdata/radar_test.png');
    return RadarData(
      imageBytes: data.buffer.asUint8List(),
      timestamp: DateTime.now(),
      source: 'assets/testdata/radar_test.png',
      bounds: RadarBounds.defaultMendoza,
    );
  }

  LatLngBounds _boundsFromRadar(RadarBounds bounds) {
    return LatLngBounds.fromPoints([
      LatLng(bounds.southWest.latitude, bounds.southWest.longitude),
      LatLng(bounds.southWest.latitude, bounds.northEast.longitude),
      LatLng(bounds.northEast.latitude, bounds.northEast.longitude),
      LatLng(bounds.northEast.latitude, bounds.southWest.longitude),
    ]);
  }

  Future<Uint8List> _encodeOverlay(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('No se pudo codificar el overlay');
    }
    return byteData.buffer.asUint8List();
  }

  Future<void> _onRefresh() async {
    await _refreshRadar(forceRefresh: true);
  }

  Future<void> _goToMyLocation() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final Position pos =
        await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    _center = LatLng(pos.latitude, pos.longitude);
    _zoom = 12.0;
    if (mounted) {
      setState(() {});
      _mapController.move(_center, _zoom);
    }
  }

  Future<void> _shareMapLink() async {
    final Uri uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.josecastillo.granizo',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _buildStatusMessage(
    RadarData data,
    DownloadResult result,
    int nucleiCount,
  ) {
    final buffer = StringBuffer();
    buffer.write('Fuente: ${data.sourceUrl}');
    buffer.write(' · ');
    buffer.write('Actualizado hace ${data.ageInMinutes} min');
    if (result == DownloadResult.usedCache) {
      buffer.write(' (cache)');
    } else if (result == DownloadResult.noInternet) {
      buffer.write(' (sin internet)');
    }
    if (nucleiCount > 0) {
      buffer.write(' · Núcleos: $nucleiCount');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _zoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.josecastillo.granizo',
              ),
              if (_overlayBytes != null)
                OverlayImageLayer(
                  overlayImages: [
                    OverlayImage(
                      bounds: _overlayBounds,
                      imageProvider: MemoryImage(_overlayBytes!),
                    ),
                  ],
                ),
            ],
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_statusMessage != null)
            Positioned(
              left: 16,
              right: 16,
              top: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black87.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    _statusMessage!,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CircleButton(
                  tooltip: _isLoading ? 'Actualizando…' : 'Refrescar',
                  icon: Icons.refresh,
                  onPressed: _isLoading ? null : _onRefresh,
                ),
                const SizedBox(height: 12),
                _CircleButton(
                  tooltip: 'Mi ubicación',
                  icon: Icons.my_location,
                  onPressed: _goToMyLocation,
                ),
                const SizedBox(height: 12),
                _CircleButton(
                  tooltip: 'Compartir',
                  icon: Icons.share,
                  onPressed: _shareMapLink,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _CircleButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(icon, size: 20, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}
