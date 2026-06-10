import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import '../services/auth_service.dart';
import '../services/biometric_auth_service.dart';
import '../../../routes/app_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/security/input_validator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _biometricAuth = GetIt.instance<BiometricAuthService>();
  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  bool _enableBiometric = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await _biometricAuth.isAvailable();
    final enabled = await _biometricAuth.isEnabled();
    if (!mounted) return;
    setState(() => _biometricAvailable = available);
    if (available && enabled) {
      _doBiometricLogin();
    }
  }

  Future<void> _doBiometricLogin() async {
    final authed = await _biometricAuth.authenticate();
    if (!mounted || !authed) return;
    final username = await _biometricAuth.getStoredUsername();
    if (username == null) return;
    final auth = context.read<AuthService>();
    final success = await auth.loginByUsername(username);
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, AppRouter.dashboard);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);

    final auth = context.read<AuthService>();
    final result = await auth.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      if (_enableBiometric) {
        try {
          await _biometricAuth.enable(_usernameController.text.trim());
        } catch (e) {
          debugPrint('Failed to enable biometric during login: $e');
        }
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRouter.dashboard);
    } else if (result.isRateLimited) {
      final rateLimitedResult = result as LoginRateLimited;
      final minutes = rateLimitedResult.seconds ~/ 60;
      final seconds = rateLimitedResult.seconds % 60;
      setState(() => _error = 'Too many attempts. Try again in ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}');
    } else {
      setState(() => _error = result.errorMessage ?? 'Invalid username or password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthService>().isLoading;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Semantics(
                    label: 'MediOS Pharmacy App Icon',
                    child: const Icon(Icons.local_pharmacy, size: 80, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    header: true,
                    child: Text('MediOS', style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold, color: AppColors.primary,
                    )),
                  ),
                  const SizedBox(height: 8),
                  Text('Pharmacy Management System',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  )),
                  const SizedBox(height: 48),
                  Semantics(
                    textField: true,
                    child: TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'Enter your username',
                        prefixIcon: Icon(Icons.person),
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _formKey.currentState?.validate(),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Username is required';
                        if (!InputValidator.isValidUsername(v)) {
                          return 'Username must be 3-30 characters (letters, numbers, underscores)';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    textField: true,
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: Semantics(
                          label: _obscurePassword ? 'Show password' : 'Hide password',
                          button: true,
                          child: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => _formKey.currentState?.validate(),
                      validator: (v) => v == null || v.isEmpty ? 'Enter password' : null,
                      onFieldSubmitted: (_) => _login(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(_error!, style: const TextStyle(color: AppColors.error)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Semantics(
                    button: true,
                    label: 'Login',
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _login,
                        child: isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Login', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                  if (_biometricAvailable) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      button: true,
                      label: 'Login with Biometrics',
                      child: SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: isLoading ? null : _doBiometricLogin,
                          icon: const Icon(Icons.fingerprint),
                          label: const Text('Login with Biometrics'),
                        ),
                      ),
                    ),
                    Semantics(
                      label: 'Enable biometric login toggle',
                      child: CheckboxListTile(
                        value: _enableBiometric,
                        onChanged: (v) => setState(() => _enableBiometric = v ?? false),
                        title: const Text('Enable biometric login'),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
