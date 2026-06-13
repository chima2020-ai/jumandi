import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../services/call_service.dart';
import '../../services/websocket_service.dart';

/// Listens for real-time incoming call notifications and shows a call-back dialog.
class IncomingCallListener extends StatefulWidget {
  const IncomingCallListener({super.key, required this.child});

  final Widget child;

  @override
  State<IncomingCallListener> createState() => _IncomingCallListenerState();
}

class _IncomingCallListenerState extends State<IncomingCallListener> {
  StreamSubscription<Map<String, dynamic>>? _sub;
  bool _dialogOpen = false;
  AuthProvider? _auth;
  WebSocketService? _ws;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncConnection());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _auth?.removeListener(_syncConnection);
    _auth = context.read<AuthProvider>();
    _ws = context.read<WebSocketService>();
    _auth!.addListener(_syncConnection);
  }

  @override
  void dispose() {
    _auth?.removeListener(_syncConnection);
    _sub?.cancel();
    _ws?.disconnectNotifications();
    super.dispose();
  }

  void _syncConnection() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final ws = context.read<WebSocketService>();

    if (!auth.isLoggedIn || auth.token == null) {
      _sub?.cancel();
      _sub = null;
      ws.disconnectNotifications();
      return;
    }

    ws.connectNotifications(auth.token!);
    _sub?.cancel();
    _sub = ws.notifications.listen(_onNotification);
  }

  void _onNotification(Map<String, dynamic> event) {
    if (event['type'] != 'incoming_call' || !mounted || _dialogOpen) return;
    _showIncomingCall(event);
  }

  Future<void> _showIncomingCall(Map<String, dynamic> event) async {
    _dialogOpen = true;
    final callerName = event['caller_name'] as String? ?? 'Someone';
    final callerPhone = event['caller_phone'] as String? ?? '';
    final message = event['message'] as String? ?? '$callerName is calling';

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Incoming call', style: AppTextStyles.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: AppTextStyles.body),
            if (callerPhone.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(callerPhone, style: AppTextStyles.caption.copyWith(color: AppColors.brandYellow)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Dismiss', style: AppTextStyles.button.copyWith(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (callerPhone.isEmpty) return;
              try {
                await context.read<CallService>().dialNumber(callerPhone);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            child: Text('Call back', style: AppTextStyles.button.copyWith(color: AppColors.brandYellow)),
          ),
        ],
      ),
    );

    _dialogOpen = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
