import 'package:flutter/material.dart';

/// Constantes de la aplicación Validador de Tickets
class AppConstants {
  // Información de la app
  static const String appName = 'Validador de Tickets';
  static const String appVersion = '1.0.0';
  static const String deviceId = 'FLUTTER_SCANNER_001';

  // URLs y configuración de red
  static const String defaultApiUrl = 'https://api.example.com';
  static const Duration networkTimeout = Duration(seconds: 10);
  static const Duration connectionTestTimeout = Duration(seconds: 5);

  // Configuración de UI
  static const Duration animationDuration = Duration(milliseconds: 500);
  static const Duration backgroundAnimationDuration = Duration(milliseconds: 800);
  static const Duration autoResetDuration = Duration(seconds: 3);
  static const int maxHistoryItems = 10;

  // Colores de estado
  static const Color readyColor = Color(0xFF2E3B4E);
  static const Color validatingColor = Colors.orange;
  static const Color validColor = Colors.green;
  static const Color invalidColor = Colors.red;

  // Colores de UI
  static const Color primaryColor = Colors.blue;
  static const Color whiteTransparent70 = Color(0xB3FFFFFF);
  static const Color whiteTransparent80 = Color(0xCCFFFFFF);
  static const Color whiteTransparent90 = Color(0xE6FFFFFF);
  static const Color whiteTransparent20 = Color(0x33FFFFFF);

  // Tamaños de fuente
  static const double titleFontSize = 32.0;
  static const double messageFontSize = 24.0;
  static const double bodyFontSize = 16.0;
  static const double captionFontSize = 14.0;
  static const double smallFontSize = 12.0;

  // Iconos por estado
  static const IconData readyIcon = Icons.qr_code_scanner;
  static const IconData validatingIcon = Icons.hourglass_empty;
  static const IconData validIcon = Icons.check_circle;
  static const IconData invalidIcon = Icons.error;
  static const IconData historyIcon = Icons.history;
  static const IconData settingsIcon = Icons.settings;
  static const IconData wifiIcon = Icons.wifi;
  static const IconData wifiOffIcon = Icons.wifi_off;

  // Rutas de audio
  static const String successSoundPath = 'sounds/success.mp3';
  static const String errorSoundPath = 'sounds/error.mp3';

  // Mensajes de estado
  static const String readyMessage = 'Listo para escanear';
  static const String validatingMessage = 'Validando ticket...';
  static const String validMessage = '¡Ticket Válido!';
  static const String invalidMessage = 'Código Inválido';
  static const String offlineMessage = 'Sin conexión - guardado para sincronización';
  static const String connectionErrorMessage = 'Error de conexión';

  // Configuración de SharedPreferences
  static const String apiUrlKey = 'api_url';
  static const String offlineValidationsKey = 'offline_validations';
  static const String volumeKey = 'sound_volume';
  static const String vibrationEnabledKey = 'vibration_enabled';

  // Configuración de API
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'User-Agent': 'TicketScanner/1.0',
  };

  // Estados de validación como strings
  static const String readyState = 'ready';
  static const String validatingState = 'validating';
  static const String validState = 'valid';
  static const String invalidState = 'invalid';

  // Configuración de QR
  static const int maxQrCodeLength = 500;
  static const int displayCodeLength = 8;

  // Configuración de UI responsiva
  static const double scanAreaSize = 200.0;
  static const double scanBorderWidth = 3.0;
  static const double scanBorderRadius = 20.0;
  static const double iconSize = 80.0;
  static const double buttonIconSize = 20.0;

  // Padding y márgenes
  static const EdgeInsets defaultPadding = EdgeInsets.all(20.0);
  static const EdgeInsets smallPadding = EdgeInsets.all(8.0);
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: 20.0);
  static const EdgeInsets verticalPadding = EdgeInsets.symmetric(vertical: 20.0);

  // Configuración de cards
  static const double cardElevation = 2.0;
  static const double cardBorderRadius = 8.0;

  // Configuración de listas
  static const double listItemHeight = 72.0;
  static const double historySheetHeight = 400.0;

  // Configuración de validación
  static const int minQrCodeLength = 3;
  static const String qrCodePattern = r'^[A-Za-z0-9\-_]+$';

  // Mensajes de error específicos
  static const Map<String, String> errorMessages = {
    'INVALID_CODE': 'Código QR inválido',
    'ALREADY_USED': 'Ticket ya utilizado',
    'EXPIRED': 'Ticket expirado',
    'NOT_FOUND': 'Ticket no encontrado',
    'NETWORK_ERROR': 'Error de red',
    'TIMEOUT': 'Tiempo de conexión agotado',
    'OFFLINE': 'Sin conexión a internet',
  };

  // Configuración de desarrollo
  static const bool debugMode = true;
  static const bool enableLogging = true;
  static const String logTag = 'TicketScanner';
}

/// Extensiones útiles para temas y colores
extension AppTheme on ThemeData {
  Color get readyColor => AppConstants.readyColor;
  Color get validatingColor => AppConstants.validatingColor;
  Color get validColor => AppConstants.validColor;
  Color get invalidColor => AppConstants.invalidColor;
}

/// Extensiones para BuildContext
extension AppContext on BuildContext {
  // Shortcuts para navegación
  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Shortcuts para temas
  Color get primaryColor => Theme.of(this).primaryColor;
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  // Responsive design helpers
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isTablet => screenWidth > 600;
  bool get isMobile => screenWidth <= 600;
} 