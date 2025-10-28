import '../data/models/radar_data.dart';

class DACCDownloader {
  /// Descarga el último radar del DACC
  /// Por ahora retorna datos de prueba
  static Future<(RadarData?, String)> getLatestRadar({
    bool forceRefresh = false,
  }) async {
    try {
      // TODO: Implementar descarga real del DACC
      // Por ahora retornar null para que no haya errores

      return (null, 'not_implemented');
    } catch (e) {
      return (null, 'error: $e');
    }
  }
}
