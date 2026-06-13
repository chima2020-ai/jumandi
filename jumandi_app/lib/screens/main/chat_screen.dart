import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/call_icon_button.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.bookingId});

  final int? bookingId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  int? _bookingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveBooking());
  }

  Future<void> _resolveBooking() async {
    if (widget.bookingId != null) {
      setState(() => _bookingId = widget.bookingId);
      return;
    }
    final bookings = context.read<BookingProvider>();
    await bookings.loadCustomerBookings();
    if (!mounted) return;
    setState(() => _bookingId = bookings.activeCustomerBooking?.id);
  }

  void _callUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No active delivery to call yet')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingId = _bookingId;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.brandYellow),
          onPressed: () {},
        ),
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Driver', style: AppTextStyles.logo.copyWith(fontSize: 18)),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AppColors.brandYellow, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text('Active Now', style: AppTextStyles.caption.copyWith(color: AppColors.white)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (bookingId != null)
            CallIconButton(bookingId: bookingId, color: AppColors.white)
          else
            IconButton(
              icon: const Icon(Icons.phone_outlined, color: AppColors.white),
              onPressed: _callUnavailable,
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.card,
              child: Icon(Icons.person, size: 18, color: AppColors.brandGold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Today', style: AppTextStyles.caption),
                  ),
                ),
                const SizedBox(height: 20),
                _incomingBubble('Hi! I am on my way with your gas delivery. ETA 12 minutes.'),
                const SizedBox(height: 12),
                _outgoingBubble('Great, I will be waiting at the gate.'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: AppTextStyles.body.copyWith(color: AppColors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: AppTextStyles.caption,
                      filled: true,
                      fillColor: AppColors.card,
                      prefixIcon: const Icon(Icons.attach_file, color: AppColors.textMuted, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(color: AppColors.brandYellow, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward, color: AppColors.black),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _incomingBubble(String text) {
    return Row(
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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(text, style: AppTextStyles.body.copyWith(color: AppColors.white)),
              ),
              const SizedBox(height: 4),
              Text('10:24 AM', style: AppTextStyles.caption.copyWith(fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _outgoingBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.brandYellow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text, style: AppTextStyles.body.copyWith(color: AppColors.black)),
      ),
    );
  }
}
