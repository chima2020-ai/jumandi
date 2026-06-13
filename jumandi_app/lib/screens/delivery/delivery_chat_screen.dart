import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../widgets/common/delivery_bottom_nav.dart';

class DeliveryChatScreen extends StatefulWidget {
  const DeliveryChatScreen({super.key, required this.customerId});

  final int customerId;

  @override
  State<DeliveryChatScreen> createState() => _DeliveryChatScreenState();
}

class _DeliveryChatScreenState extends State<DeliveryChatScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.brandYellow),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: Alex S.', style: AppTextStyles.logo.copyWith(fontSize: 16)),
            Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('Online', style: AppTextStyles.caption.copyWith(color: AppColors.success, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.phone_outlined, color: AppColors.brandYellow), onPressed: () {}),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(radius: 16, backgroundColor: AppColors.card, child: Icon(Icons.person, size: 18, color: AppColors.brandGold)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
                    child: Text('Today', style: AppTextStyles.caption),
                  ),
                ),
                const SizedBox(height: 20),
                _incoming('I am at the east gate. Please call when you arrive.', '09:41 AM'),
                const SizedBox(height: 12),
                _incomingWithImage('This is my car just in case.'),
                const SizedBox(height: 12),
                _outgoing('On my way. ETA 2 minutes.', '09:42 AM'),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.inputBorder)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ARRIVAL IN 2 MINS', style: AppTextStyles.label.copyWith(fontSize: 9)),
                    ),
                    Expanded(child: Divider(color: AppColors.inputBorder)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: AppColors.textMuted),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: AppTextStyles.body.copyWith(color: AppColors.white),
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
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: AppColors.brandYellow, shape: BoxShape.circle),
                  child: const Icon(Icons.send, color: AppColors.black, size: 20),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _quickReply("I'm here"),
                _quickReply('Traffic was heavy'),
                _quickReply('Safety protocols met'),
                _quickReply('Almost finished'),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _incoming(String text, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(text, style: AppTextStyles.body.copyWith(color: AppColors.white)),
        ),
        const SizedBox(height: 4),
        Text(time, style: AppTextStyles.caption.copyWith(fontSize: 10)),
      ],
    );
  }

  Widget _incomingWithImage(String text) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.input,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Center(child: Icon(Icons.directions_car, size: 40, color: AppColors.textMuted)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(text, style: AppTextStyles.body.copyWith(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  Widget _outgoing(String text, String time) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.brandYellow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(text, style: AppTextStyles.body.copyWith(color: AppColors.black)),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(time, style: AppTextStyles.caption.copyWith(fontSize: 10)),
              const SizedBox(width: 4),
              Icon(Icons.done_all, size: 14, color: AppColors.brandYellow),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickReply(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Text(text, style: AppTextStyles.caption.copyWith(color: AppColors.white, fontSize: 11)),
    );
  }
}
