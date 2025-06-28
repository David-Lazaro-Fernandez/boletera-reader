# 🎫 Validador de Tickets - Flutter App

Una aplicación móvil moderna en Flutter para la validación automática de boletos de conciertos mediante códigos QR escaneados con lectores láser externos.

## 📋 Características Principales

### ✨ Interfaz de Usuario
- **Diseño moderno y profesional** con animaciones fluidas
- **Estados visuales dinámicos** que cambian según la validación
- **Indicadores de conectividad** (Online/Offline)
- **Feedback háptico y sonoro** para cada validación
- **Historial de validaciones** con interfaz deslizable

### 🔧 Funcionalidades Técnicas
- **Captura automática de códigos QR** via input invisible
- **Validación en tiempo real** contra API REST
- **Modo offline** con sincronización posterior
- **Configuración flexible** de URL de API
- **Contador de sesión** en tiempo real
- **Gestión robusta de errores** y reconexión automática

## 🚀 Instalación y Configuración

### Prerrequisitos
- Flutter SDK (>=3.8.1)
- Dart SDK
- Android Studio o Xcode (para desarrollo móvil)
- Lector de códigos QR USB/Bluetooth configurado como HID

### Pasos de Instalación

1. **Clonar el repositorio**
   ```bash
   git clone <repository-url>
   cd ticket_scanner
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar archivos de audio (opcional)**
   - Agregar archivos `success.mp3` y `error.mp3` en `assets/sounds/`
   - Los sonidos del sistema se usan como fallback

4. **Compilar y ejecutar**
   ```bash
   # Para Android
   flutter build apk --release
   
   # Para iOS
   flutter build ios --release
   
   # Para desarrollo
   flutter run
   ```

## ⚙️ Configuración de API

### Endpoint Requerido
La aplicación espera un endpoint REST en:
```
POST /api/validate-ticket
```

### Formato de Request
```json
{
  "code": "QR_CODE_STRING",
  "timestamp": "2024-12-01T20:00:00.000Z",
  "device_id": "FLUTTER_SCANNER_001"
}
```

### Formato de Response

**Ticket Válido:**
```json
{
  "valid": true,
  "message": "Ticket válido",
  "ticket_info": {
    "event": "Concierto Rock Festival 2024",
    "date": "2024-12-01T20:00:00Z"
  }
}
```

**Ticket Inválido:**
```json
{
  "valid": false,
  "message": "Código inválido o ya utilizado",
  "error_code": "INVALID_CODE"
}
```

## 📱 Guía de Uso

### Primera Configuración
1. Abrir la aplicación
2. Tocar el ícono de configuración ⚙️
3. Introducir la URL de la API de validación
4. Guardar configuración

### Proceso de Validación
1. **Estado Listo**: La app muestra "Listo para escanear"
2. **Escaneo**: El lector QR envía el código automáticamente
3. **Validación**: La app muestra "Validando ticket..." con spinner
4. **Resultado**: 
   - ✅ **Válido**: Fondo verde, sonido de confirmación, información del evento
   - ❌ **Inválido**: Fondo rojo, sonido de error, mensaje de error
5. **Reset Automático**: Regresa al estado listo después de 3 segundos

### Historial de Validaciones
- Tocar el ícono de historial 📋
- Ver últimas 10 validaciones
- Información incluye: evento, código parcial, timestamp, estado

## 🎨 Estados Visuales

| Estado | Color de Fondo | Icono | Sonido |
|--------|---------------|-------|--------|
| **Listo** | Azul/Gris neutro | 📱 QR Scanner | Silencio |
| **Validando** | Naranja suave | ⏳ Reloj | Silencio |
| **Válido** | Verde brillante | ✅ Check | Ding positivo |
| **Inválido** | Rojo | ❌ Error | Beep negativo |

## 🔧 Configuración Avanzada

### Variables de Entorno
```bash
# URL por defecto de API
API_URL=https://api.example.com

# Timeout de red (segundos)
NETWORK_TIMEOUT=10

