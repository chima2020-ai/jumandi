import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/call_service.dart';

class CallIconButton extends StatefulWidget {
  const CallIconButton({
    super.key,
    required this.bookingId,
    this.color = AppColors.white,
    this.icon = Icons.phone_outlined,
  });

  final int bookingId;
  final Color color;
  final IconData icon;

  @override
  State<CallIconButton> createState() => _CallIconButtonState();
}

class _CallIconButtonState extends State<CallIconButton> {
  bool _calling = false;

  Future<void> _call() async {
    if (_calling) return;
    setState(() => _calling = true);
    try {
      await context.read<CallService>().startCall(widget.bookingId);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _calling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_calling) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: widget.color),
        ),
      );
    }
    return IconButton(
      icon: Icon(widget.icon, color: widget.color),
      onPressed: _call,
    );
  }
}
