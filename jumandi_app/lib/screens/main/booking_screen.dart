import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../services/location_service.dart';
import '../../widgets/common/jumandi_app_bar.dart';
import '../../widgets/common/jumandi_button.dart';
import '../../widgets/common/jumandi_text_field.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  double _gasKg = 12.5;
  int _deliveryWindow = 0;
  bool _submitting = false;
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  bool _loadingAddress = false;
  final _locationService = LocationService();
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _loadingAddress = true);
    final details = await _locationService.getCurrentLocationDetails();
    if (!mounted) return;
    if (!details.hasPosition) {
      setState(() => _loadingAddress = false);
      if (details.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(details.errorMessage!)),
        );
      }
      return;
    }
    setState(() {
      _lat = details.position!.latitude;
      _lng = details.position!.longitude;
      _loadingAddress = false;
      if (details.address != null &&
          details.address!.isNotEmpty &&
          _addressController.text.trim().isEmpty) {
        _addressController.text = details.address!;
      }
    });
  }

  Future<void> _confirm() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a delivery address')),
      );
      return;
    }

    setState(() => _submitting = true);
    final provider = context.read<BookingProvider>();
    try {
      final result = await provider.createBooking(
        gasKg: _gasKg,
        address: address,
        latitude: _lat ?? 6.5244,
        longitude: _lng ?? 3.3792,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (!mounted) return;
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking #${result.id} confirmed!')),
        );
        context.go('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Booking failed')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estimatedPrice = (_gasKg * 450).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: const JumandiAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Book Gas Delivery', style: AppTextStyles.headingSmall),
            const SizedBox(height: 8),
            Text(
              'Order is sent to the live Jumandi API. A delivery agent will accept your order.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 24),
            JumandiTextField(
              label: 'DELIVERY ADDRESS',
              controller: _addressController,
              hint: _loadingAddress ? 'Detecting your address...' : 'Street, gate, landmark...',
              prefixIcon: Icons.place_outlined,
            ),
            const SizedBox(height: 18),
            JumandiTextField(
              label: 'NOTES (OPTIONAL)',
              controller: _notesController,
              hint: 'Call when you arrive...',
              prefixIcon: Icons.notes_outlined,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Gas quantity', style: AppTextStyles.headingSmall),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${_gasKg.toStringAsFixed(1)} ',
                        style: AppTextStyles.headingSmall.copyWith(color: AppColors.brandYellow),
                      ),
                      TextSpan(text: 'KG', style: AppTextStyles.label.copyWith(color: AppColors.white)),
                    ],
                  ),
                ),
              ],
            ),
            Slider(
              value: _gasKg,
              min: 3,
              max: 50,
              divisions: 47,
              label: '${_gasKg.toStringAsFixed(1)} kg',
              onChanged: (v) => setState(() => _gasKg = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['3kg', '12kg', '25kg', '50kg']
                  .map((l) => Text(l, style: AppTextStyles.caption))
                  .toList(),
            ),
            if (_lat != null) ...[
              const SizedBox(height: 8),
              Text(
                'GPS: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
                style: AppTextStyles.caption.copyWith(fontSize: 10),
              ),
            ],
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
                      Text('₦$estimatedPrice', style: AppTextStyles.heading.copyWith(color: AppColors.brandYellow, fontSize: 24)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estimate only. Final price may vary by location.',
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