# ID del dispositivo
DEVICE_ID=FLUTTER_SCANNER_001
```

### Configuración del Lector QR
1. **Modo HID**: Configurar el lector como teclado
2. **Sufijo**: Configurar Enter o salto de línea como terminador
3. **Prefijo**: Sin prefijo recomendado
4. **Codificación**: UTF-8

## 🛠️ Desarrollo y Personalización

### Estructura del Proyecto
```
lib/
├── main.dart                 # Aplicación principal
├── models/
│   └── ticket_info.dart     # Modelo de datos de ticket
├── services/
│   └── api_service.dart     # Servicio de API
├── widgets/
│   ├── history_sheet.dart   # Widget de historial
│   └── settings_dialog.dart # Dialog de configuración
└── utils/
    └── constants.dart       # Constantes de la app
```

### Personalización de Colores
```dart
// En main.dart, método _getBackgroundColor()
case ValidationState.ready:
  return const Color(0xFF2E3B4E);  // Azul personalizado
case ValidationState.valid:
  return Colors.green;             // Verde de éxito
case ValidationState.invalid:
  return Colors.red.shade400;      // Rojo de error
```

### Añadir Nuevos Sonidos
1. Agregar archivos .mp3 en `assets/sounds/`
2. Actualizar `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/sounds/
   ```
3. Usar en código:
   ```dart
   await audioPlayer.play(AssetSource('sounds/nuevo_sonido.mp3'));
   ```

## 🧪 Testing

### Ejecutar Tests
```bash
# Tests unitarios
flutter test

# Tests de integración
flutter test integration_test/
```

### Tests Incluidos
- ✅ Carga correcta de la aplicación
- ✅ Apertura del diálogo de configuración
- ✅ Validación de respuesta de API
- ✅ Manejo de errores de red

## 📊 Casos de Uso

### 1. Evento Masivo (10,000+ asistentes)
- **Configuración**: Múltiples dispositivos con API centralizada
- **Red**: Conexión estable requerida
- **Performance**: < 2 segundos por validación

### 2. Venue Pequeño (500 asistentes)
- **Configuración**: Un solo dispositivo
- **Red**: Conexión WiFi local
- **Backup**: Modo offline disponible

### 3. Festival Multi-día
- **Configuración**: Validación de pases diarios
- **API**: Endpoints diferentes por día
- **Historial**: Tracking completo por sesión

### 4. Evento VIP
- **Configuración**: Diferentes niveles de acceso
- **Validación**: Códigos específicos por área
- **Seguridad**: Logs detallados requeridos

## 🔐 Seguridad y Privacidad

- **Encriptación local** de datos sensibles
- **Logs seguros** sin exposición de códigos completos
- **Rate limiting** para prevenir spam
- **Validación robusta** de entrada

## 📈 Performance

- **Tiempo de respuesta**: < 2 segundos para validación online
- **Uso de memoria**: Optimizado para uso prolongado
- **Batería**: Gestión eficiente de recursos
- **Conectividad**: Reconexión automática inteligente

## 🐛 Solución de Problemas

### Problemas Comunes

**1. El lector QR no funciona**
- Verificar configuración HID
- Comprobar que el sufijo sea Enter/newline
- Probar en un editor de texto primero

**2. Error de conexión a API**
- Verificar URL en configuración
- Comprobar conectividad de red
- Revisar formato de respuesta del servidor

**3. Audio no reproduce**
- Verificar archivos en `assets/sounds/`
- Comprobar permisos de audio del dispositivo
- Los sonidos del sistema funcionan como fallback

**4. Aplicación lenta**
- Cerrar y reabrir la aplicación
- Limpiar historial de validaciones
- Verificar memoria disponible del dispositivo

## 📞 Soporte

Para soporte técnico o reportar problemas:
- 📧 Email: soporte@ticketscanner.com
- 📱 Teléfono: +1 (555) 123-4567
- 🌐 Web: https://ticketscanner.com/support

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

---

**Desarrollado con ❤️ usando Flutter**
