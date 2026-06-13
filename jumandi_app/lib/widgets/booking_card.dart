import 'package:flutter/material.dart';

import '../models/booking_model.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.trailing,
  });

  final BookingModel booking;
  final VoidCallback? onTap;
  final Widget? trailing;

  Color _statusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.accepted:
        return Colors.blue;
      case BookingStatus.inTransit:
        return Colors.purple;
      case BookingStatus.delivered:
        return Colors.green;
      case BookingStatus.cancelled:
      case BookingStatus.declined:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        title: Text('${booking.gasKg} kg gas'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(booking.address, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor(booking.status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                booking.status.label,
                style: TextStyle(
                  color: _statusColor(booking.status),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        trailing: trailing,
      ),
    );
  }
}
