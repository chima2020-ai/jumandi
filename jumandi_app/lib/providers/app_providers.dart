import 'package:flutter/foundation.dart';

import '../models/booking_model.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = true;
  String? _error;

  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isCustomer => _user?.role == UserRole.customer;
  bool get isDelivery => _user?.role == UserRole.delivery;

  Future<void> init() async {
    _loading = false;
    notifyListeners();
  }

  Future<bool> login(
    String email,
    String password, {
    UserRole role = UserRole.customer,
  }) async {
    _error = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _user = UserModel(
      id: 1,
      name: role == UserRole.delivery ? 'Marcus V. Sterling' : 'Alex Sterling',
      email: email.isEmpty ? 'demo@jumandi.com' : email,
      phone: '+1 (555) 942-0192',
      role: role,
    );
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    _error = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _user = UserModel(
      id: 1,
      name: name.isEmpty ? 'Alex Sterling' : name,
      email: email.isEmpty ? 'demo@jumandi.com' : email,
      phone: phone.isEmpty ? '+1 (555) 942-0192' : phone,
      role: role,
    );
    notifyListeners();
    return true;
  }

  Future<bool> verifyOtp(String code) async {
    _error = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return true;
  }

  Future<bool> resendOtp() async {
    _error = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return true;
  }

  Future<void> logout() async {
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class BookingProvider extends ChangeNotifier {
  BookingProvider() {
    _seedDemoData();
  }

  List<BookingModel> _customerBookings = [];
  List<BookingModel> _pendingBookings = [];
  List<BookingModel> _deliveryBookings = [];
  bool _loading = false;
  String? _error;
  int _nextId = 100;

  List<BookingModel> get bookings => _customerBookings;
  List<BookingModel> get pendingBookings => _pendingBookings;
  List<BookingModel> get deliveryBookings => _deliveryBookings;
  bool get loading => _loading;
  String? get error => _error;

  void _seedDemoData() {
    final demoCustomer = UserModel(
      id: 2,
      name: 'Sarah Chen',
      email: 'sarah@example.com',
      phone: '+1 (555) 801-4421',
      role: UserRole.customer,
    );
    _pendingBookings = [
      BookingModel(
        id: 1,
        customerId: 2,
        gasKg: 12.5,
        address: '742 Evergreen Terrace',
        latitude: 37.7749,
        longitude: -122.4194,
        notes: 'Leave at gate',
        status: BookingStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
        customer: demoCustomer,
      ),
    ];
    _customerBookings = [
      BookingModel(
        id: 2,
        customerId: 1,
        gasKg: 24.5,
        address: '123 Main Street',
        latitude: 37.7849,
        longitude: -122.4094,
        status: BookingStatus.delivered,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        deliveredAt: DateTime.now().subtract(const Duration(days: 2, hours: -1)),
      ),
    ];
    _deliveryBookings = [];
  }

  Future<void> loadCustomerBookings() async {
    _loading = true;
    _error = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _loading = false;
    notifyListeners();
  }

  Future<void> loadPendingBookings() async {
    _loading = true;
    _error = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _loading = false;
    notifyListeners();
  }

  Future<void> loadMyDeliveries() async {
    _loading = true;
    _error = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _loading = false;
    notifyListeners();
  }

  Future<BookingModel?> createBooking({
    required double gasKg,
    required String address,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    _error = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final booking = BookingModel(
      id: _nextId++,
      customerId: 1,
      gasKg: gasKg,
      address: address,
      latitude: latitude,
      longitude: longitude,
      notes: notes,
      status: BookingStatus.pending,
      createdAt: DateTime.now(),
    );
    _customerBookings = [booking, ..._customerBookings];
    notifyListeners();
    return booking;
  }

  Future<bool> acceptBooking(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _pendingBookings = _pendingBookings.where((b) => b.id != id).toList();
    notifyListeners();
    return true;
  }

  Future<bool> startDelivery(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    notifyListeners();
    return true;
  }

  Future<bool> completeDelivery(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    notifyListeners();
    return true;
  }
}
