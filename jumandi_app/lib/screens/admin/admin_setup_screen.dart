import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';
import '../../widgets/common/jumandi_button.dart';
import '../../widgets/common/jumandi_text_field.dart';

class AdminSetupScreen extends StatefulWidget {
  const AdminSetupScreen({super.key});

  @override
  State<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _checkingSetup = true;
  bool _needsSetup = true;

  @override
  void initState() {
    super.initState();
    _checkSetup();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
        if (!status.needsSetup) {
          context.go('/admin/login');
        }
      }
    } catch (_) {
      if (mounted) setState(() => _checkingSetup = false);
    }
  }

  Future<void> _submit() async {
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<ApiService>().setupAdminAccount(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
          );

      final auth = context.read<AuthProvider>();
      final ok = await auth.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;

      if (ok && auth.isAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin account created')),
        );
        context.go('/admin');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created. Please sign in.')),
        );
        context.go('/admin/login');
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSetup) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.brandYellow)),
      );
    }

    if (!_needsSetup) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.go('/admin/login'),
        ),
        title: Text('Create Admin', style: AppTextStyles.headingSmall),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Admin Account',
                style: AppTextStyles.heading.copyWith(fontSize: 26),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Set up the first admin. You choose the email and password.',
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
                    const SizedBox(height: 14),
                    JumandiTextField(
                      label: 'ADMIN EMAIL',
                      controller: _emailController,
                      hint: 'admin@jumandi.com',
                      prefixIcon: Icons.alternate_email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    JumandiTextField(
                      label: 'PHONE',
                      controller: _phoneController,
                      hint: '+234...',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    JumandiTextField(
                      label: 'PASSWORD',
                      controller: _passwordController,
                      obscureText: _obscure,
                      prefixIcon: Icons.lock_outline,
                    ),
                    const SizedBox(height: 14),
                    JumandiTextField(
                      label: 'CONFIRM PASSWORD',
                      controller: _confirmController,
                      obscureText: _obscure,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: 24),
                    JumandiPrimaryButton(
                      label: 'CREATE ADMIN & SIGN IN',
                      icon: Icons.admin_panel_settings,
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
