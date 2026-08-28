import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/presentation/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Lectura dinámica desde variables de entorno (Vercel) con respaldo local (defaultValue)
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://lxxzuqpogmuayfefiuiy.supabase.co',
  );

  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4eHp1cXBvZ211YXlmZWZpdWl5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc1OTc4NzYsImV4cCI6MjEwMzE3Mzg3Nn0.Qr2vM2Bi_ylycYXbP9voIQhHHoRyIQq3r6cfeLt0p0w',
  );

  // 2. Inicialización de Supabase con respaldo para modo incógnito (EmptyLocalStorage)
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Aviso: Falló almacenamiento local de Supabase ($e). Reintentando con EmptyLocalStorage...');
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          localStorage: EmptyLocalStorage(),
        ),
      );
    } catch (e2, stack) {
      debugPrint('Error crítico inicializando Supabase: $e2\n$stack');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema BIP Web',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
