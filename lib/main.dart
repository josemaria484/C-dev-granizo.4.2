// Archivo listo para copiar y pegar en Android Studio.
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image/image.dart' as img;

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
  LatLng _center = const LatLng(-34.6177, -68.3301); // San Rafael, Mendoza
  double _zoom = 9.5;

  Uint8List? _overlayBytes;

  // Bounds del overlay “nubes sintéticas”. Ajustá si tu PNG usa otros límites.
  // Sur/Oeste/Norte/Este en grados decimales.
  static final LatLngBounds _overlayBounds = LatLngBounds.fromPoints(const [
    LatLng(-35.20, -69.15), // S, W
    LatLng(-35.20, -67.50), // S, E
    LatLng(-34.05, -67.50), // N, E
    LatLng(-34.05, -69.15), // N, W
  ]);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadOverlayPng();
    setState(() {});
  }

  /// Carga un PNG de overlay desde assets si existe.
  /// Si no existe, genera un PNG 1x1 100% transparente.
  Future<void> _loadOverlayPng() async {
    Uint8List? bytes;
    try {
      // Cambiá el path si tu dataset usa otro nombre.
      final ByteData bd = await rootBundle.load('assets/datasets/last.png');
      bytes = bd.buffer.asUint8List();
    } catch (_) {
      // Genera PNG transparente 1x1 para no romper el OverlayImageLayer.
      final img.Image transparent = img.Image(1, 1);
      transparent.fill(img.getColor(0, 0, 0, 0));
      bytes = Uint8List.fromList(img.encodePng(transparent));
    }
    _overlayBytes = bytes;
  }

  Future<void> _onRefresh() async {
    // En tu app real, acá gatillás:
    // - descarga DACC
    // - análisis IA local
    // - regeneración del PNG con alfa
    await _loadOverlayPng();
    if (mounted) setState(() {});
  }

  Future<void> _goToMyLocation() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // No fuerza UI. Solo retorna.
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
      // flutter_map 6.x: move/rotate/zoom con MapController
      _mapController.move(_center, _zoom);
    }
  }

  Future<void> _shareMapLink() async {
    // Sin dependencias nuevas. Usa url_launcher para abrir Play Store o link público.
    final Uri uri = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.josecastillo.granizo');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
              // Capa base. No usar TileLayer.opacity según regla dura.
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.josecastillo.granizo',
                subdomains: const [],
              ),

              // Overlay de nubes sintéticas usando alfa del PNG.
              if (_overlayBytes != null)
                OverlayImageLayer(
                  overlayImages: [
                    OverlayImage(
                      bounds: _overlayBounds,
                      imageProvider: MemoryImage(_overlayBytes!),
                      // No establecer opacity aquí. El alfa viene en el PNG.
                    ),
                  ],
                ),
            ],
          ),

          // Botones: mantener posiciones y orden.
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CircleButton(
                  tooltip: 'Refrescar',
                  icon: Icons.refresh,
                  onPressed: _onRefresh,
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
  final VoidCallback onPressed;

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
