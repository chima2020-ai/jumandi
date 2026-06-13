import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/call_icon_button.dart';
import '../../widgets/common/delivery_bottom_nav.dart';
import '../../widgets/common/jumandi_button.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _accepting = false;

  Future<void> _accept() async {
    setState(() => _accepting = true);
    final ok = await context.read<BookingProvider>().acceptBooking(widget.orderId);
    if (!mounted) return;
    setState(() => _accepting = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order accepted!')),
      );
      context.go('/delivery/requests');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: DeliveryAppBar(
        title: 'ORDER_DETAIL',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: AppColors.card,
                  child: CustomPaint(painter: _MapGridPainter()),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('DELIVERY POINT', style: AppTextStyles.label.copyWith(fontSize: 9, color: AppColors.white)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.brandYellow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.local_gas_station, color: AppColors.black),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.black],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(child: _infoCard('FUEL TYPE', 'Premium Diesel', subtitle: 'High Grade', icon: Icons.verified)),
                    const SizedBox(width: 12),
                    Expanded(child: _infoCard('QUANTITY', '25 Gal', highlight: true, showBar: true)),
                  ],
                ),
                const SizedBox(height: 12),
                _customerCard(context),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DELIVERY INSTRUCTIONS', style: AppTextStyles.label),
                      const SizedBox(height: 10),
                      Text(
                        '"Park near the east gate. Vehicle is a black heavy-duty transport truck. Gate code is #7420."',
                        style: AppTextStyles.body.copyWith(color: AppColors.white, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                JumandiPrimaryButton(
                  label: 'ACCEPT ORDER',
                  icon: Icons.chevron_right,
                  loading: _accepting,
                  onPressed: _accept,
                ),
                const SizedBox(height: 10),
                Text(
                  'By accepting, you agree to our Safety Protocols and Terms of Service.',
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value, {String? subtitle, IconData? icon, bool highlight = false, bool showBar = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading.copyWith(
              fontSize: 18,
              color: highlight ? AppColors.brandYellow : AppColors.white,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(icon, size: 14, color: AppColors.brandYellow),
                const SizedBox(width: 4),
                Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.brandYellow, fontSize: 10)),
              ],
            ),
          ],
          if (showBar) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0.85,
                minHeight: 4,
                backgroundColor: AppColors.input,
                color: AppColors.brandYellow,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _customerCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.input,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person, color: AppColors.brandGold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Request From', style: AppTextStyles.caption),
                    Text('Alexander Vance', style: AppTextStyles.headingSmall.copyWith(fontSize: 15)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: AppColors.white),
                onPressed: () => context.push('/delivery/chat/${widget.orderId}'),
              ),
              CallIconButton(bookingId: widget.orderId, color: AppColors.brandYellow),
            ],
          ),
          const Divider(color: AppColors.inputBorder, height: 24),
          _detailRow(Icons.place_outlined, 'Distance', '4.2 miles'),
          _detailRow(Icons.access_time, 'Est. Time', '12 mins'),
          _detailRow(Icons.payments_outlined, 'Payout', '\$42.50', highlight: true),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Text(label, style: AppTextStyles.caption),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.headingSmall.copyWith(
              fontSize: 14,
              color: highlight ? AppColors.brandYellow : AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.inputBorder.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    for (var i = 0.0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (var i = 0.0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
