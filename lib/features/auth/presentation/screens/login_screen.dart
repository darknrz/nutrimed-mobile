import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
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

  bool _loading       = false;
  bool _showEmailForm = false;
  bool _isRegister    = false;

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
      // Forzar cierre de sesión previa para obtener token fresco
      await _googleSignIn.signOut();

      final account = await _googleSignIn.signIn();
      if (account == null) return;

      // Limpiar cache del token anterior
      await account.clearAuthCache();
      final auth    = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw Exception('No se obtuvo idToken');

      final res = await sl<DioClient>().post(
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
      await _saveAndNavigate(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? e.response!.data['message'] ?? 'Error de servidor'
          : 'Error de servidor';
      _showError(msg);
    } catch (e) {
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
    await storage.saveUserInfo(
      userId:   user['id'].toString(),
      username: user['username'] as String? ?? '',
      name:     user['name']     as String? ?? '',
    );
    await storage.setNeedsOnboarding(!onboardingDone);
    if (mounted) {
      context.go(onboardingDone ? '/home' : '/onboarding');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: AppColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
      color: const Color(0xFFFFEEF1),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFFFB3C1), width: 0.5),
    ),
    child: const Icon(Icons.eco_rounded, size: 38, color: AppColors.primary),
  );

  Widget _buildTitle() => RichText(
    textAlign: TextAlign.center,
    text: TextSpan(
      style: const TextStyle(fontSize: 28, height: 1.25, color: AppColors.textPrimary),
      children: [
        const TextSpan(text: 'Alimenta tu\n'),
        TextSpan(
          text: 'bienestar',
          style: TextStyle(
            color: AppColors.primary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ),
  );

  Widget _buildSubtitle() => const Text(
    'Recetas personalizadas según\ntu condición de salud.',
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
  );

  Widget _buildGoogleButton() => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: _loading ? null : _loginWithGoogle,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(vertical: 15),
        side: const BorderSide(color: AppColors.border, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: _loading
          ? const SizedBox(width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
          : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            'https://www.google.com/favicon.ico',
            width: 18, height: 18,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.g_mobiledata_rounded,
              size: 22, color: Color(0xFF4285F4),
            ),
          ),
          const SizedBox(width: 10),
          const Text('Continuar con Google',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              )),
        ],
      ),
    ),
  );

  Widget _buildDivider() => Row(
    children: [
      Expanded(child: Divider(color: AppColors.border)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('o',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ),
      Expanded(child: Divider(color: AppColors.border)),
    ],
  );

  Widget _buildEmailButton() => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: () => setState(() { _showEmailForm = true; _isRegister = false; }),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mail_outline, size: 18),
          SizedBox(width: 8),
          Text('Continuar con email',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 14, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _isRegister ? 'Crear cuenta' : 'Iniciar sesión',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500,
                color: AppColors.textPrimary),
          ),
        ],
      ),
      const SizedBox(height: 20),

      // Tab selector
      Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
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
        _buildField(_nameCtrl,     'Nombre completo',   Icons.person_outline,    false),
        const SizedBox(height: 12),
        _buildField(_usernameCtrl, 'Nombre de usuario', Icons.alternate_email,   false),
        const SizedBox(height: 12),
      ],
      _buildField(_emailCtrl,
          _isRegister ? 'Email' : 'Email o usuario', Icons.mail_outline, false),
      const SizedBox(height: 12),
      _buildPasswordField(),
      const SizedBox(height: 24),

      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : _submitEmailForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _loading
              ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(
            _isRegister ? 'Crear cuenta' : 'Ingresar',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ],
  );

  Widget _tabBtn(String label, bool active, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: active ? Border.all(color: AppColors.border) : null,
        ),
        child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? AppColors.primary : AppColors.textSecondary,
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
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 18),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary)),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      );

  Widget _buildPasswordField() => TextField(
    controller: _passwordCtrl,
    obscureText: _obscure,
    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
    decoration: InputDecoration(
      hintText: 'Contraseña',
      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 18),
      suffixIcon: GestureDetector(
        onTap: () => setState(() => _obscure = !_obscure),
        child: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textSecondary, size: 18,
        ),
      ),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary)),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    ),
  );

  Widget _buildTerms() => const Text(
    'Al continuar aceptas los Términos de uso\ny la Política de privacidad',
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.5),
  );
}