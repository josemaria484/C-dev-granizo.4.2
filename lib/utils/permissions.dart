import 'package:permission_handler/permission_handler.dart';

enum PermissionResult {
  granted,
  denied,
  permanentlyDenied,
}

class AppPermissionHandler {
  static Future<PermissionResult> checkAndRequestLocationPermission() async {
    final status = await Permission.location.request();

    if (status.isGranted) {
      return PermissionResult.granted;
    } else if (status.isPermanentlyDenied) {
      return PermissionResult.permanentlyDenied;
    } else {
      return PermissionResult.denied;
    }
  }

  static String getPermissionMessage(PermissionResult result) {
    switch (result) {
      case PermissionResult.granted:
        return 'Permiso concedido';
      case PermissionResult.denied:
        return 'Permiso denegado. Se necesita acceso a la ubicación.';
      case PermissionResult.permanentlyDenied:
        return 'Permiso denegado permanentemente. Ve a Configuración → Permisos.';
    }
  }
}
