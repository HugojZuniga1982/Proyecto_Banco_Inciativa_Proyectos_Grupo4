// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_programacion_movil_grupo_4/main.dart';

void main() {
  testWidgets('BIP Web Login Screen renders successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our login screen elements are present.
    expect(find.text('Sistema BIP Web'), findsOneWidget);
    expect(find.text('Módulo de Administración y Seguridad'), findsOneWidget);
    expect(find.text('Correo Institucional'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
  });
}
