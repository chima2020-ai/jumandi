import 'package:flutter/foundation.dart';

import '../models/booking_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api);

  final ApiService _api;
  UserModel? _user;
  String? _token;
  bool _loading = true;
  String? _error;

  UserModel? get user => _user;
  String? get token => _token;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null && _token != null;
  bool get isCustomer => _user?.role == UserRole.customer;
  bool get isDelivery => _user?.role == UserRole.delivery;

  Future<void> init() async {
    _token = await _api.getToken();
    _user = await _api.getStoredUser();
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
    try {
      final (token, user) = await _api.login(email: email, password: password);
      if (user.role != role) {
        _error = role == UserRole.delivery
            ? 'This account is not a delivery agent'
            : 'This account is not a customer';
        notifyListeners();
        return false;
      }
      _token = token;
      _user = user;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
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
    try {
      final (token, user) = await _api.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      _token = token;
      _user = user;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String code) async {
    _error = null;
    notifyListeners();
    try {
      final user = await _api.verifyOtp(code);
      _user = user;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendOtp() async {
    _error = null;
    notifyListeners();
    try {
      await _api.sendOtp();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.clearSession();
    _user = null;
    _token = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class BookingProvider extends ChangeNotifier {
  BookingProvider(this._api);

  final ApiService _api;
  List<BookingModel> _customerBookings = [];
  List<BookingModel> _pendingBookings = [];
  List<BookingModel> _deliveryBookings = [];
  bool _loading = false;
  String? _error;

  List<BookingModel> get bookings => _customerBookings;
  List<BookingModel> get pendingBookings => _pendingBookings;
  List<BookingModel> get deliveryBookings => _deliveryBookings;
  bool get loading => _loading;
  String? get error => _error;

  BookingModel? get activeCustomerBooking {
    for (final booking in _customerBookings) {
      if (booking.status == BookingStatus.accepted ||
          booking.status == BookingStatus.inTransit) {
        return booking;
      }
    }
    return null;
  }

  Future<void> loadCustomerBookings() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _customerBookings = await _api.getMyBookings();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadPendingBookings() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _pendingBookings = await _api.getPendingBookings();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyDeliveries() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _deliveryBookings = await _api.getMyDeliveries();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
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
    try {
      final booking = await _api.createBooking(
        gasKg: gasKg,
        address: address,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
      );
      _customerBookings = [booking, ..._customerBookings];
      notifyListeners();
      return booking;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> acceptBooking(int id) async {
    try {
      final booking = await _api.acceptBooking(id);
      _pendingBookings = _pendingBookings.where((b) => b.id != id).toList();
      _deliveryBookings = [booking, ..._deliveryBookings];
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> startDelivery(int id) async {
    try {
      final booking = await _api.startDelivery(id);
      _replaceDeliveryBooking(booking);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeDelivery(int id) async {
    try {
      final booking = await _api.completeDelivery(id);
      _replaceDeliveryBooking(booking);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  void _replaceDeliveryBooking(BookingModel booking) {
    _deliveryBookings = [
      booking,
      ..._deliveryBookings.where((b) => b.id != booking.id),
    ];
  }
}
