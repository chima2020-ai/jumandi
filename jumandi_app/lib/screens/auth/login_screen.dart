import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/jumandi_button.dart';
import '../../widgets/common/jumandi_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    try {
      final ok = await auth.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      if (ok) {
        context.go(auth.homeRoute);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error ?? 'Login failed')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Welcome Back',
                      style: AppTextStyles.heading.copyWith(fontSize: 26),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in as customer or delivery agent.',
                      style: AppTextStyles.body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Column(
                        children: [
                          JumandiTextField(
                            label: 'EMAIL',
                            controller: _emailController,
                            hint: 'email@jumandi.com',
                            prefixIcon: Icons.alternate_email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 18),
                          JumandiTextField(
                            label: 'PASSWORD',
                            controller: _passwordController,
                            hint: '••••••••',
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscure,
                            trailingLabel: 'FORGOT?',
                            onTrailingTap: () {},
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          const SizedBox(height: 28),
                          JumandiPrimaryButton(
                            label: 'SIGN IN',
                            icon: Icons.bolt,
                            loading: _loading,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () => context.push('/register'),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: AppTextStyles.body,
                                children: [
                                  const TextSpan(text: 'New customer? '),
                                  TextSpan(
                                    text: 'CREATE ACCOUNT',
                                    style: AppTextStyles.button.copyWith(color: AppColors.brandYellow),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () => context.go('/admin/login'),
                            icon: const Icon(Icons.admin_panel_settings, color: AppColors.brandGold),
                            label: Text(
                              'ADMIN PORTAL',
                              style: AppTextStyles.button.copyWith(color: AppColors.brandGold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Delivery logins are created by admin.',
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                            textAlign: TextAlign.center,
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
    );
  }
}
