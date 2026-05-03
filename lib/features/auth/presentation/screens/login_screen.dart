import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final _googleSignIn = GoogleSignIn(
    serverClientId: '261849466585-1kr2mmin7f3ul6egqmbn5ovpfo5oh780.apps.googleusercontent.com',
  );

  bool _loading = false;
  bool _showEmailForm = false;
  bool _isRegister = false;

  final _emailCtrl    = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl     = TextEditingController();
  bool  _obscure      = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return;
      final auth    = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw Exception('No se obtuvo idToken');
      final res  = await sl<DioClient>().post(
        ApiConstants.authGoogle, {'idToken': idToken},
      );
      await _saveAndNavigate(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? e.response!.data['message'] ?? 'Error de servidor'
          : 'Error de servidor';
      _showError(msg);
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitEmailForm() async {
    setState(() => _loading = true);
    debugPrint('=== SUBMIT INICIADO');
    try {
      final Response res;
      if (_isRegister) {
        res = await sl<DioClient>().post(ApiConstants.register, {
          'email':    _emailCtrl.text.trim(),
          'username': _usernameCtrl.text.trim(),
          'password': _passwordCtrl.text,
          'name':     _nameCtrl.text.trim(),
        });
      } else {
        res = await sl<DioClient>().post(ApiConstants.login, {
          'emailOrUsername': _emailCtrl.text.trim(),
          'password':        _passwordCtrl.text,
        });
      }
      debugPrint('=== RESPONSE STATUS: ${res.statusCode}');
      debugPrint('=== RESPONSE DATA TYPE: ${res.data.runtimeType}');
      final data = res.data as Map<String, dynamic>;
      debugPrint('=== LLAMANDO saveAndNavigate');
      await _saveAndNavigate(data);
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? e.response!.data['message'] ?? 'Error de servidor'
          : 'Error de servidor';
      _showError(msg);
    } catch (e, stack) {
      debugPrint('=== ERROR: $e');
      debugPrint('=== STACK: $stack');
      _showError('Ocurrió un error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveAndNavigate(Map<String, dynamic> data) async {
    final storage = sl<SecureStorage>();

    await storage.saveTokens(
      access:  data['accessToken'] as String,
      refresh: data['refreshToken'] as String,
    );

    final user           = data['user'] as Map<String, dynamic>;
    final onboardingDone = user['onboardingDone'] as bool? ?? false;

    // ← guardar nombre y username
    await storage.saveUserInfo(
      userId:   user['id'].toString(),
      username: user['username'] as String? ?? '',
      name:     user['name']     as String? ?? '',
    );

    await storage.setNeedsOnboarding(!onboardingDone);

    if (mounted) {
      if (!onboardingDone) {
        context.go('/onboarding');
      } else {
        context.go('/home');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFE85D4A),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1412),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  _buildLogo(),
                  const SizedBox(height: 28),
                  _buildTitle(),
                  const SizedBox(height: 8),
                  _buildSubtitle(),
                  const Spacer(),
                  const SizedBox(height: 32),
                  if (!_showEmailForm) ...[
                    _buildGoogleButton(),
                    const SizedBox(height: 12),
                    _buildDivider(),
                    const SizedBox(height: 12),
                    _buildEmailButton(),
                  ] else ...[
                    _buildEmailForm(),
                  ],
                  const SizedBox(height: 24),
                  _buildTerms(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() => Container(
    width: 76, height: 76,
    decoration: BoxDecoration(
      color: const Color(0xFF1A4A30),
      borderRadius: BorderRadius.circular(22),
    ),
    child: const Icon(Icons.eco_rounded, size: 38,
        color: Color(0xFF3ECF7C)),
  );

  Widget _buildTitle() => RichText(
    textAlign: TextAlign.center,
    text: const TextSpan(
      style: TextStyle(fontSize: 28, height: 1.25,
          color: Color(0xFFE8F0EC)),
      children: [
        TextSpan(text: 'Alimenta tu\n'),
        TextSpan(
          text: 'bienestar',
          style: TextStyle(color: Color(0xFF3ECF7C),
              fontStyle: FontStyle.italic),
        ),
      ],
    ),
  );

  Widget _buildSubtitle() => const Text(
    'Recetas personalizadas según\ntu condición de salud.',
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: 14, color: Color(0xFF8FA899),
        height: 1.6),
  );

  Widget _buildGoogleButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _loading ? null : _loginWithGoogle,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
      child: _loading
          ? const SizedBox(width: 20, height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFF1A1A1A)))
          : const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.g_mobiledata_rounded, size: 24,
              color: Color(0xFF4285F4)),
          SizedBox(width: 10),
          Text('Continuar con Google',
              style: TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );

  Widget _buildDivider() => Row(
    children: [
      Expanded(child: Divider(
          color: Colors.white.withOpacity(0.1))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('o', style: TextStyle(
            color: Colors.white.withOpacity(0.3), fontSize: 13)),
      ),
      Expanded(child: Divider(
          color: Colors.white.withOpacity(0.1))),
    ],
  );

  Widget _buildEmailButton() => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: () => setState(() {
        _showEmailForm = true;
        _isRegister = false;
      }),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFE8F0EC),
        side: BorderSide(color: Colors.white.withOpacity(0.15)),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mail_outline, size: 18),
          SizedBox(width: 8),
          Text('Continuar con email',
              style: TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    ),
  );

  Widget _buildEmailForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showEmailForm = false),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2420),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 14, color: Color(0xFF8FA899)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _isRegister ? 'Crear cuenta' : 'Iniciar sesión',
            style: const TextStyle(fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFFE8F0EC)),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161E1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.white.withOpacity(0.08)),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _tabBtn('Iniciar sesión', !_isRegister,
                    () => setState(() => _isRegister = false)),
            _tabBtn('Crear cuenta', _isRegister,
                    () => setState(() => _isRegister = true)),
          ],
        ),
      ),
      const SizedBox(height: 20),
      if (_isRegister) ...[
        _buildField(_nameCtrl, 'Nombre completo',
            Icons.person_outline, false),
        const SizedBox(height: 12),
        _buildField(_usernameCtrl, 'Nombre de usuario',
            Icons.alternate_email, false),
        const SizedBox(height: 12),
      ],
      _buildField(
        _emailCtrl,
        _isRegister ? 'Email' : 'Email o usuario',
        Icons.mail_outline, false,
      ),
      const SizedBox(height: 12),
      _buildPasswordField(),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : _submitEmailForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3ECF7C),
            foregroundColor: const Color(0xFF0F1412),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: _loading
              ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF0F1412)))
              : Text(
            _isRegister ? 'Crear cuenta' : 'Ingresar',
            style: const TextStyle(fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ],
  );

  Widget _tabBtn(String label, bool active,
      VoidCallback onTap) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF1E2923)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              border: active
                  ? Border.all(
                  color: Colors.white.withOpacity(0.1))
                  : null,
            ),
            child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active
                    ? FontWeight.w600 : FontWeight.w400,
                color: active
                    ? const Color(0xFF3ECF7C)
                    : const Color(0xFF8FA899),
              ),
            ),
          ),
        ),
      );

  Widget _buildField(TextEditingController ctrl,
      String hint, IconData icon, bool obscure) =>
      TextField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(
            color: Color(0xFFE8F0EC), fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: Color(0xFF566860), fontSize: 14),
          prefixIcon: Icon(icon,
              color: const Color(0xFF566860), size: 18),
          filled: true,
          fillColor: const Color(0xFF161E1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: Colors.white.withOpacity(0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: Colors.white.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: Color(0xFF3ECF7C)),
          ),
          contentPadding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 16),
        ),
      );

  Widget _buildPasswordField() => TextField(
    controller: _passwordCtrl,
    obscureText: _obscure,
    style: const TextStyle(
        color: Color(0xFFE8F0EC), fontSize: 14),
    decoration: InputDecoration(
      hintText: 'Contraseña',
      hintStyle: const TextStyle(
          color: Color(0xFF566860), fontSize: 14),
      prefixIcon: const Icon(Icons.lock_outline,
          color: Color(0xFF566860), size: 18),
      suffixIcon: GestureDetector(
        onTap: () => setState(() => _obscure = !_obscure),
        child: Icon(
          _obscure
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: const Color(0xFF566860), size: 18,
        ),
      ),
      filled: true,
      fillColor: const Color(0xFF161E1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: Colors.white.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: Color(0xFF3ECF7C)),
      ),
      contentPadding: const EdgeInsets.symmetric(
          vertical: 14, horizontal: 16),
    ),
  );

  Widget _buildTerms() => const Text(
    'Al continuar aceptas los Términos de uso\ny la Política de privacidad',
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: 11,
        color: Color(0xFF566860), height: 1.5),
  );
}