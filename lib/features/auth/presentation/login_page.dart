import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/security/servicio_permisos.dart';
import '../../security/presentation/paginas/navegacion_principal_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showForgotPassword = false;

  Future<void> _iniciarSesion() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese correo y contraseña.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Autenticación con Supabase Auth
      final respuesta = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (respuesta.session != null && mounted) {
        // 2. Cargar permisos efectivos del usuario en memoria antes de navegar
        await ServicioPermisos().cargarPermisosUsuario();

        if (!mounted) return;

        // 3. Redirección con permisos ya listos en memoria al Contenedor Principal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const NavegacionPrincipalPage(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _recuperarContrasena() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese su dirección de correo institucional.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Supabase reset password trigger
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.bipweb://reset-callback',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se ha enviado el enlace de recuperación a su correo electrónico.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _showForgotPassword = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar solicitud: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    final formPanel = Container(
      width: isDesktop ? 480 : double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo and Title for mobile view
              if (!isDesktop) ...[
                const Icon(Icons.account_balance, size: 52, color: Color(0xFF24389C)),
                const SizedBox(height: 12),
                const Text(
                  'Sistema BIP Web',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF191C1E),
                  ),
                ),
                const Text(
                  'Módulo de Administración y Seguridad',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 32),
              ],

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showForgotPassword
                    ? _buildForgotPasswordView()
                    : _buildLoginView(),
              ),
            ],
          ),
        ),
      ),
    );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Left decorative panel matching Stitch premium styling
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF24389C), Color(0xFF192565)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(64),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_balance, size: 64, color: Colors.white),
                    const SizedBox(height: 32),
                    const Text(
                      'Gestor de Iniciativas\nde Proyectos',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Banco de Iniciativas de Proyectos (BIP-SNIPH)\nSecretaría de Finanzas - República de Honduras',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Acceso Seguro',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Autenticación institucional y control de acceso basado en roles (RBAC).',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            formPanel,
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(child: formPanel),
    );
  }

  Widget _buildLoginView() {
    return Column(
      key: const ValueKey('login_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Iniciar Sesión',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF191C1E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingrese sus credenciales institucionales para acceder al sistema.',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 32),
        
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Correo Institucional',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Contraseña',
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _iniciarSesion(),
        ),
        const SizedBox(height: 12),
        
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => setState(() => _showForgotPassword = true),
            child: const Text(
              '¿Olvidó su contraseña?',
              style: TextStyle(
                color: Color(0xFF24389C),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        ElevatedButton(
          onPressed: _isLoading ? null : _iniciarSesion,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF24389C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Ingresar al Sistema',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordView() {
    return Column(
      key: const ValueKey('forgot_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Recuperar Contraseña',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF191C1E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingrese su dirección de correo institucional. Le enviaremos un enlace seguro para restablecer su contraseña.',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 32),
        
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Correo Registrado',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        
        ElevatedButton(
          onPressed: _isLoading ? null : _recuperarContrasena,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF24389C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Enviar Enlace de Recuperación',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(height: 12),
        
        OutlinedButton(
          onPressed: () => setState(() => _showForgotPassword = false),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: Color(0xFF24389C)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Volver al Iniciar Sesión',
            style: TextStyle(
              color: Color(0xFF24389C),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
