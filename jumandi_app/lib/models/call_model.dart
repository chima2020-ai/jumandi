import '../models/user_model.dart';

class CallContact {
  const CallContact({
    required this.bookingId,
    required this.contactId,
    required this.contactName,
    required this.contactPhone,
    required this.contactRole,
    required this.telUri,
  });

  final int bookingId;
  final int contactId;
  final String contactName;
  final String contactPhone;
  final UserRole contactRole;
  final String telUri;

  factory CallContact.fromJson(Map<String, dynamic> json) {
    return CallContact(
      bookingId: json['booking_id'] as int,
      contactId: json['contact_id'] as int,
      contactName: json['contact_name'] as String,
      contactPhone: json['contact_phone'] as String,
      contactRole: userRoleFromString(json['contact_role'] as String),
      telUri: json['tel_uri'] as String,
    );
  }
}

class CallInitiateResult {
  const CallInitiateResult({
    required this.callId,
    required this.bookingId,
    required this.contactName,
    required this.contactPhone,
    required this.telUri,
    required this.message,
  });

  final int callId;
  final int bookingId;
  final String contactName;
  final String contactPhone;
  final String telUri;
  final String message;

  factory CallInitiateResult.fromJson(Map<String, dynamic> json) {
    return CallInitiateResult(
      callId: json['call_id'] as int,
      bookingId: json['booking_id'] as int,
      contactName: json['contact_name'] as String,
      contactPhone: json['contact_phone'] as String,
      telUri: json['tel_uri'] as String,
      message: json['message'] as String,
    );
  }
}
