import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/user_model.dart';
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
  bool _isUser = true;
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
    final ok = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
      role: _isUser ? UserRole.customer : UserRole.delivery,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      if (auth.isDelivery || !_isUser) {
        context.go('/delivery');
      } else {
        context.go('/home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Login failed')),
      );
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
                            label: 'IDENTIFICATION',
                            controller: _emailController,
                            hint: 'email@jumandi.com',
                            prefixIcon: Icons.alternate_email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 18),
                          JumandiTextField(
                            label: 'ENCRYPTION KEY',
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
                            onTap: () => context.push('/register'),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: AppTextStyles.body,
                                children: [
                                  const TextSpan(text: 'New to the forge? '),
                                  TextSpan(
                                    text: 'CREATE ACCOUNT',
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
