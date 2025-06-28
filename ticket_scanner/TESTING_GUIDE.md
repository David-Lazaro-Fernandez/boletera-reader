# 🧪 Guía de Pruebas y Despliegue - Validador de Tickets

## 📋 Índice
- [Configuración del Entorno de Pruebas](#configuración-del-entorno-de-pruebas)
- [Pruebas Unitarias](#pruebas-unitarias)
- [Pruebas de Integración](#pruebas-de-integración)
- [Pruebas Manuales](#pruebas-manuales)
- [Pruebas de QR Scanner](#pruebas-de-qr-scanner)
- [Configuración de API Mock](#configuración-de-api-mock)
- [Pruebas de Conectividad](#pruebas-de-conectividad)
- [Pruebas de Performance](#pruebas-de-performance)
- [Despliegue](#despliegue)
- [Troubleshooting](#troubleshooting)

## ⚙️ Configuración del Entorno de Pruebas

### Prerrequisitos
```bash
# Verificar instalación de Flutter
flutter --version

# Verificar dispositivos conectados
flutter devices

# Verificar dependencias
flutter doctor
```

### Setup del Proyecto
```bash
# Clonar e instalar
git clone <repository-url>
cd ticket_scanner
flutter pub get

# Verificar que no hay errores de lint
flutter analyze

# Ejecutar tests básicos
flutter test
```

## 🔬 Pruebas Unitarias

### Ejecutar Tests Unitarios
```bash
# Todos los tests
flutter test

# Tests con coverage
flutter test --coverage

# Tests específicos
flutter test test/models/ticket_info_test.dart
flutter test test/services/api_service_test.dart
```

### Tests Implementados

#### ✅ Modelo TicketInfo
- Creación desde JSON válido
- Creación desde JSON inválido
- Métodos display (displayCode, displayTime)
- Serialización toJson()
- Factory constructor offline

#### ✅ Servicio API
- Validación exitosa de ticket
- Manejo de tickets inválidos
- Timeout de conexión
- Respuestas malformadas del servidor
- Modo offline

#### ✅ Servicio de Audio
- Reproducción de sonidos de éxito/error
- Fallback a sonidos del sistema
- Control de volumen
- Habilitar/deshabilitar sonidos

## 🔄 Pruebas de Integración

### Setup para Pruebas de Integración
```bash
# Crear directorio si no existe
mkdir -p integration_test

# Ejecutar pruebas de integración
flutter test integration_test/app_test.dart
```

### Casos de Prueba de Integración
1. **Flujo completo de validación exitosa**
2. **Flujo completo de validación fallida**
3. **Cambio de configuración de API**
4. **Funcionalidad offline**
5. **Navegación entre pantallas**

## 📱 Pruebas Manuales

### Lista de Verificación UI/UX

#### ✅ Pantalla Principal
- [ ] Título "Validador de Tickets" visible
- [ ] Indicador de conectividad (Online/Offline)
- [ ] Marco de escaneo con animación
- [ ] Mensaje de estado correcto
- [ ] Contador de sesión funcional
- [ ] Botones de historial y configuración accesibles

#### ✅ Estados Visuales
- [ ] **Estado Listo**: Fondo azul, icono QR, mensaje "Listo para escanear"
- [ ] **Estado Validando**: Fondo naranja, spinner, mensaje "Validando..."
- [ ] **Estado Válido**: Fondo verde, checkmark, información del evento
- [ ] **Estado Inválido**: Fondo rojo, X, mensaje de error

#### ✅ Transiciones y Animaciones
- [ ] Animación suave entre estados
- [ ] Escala del marco de escaneo en éxito
- [ ] Gradiente de colores funcional
- [ ] Auto-reset después de 3 segundos

#### ✅ Audio y Feedback
- [ ] Sonido de éxito en validación correcta
- [ ] Sonido de error en validación fallida
- [ ] Vibración háptica en ambos casos
- [ ] Fallback a sonidos del sistema

### Lista de Verificación Funcional

#### ✅ Configuración
- [ ] Apertura del diálogo de configuración
- [ ] Modificación de URL de API
- [ ] Guardado persistente de configuración
- [ ] Validación de formato URL

#### ✅ Historial
- [ ] Apertura de bottom sheet de historial
- [ ] Visualización de últimas 10 validaciones
- [ ] Información completa por entrada
- [ ] Scroll en lista de historial

#### ✅ Conectividad
- [ ] Detección automática de conexión/desconexión
- [ ] Modo offline funcional
- [ ] Sincronización al recuperar conexión
- [ ] Indicador visual de estado de red

## 📦 Pruebas de QR Scanner

### Configuración del Lector QR

#### Configuración HID (Human Interface Device)
1. **Modo de Entrada**: Teclado HID
2. **Prefijo**: Ninguno
3. **Sufijo**: Enter (Carriage Return)
4. **Codificación**: UTF-8
5. **Rate**: Estándar (no muy rápido)

### Pruebas con Diferentes Códigos QR

#### Códigos de Prueba Recomendados
```
# Códigos válidos simulados
TEST_VALID_001
EVENT_2024_VIP_123
CONCERT_ROCK_456789

# Códigos inválidos simulados  
EXPIRED_CODE_001
USED_TICKET_002
INVALID_FORMAT
```

### Protocolo de Pruebas QR
1. **Prueba básica**: Código alfanumérico simple
2. **Prueba de longitud**: Códigos largos (>50 caracteres)
3. **Prueba de caracteres especiales**: Códigos con guiones, puntos
4. **Prueba de velocidad**: Múltiples escaneos consecutivos
5. **Prueba de reconexión**: Desconectar/reconectar lector

## 🖥️ Configuración de API Mock

### Servidor Mock Simple (Node.js)
```javascript
// mock-server.js
const express = require('express');
const app = express();
app.use(express.json());

const validCodes = ['TEST_VALID_001', 'EVENT_2024_VIP_123'];

app.post('/api/validate-ticket', (req, res) => {
  const { code } = req.body;
  
  if (validCodes.includes(code)) {
    res.json({
      valid: true,
      message: "Ticket válido",
      ticket_info: {
        event: "Concierto de Prueba 2024",
        date: "2024-12-01T20:00:00Z"
      }
    });
  } else {
    res.json({
      valid: false,
      message: "Código inválido",
      error_code: "INVALID_CODE"
    });
  }
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'OK' });
});

app.listen(3000, () => {
  console.log('Mock server running on port 3000');
});
```

### Uso del Servidor Mock
```bash
# Instalar Node.js y ejecutar
npm init -y
npm install express
node mock-server.js

# Configurar app para usar: http://localhost:3000
```

## 🌐 Pruebas de Conectividad

### Escenarios de Red
1. **WiFi estable**: Validación normal
2. **WiFi inestable**: Reconexión automática
3. **Modo avión**: Modo offline
4. **Datos móviles**: Validación con latencia
5. **Sin internet**: Guardado offline

### Pruebas de API
```bash
# Probar endpoint manualmente
curl -X POST http://localhost:3000/api/validate-ticket \
  -H "Content-Type: application/json" \
  -d '{"code":"TEST_VALID_001","timestamp":"2024-01-01T12:00:00Z","device_id":"TEST"}'

# Probar health check
curl http://localhost:3000/api/health
```

## ⚡ Pruebas de Performance

### Métricas Objetivo
- **Tiempo de validación**: < 2 segundos
- **Uso de memoria**: < 100MB constante
- **Tiempo de arranque**: < 3 segundos
- **Framerate**: 60 FPS consistente

### Herramientas de Medición
```bash
# Profile de performance
flutter run --profile

# Análisis de memoria
flutter run --debug
# Luego usar DevTools para análisis

# Test de stress
# Escanear 100 códigos consecutivos
```

### Casos de Stress Testing
1. **Validaciones rápidas**: 50 códigos en 1 minuto
2. **Uso prolongado**: 8 horas continuas
3. **Múltiples reconexiones**: 20 cambios de red
4. **Historial completo**: 100+ validaciones almacenadas

## 🚀 Despliegue

### Build para Producción

#### Android APK
```bash
# Release APK
flutter build apk --release

# App Bundle para Play Store
flutter build appbundle --release

# Ubicación del archivo
# build/app/outputs/flutter-apk/app-release.apk
# build/app/outputs/bundle/release/app-release.aab
```

#### iOS IPA
```bash
# Requiere certificados de desarrollador
flutter build ios --release

# Para distribución
flutter build ipa --release
```

### Configuración de Signing

#### Android
```bash
# Generar keystore
keytool -genkey -v -keystore release-key.keystore -alias key -keyalg RSA -keysize 2048 -validity 10000

# Configurar en android/app/build.gradle
```

#### iOS
- Configurar en Xcode
- Apple Developer Account requerido
- Provisioning profiles actualizados

### Variables de Entorno Producción
```bash
# Configurar URL de API real
API_URL=https://api.production.com

# Deshabilitar debug
DEBUG_MODE=false

# Configurar device ID único por instalación
DEVICE_ID_STRATEGY=uuid
```

## 🏥 Checklist Pre-Producción

### ✅ Funcionalidad
- [ ] Todos los tests unitarios pasan
- [ ] Pruebas de integración exitosas
- [ ] Validación con API real funciona
- [ ] Modo offline completamente funcional
- [ ] Audio y vibración funcionan en dispositivos objetivo

### ✅ Performance
- [ ] Tiempo de validación < 2 segundos
- [ ] Sin memory leaks detectados
- [ ] Framerate estable en dispositivos objetivo
- [ ] Batería: uso eficiente confirmado

### ✅ Seguridad
- [ ] Códigos QR no se logean completos
- [ ] URLs de API validadas
- [ ] Rate limiting implementado
- [ ] Datos sensibles encriptados localmente

### ✅ Usabilidad
- [ ] Interfaz testada en múltiples tamaños de pantalla
- [ ] Accesibilidad verificada
- [ ] Orientación portrait/landscape funcional
- [ ] Feedback visual/audio claro

### ✅ Compatibilidad
- [ ] Android 8.0+ (API 26+)
- [ ] iOS 12.0+
- [ ] Múltiples modelos de lectores QR testados
- [ ] Diferentes velocidades de red testadas

## 🐛 Troubleshooting

### Problemas Comunes y Soluciones

#### 🔧 "Lector QR no funciona"
**Síntomas**: La app no recibe códigos QR
**Solución**:
```bash
# 1. Verificar configuración HID del lector
# 2. Comprobar que termina en Enter/newline
# 3. Probar en notepad/editor de texto primero
# 4. Verificar que el TextField invisible tiene focus
```

#### 🔧 "Error de conexión persistente"
**Síntomas**: Siempre muestra error de API
**Solución**:
```bash
# 1. Verificar URL en configuración
# 2. Probar endpoint manualmente con curl
# 3. Verificar conectividad del dispositivo
# 4. Revisar logs de la app
```

#### 🔧 "App lenta o consume mucha batería"
**Síntomas**: Performance degradada
**Solución**:
```bash
# 1. Limpiar historial de validaciones
# 2. Reiniciar la aplicación
# 3. Verificar versión de Flutter actualizada
# 4. Usar flutter run --profile para diagnosis
```

#### 🔧 "Audio no reproduce"
**Síntomas**: Sin sonidos de confirmación
**Solución**:
```bash
# 1. Verificar archivos en assets/sounds/
# 2. Comprobar permisos de audio del dispositivo
# 3. Aumentar volumen del dispositivo
# 4. Los sonidos del sistema funcionan como fallback
```

### Logs de Debug
```bash
# Habilitar logs detallados
flutter run --debug

# Filtrar logs específicos
adb logcat | grep "TicketScanner"

# Logs de red
adb logcat | grep "HTTP"
```

### Información de Debug Útil
- Versión de Flutter y Dart
- Modelo de dispositivo y versión OS
- Configuración de red actual
- URL de API configurada
- Historial de errores recientes

---

## 📞 Soporte Técnico

Para problemas no cubiertos en esta guía:
- 📧 **Email**: dev-support@ticketscanner.com  
- 📱 **Slack**: #ticket-scanner-support
- 🌐 **Wiki**: https://github.com/company/ticket-scanner/wiki
- 🎫 **Issues**: https://github.com/company/ticket-scanner/issues

---

**Última actualización**: Diciembre 2024  
**Versión de la guía**: 1.0.0 