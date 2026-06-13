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
  bool _isUser = true;
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
    final ok = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      role: _isUser ? UserRole.customer : UserRole.delivery,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      context.go(_isUser ? '/otp' : '/delivery');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Registration failed')),
      );
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
                'Create Account',
                style: AppTextStyles.heading.copyWith(fontSize: 26),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Precision energy on-demand.',
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
                    UserPartnerToggle(
                      isUser: _isUser,
                      onChanged: (v) => setState(() => _isUser = v),
                    ),
                    const SizedBox(height: 24),
                    JumandiTextField(
                      label: 'FULL NAME',
                      controller: _nameController,
                      hint: 'Your name',
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 18),
                    JumandiTextField(
                      label: 'IDENTIFICATION',
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
                      label: 'ENCRYPTION KEY',
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
                      label: 'CONFIRM KEY',
                      controller: _confirmController,
                      obscureText: _obscure,
                      prefixIcon: Icons.lock_outline,
                    ),
                    const SizedBox(height: 28),
                    JumandiPrimaryButton(
                      label: 'AUTHENTICATE ACCESS',
                      icon: Icons.bolt,
                      loading: _loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.inputBorder)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('OR CONNECT VIA', style: AppTextStyles.label),
                        ),
                        Expanded(child: Divider(color: AppColors.inputBorder)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _socialButton('G', 'GOOGLE')),
                        const SizedBox(width: 12),
                        Expanded(child: _socialButton('f', 'FACEBOOK')),
                      ],
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

  Widget _socialButton(String logo, String label) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(logo, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.button.copyWith(color: AppColors.white, fontSize: 11)),
        ],
      ),
    );
  }
}
