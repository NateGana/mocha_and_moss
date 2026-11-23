import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/auth_header.dart';
import '../widgets/common.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Used to validate all fields inside the sign-up form
  final _formKey = GlobalKey<FormState>();

  // Controllers store the values entered by the user
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Controls whether each password field is hidden or visible
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Validates the form and saves the new account on this device
  void _handleSignUp() {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final error = store.register(
      name: _fullNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    // Replace the stack so Back from Home doesn't return to Sign Up.
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  Widget _eye(bool obscured, VoidCallback onTap, AppColors colors) => IconButton(
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    tooltip: 'Show or hide password',
    icon: Icon(
      obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      color: colors.oat,
      size: 20,
    ),
    onPressed: onTap,
  );

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final serifDisplay = AppFonts.serif(color: colors.latte);
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: colors.espresso,
      body: PhoneFrame(
        child: Column(
          children: [
            if (!keyboardOpen) const AuthHeader(heightFactor: 0.26),
            Expanded(
              child: SafeArea(
                top: keyboardOpen,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Create an account', style: serifDisplay.copyWith(fontSize: 22)),
                            const SizedBox(height: 6),
                            Text(
                              'Join us for your daily mocha',
                              style: TextStyle(color: colors.oat, fontSize: 13),
                            ),
                            const SizedBox(height: 28),
                            AppTextField(
                              label: 'Full name',
                              hint: 'Jane Doe',
                              controller: _fullNameController,
                              keyboardType: TextInputType.name,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter your full name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 22),
                            AppTextField(
                              label: 'Email',
                              hint: 'you@example.com',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter your email';
                                }
                                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
                                  return 'Please enter a valid email address.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 22),
                            AppTextField(
                              label: 'Contact number',
                              hint: '09XX XXX XXXX',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                                if (digits.length < 10) return 'Enter a valid contact number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 22),
                            AppTextField(
                              label: 'Password',
                              hint: '••••••',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Enter a password';
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters.';
                                }
                                return null;
                              },
                              suffixIcon: _eye(
                                _obscurePassword,
                                () => setState(() => _obscurePassword = !_obscurePassword),
                                colors,
                              ),
                            ),
                            const SizedBox(height: 22),
                            AppTextField(
                              label: 'Confirm password',
                              hint: '••••••',
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Confirm your password';
                                if (value != _passwordController.text) return 'Passwords do not match';
                                return null;
                              },
                              suffixIcon: _eye(
                                _obscureConfirmPassword,
                                () => setState(
                                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                                ),
                                colors,
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                              ),
                            ],
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: AppButton(label: 'Sign up', onPressed: _handleSignUp),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(color: colors.oat, fontSize: 13),
                                    children: [
                                      const TextSpan(text: 'Already have an account? '),
                                      TextSpan(
                                        text: 'Log in',
                                        style: TextStyle(
                                          color: colors.gold,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
