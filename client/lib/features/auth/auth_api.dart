import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client_platform.dart';
import 'auth_models.dart';

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(createDio()));

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthSession> signIn(
          {required String email, required String password}) =>
      _submit(
        '/api/auth/login',
        {'email': email, 'password': password},
      );

  Future<AuthSession> register(
          {required String name,
          required String email,
          required String password,
          required String ageRange,
          String? gender}) =>
      _submit(
        '/api/auth/register',
        {
          'displayName': name,
          'email': email,
          'password': password,
          'ageRange': ageRange,
          if (gender != null) 'gender': gender,
        },
      );

  Future<AuthSession?> restore() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
          '/api/auth/refresh',
          data: const <String, dynamic>{});
      return AuthSession.fromJson(response.data!);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) return null;
      throw AuthException.fromDio(error);
    }
  }

  Future<void> signOut() async {
    try {
      await _dio.post<void>('/api/auth/logout');
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/auth/forgot-password',
        data: {'email': email},
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/auth/reset-password',
        data: {
          'email': email,
          'code': code,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  Future<DeuNestUser> updateProfile({
    required String token,
    required String displayName,
    String? ageRange,
    String? gender,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/auth/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: {
          'displayName': displayName,
          if (ageRange != null) 'ageRange': ageRange,
          if (gender != null) 'gender': gender,
        },
      );
      return DeuNestUser.fromJson(response.data!);
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  Future<void> updatePassword(
      String token, String currentPassword, String newPassword) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/api/auth/password',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  Future<AuthSession> _submit(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body);
      return AuthSession.fromJson(response.data!);
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  factory AuthException.fromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return AuthException(data['message'] as String);
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const AuthException(
          'DueNest is unavailable right now. Please check your connection and try again.');
    }
    return const AuthException(
        'We could not complete that request. Please try again.');
  }

  @override
  String toString() => message;
}
