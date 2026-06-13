import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/app_providers.dart';
import '../../services/location_service.dart';

class BookGasScreen extends StatefulWidget {
  const BookGasScreen({super.key});

  @override
  State<BookGasScreen> createState() => _BookGasScreenState();
}

class _BookGasScreenState extends State<BookGasScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationService = LocationService();

  double _gasKg = 6;
  double? _latitude;
  double? _longitude;
  bool _loadingLocation = false;
  bool _submitting = false;

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() => _loadingLocation = true);
    final position = await _locationService.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _loadingLocation = false;
      if (position != null) {
        _latitude = position.latitude;
        _longitude = position.longitude;
      }
    });
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get location. Enable GPS.')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set your delivery location')),
      );
      return;
    }

    setState(() => _submitting = true);
    final provider = context.read<BookingProvider>();
    final booking = await provider.createBooking(
      gasKg: _gasKg,
      address: _addressController.text.trim(),
      latitude: _latitude!,
      longitude: _longitude!,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (booking != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking placed! Waiting for delivery agent.')),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Booking failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book gas')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Select gas size (kg)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _gasKg,
                  min: 3,
                  max: 50,
                  divisions: 47,
                  label: '${_gasKg.toStringAsFixed(1)} kg',
                  onChanged: (v) => setState(() => _gasKg = v),
                ),
                Text(
                  '${_gasKg.toStringAsFixed(1)} kg',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Delivery address',
                    hintText: 'House number, street, area...',
                  ),
                  validator: (v) =>
                      v == null || v.length < 5 ? 'Enter full address' : null,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _loadingLocation ? null : _useMyLocation,
                  icon: _loadingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    _latitude != null
                        ? 'Location set (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})'
                        : 'Use my GPS location',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Call when you arrive...',
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirm booking'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
