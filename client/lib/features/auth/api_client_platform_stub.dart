import 'package:dio/dio.dart';

Dio createDio() => Dio(
      BaseOptions(
        baseUrl: const String.fromEnvironment('API_BASE_URL',
            defaultValue: 'http://localhost:3000'),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        contentType: Headers.jsonContentType,
      ),
    );
