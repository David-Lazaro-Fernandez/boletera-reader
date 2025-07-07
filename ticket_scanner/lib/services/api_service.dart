import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket_info.dart';

class ApiService {
  final String baseUrl;
  
  ApiService({required this.baseUrl});
  
  // Validate ticket and mark as used
  Future<ApiResponse> validateTicket(String ticketCode) async {
    try {
      // Extraer ticketId del JSON del QR code
      String ticketId = _extractTicketId(ticketCode);
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/tickets/validate/$ticketId'),
      ).timeout(const Duration(seconds: 10));
      
      return _handleResponse(response, originalQrCode: ticketCode);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Error de conexión: $e',
        code: 'CONNECTION_ERROR',
      );
    }
  }

  // Extraer ticketId del JSON del QR code
  String _extractTicketId(String qrCode) {
    try {
      // Intentar parsear como JSON
      final Map<String, dynamic> qrData = jsonDecode(qrCode);
      
      // Extraer ticketId del JSON
      if (qrData.containsKey('ticketId')) {
        return qrData['ticketId'];
      }
      
      // Si no tiene ticketId, devolver el código original
      return qrCode;
    } catch (e) {
      // Si no es JSON válido, devolver el código original
      return qrCode;
    }
  }
  
  // Quick validation using GET endpoint
  Future<ApiResponse> quickValidateTicket(String ticketCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/validate-ticket/$ticketCode'),
      ).timeout(const Duration(seconds: 10));
      
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Error de conexión: $e',
        code: 'CONNECTION_ERROR',
      );
    }
  }
  
  // Check ticket status without marking as used
  Future<ApiResponse> checkTicketStatus(String ticketCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/check-ticket/$ticketCode'),
      ).timeout(const Duration(seconds: 10));
      
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Error de conexión: $e',
        code: 'CONNECTION_ERROR',
      );
    }
  }
  
  // Reset ticket usage (admin)
  Future<ApiResponse> resetTicket(String ticketCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-ticket/$ticketCode'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Error de conexión: $e',
        code: 'CONNECTION_ERROR',
      );
    }
  }
  
  // Get all tickets (admin)
  Future<ApiResponse> getAllTickets() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/tickets'),
      ).timeout(const Duration(seconds: 10));
      
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Error de conexión: $e',
        code: 'CONNECTION_ERROR',
      );
    }
  }
  
  // Health check
  Future<ApiResponse> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Servidor no disponible',
        code: 'SERVER_UNAVAILABLE',
      );
    }
  }
  
  ApiResponse _handleResponse(http.Response response, {String? originalQrCode}) {
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      return ApiResponse(
        success: data['success'] ?? false,
        message: data['message'],
        code: data['success'] ? 'SUCCESS' : 'UNKNOWN_ERROR',
        ticketInfo: data['success'] && data['data'] != null 
          ? TicketInfo.fromBackendJson(data, originalQrCode: originalQrCode)
          : null,
      );
    } else if (response.statusCode == 404) {
      return ApiResponse(
        success: false,
        error: data['message'] ?? 'Ticket no encontrado',
        code: 'TICKET_NOT_FOUND',
        statusCode: response.statusCode,
      );
    } else {
      return ApiResponse(
        success: false,
        error: data['message'] ?? data['error'] ?? 'Error del servidor',
        code: data['code'] ?? 'UNKNOWN_ERROR',
        statusCode: response.statusCode,
      );
    }
  }
}

class ApiResponse {
  final bool success;
  final String? error;
  final String? code;
  final String? message;
  final TicketInfo? ticketInfo;
  final int? statusCode;
  final String? receivedCode;
  final List<TicketInfo>? tickets;
  final int? totalTickets;
  final int? usedTickets;
  
  ApiResponse({
    required this.success,
    this.error,
    this.code,
    this.message,
    this.ticketInfo,
    this.statusCode,
    this.receivedCode,
    this.tickets,
    this.totalTickets,
    this.usedTickets,
  });
  
  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      error: json['error'],
      code: json['code'],
      message: json['message'],
      ticketInfo: json['ticketInfo'] != null ? TicketInfo.fromBackendJson(json['ticketInfo']) : null,
      receivedCode: json['receivedCode'],
      tickets: json['tickets'] != null 
        ? (json['tickets'] as List).map((e) => TicketInfo.fromBackendJson(e)).toList()
        : null,
      totalTickets: json['totalTickets'],
      usedTickets: json['usedTickets'],
    );
  }
} 