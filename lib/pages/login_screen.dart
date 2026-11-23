import 'package:flutter/material.dart';

import '../config/brand.dart';
import '../data/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/auth_header.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Used to validate all fields inside the login form
  final _formKey = GlobalKey<FormState>();

  // Controllers store the values entered by the user
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  // Controls whether the password is hidden or visible
  bool _obscurePassword = true;

  // Shown under the form when the credentials do not match an account
  String? _loginError;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Validates the form, then checks the credentials against saved accounts
  void _handleLogin() {
    setState(() => _loginError = null);
    if (!_formKey.currentState!.validate()) return;
    final error = store.login(
      _identifierController.text,
      _passwordController.text,
    );
    if (error != null) {
      setState(() => _loginError = error);
      return;
    }
    // Staff go to the admin dashboard, customers to the storefront.
    Navigator.pushReplacementNamed(
      context,
      store.isAdmin ? '/admin' : '/home',
    );
  }

  void _fillDemo(String email, String password) {
    setState(() {
      _identifierController.text = email;
      _passwordController.text = password;
      _loginError = null;
    });
  }

  Future<void> _forgotPassword() async {
    final colors = AppColors.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forgot password?'),
        content: Text(
          'Password reset emails need an email service, which is not connected in demo mode. '
          'Ask the café owner to help, or create a new account.',
          style: TextStyle(color: colors.oat),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: TextStyle(color: colors.gold)),
          ),
        ],
      ),
    );
  }

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
            // The banner steps aside while the keyboard is open so the form
            // keeps enough room on small screens.
            if (!keyboardOpen) const AuthHeader(),
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
                            Text(Brand.loginHeading, style: serifDisplay.copyWith(fontSize: 22)),
                            const SizedBox(height: 6),
                            Text(
                              Brand.loginSubtitle,
                              style: TextStyle(color: colors.oat, fontSize: 13),
                            ),
                            const SizedBox(height: 32),
                            AppTextField(
                              label: 'Email or Username',
                              hint: 'you@example.com',
                              controller: _identifierController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter your email or username';
                                }
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
                                if (value == null || value.isEmpty) {
                                  return 'Enter your password';
                                }
                                return null;
                              },
                              // Button for showing or hiding the password
                              suffixIcon: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                tooltip: 'Show or hide password',
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: colors.oat,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _forgotPassword,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(color: colors.oat, fontSize: 12),
                                ),
                              ),
                            ),
                            if (_loginError != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _loginError!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: AppButton(label: 'Log in', onPressed: _handleLogin),
                            ),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                Expanded(child: Divider(color: colors.line, thickness: 1)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    'or',
                                    style: TextStyle(
                                      color: colors.oat.withValues(alpha: 0.8),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: colors.line, thickness: 1)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Social sign-in is only a visual placeholder in this build.
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (final icon in [
                                  Icons.email_rounded,
                                  Icons.facebook_rounded,
                                  Icons.tiktok_rounded,
                                ]) ...[
                                  SocialLoginButton(
                                    icon: icon,
                                    onTap: () => showMessage(
                                      context,
                                      'Social sign-in is not connected yet. Use email and password.',
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                ],
                              ],
                            ),
                            const SizedBox(height: 28),
                            Center(
                              child: GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/signup'),
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(color: colors.oat, fontSize: 13),
                                    children: [
                                      TextSpan(text: 'New to ${store.settings.name}? '),
                                      TextSpan(
                                        text: 'Create an account',
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
                            const SizedBox(height: 22),
                            // Demo shortcuts: they only fill the form, you still tap Log in.
                            Center(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  ActionChip(
                                    avatar: Icon(Icons.person_outline, size: 16, color: colors.gold),
                                    label: const Text('Customer demo'),
                                    onPressed: () => _fillDemo(
                                      Brand.demoCustomerEmail,
                                      Brand.demoCustomerPassword,
                                    ),
                                  ),
                                  ActionChip(
                                    avatar: Icon(Icons.storefront_outlined, size: 16, color: colors.gold),
                                    label: const Text('Admin demo'),
                                    onPressed: () => _fillDemo(
                                      Brand.demoAdminEmail,
                                      Brand.demoAdminPassword,
                                    ),
                                  ),
                                ],
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
