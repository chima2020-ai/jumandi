import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/booking_model.dart';
import '../../models/chat_message_model.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';
import '../../widgets/common/call_icon_button.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.bookingId});

  final int? bookingId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  int? _bookingId;
  BookingModel? _booking;
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final bookings = context.read<BookingProvider>();
    await bookings.loadCustomerBookings();
    if (!mounted) return;

    BookingModel? booking;
    if (widget.bookingId != null) {
      for (final b in bookings.bookings) {
        if (b.id == widget.bookingId) {
          booking = b;
          break;
        }
      }
    } else {
      booking = bookings.chatCustomerBooking;
    }

    if (booking == null) {
      setState(() {
        _loading = false;
        _bookingId = null;
        _booking = null;
        _messages = [];
      });
      return;
    }

    final activeBooking = booking;

    try {
      final messages = await bookings.loadChatMessages(activeBooking.id);
      if (!mounted) return;
      setState(() {
        _bookingId = activeBooking.id;
        _booking = activeBooking;
        _messages = messages;
        _loading = false;
      });
      _scrollToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _bookingId = activeBooking.id;
        _booking = activeBooking;
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _bookingId == null || _sending) return;

    setState(() => _sending = true);
    _controller.clear();

    try {
      final message = await context.read<BookingProvider>().sendChatMessage(
            bookingId: _bookingId!,
            content: text,
          );
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, message];
        _sending = false;
      });
      _scrollToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _callUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No active delivery to call yet')),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final driverName = _booking?.deliveryAgent?.name ?? 'Waiting for driver';
    final canCall = _bookingId != null &&
        _booking?.deliveryAgentId != null &&
        (_booking!.status == BookingStatus.accepted ||
            _booking!.status == BookingStatus.inTransit);

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        leading: IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.brandYellow),
          onPressed: _load,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(driverName, style: AppTextStyles.logo.copyWith(fontSize: 18)),
            if (_booking != null)
              Text(
                'Booking #${_booking!.id} • ${_booking!.status.label}',
                style: AppTextStyles.caption.copyWith(fontSize: 11),
              ),
          ],
        ),
        actions: [
          if (canCall)
            CallIconButton(bookingId: _bookingId!, color: AppColors.white)
          else
            IconButton(
              icon: const Icon(Icons.phone_outlined, color: AppColors.white),
              onPressed: _callUnavailable,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.brandYellow))
                : _bookingId == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('No active booking', style: AppTextStyles.headingSmall),
                              const SizedBox(height: 8),
                              Text(
                                'Book gas first, then chat with your driver here.',
                                style: AppTextStyles.body,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () => context.go('/home/booking'),
                                child: Text('Book gas', style: AppTextStyles.button.copyWith(color: AppColors.brandYellow)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.brandYellow,
                        child: ListView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          children: [
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(_error!, style: AppTextStyles.caption.copyWith(color: Colors.redAccent)),
                              ),
                            if (_messages.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32),
                                child: Text(
                                  'No messages yet. Say hello to your driver.',
                                  style: AppTextStyles.body,
                                  textAlign: TextAlign.center,
                                ),
                              )
                            else
                              ..._messages.map((m) => _messageBubble(m, auth.user?.id)),
                          ],
                        ),
                      ),
          ),
          if (_bookingId != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: AppTextStyles.body.copyWith(color: AppColors.white),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: AppTextStyles.caption,
                        filled: true,
                        fillColor: AppColors.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(color: AppColors.brandYellow, shape: BoxShape.circle),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.black),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send, color: AppColors.black),
                            onPressed: _send,
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _messageBubble(ChatMessage message, int? currentUserId) {
    final isMine = message.senderId == currentUserId;
    final time = DateFormat('h:mm a').format(message.createdAt.toLocal());

    if (isMine) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.brandYellow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(message.content, style: AppTextStyles.body.copyWith(color: AppColors.black)),
              ),
              const SizedBox(height: 4),
              Text(time, style: AppTextStyles.caption.copyWith(fontSize: 10)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.card,
            child: Icon(Icons.person, size: 14, color: AppColors.brandGold),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.senderName, style: AppTextStyles.caption.copyWith(fontSize: 10)),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(message.content, style: AppTextStyles.body.copyWith(color: AppColors.white)),
                ),
                const SizedBox(height: 4),
                Text(time, style: AppTextStyles.caption.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
