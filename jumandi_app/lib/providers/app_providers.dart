import 'package:flutter/foundation.dart';

import '../models/booking_model.dart';
import '../models/chat_message_model.dart';
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
  bool get isAdmin => _user?.role == UserRole.admin;
  bool get needsEmailVerification =>
      isCustomer && _user != null && !_user!.isVerified;

  String get homeRoute {
    if (isAdmin) return '/admin';
    if (isDelivery) return '/delivery';
    if (needsEmailVerification) return '/otp';
    return '/home';
  }

  Future<void> init() async {
    try {
      _token = await _api.getToken();
      _user = await _api.getStoredUser();
      if (_token != null) {
        try {
          _user = await _api.getMe();
        } catch (_) {
          // Keep cached user if token expired or offline.
        }
      }
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> login(
    String email,
    String password,
  ) async {
    _error = null;
    notifyListeners();
    try {
      final (token, user) = await _api.login(email: email, password: password);
      _token = token;
      _user = user;
      try {
        _user = await _api.getMe();
      } catch (_) {}
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
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
    } catch (e) {
      _error = e.toString();
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
    } catch (e) {
      _error = e.toString();
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

class AdminProvider extends ChangeNotifier {
  AdminProvider(this._api);

  final ApiService _api;
  List<UserModel> _deliveryAgents = [];
  bool _loading = false;
  String? _error;

  List<UserModel> get deliveryAgents => _deliveryAgents;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadDeliveryAgents() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _deliveryAgents = await _api.getDeliveryAgents();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<UserModel?> createDeliveryAgent({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _error = null;
    notifyListeners();
    try {
      final agent = await _api.createDeliveryAgent(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      _deliveryAgents = [agent, ..._deliveryAgents];
      notifyListeners();
      return agent;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateDeliveryAgent({
    required int id,
    String? name,
    String? phone,
    String? password,
    bool? isAvailable,
  }) async {
    _error = null;
    notifyListeners();
    try {
      final agent = await _api.updateDeliveryAgent(
        id: id,
        name: name,
        phone: phone,
        password: password,
        isAvailable: isAvailable,
      );
      _deliveryAgents = [
        agent,
        ..._deliveryAgents.where((a) => a.id != id),
      ];
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<UserModel?> createAdminAccount({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _error = null;
    notifyListeners();
    try {
      final admin = await _api.createAdminAccount(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      notifyListeners();
      return admin;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteDeliveryAgent(int id) async {
    _error = null;
    notifyListeners();
    try {
      await _api.deleteDeliveryAgent(id);
      _deliveryAgents = _deliveryAgents.where((a) => a.id != id).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
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

  BookingModel? get currentCustomerBooking {
    for (final booking in _customerBookings) {
      if (booking.status == BookingStatus.pending ||
          booking.status == BookingStatus.accepted ||
          booking.status == BookingStatus.inTransit) {
        return booking;
      }
    }
    return null;
  }

  BookingModel? get chatCustomerBooking {
    for (final booking in _customerBookings) {
      if (booking.status != BookingStatus.delivered &&
          booking.status != BookingStatus.cancelled &&
          booking.status != BookingStatus.declined) {
        return booking;
      }
    }
    return null;
  }

  List<BookingModel> get completedBookings => _customerBookings
      .where(
        (b) =>
            b.status == BookingStatus.delivered ||
            b.status == BookingStatus.cancelled,
      )
      .toList();

  double get totalGasKgDelivered => _customerBookings
      .where((b) => b.status == BookingStatus.delivered)
      .fold(0, (sum, b) => sum + b.gasKg);

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

  Future<List<ChatMessage>> loadChatMessages(int bookingId) async {
    try {
      return await _api.getChatMessages(bookingId);
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<ChatMessage> sendChatMessage({
    required int bookingId,
    required String content,
  }) async {
    try {
      return await _api.sendChatMessage(bookingId: bookingId, content: content);
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }
}
