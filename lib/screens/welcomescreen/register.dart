import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartpantri/services/auth_service.dart';

import '../../generated/l10n.dart';

class RegisterScreen extends StatefulWidget {
  final Function(bool)? setGuestMode;
  const RegisterScreen({Key? key, this.setGuestMode}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  DateTime? _birthDate;
  bool _loading = false;
  final AuthService _authService = AuthService();

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

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await _authService.register(
      context: context,
      firstName: _firstNameCtrl.text,
      lastName: _lastNameCtrl.text,
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      confirmPassword: _confirmPassCtrl.text,
      birthDate: _birthDate,
    );
    setState(() => _loading = false);
    if (result['success']) {
      widget.setGuestMode?.call(false);
      Navigator.pushReplacementNamed(context, '/verify-email');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'])),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                Text(
                  AppLocalizations.of(context)!.register,
                  style: theme.textTheme.headlineSmall!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                // First Name
                TextFormField(
                  controller: _firstNameCtrl,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.firstName,
                    prefixIcon: Icon(Icons.person_outline, color: theme.hintColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? AppLocalizations.of(context)!.firstNameRequired
                      : null,
                ),
                const SizedBox(height: 16),

                // Last Name
                TextFormField(
                  controller: _lastNameCtrl,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.lastName,
                    prefixIcon: Icon(Icons.person_outline, color: theme.hintColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? AppLocalizations.of(context)!.lastNameRequired
                      : null,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.email,
                    prefixIcon: Icon(Icons.email_outlined, color: theme.hintColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return AppLocalizations.of(context)!.emailRequired;
                    }
                    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                    if (!regex.hasMatch(v)) {
                      return AppLocalizations.of(context)!.invalidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.password,
                    prefixIcon: Icon(Icons.lock_outline, color: theme.hintColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return AppLocalizations.of(context)!.passwordRequired;
                    }
                    if (v.length < 6) {
                      return AppLocalizations.of(context)!.passwordTooShort;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPassCtrl,
                  obscureText: true,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.confirmPassword,
                    prefixIcon: Icon(Icons.lock_outline, color: theme.hintColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return AppLocalizations.of(context)!.confirmPasswordRequired;
                    }
                    if (v != _passwordCtrl.text) {
                      return AppLocalizations.of(context)!.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Birth Date
                GestureDetector(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.selectBirthDate,
                      prefixIcon: Icon(Icons.calendar_today_outlined, color: theme.hintColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      _birthDate != null
                          ? DateFormat('yyyy-MM-dd').format(_birthDate!)
                          : AppLocalizations.of(context)!.selectBirthDate,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Register Button
                _buildActionButton(
                  text: AppLocalizations.of(context)!.register,
                  onPressed: _loading ? null : _register,
                ),
                const SizedBox(height: 16),

                // Already have account?
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: Text(
                    AppLocalizations.of(context)!.alreadyHaveAccountLogin,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}