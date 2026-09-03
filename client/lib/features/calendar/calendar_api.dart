import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/api_client_platform.dart';
import '../auth/auth_controller.dart';
import '../documents/document_models.dart';

final calendarApiProvider = Provider<CalendarApi>((ref) {
  final dio = createDio();
  final token = ref.watch(authControllerProvider).value?.accessToken;
  if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
  return CalendarApi(dio);
});

class CalendarEventResult {
  const CalendarEventResult({
    required this.eventId,
    required this.eventLink,
    required this.created,
  });

  final String eventId;
  final String eventLink;
  final bool created;

  factory CalendarEventResult.fromJson(Map<String, dynamic> json) =>
      CalendarEventResult(
        eventId: json['eventId'] as String,
        eventLink: json['eventLink'] as String,
        created: json['created'] as bool? ?? true,
      );
}

class CalendarConnection {
  const CalendarConnection({required this.connected});

  final bool connected;

  factory CalendarConnection.fromJson(Map<String, dynamic> json) =>
      CalendarConnection(connected: json['connected'] as bool? ?? false);
}

class CalendarApiException implements Exception {
  const CalendarApiException(this.message,
      {this.authorizationRequired = false});

  final String message;
  final bool authorizationRequired;
}

class CalendarApi {
  const CalendarApi(this._dio);

  final Dio _dio;

  Future<CalendarConnection> connection() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/calendar/connection',
      );
      return CalendarConnection.fromJson(response.data!);
    } on DioException {
      return const CalendarConnection(connected: false);
    }
  }

  Future<Uri> beginConnection() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/calendar/connection/authorize',
        data: const <String, dynamic>{},
      );
      final rawUrl = response.data?['authorizationUrl'];
      final uri = rawUrl is String ? Uri.tryParse(rawUrl) : null;
      if (uri == null || uri.scheme != 'https') {
        throw const CalendarApiException(
            'Google Calendar connection could not be started.');
      }
      return uri;
    } on DioException catch (error) {
      final data = error.response?.data;
      final payload = data is Map ? data : const <String, dynamic>{};
      final message = payload['message'];
      throw CalendarApiException(message is String
          ? message
          : 'Google Calendar connection could not be started.');
    }
  }

  Future<CalendarEventResult> addExpiryEvent({
    required TrackedDocument document,
    required String timeZone,
  }) async {
    final start = DateTime(
      document.expiryDate.year,
      document.expiryDate.month,
      document.expiryDate.day,
    );
    final end = DateTime(start.year, start.month, start.day + 1);

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/calendar/events',
        data: {
          'title': '${document.title} expiry',
          'description':
              'DueNest expiry reminder for ${document.type.label}: ${document.title}.',
          'start': _localIso(start),
          'end': _localIso(end),
          'timeZone': timeZone,
        },
      );
      return CalendarEventResult.fromJson(response.data!);
    } on DioException catch (error) {
      final data = error.response?.data;
      final payload = data is Map ? data : const <String, dynamic>{};
      final code = payload['error'];
      if (code == 'CALENDAR_AUTHORIZATION_REQUIRED' ||
          code == 'CALENDAR_CONNECTION_REQUIRED') {
        throw const CalendarApiException(
          'Connect your Google Calendar before adding an event.',
          authorizationRequired: true,
        );
      }
      final message = payload['message'];
      throw CalendarApiException(
        message is String
            ? message
            : 'Could not add this expiry to Google Calendar. Please try again.',
      );
    }
  }

  String _localIso(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}T'
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}:'
      '${value.second.toString().padLeft(2, '0')}';
}
