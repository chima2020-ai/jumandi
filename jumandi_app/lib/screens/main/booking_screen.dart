import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../services/location_service.dart';
import '../../widgets/common/jumandi_app_bar.dart';
import '../../widgets/common/jumandi_button.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _fuelType = 1;
  double _quantity = 24.5;
  int _deliveryWindow = 0;
  bool _submitting = false;
  final _addressController = TextEditingController(text: '123 Main Street');
  final _locationService = LocationService();
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    final pos = await _locationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    }
  }

  Future<void> _confirm() async {
    setState(() => _submitting = true);
    final provider = context.read<BookingProvider>();
    final gasKg = _fuelType == 2 ? _quantity : _quantity * 0.45;
    final result = await provider.createBooking(
      gasKg: gasKg,
      address: _addressController.text,
      latitude: _lat ?? 37.7749,
      longitude: _lng ?? -122.4194,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking confirmed!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = (_quantity * (_fuelType == 1 ? 4.12 : _fuelType == 0 ? 3.45 : 4.55)).toStringAsFixed(2);

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: const JumandiAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vehicle Selection', style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),
            _vehicleCard(),
            const SizedBox(height: 24),
            Text('Fuel Type', style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                _fuelOption(0, Icons.local_gas_station, 'Regular', '\$3.45/g'),
                const SizedBox(width: 10),
                _fuelOption(1, Icons.star, 'Premium', '\$4.12/g'),
                const SizedBox(width: 10),
                _fuelOption(2, Icons.oil_barrel, 'Gas', '\$4.55/g'),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Quantity', style: AppTextStyles.headingSmall),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: '${_quantity.toStringAsFixed(1)} ', style: AppTextStyles.headingSmall.copyWith(color: AppColors.brandYellow)),
                      TextSpan(text: 'GALLONS', style: AppTextStyles.label.copyWith(color: AppColors.white)),
                    ],
                  ),
                ),
              ],
            ),
            Slider(
              value: _quantity,
              min: 5,
              max: 100,
              onChanged: (v) => setState(() => _quantity = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['5g', '25g', '50g', '75g', '100g']
                  .map((l) => Text(l, style: AppTextStyles.caption))
                  .toList(),
            ),
            const SizedBox(height: 24),
            Text('Delivery Window', style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),
            _deliveryOption(0, Icons.bolt, 'ASAP Delivery', 'Estimated arrival: 15-30 mins'),
            const SizedBox(height: 10),
            _deliveryOption(1, Icons.schedule, 'Schedule Time', 'Pick a slot for later today or tomorrow'),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: const Border(left: BorderSide(color: AppColors.brandYellow, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ESTIMATED TOTAL', style: AppTextStyles.label.copyWith(color: AppColors.white)),
                      Text('\$$price', style: AppTextStyles.heading.copyWith(color: AppColors.brandYellow, fontSize: 24)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Includes taxes, fuel surcharges, and delivery fee.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            JumandiPrimaryButton(
              label: 'CONFIRM BOOKING',
              icon: Icons.verified,
              loading: _submitting,
              onPressed: _confirm,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _vehicleCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.input,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_shipping, color: AppColors.brandGold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('White Ford F-150', style: AppTextStyles.headingSmall.copyWith(fontSize: 15)),
                Text('Plate: TX-9942-FL', style: AppTextStyles.caption),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.brandYellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.brandYellow, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('ACTIVE FLEET', style: AppTextStyles.label.copyWith(color: AppColors.brandYellow, fontSize: 9)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _fuelOption(int index, IconData icon, String label, String price) {
    final selected = _fuelType == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _fuelType = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.brandYellow : AppColors.inputBorder),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? AppColors.brandYellow : AppColors.textMuted, size: 22),
              const SizedBox(height: 8),
              Text(label, style: AppTextStyles.caption.copyWith(color: selected ? AppColors.brandYellow : AppColors.white)),
              Text(price, style: AppTextStyles.caption.copyWith(color: selected ? AppColors.brandYellow : AppColors.textMuted, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deliveryOption(int index, IconData icon, String title, String subtitle) {
    final selected = _deliveryWindow == index;
    return GestureDetector(
      onTap: () => setState(() => _deliveryWindow = index),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.brandYellow : AppColors.inputBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? AppColors.brandYellow : AppColors.input,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: selected ? AppColors.black : AppColors.textMuted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.brandYellow : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
