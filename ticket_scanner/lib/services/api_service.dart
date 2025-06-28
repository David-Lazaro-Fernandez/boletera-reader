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
      final response = await http.post(
        Uri.parse('$baseUrl/validate-ticket'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ticketCode': ticketCode}),
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
  
  ApiResponse _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      return ApiResponse.fromJson(data);
    } else {
      return ApiResponse(
        success: false,
        error: data['error'] ?? 'Error del servidor',
        code: data['code'] ?? 'UNKNOWN_ERROR',
        statusCode: response.statusCode,
        receivedCode: data['receivedCode'],
        ticketInfo: data['ticketInfo'] != null ? TicketInfo.fromBackendJson(data['ticketInfo']) : null,
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

class TicketInfo {
  final String id;
  final String type;
  final String event;
  final String section;
  final String seat;
  final double price;
  final String holderName;
  final String issueDate;
  final String eventDate;
  final String venue;
  final String status;
  final String? scannedAt;
  final String? qrCode;
  final bool? isUsed;
  final DateTime timestamp;

  TicketInfo({
    required this.id,
    required this.type,
    required this.event,
    required this.section,
    required this.seat,
    required this.price,
    required this.holderName,
    required this.issueDate,
    required this.eventDate,
    required this.venue,
    required this.status,
    this.scannedAt,
    this.qrCode,
    this.isUsed,
    required this.timestamp,
  });

  factory TicketInfo.fromBackendJson(Map<String, dynamic> json) {
    return TicketInfo(
      id: json['id'] ?? '',
      type: json['type'] ?? 'Ticket',
      event: json['event'] ?? 'Evento desconocido',
      section: json['section'] ?? '',
      seat: json['seat'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      holderName: json['holderName'] ?? '',
      issueDate: json['issueDate'] ?? '',
      eventDate: json['eventDate'] ?? '',
      venue: json['venue'] ?? '',
      status: json['status'] ?? 'unknown',
      scannedAt: json['scannedAt'],
      qrCode: json['qrCode'],
      isUsed: json['isUsed'],
      timestamp: DateTime.now(),
    );
  }
  
  bool get isValid => status == 'active' && (isUsed != true);
  
  String get displayCode => qrCode?.substring(0, 8) ?? id.substring(0, 8);
} 