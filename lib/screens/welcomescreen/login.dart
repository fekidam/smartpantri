import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../generated/l10n.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final Function(bool)? setGuestMode;
  const LoginScreen({Key? key, this.setGuestMode}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _error;
  bool _obscure = true;
  bool _loading = false;
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
  }

  Color _darken(Color color, [double amount = .2]) {
    final hsl = HSLColor.fromColor(color);
    final l = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(l).toColor();
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback? onPressed,
    Color? baseColor,
  }) {
    final bg = _darken(baseColor ?? Theme.of(context).colorScheme.primary);
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: bg,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
      ),
      child: Text(text),
    );
  }

  Future<void> _login() async {
    setState(() {
      _error = null;
      _loading = true;
    });

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    final result = await _authService.login(
      context: context,
      email: email,
      password: pass,
    );

    setState(() {
      _loading = false;
      if (result['success']) {
        widget.setGuestMode?.call(false);
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _error = result['error'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 40),
              Text(
                AppLocalizations.of(context)!.logIn,
                style: theme.textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              _buildField(
                controller: _emailCtrl,
                hint: AppLocalizations.of(context)!.enterYourEmail,
                icon: Icons.email_outlined,
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 20),
              _buildField(
                controller: _passCtrl,
                hint: AppLocalizations.of(context)!.password,
                icon: Icons.lock_outline,
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: theme.hintColor,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 32),
              _buildActionButton(
                text: AppLocalizations.of(context)!.logIn,
                onPressed: _loading ? null : _login,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: Text(
                  AppLocalizations.of(context)!.dontHaveAnAccountRegister,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    required void Function(String) onSubmitted,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: theme.textTheme.bodyMedium,
        prefixIcon: Icon(icon, color: theme.hintColor),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onFieldSubmitted: onSubmitted,
    );
  }
}