import 'user_model.dart';

enum BookingStatus {
  pending,
  accepted,
  declined,
  inTransit,
  delivered,
  cancelled,
}

BookingStatus bookingStatusFromString(String value) {
  switch (value) {
    case 'accepted':
      return BookingStatus.accepted;
    case 'declined':
      return BookingStatus.declined;
    case 'in_transit':
      return BookingStatus.inTransit;
    case 'delivered':
      return BookingStatus.delivered;
    case 'cancelled':
      return BookingStatus.cancelled;
    default:
      return BookingStatus.pending;
  }
}

extension BookingStatusLabel on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.declined:
        return 'Declined';
      case BookingStatus.inTransit:
        return 'In transit';
      case BookingStatus.delivered:
        return 'Delivered';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class BookingModel {
  const BookingModel({
    required this.id,
    required this.customerId,
    this.deliveryAgentId,
    required this.gasKg,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.notes,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.deliveredAt,
    this.customer,
    this.deliveryAgent,
  });

  final int id;
  final int customerId;
  final int? deliveryAgentId;
  final double gasKg;
  final String address;
  final double latitude;
  final double longitude;
  final String? notes;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;
  final UserModel? customer;
  final UserModel? deliveryAgent;

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as int,
      customerId: json['customer_id'] as int,
      deliveryAgentId: json['delivery_agent_id'] as int?,
      gasKg: (json['gas_kg'] as num).toDouble(),
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      notes: json['notes'] as String?,
      status: bookingStatusFromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      customer: json['customer'] != null
          ? UserModel.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      deliveryAgent: json['delivery_agent'] != null
          ? UserModel.fromJson(json['delivery_agent'] as Map<String, dynamic>)
          : null,
    );
  }
}
