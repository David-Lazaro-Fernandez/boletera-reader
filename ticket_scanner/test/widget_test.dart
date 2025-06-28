// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ticket_scanner/main.dart';

void main() {
  testWidgets('Ticket Scanner app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TicketScannerApp());

    // Verify that the title is displayed
    expect(find.text('Validador de Tickets'), findsOneWidget);
    
    // Verify the initial state message
    expect(find.text('Listo para escanear'), findsOneWidget);
    
    // Verify the scan icon is present
    expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
  });

  testWidgets('Settings dialog can be opened', (WidgetTester tester) async {
    await tester.pumpWidget(const TicketScannerApp());

    // Find and tap the settings button
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Verify the settings dialog appears
    expect(find.text('Configuración'), findsOneWidget);
    expect(find.text('URL de API'), findsOneWidget);
  });
}
