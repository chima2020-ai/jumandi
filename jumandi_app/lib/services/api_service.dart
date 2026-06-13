import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../models/booking_model.dart';
import '../models/call_model.dart';
import '../models/chat_message_model.dart';
import '../models/user_model.dart';
import 'session_storage.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(AppConfig.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  late final Dio _dio;
  final SessionStorage _storage = SessionStorage();

  String _extractError(DioException e) {
    if (e.type == DioExceptionType.connectionError && e.response == null) {
      return 'Cannot reach the API. If you are on web, redeploy the backend with CORS enabled for localhost.';
    }
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        return detail.first['msg']?.toString() ?? 'Request failed';
      }
    }
    return e.message ?? 'Network error';
  }

  Future<(String token, UserModel user)> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'role': userRoleToString(role),
        },
      );
      final token = response.data['access_token'] as String;
      final user = UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
      await saveSession(token, user);
      return (token, user);
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }

  Future<(String token, UserModel user)> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {
          'username': email,
          'password': password,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final token = response.data['access_token'] as String;
      final user = UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
      await saveSession(token, user);
      return (token, user);
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }

  Future<UserModel?> getStoredUser() async {
    final raw = await _storage.read(AppConfig.userKey);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<String?> getToken() => _storage.read(AppConfig.tokenKey);

  Future<void> saveSession(String token, UserModel user) async {
    await _storage.write(AppConfig.tokenKey, token);
    await _storage.write(AppConfig.userKey, jsonEncode(user.toJson()));
  }

  Future<void> clearSession() async {
    await _storage.delete(AppConfig.tokenKey);
    await _storage.delete(AppConfig.userKey);
  }

  Future<BookingModel> createBooking({
    required double gasKg,
    required String address,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/api/bookings',
        data: {
          'gas_kg': gasKg,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          'notes': notes,
        },
      );
      return BookingModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }

  Future<List<BookingModel>> getMyBookings() async {
    try {
      final response = await _dio.get('/api/bookings/my');
      return (response.data as List)
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }

  Future<BookingModel> getBooking(int id) async {
    try {
      final response = await _dio.get('/api/bookings/$id');
      return BookingModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }

  Future<List<BookingModel>> getPendingBookings() async {
    try {
      final response = await _dio.get('/api/delivery/pending');
      return (response.data as List)
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }

  Future<List<BookingModel>> getMyDeliveries() async {
    try {
      final response = await _dio.get('/api/delivery/my');
      return (response.data as List)
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }

  Future<BookingModel> acceptBooking(int id) async {
    try {
      final response = await _dio.post('/api/delivery/$id/accept');
      return BookingModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }

  Future<BookingModel> startDelivery(int id) async {
    try {
      final response = await _dio.post('/api/delivery/$id/start');
      return BookingModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }

  Future<BookingModel> completeDelivery(int id) async {
    try {
      final response = await _dio.post('/api/delivery/$id/complete');
      return BookingModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }

  Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _dio.post(
        '/api/delivery/location',
        data: {'latitude': latitude, 'longitude': longitude},
      );
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }

  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get('/api/auth/me');
      final user = UserModel.fromJson(response.data as Map<String, dynamic>);
      final token = await getToken();
      if (token != null) {
        await saveSession(token, user);
      }
      return user;
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }

  Future<UserModel> updateProfile({String? name, String? phone}) async {
    try {
      final response = await _dio.patch(
        '/api/auth/me',
        data: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
        },
      );
      final user = UserModel.fromJson(response.data as Map<String, dynamic>);
      final token = await getToken();
      if (token != null) {
        await saveSession(token, user);
      }
      return user;
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }

  Future<void> sendOtp() async {
    try {
      await _dio.post('/api/auth/otp/send');
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }

  Future<UserModel> verifyOtp(String code) async {
    try {
      final response = await _dio.post(
        '/api/auth/otp/verify',
        data: {'code': code},
      );
      final user = UserModel.fromJson(response.data as Map<String, dynamic>);
      final token = await getToken();
      if (token != null) {
        await saveSession(token, user);
      }
      return user;
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/api/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/api/auth/reset-password',
        data: {
          'email': email,
          'token': token,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }

  Future<BookingModel> cancelBooking(int id) async {
    try {
      final response = await _dio.post('/api/bookings/$id/cancel');
      return BookingModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }

  Future<BookingModel> declineBooking(int id) async {
    try {
      final response = await _dio.post('/api/delivery/$id/decline');
      return BookingModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }

  Future<List<ChatMessage>> getChatMessages(int bookingId) async {
    try {
      final response = await _dio.get('/api/chat/$bookingId/messages');
      return (response.data as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }

  Future<ChatMessage> sendChatMessage({
    required int bookingId,
    required String content,
  }) async {
    try {
      final response = await _dio.post(
        '/api/chat/$bookingId/messages',
        data: {'content': content},
      );
      return ChatMessage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }

  Future<CallContact> getCallContact(int bookingId) async {
    try {
      final response = await _dio.get('/api/calls/booking/$bookingId/contact');
      return CallContact.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }

  Future<CallInitiateResult> initiateCall(int bookingId) async {
    try {
      final response = await _dio.post('/api/calls/booking/$bookingId/initiate');
      return CallInitiateResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }
}
