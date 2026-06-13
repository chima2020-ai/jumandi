import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/jumandi_button.dart';
import '../../widgets/common/jumandi_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    try {
      final ok = await auth.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        role: UserRole.customer,
      );
      if (!mounted) return;
      if (ok) {
        context.go('/otp');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error ?? 'Registration failed')),
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Customer Account',
                style: AppTextStyles.heading.copyWith(fontSize: 26),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Sign up to book gas delivery. Delivery drivers are added by admin.',
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
                      label: 'FULL NAME',
                      controller: _nameController,
                      hint: 'Your name',
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 18),
                    JumandiTextField(
                      label: 'EMAIL',
                      controller: _emailController,
                      hint: 'email@jumandi.com',
                      prefixIcon: Icons.alternate_email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 18),
                    JumandiTextField(
                      label: 'PHONE',
                      controller: _phoneController,
                      hint: '+1234567890',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 18),
                    JumandiTextField(
                      label: 'PASSWORD',
                      controller: _passwordController,
                      obscureText: _obscure,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppColors.textMuted, size: 20),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: 18),
                    JumandiTextField(
                      label: 'CONFIRM PASSWORD',
                      controller: _confirmController,
                      obscureText: _obscure,
                      prefixIcon: Icons.lock_outline,
                    ),
                    const SizedBox(height: 28),
                    JumandiPrimaryButton(
                      label: 'CREATE ACCOUNT',
                      icon: Icons.bolt,
                      loading: _loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: AppTextStyles.body,
                          children: [
                            const TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Login',
                              style: AppTextStyles.button.copyWith(color: AppColors.brandYellow),
                            ),
                          ],
                        ),
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
