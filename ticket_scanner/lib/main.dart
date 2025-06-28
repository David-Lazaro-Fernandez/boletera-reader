import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'services/api_service.dart';
import 'dart:async';

void main() {
  runApp(const TicketScannerApp());
}

class TicketScannerApp extends StatelessWidget {
  const TicketScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Validador de Tickets',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TicketValidatorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum ValidationState {
  ready,
  validating,
  valid,
  invalid,
}

enum AdminMode {
  off,
  viewer,
  admin,
}

class TicketValidatorScreen extends StatefulWidget {
  const TicketValidatorScreen({super.key});

  @override
  State<TicketValidatorScreen> createState() => _TicketValidatorScreenState();
}

class _TicketValidatorScreenState extends State<TicketValidatorScreen>
    with TickerProviderStateMixin {
  final TextEditingController _qrController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  ValidationState _currentState = ValidationState.ready;
  
  // Modo debug para testing
  bool _debugMode = true;
  String _currentInputText = '';
  String _lastProcessedCode = '';
  DateTime? _lastEnterPressed;
  
  late AnimationController _animationController;
  late AnimationController _backgroundController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _backgroundAnimation;
  
  AudioPlayer audioPlayer = AudioPlayer();
  List<TicketInfo> _validationHistory = [];
  int _sessionCount = 0;
  bool _isConnected = true;
  String _apiUrl = 'http://localhost:3000';
  late ApiService _apiService;
  AdminMode _adminMode = AdminMode.off;
  
  Timer? _resetTimer;
  String _currentMessage = 'Listo para escanear';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSettings();
    _checkConnectivity();
    _maintainFocus();
    
    // Listener para mostrar texto en tiempo real en modo debug
    _qrController.addListener(() {
      if (_debugMode) {
        setState(() {
          _currentInputText = _qrController.text;
        });
      }
    });
    
    // Monitor de conectividad
    Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _backgroundAnimation = ColorTween(
      begin: const Color(0xFF2E3B4E),
      end: Colors.green,
    ).animate(_backgroundController);
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiUrl = prefs.getString('api_url') ?? 'http://localhost:3000';
      _apiService = ApiService(baseUrl: _apiUrl);
    });
  }

  void _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
    });
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    setState(() {
      _isConnected = result != ConnectivityResult.none;
    });
  }

  void _maintainFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _currentState != ValidationState.validating) {
        _focusNode.requestFocus();
      }
    });
  }

  Future<void> _processQRCode(String qrCode) async {
    if (qrCode.trim().isEmpty || _currentState == ValidationState.validating) {
      return;
    }

    // Registrar el evento de Enter/envío
    setState(() {
      _lastEnterPressed = DateTime.now();
      _lastProcessedCode = qrCode.trim();
      _currentInputText = ''; // Limpiar el display
    });

    _qrController.clear();
    
    setState(() {
      _currentState = ValidationState.validating;
      _currentMessage = 'Validando ticket...';
    });

    try {
      final result = await _validateTicket(qrCode.trim());
      _handleValidationResult(result, qrCode.trim());
    } catch (e) {
      _handleError('Error de conexión');
    }
  }

  Future<ApiResponse> _validateTicket(String code) async {
    if (!_isConnected) {
      // Modo offline - guardar para sincronización posterior
      await _saveOfflineValidation(code);
      return ApiResponse(
        success: false,
        error: 'Sin conexión a internet',
        code: 'OFFLINE',
      );
    }

    return await _apiService.validateTicket(code);
  }

  void _handleValidationResult(ApiResponse response, String code) {
    final isValid = response.success && response.ticketInfo != null;
    final ticketInfo = response.ticketInfo;
    
    setState(() {
      _currentState = isValid ? ValidationState.valid : ValidationState.invalid;
      
      if (isValid && ticketInfo != null) {
        _currentMessage = '¡Ticket Válido!\n${ticketInfo.event}\n${ticketInfo.type}';
      } else {
        // Handle different error codes
        switch (response.code) {
          case 'TICKET_NOT_FOUND':
            _currentMessage = 'Ticket no encontrado\no inválido';
            break;
          case 'TICKET_ALREADY_USED':
            _currentMessage = 'Ticket ya fue\nescaneado anteriormente';
            break;
          case 'OFFLINE':
            _currentMessage = 'Sin conexión\n(guardado offline)';
            break;
          default:
            _currentMessage = response.error ?? 'Error desconocido';
        }
      }
      
      _sessionCount++;
    });

    // Añadir al historial si tenemos información del ticket
    if (ticketInfo != null) {
      _validationHistory.insert(0, ticketInfo);
      if (_validationHistory.length > 10) {
        _validationHistory.removeLast();
      }
    }

    // Animaciones y efectos
    if (isValid) {
      _animationController.forward();
      _backgroundController.forward();
      _playSuccessSound();
      _vibrate();
    } else {
      _playErrorSound();
      _vibrate();
    }

    // Auto-reset después de 3 segundos
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 3), _resetToReady);
  }

  void _handleError(String error) {
    setState(() {
      _currentState = ValidationState.invalid;
      _currentMessage = error;
    });
    
    _playErrorSound();
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 3), _resetToReady);
  }

  void _resetToReady() {
    setState(() {
      _currentState = ValidationState.ready;
      _currentMessage = 'Listo para escanear';
    });
    
    _animationController.reset();
    _backgroundController.reset();
    _maintainFocus();
  }

  Future<void> _playSuccessSound() async {
    try {
      await audioPlayer.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      // Fallback con sonido del sistema
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> _playErrorSound() async {
    try {
      await audioPlayer.play(AssetSource('sounds/error.mp3'));
    } catch (e) {
      // Fallback con sonido del sistema
      SystemSound.play(SystemSoundType.alert);
    }
  }

  void _vibrate() {
    HapticFeedback.mediumImpact();
  }

  Future<void> _saveOfflineValidation(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final offline = prefs.getStringList('offline_validations') ?? [];
    offline.add('$code|${DateTime.now().toIso8601String()}');
    await prefs.setStringList('offline_validations', offline);
  }

  Color _getBackgroundColor() {
    switch (_currentState) {
      case ValidationState.ready:
        return const Color(0xFF2E3B4E);
      case ValidationState.validating:
        return Colors.orange.shade300;
      case ValidationState.valid:
        return _backgroundAnimation.value ?? Colors.green;
      case ValidationState.invalid:
        return Colors.red.shade400;
    }
  }

  IconData _getStateIcon() {
    switch (_currentState) {
      case ValidationState.ready:
        return Icons.qr_code_scanner;
      case ValidationState.validating:
        return Icons.hourglass_empty;
      case ValidationState.valid:
        return Icons.check_circle;
      case ValidationState.invalid:
        return Icons.error;
    }
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      builder: (context) => HistoryBottomSheet(history: _validationHistory),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        currentApiUrl: _apiUrl,
        adminMode: _adminMode,
        onApiUrlChanged: (url) {
          setState(() {
            _apiUrl = url;
            _apiService = ApiService(baseUrl: url);
          });
        },
        onAdminModeChanged: (mode) {
          setState(() {
            _adminMode = mode;
          });
        },
      ),
    );
  }

  void _toggleDebugMode() {
    setState(() {
      _debugMode = !_debugMode;
      if (!_debugMode) {
        _currentInputText = '';
      }
    });
    _maintainFocus();
  }

  void _clearInput() {
    _qrController.clear();
    setState(() {
      _currentInputText = '';
    });
    _maintainFocus();
  }

  void _resetDebugInfo() {
    setState(() {
      _lastProcessedCode = '';
      _lastEnterPressed = null;
      _currentInputText = '';
    });
    _clearInput();
  }

  void _showAdminPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AdminPanelSheet(
        apiService: _apiService,
        adminMode: _adminMode,
      ),
    );
  }

  Future<void> _checkTicketPreview(String code) async {
    if (code.trim().isEmpty) return;
    
    try {
      final response = await _apiService.checkTicketStatus(code.trim());
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(response.success ? 'Vista Previa del Ticket' : 'Error'),
          content: response.success && response.ticketInfo != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Evento: ${response.ticketInfo!.event}'),
                  Text('Tipo: ${response.ticketInfo!.type}'),
                  Text('Asiento: ${response.ticketInfo!.seat}'),
                  Text('Precio: \$${response.ticketInfo!.price}'),
                  Text('Propietario: ${response.ticketInfo!.holderName}'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: response.ticketInfo!.isValid ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      response.ticketInfo!.isValid ? 'Estado: ACTIVO' : 'Estado: YA USADO',
                      style: TextStyle(
                        color: response.ticketInfo!.isValid ? Colors.green.shade800 : Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            : Text(response.error ?? 'Error desconocido'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorDialog('Error al consultar ticket: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _toggleAdminMode() {
    setState(() {
      switch (_adminMode) {
        case AdminMode.off:
          _adminMode = AdminMode.viewer;
          break;
        case AdminMode.viewer:
          _adminMode = AdminMode.admin;
          break;
        case AdminMode.admin:
          _adminMode = AdminMode.off;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _getBackgroundColor(),
                  _getBackgroundColor().withValues(alpha: 0.8),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isConnected ? Icons.wifi : Icons.wifi_off,
                              color: Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isConnected ? 'Online' : 'Offline',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _showHistory,
                              icon: const Icon(Icons.history, color: Colors.white),
                            ),
                            if (_adminMode != AdminMode.off)
                              IconButton(
                                onPressed: _showAdminPanel,
                                icon: Icon(
                                  Icons.admin_panel_settings,
                                  color: _adminMode == AdminMode.admin ? Colors.red : Colors.orange,
                                ),
                              ),
                            IconButton(
                              onPressed: _toggleDebugMode,
                              icon: Icon(
                                _debugMode ? Icons.bug_report : Icons.bug_report_outlined,
                                color: _debugMode ? Colors.yellow : Colors.white,
                              ),
                            ),
                            IconButton(
                              onPressed: _showSettings,
                              icon: const Icon(Icons.settings, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Título principal
                  const Text(
                    'Validador de Tickets',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Área central de escaneo
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Marco de escaneo visual
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                _getStateIcon(),
                                size: 80,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // Mensaje de estado
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              _currentMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          
                          if (_currentState == ValidationState.validating)
                            const Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Sección de Debug (solo visible en modo debug)
                  if (_debugMode) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.yellow, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.bug_report, color: Colors.yellow, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'MODO DEBUG - Testing Scanner',
                                style: TextStyle(
                                  color: Colors.yellow,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                                                     // Texto actual en el input (en tiempo real)
                           Text(
                             'Escribiendo en tiempo real:',
                             style: TextStyle(
                               color: Colors.white.withValues(alpha: 0.8),
                               fontSize: 14,
                             ),
                           ),
                           const SizedBox(height: 4),
                           Container(
                             width: double.infinity,
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(
                               color: Colors.black.withValues(alpha: 0.5),
                               borderRadius: BorderRadius.circular(6),
                               border: Border.all(
                                 color: _currentInputText.isNotEmpty ? Colors.green : Colors.grey,
                                 width: 1,
                               ),
                             ),
                             child: Text(
                               _currentInputText.isEmpty ? '(esperando que el scanner escriba...)' : _currentInputText,
                               style: TextStyle(
                                 color: _currentInputText.isEmpty ? Colors.grey : Colors.green,
                                 fontFamily: 'monospace',
                                 fontSize: 16,
                                 fontWeight: _currentInputText.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                               ),
                             ),
                           ),
                           
                           const SizedBox(height: 12),
                           
                           // Último código procesado (cuando se presionó Enter)
                           Text(
                             'Último código enviado (Enter):',
                             style: TextStyle(
                               color: Colors.white.withValues(alpha: 0.8),
                               fontSize: 14,
                             ),
                           ),
                           const SizedBox(height: 4),
                           Container(
                             width: double.infinity,
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(
                               color: Colors.blue.withValues(alpha: 0.2),
                               borderRadius: BorderRadius.circular(6),
                               border: Border.all(
                                 color: _lastProcessedCode.isNotEmpty ? Colors.blue : Colors.grey,
                                 width: 1,
                               ),
                             ),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   _lastProcessedCode.isEmpty ? '(ningún código enviado aún)' : _lastProcessedCode,
                                   style: TextStyle(
                                     color: _lastProcessedCode.isEmpty ? Colors.grey : Colors.blue,
                                     fontFamily: 'monospace',
                                     fontSize: 16,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                                 if (_lastEnterPressed != null) ...[
                                   const SizedBox(height: 4),
                                   Text(
                                     'Enviado: ${_lastEnterPressed!.toString().substring(11, 19)}',
                                     style: TextStyle(
                                       color: Colors.blue.withValues(alpha: 0.7),
                                       fontSize: 12,
                                     ),
                                   ),
                                 ],
                               ],
                             ),
                           ),
                          
                          const SizedBox(height: 12),
                          
                                                     // Input visible para testing manual
                           TextField(
                             controller: _qrController,
                             focusNode: _focusNode,
                             style: const TextStyle(color: Colors.white),
                             decoration: InputDecoration(
                               labelText: 'Input del Scanner - Presiona ENTER para enviar',
                               labelStyle: const TextStyle(color: Colors.white70),
                               helperText: 'El scanner debe terminar con Enter/Return',
                               helperStyle: const TextStyle(color: Colors.yellow, fontSize: 11),
                               border: OutlineInputBorder(
                                 borderSide: const BorderSide(color: Colors.yellow),
                                 borderRadius: BorderRadius.circular(8),
                               ),
                               enabledBorder: OutlineInputBorder(
                                 borderSide: const BorderSide(color: Colors.yellow),
                                 borderRadius: BorderRadius.circular(8),
                               ),
                               focusedBorder: OutlineInputBorder(
                                 borderSide: const BorderSide(color: Colors.yellow, width: 2),
                                 borderRadius: BorderRadius.circular(8),
                               ),
                               filled: true,
                               fillColor: Colors.black.withValues(alpha: 0.3),
                               suffixIcon: _currentInputText.isNotEmpty 
                                 ? const Icon(Icons.keyboard_return, color: Colors.yellow, size: 20)
                                 : null,
                             ),
                             onSubmitted: (value) {
                               // Procesar solo cuando se presiona Enter
                               print('🔥 ENTER DETECTADO: "$value"');
                               _processQRCode(value);
                             },
                             onChanged: (value) {
                               // Solo actualizar el display, NO procesar
                               setState(() {
                                 _currentInputText = value;
                               });
                             },
                             autofocus: true,
                             textInputAction: TextInputAction.done,
                           ),
                          
                          const SizedBox(height: 12),
                          
                                                     // Botones de control
                           Row(
                             children: [
                               Expanded(
                                 child: ElevatedButton.icon(
                                   onPressed: _clearInput,
                                   icon: const Icon(Icons.clear),
                                   label: const Text('Limpiar'),
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: Colors.orange,
                                     foregroundColor: Colors.white,
                                   ),
                                 ),
                               ),
                               const SizedBox(width: 8),
                               Expanded(
                                 child: ElevatedButton.icon(
                                   onPressed: () {
                                     setState(() {
                                       _lastProcessedCode = '';
                                       _lastEnterPressed = null;
                                       _currentInputText = '';
                                     });
                                     _clearInput();
                                   },
                                   icon: const Icon(Icons.refresh),
                                   label: const Text('Reset'),
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: Colors.purple,
                                     foregroundColor: Colors.white,
                                   ),
                                 ),
                               ),
                               const SizedBox(width: 8),
                               Expanded(
                                 child: ElevatedButton.icon(
                                   onPressed: () {
                                     // Simular un código de prueba y ENTER
                                     final testCode = 'TEST_${DateTime.now().millisecondsSinceEpoch}';
                                     _qrController.text = testCode;
                                     setState(() {
                                       _currentInputText = testCode;
                                     });
                                     // Simular el Enter después de un pequeño delay
                                     Future.delayed(const Duration(milliseconds: 500), () {
                                       _processQRCode(testCode);
                                     });
                                   },
                                   icon: const Icon(Icons.play_arrow),
                                   label: const Text('Test'),
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: Colors.green,
                                     foregroundColor: Colors.white,
                                   ),
                                 ),
                               ),
                             ],
                           ),
                          
                          const SizedBox(height: 8),
                          
                                                     // Información de status detallada
                           Container(
                             width: double.infinity,
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(
                               color: Colors.grey.withValues(alpha: 0.2),
                               borderRadius: BorderRadius.circular(6),
                             ),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   'STATUS DE DEBUG:',
                                   style: TextStyle(
                                     color: Colors.white.withValues(alpha: 0.9),
                                     fontSize: 12,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                                 const SizedBox(height: 4),
                                 Text(
                                   '• Estado: ${_currentState.name.toUpperCase()}',
                                   style: TextStyle(
                                     color: Colors.white.withValues(alpha: 0.7),
                                     fontSize: 11,
                                   ),
                                 ),
                                 Text(
                                   '• Input en focus: ${_focusNode.hasFocus ? "✅ SÍ" : "❌ NO"}',
                                   style: TextStyle(
                                     color: _focusNode.hasFocus ? Colors.green : Colors.red,
                                     fontSize: 11,
                                   ),
                                 ),
                                 Text(
                                   '• Caracteres escribiendo: ${_currentInputText.length}',
                                   style: TextStyle(
                                     color: Colors.white.withValues(alpha: 0.7),
                                     fontSize: 11,
                                   ),
                                 ),
                                 Text(
                                   '• Último ENTER: ${_lastEnterPressed != null ? "✅ ${_lastEnterPressed.toString().substring(11, 19)}" : "❌ Ninguno"}',
                                   style: TextStyle(
                                     color: _lastEnterPressed != null ? Colors.green : Colors.grey,
                                     fontSize: 11,
                                   ),
                                 ),
                               ],
                             ),
                           ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Información de sesión
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tickets procesados: $_sessionCount',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Text(
                                'Agregar a Apple Wallet',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Información adicional en modo debug
                        if (_debugMode) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.yellow.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.yellow, width: 1),
                            ),
                            child: Text(
                              '🐛 MODO DEBUG ACTIVO\n• El scanner debe escribir el código + ENTER\n• Verás el texto escribiéndose en tiempo real\n• Solo se procesa cuando detecta ENTER',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.yellow.shade200,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      
      // Input invisible para capturar códigos QR (solo cuando NO está en modo debug)
      bottomSheet: _debugMode ? null : SizedBox(
        height: 0,
        child: TextField(
          controller: _qrController,
          focusNode: _focusNode,
          style: const TextStyle(color: Colors.transparent),
          decoration: const InputDecoration(border: InputBorder.none),
          onSubmitted: _processQRCode,
          autofocus: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _qrController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    _backgroundController.dispose();
    _resetTimer?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }
}

class HistoryBottomSheet extends StatelessWidget {
  final List<TicketInfo> history;

  const HistoryBottomSheet({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historial de Validaciones',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final ticket = history[index];
                                  return Card(
                    child: ListTile(
                      leading: Icon(
                        ticket.isValid ? Icons.check_circle : Icons.error,
                        color: ticket.isValid ? Colors.green : Colors.red,
                      ),
                      title: Text(ticket.event),
                      subtitle: Text(
                        '${ticket.displayCode}... - ${ticket.timestamp.toString().substring(11, 19)}',
                      ),
                      trailing: Text(
                        ticket.isValid ? 'Válido' : 'Usado',
                        style: TextStyle(
                          color: ticket.isValid ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AdminPanelSheet extends StatefulWidget {
  final ApiService apiService;
  final AdminMode adminMode;

  const AdminPanelSheet({
    super.key,
    required this.apiService,
    required this.adminMode,
  });

  @override
  State<AdminPanelSheet> createState() => _AdminPanelSheetState();
}

class _AdminPanelSheetState extends State<AdminPanelSheet> {
  List<TicketInfo>? _allTickets;
  bool _loading = false;
  final TextEditingController _ticketCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllTickets();
  }

  Future<void> _loadAllTickets() async {
    setState(() => _loading = true);
    try {
      final response = await widget.apiService.getAllTickets();
      setState(() {
        _allTickets = response.tickets ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _resetTicket(String qrCode) async {
    try {
      final response = await widget.apiService.resetTicket(qrCode);
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket reset exitosamente')),
        );
        _loadAllTickets(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.error}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Panel de Administración',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: widget.adminMode == AdminMode.admin ? Colors.red : Colors.orange,
            ),
          ),
          const SizedBox(height: 20),
          
          if (widget.adminMode == AdminMode.admin) ...[
            TextField(
              controller: _ticketCodeController,
              decoration: const InputDecoration(
                labelText: 'Código QR para resetear',
                hintText: 'QUJDLWFiYy0xMjM0',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (_ticketCodeController.text.isNotEmpty) {
                  _resetTicket(_ticketCodeController.text);
                  _ticketCodeController.clear();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reset Ticket', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
          ],
          
          Text(
            'Todos los Tickets (${_allTickets?.length ?? 0})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _allTickets == null || _allTickets!.isEmpty
                ? const Center(child: Text('No hay tickets disponibles'))
                : ListView.builder(
                    itemCount: _allTickets!.length,
                    itemBuilder: (context, index) {
                      final ticket = _allTickets![index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: ticket.isValid ? Colors.green : Colors.red,
                            child: Text(
                              ticket.type.substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(ticket.event),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${ticket.type} - ${ticket.seat}'),
                              Text('QR: ${ticket.qrCode?.substring(0, 12) ?? ticket.id.substring(0, 12)}...'),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                ticket.isValid ? 'ACTIVO' : 'USADO',
                                style: TextStyle(
                                  color: ticket.isValid ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('\$${ticket.price}'),
                            ],
                          ),
                          onTap: widget.adminMode == AdminMode.admin && !ticket.isValid
                            ? () => _resetTicket(ticket.qrCode ?? ticket.id)
                            : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ticketCodeController.dispose();
    super.dispose();
  }
}

class SettingsDialog extends StatefulWidget {
  final String currentApiUrl;
  final AdminMode adminMode;
  final Function(String) onApiUrlChanged;
  final Function(AdminMode) onAdminModeChanged;

  const SettingsDialog({
    super.key,
    required this.currentApiUrl,
    required this.adminMode,
    required this.onApiUrlChanged,
    required this.onAdminModeChanged,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.currentApiUrl);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configuración'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'URL de API',
              hintText: 'http://localhost:3000',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Modo Admin:'),
              const SizedBox(width: 10),
              DropdownButton<AdminMode>(
                value: widget.adminMode,
                items: const [
                  DropdownMenuItem(value: AdminMode.off, child: Text('Desactivado')),
                  DropdownMenuItem(value: AdminMode.viewer, child: Text('Visualización')),
                  DropdownMenuItem(value: AdminMode.admin, child: Text('Administrador')),
                ],
                onChanged: (mode) {
                  if (mode != null) {
                    widget.onAdminModeChanged(mode);
                  }
                },
              ),
            ],
          ),
          if (widget.adminMode != AdminMode.off)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Modo admin permite ver y resetear tickets',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('api_url', _urlController.text);
            widget.onApiUrlChanged(_urlController.text);
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
