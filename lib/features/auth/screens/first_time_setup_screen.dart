import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../../../core/services/first_time_setup_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../routes/app_router.dart';
import '../../../core/security/password_policy.dart';

class FirstTimeSetupScreen extends StatefulWidget {
  const FirstTimeSetupScreen({super.key});

  @override
  State<FirstTimeSetupScreen> createState() => _FirstTimeSetupScreenState();
}

class _FirstTimeSetupScreenState extends State<FirstTimeSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _passwordStrength = 0;
  String? _passwordStrengthText;
  Color _passwordStrengthColor = AppColors.textSecondary;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final setupService = context.read<FirstTimeSetupService>();
    final strength = setupService.getPasswordStrength(_passwordController.text);
    
    setState(() {
      _passwordStrength = strength;
      
      if (strength < 30) {
        _passwordStrengthText = 'Weak';
        _passwordStrengthColor = AppColors.error;
      } else if (strength < 70) {
        _passwordStrengthText = 'Fair';
        _passwordStrengthColor = AppColors.warning;
      } else {
        _passwordStrengthText = 'Strong';
        _passwordStrengthColor = AppColors.success;
      }
    });
  }

  Future<void> _generateStrongPassword() async {
    final setupService = context.read<FirstTimeSetupService>();
    final suggestion = setupService.getPasswordSuggestion();
    
    setState(() {
      _passwordController.text = suggestion;
      _confirmPasswordController.text = suggestion;
      _updatePasswordStrength();
    });
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    final setupService = context.read<FirstTimeSetupService>();
    
    final result = await setupService.createFirstAdmin(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
    );

    if (!mounted) return;

    if (result.isSuccess) {
      if (result is FirstTimeSetupSuccess && result.autoLoginFailed) {
        // Setup successful but auto-login failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Admin account created. Please log in manually.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushReplacementNamed(context, AppRouter.login);
      } else {
        // Setup and auto-login successful
        Navigator.pushReplacementNamed(context, AppRouter.dashboard);
      }
    } else {
      // Setup failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Setup failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3 || value.length > 30) {
      return 'Username must be 3-30 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Only letters, numbers, and underscores are allowed';
    }
    return null;
  }

  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    if (value.length < 2 || value.length > 50) {
      return 'Full name must be 2-50 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(value)) {
      return 'Only letters, spaces, and hyphens are allowed';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    final errors = PasswordPolicy.validate(value);
    if (errors.isNotEmpty) {
      return errors.join('\n');
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final setupService = context.watch<FirstTimeSetupService>();
    final isLoading = setupService.isSettingUp;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.xl),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const Icon(
                    Icons.local_pharmacy,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  Text(
                    'Welcome to MediOS',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  Text(
                    'Pharmacy Management System',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  
                  // Setup instructions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'First-Time Setup',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.sm),
                          Text(
                            'Create your first administrator account to get started. '
                            'This account will have full access to all features.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppDimensions.md),
                          const Text(
                            'Password Requirements:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: AppDimensions.xs),
                          const Text('• Minimum 12 characters'),
                          const Text('• At least one uppercase letter'),
                          const Text('• At least one lowercase letter'),
                          const Text('• At least one number'),
                          const Text('• At least one special character'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  
                  // Form fields
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                      hintText: 'Enter your full name',
                    ),
                    validator: _validateFullName,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline),
                      hintText: 'Choose a username',
                    ),
                    validator: _validateUsername,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  
                  // Password field with strength indicator
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          hintText: 'Create a strong password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: _validatePassword,
                        textInputAction: TextInputAction.next,
                      ),
                      if (_passwordController.text.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.sm),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: _passwordStrength / 100,
                                backgroundColor: AppColors.border,
                                color: _passwordStrengthColor,
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.md),
                            Text(
                              _passwordStrengthText ?? '',
                              style: TextStyle(
                                color: _passwordStrengthColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  
                  // Confirm password
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      hintText: 'Re-enter your password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: _validateConfirmPassword,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _generateStrongPassword,
                          icon: const Icon(Icons.autorenew),
                          label: const Text('Generate Strong Password'),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.lg),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : _completeSetup,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check_circle),
                          label: isLoading
                              ? const Text('Setting up...')
                              : const Text('Complete Setup'),
                        ),
                      ),
                    ],
                  ),
                  
                  // Error message
                  if (setupService.error != null) ...[
                    const SizedBox(height: AppDimensions.lg),
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.md),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error),
                          const SizedBox(width: AppDimensions.md),
                          Expanded(
                            child: Text(
                              setupService.error!,
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
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