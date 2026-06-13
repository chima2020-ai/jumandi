import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/booking_card.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().loadCustomerBookings();
    });
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bookings = context.watch<BookingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jumandi'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: bookings.loadCustomerBookings,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Hello, ${auth.user?.name ?? 'Customer'}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Order gas and track your delivery',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/customer/book'),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Book gas'),
            ),
            const SizedBox(height: 24),
            Text('My bookings', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (bookings.loading)
              const Center(child: CircularProgressIndicator())
            else if (bookings.bookings.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No bookings yet')),
              )
            else
              ...bookings.bookings.map((b) {
                return BookingCard(
                  booking: b,
                  onTap: b.status == BookingStatus.inTransit
                      ? () => context.push('/customer/track/${b.id}')
                      : null,
                  trailing: b.status == BookingStatus.inTransit
                      ? const Icon(Icons.map, color: Colors.purple)
                      : null,
                );
              }),
          ],
        ),
      ),
    );
  }
}
