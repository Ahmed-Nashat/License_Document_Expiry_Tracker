import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/api_client_platform.dart';

import '../auth/auth_controller.dart';

// --- Models ---
// (No changes to models here)
class AdminUser {
  final String id;
  final String email;
  final String? displayName;
  final String role;
  final DateTime createdAt;
  final int documentCount;
  final int activeSessionCount;

  AdminUser({
    required this.id,
    required this.email,
    this.displayName,
    required this.role,
    required this.createdAt,
    required this.documentCount,
    required this.activeSessionCount,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      email: json['email'],
      displayName: json['displayName'],
      role: json['role'],
      createdAt: DateTime.parse(json['createdAt']),
      documentCount: json['_count']['documents'],
      activeSessionCount: json['_count']['sessions'],
    );
  }
}

class AuditLog {
  final String id;
  final DateTime timestamp;
  final String actorId;
  final String action;
  final String? targetId;
  final String? reason;
  final String? ipAddress;

  AuditLog({
    required this.id,
    required this.timestamp,
    required this.actorId,
    required this.action,
    this.targetId,
    this.reason,
    this.ipAddress,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      actorId: json['actorId'],
      action: json['action'],
      targetId: json['targetId'],
      reason: json['reason'],
      ipAddress: json['ipAddress'],
    );
  }
}

// --- Providers ---

final adminDioProvider = Provider<Dio>((ref) {
  final dio = createDio();
  final token = ref.watch(authControllerProvider).value?.accessToken;
  if (token != null) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }
  return dio;
});

final adminSearchQueryProvider = StateProvider<String>((ref) => '');

final adminUsersProvider = FutureProvider.autoDispose<List<AdminUser>>((ref) async {
  final search = ref.watch(adminSearchQueryProvider);
  final client = ref.watch(adminDioProvider);
  
  final queryParams = search.isNotEmpty ? '?search=${Uri.encodeQueryComponent(search)}' : '';
  final response = await client.get<List>('/api/admin/users$queryParams');

  if (response.statusCode == 200 && response.data != null) {
    return response.data!.map((json) => AdminUser.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load users: ${response.statusCode}');
  }
});

final adminAuditLogsProvider = FutureProvider.autoDispose<List<AuditLog>>((ref) async {
  final client = ref.watch(adminDioProvider);
  final response = await client.get<List>('/api/admin/audit-logs');

  if (response.statusCode == 200 && response.data != null) {
    return response.data!.map((json) => AuditLog.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load audit logs: ${response.statusCode}');
  }
});

final adminRevokeSessionsProvider = Provider((ref) {
  return (String targetUserId) async {
    final client = ref.read(adminDioProvider);
    final response = await client.post(
      '/api/admin/users/$targetUserId/sessions/revoke',
    );
    
    if (response.statusCode == 200) {
      ref.invalidate(adminUsersProvider);
      ref.invalidate(adminAuditLogsProvider);
    } else {
      throw Exception('Failed to revoke sessions');
    }
  };
});

class AdminMetrics {
  final int usersTotal;
  final Map<String, int> ageBreakdown;
  final Map<String, int> genderBreakdown;
  final int docsTotal;
  final Map<String, int> documentBreakdown;

  AdminMetrics({
    required this.usersTotal,
    required this.ageBreakdown,
    required this.genderBreakdown,
    required this.docsTotal,
    required this.documentBreakdown,
  });

  factory AdminMetrics.fromJson(Map<String, dynamic> json) {
    return AdminMetrics(
      usersTotal: json['usersTotal'] as int,
      ageBreakdown: Map<String, int>.from(json['ageBreakdown'] as Map),
      genderBreakdown: Map<String, int>.from(json['genderBreakdown'] as Map),
      docsTotal: json['docsTotal'] as int,
      documentBreakdown: Map<String, int>.from(json['documentBreakdown'] as Map),
    );
  }
}

final adminMetricsProvider = FutureProvider.autoDispose<AdminMetrics>((ref) async {
  final client = ref.watch(adminDioProvider);
  final response = await client.get<Map<String, dynamic>>('/api/admin/metrics');

  if (response.statusCode == 200 && response.data != null) {
    return AdminMetrics.fromJson(response.data!);
  } else {
    throw Exception('Failed to load metrics: ${response.statusCode}');
  }
});

