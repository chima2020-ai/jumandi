import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/jumandi_button.dart';
import '../../widgets/common/jumandi_logo.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _controller = TextEditingController();
  int _seconds = 59;
  Timer? _timer;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _seconds = 59;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds == 0) {
        t.cancel();
        return;
      }
      setState(() => _seconds--);
    });
  }

  Future<void> _verify() async {
    final code = _controller.text.trim();
    if (code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 4-digit code')),
      );
      return;
    }

    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    try {
      final ok = await auth.verifyOtp(code);
      if (!mounted) return;
      if (ok) {
        context.go('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error ?? 'Invalid verification code')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_seconds > 0) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.resendOtp();
    if (!mounted) return;

    if (ok) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code sent')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Could not resend code')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthProvider>().user?.email ?? 'your email';

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        automaticallyImplyLeading: false,
        title: const JumandiWordmark(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'SECURITY VERIFICATION',
                style: AppTextStyles.label.copyWith(color: AppColors.brandYellow),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text('Enter Code', style: AppTextStyles.heading, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'We sent a 4-digit code to $email.',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              PinCodeTextField(
                appContext: context,
                length: 4,
                controller: _controller,
                keyboardType: TextInputType.number,
                onCompleted: (_) => _verify(),
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 56,
                  activeColor: AppColors.brandYellow,
                  selectedColor: AppColors.brandYellow,
                  inactiveColor: AppColors.input,
                  activeFillColor: AppColors.input,
                  selectedFillColor: AppColors.input,
                  inactiveFillColor: AppColors.input,
                ),
                enableActiveFill: true,
                textStyle: AppTextStyles.heading.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 32),
              JumandiPrimaryButton(
                label: 'VERIFY ACCESS',
                loading: _loading,
                onPressed: _verify,
              ),
              const SizedBox(height: 20),
              Text("Haven't received the code?", style: AppTextStyles.body, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _resend,
                child: Text(
                  _seconds > 0
                      ? 'RESEND KEY (00:${_seconds.toString().padLeft(2, '0')})'
                      : 'RESEND KEY',
                  style: AppTextStyles.button.copyWith(
                    color: _seconds > 0 ? AppColors.textMuted : AppColors.brandYellow,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(child: _infoCard(Icons.shield_outlined, 'Secure', 'End-to-End')),
                  const SizedBox(width: 12),
                  Expanded(child: _infoCard(Icons.speed, 'Fast', 'Instant Key')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.brandYellow, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
              Text(subtitle, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
