import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';
import '../../widgets/common/jumandi_button.dart';
import '../../widgets/common/jumandi_text_field.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _checkingSetup = true;
  bool _needsSetup = false;

  @override
  void initState() {
    super.initState();
    _checkSetup();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkSetup() async {
    try {
      final status = await context.read<ApiService>().getAdminSetupStatus();
      if (mounted) {
        setState(() {
          _needsSetup = status.needsSetup;
          _checkingSetup = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checkingSetup = false);
    }
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
        if (auth.isAdmin) {
          context.go('/admin');
        } else {
          await auth.logout();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This account is not an admin')),
          );
        }
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
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.go('/login'),
        ),
        title: Text('Admin Login', style: AppTextStyles.headingSmall),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Admin Portal',
                style: AppTextStyles.heading.copyWith(fontSize: 26),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in to manage delivery agents and accounts.',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              if (_checkingSetup)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: CircularProgressIndicator(color: AppColors.brandYellow)),
                )
              else if (_needsSetup) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.brandYellow.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'No admin account exists yet.',
                        style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create the first admin account to get started.',
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      JumandiPrimaryButton(
                        label: 'CREATE ADMIN ACCOUNT',
                        icon: Icons.admin_panel_settings,
                        onPressed: () => context.go('/admin/setup'),
                      ),
                    ],
                  ),
                ),
              ],
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
                      label: 'ADMIN EMAIL',
                      controller: _emailController,
                      hint: 'admin@jumandi.com',
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
                      label: 'ADMIN SIGN IN',
                      icon: Icons.login,
                      loading: _loading,
                      onPressed: _submit,
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
