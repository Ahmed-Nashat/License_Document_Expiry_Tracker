import 'package:dio/dio.dart';

import 'api_client_platform_stub.dart'
    if (dart.library.html) 'api_client_platform_web.dart' as platform;

Dio createDio() => platform.createDio();
