import 'dart:convert';

class TicketInfo {
  final String event;
  final String date;
  final String code;
  final bool isValid;
  final DateTime timestamp;
  final String? message;
  final String? errorCode;

  TicketInfo({
    required this.event,
    required this.date,
    required this.code,
    required this.isValid,
    required this.timestamp,
    this.message,
    this.errorCode,
  });

  factory TicketInfo.fromJson(Map<String, dynamic> json, String qrCode) {
    return TicketInfo(
      event: json['ticket_info']?['event'] ?? 'Evento desconocido',
      date: json['ticket_info']?['date'] ?? '',
      code: qrCode,
      isValid: json['valid'] ?? false,
      timestamp: DateTime.now(),
      message: json['message'],
      errorCode: json['error_code'],
    );
  }

  factory TicketInfo.fromBackendJson(Map<String, dynamic> json, {String? originalQrCode}) {
    // Maneja la respuesta del backend con estructura:
    // { "success": true, "message": "...", "data": { "ticketId": "...", "zona": "...", "fila": "...", "asiento": "...", "valid": true } }
    final data = json['data'] ?? json;
    
    // Intentar extraer información del QR original si está disponible
    Map<String, dynamic>? qrData;
    if (originalQrCode != null) {
      try {
        qrData = jsonDecode(originalQrCode);
      } catch (e) {
        // Si no se puede parsear, usar null
        qrData = null;
      }
    }
    
    return TicketInfo(
      event: 'Zona: ${qrData?['zona'] ?? data['zona'] ?? 'N/A'} | Fila: ${qrData?['fila'] ?? data['fila'] ?? 'N/A'} | Asiento: ${qrData?['asiento'] ?? data['asiento'] ?? 'N/A'}',
      date: DateTime.now().toIso8601String().substring(0, 10),
      code: qrData?['ticketId'] ?? data['ticketId'] ?? '',
      isValid: data['valid'] ?? false,
      timestamp: DateTime.now(),
      message: json['message'],
      errorCode: json['success'] == false ? 'VALIDATION_ERROR' : null,
    );
  }

  factory TicketInfo.offline(String qrCode) {
    return TicketInfo(
      event: 'Validación Offline',
      date: DateTime.now().toIso8601String(),
      code: qrCode,
      isValid: false,
      timestamp: DateTime.now(),
      message: 'Sin conexión - guardado para sincronización',
      errorCode: 'OFFLINE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event': event,
      'date': date,
      'code': code,
      'isValid': isValid,
      'timestamp': timestamp.toIso8601String(),
      'message': message,
      'errorCode': errorCode,
    };
  }

  String get displayCode {
    return code.length > 8 ? '${code.substring(0, 8)}...' : code;
  }

  String get displayTime {
    return timestamp.toString().substring(11, 19);
  }

  String get statusText {
    return isValid ? 'Válido' : 'Inválido';
  }
} 