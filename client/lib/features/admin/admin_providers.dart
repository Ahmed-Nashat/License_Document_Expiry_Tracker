import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/api_client_platform.dart';
import '../auth/auth_controller.dart';

// ─── Dio Client ───────────────────────────────────────────────────────────────

final adminDioProvider = Provider<Dio>((ref) {
  final dio = createDio();
  final token = ref.watch(authControllerProvider).value?.accessToken;
  if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
  return dio;
});

// ─── Models ───────────────────────────────────────────────────────────────────

class AdminUser {
  final String id;
  final String email;
  final String? displayName;
  final String role;
  final String? ageRange;
  final String? gender;
  final String timeZone;
  final bool emailNotificationsEnabled;
  final DateTime? suspendedAt;
  final String? suspendedReason;
  final DateTime createdAt;
  final int documentCount;
  final int activeSessionCount;

  AdminUser({
    required this.id,
    required this.email,
    this.displayName,
    required this.role,
    this.ageRange,
    this.gender,
    required this.timeZone,
    required this.emailNotificationsEnabled,
    this.suspendedAt,
    this.suspendedReason,
    required this.createdAt,
    required this.documentCount,
    required this.activeSessionCount,
  });

  bool get isSuspended => suspendedAt != null;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      email: json['email'],
      displayName: json['displayName'],
      role: json['role'],
      ageRange: json['ageRange'],
      gender: json['gender'],
      timeZone: json['timeZone'] ?? 'Africa/Cairo',
      emailNotificationsEnabled: json['emailNotificationsEnabled'] ?? true,
      suspendedAt: json['suspendedAt'] != null
          ? DateTime.parse(json['suspendedAt'])
          : null,
      suspendedReason: json['suspendedReason'],
      createdAt: DateTime.parse(json['createdAt']),
      documentCount: json['_count']?['documents'] ?? 0,
      activeSessionCount: json['_count']?['sessions'] ?? 0,
    );
  }
}

class AdminUserPage {
  final List<AdminUser> users;
  final int total;
  final int page;
  final int pages;

  AdminUserPage(
      {required this.users,
      required this.total,
      required this.page,
      required this.pages});

  factory AdminUserPage.fromJson(Map<String, dynamic> json) {
    return AdminUserPage(
      users: (json['users'] as List).map((u) => AdminUser.fromJson(u)).toList(),
      total: json['total'],
      page: json['page'],
      pages: json['pages'],
    );
  }
}

class AuditLogEntry {
  final String id;
  final DateTime timestamp;
  final String actorId;
  final String actorType;
  final String action;
  final String? targetId;
  final String? reason;
  final String? ipAddress;
  final String result;
  final Map<String, dynamic>? metadata;

  AuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.actorId,
    required this.actorType,
    required this.action,
    this.targetId,
    this.reason,
    this.ipAddress,
    required this.result,
    this.metadata,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      actorId: json['actorId'],
      actorType: json['actorType'] ?? 'ADMIN',
      action: json['action'],
      targetId: json['targetId'],
      reason: json['reason'],
      ipAddress: json['ipAddress'],
      result: json['result'] ?? 'SUCCESS',
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }
}

class AuditLogPage {
  final List<AuditLogEntry> logs;
  final int total;
  final int page;
  final int pages;

  AuditLogPage(
      {required this.logs,
      required this.total,
      required this.page,
      required this.pages});

  factory AuditLogPage.fromJson(Map<String, dynamic> json) {
    return AuditLogPage(
      logs:
          (json['logs'] as List).map((l) => AuditLogEntry.fromJson(l)).toList(),
      total: json['total'],
      page: json['page'],
      pages: json['pages'],
    );
  }
}

class AdminMetrics {
  final int usersTotal;
  final int usersNewLast7Days;
  final int docsTotal;
  final int docsExpired;
  final int docsCritical;
  final int docsSoon;
  final Map<String, int> byType;
  final int remindersTotal;
  final int remindersSent;
  final int remindersFailed;
  final int remindersPending;
  final int deliveryRate;
  final Map<String, int> byAge;
  final Map<String, int> byGender;

  AdminMetrics({
    required this.usersTotal,
    required this.usersNewLast7Days,
    required this.docsTotal,
    required this.docsExpired,
    required this.docsCritical,
    required this.docsSoon,
    required this.byType,
    required this.remindersTotal,
    required this.remindersSent,
    required this.remindersFailed,
    required this.remindersPending,
    required this.deliveryRate,
    required this.byAge,
    required this.byGender,
  });

  factory AdminMetrics.fromJson(Map<String, dynamic> json) {
    final users = json['users'] as Map<String, dynamic>;
    final docs = json['documents'] as Map<String, dynamic>;
    final reminders = json['reminders'] as Map<String, dynamic>;
    final demo = json['demographics'] as Map<String, dynamic>;
    return AdminMetrics(
      usersTotal: users['total'],
      usersNewLast7Days: users['newLast7Days'],
      docsTotal: docs['total'],
      docsExpired: docs['expired'],
      docsCritical: docs['critical'],
      docsSoon: docs['soon'],
      byType: Map<String, int>.from(docs['byType'] as Map),
      remindersTotal: reminders['total'],
      remindersSent: reminders['sent'],
      remindersFailed: reminders['failed'],
      remindersPending: reminders['pending'],
      deliveryRate: reminders['deliveryRate'],
      byAge: Map<String, int>.from(demo['byAge'] as Map),
      byGender: Map<String, int>.from(demo['byGender'] as Map),
    );
  }
}

class ReminderStats {
  final int pending;
  final int processing;
  final int sent;
  final int failed;
  final bool paused;
  final String? lastRun;

  ReminderStats(
      {required this.pending,
      required this.processing,
      required this.sent,
      required this.failed,
      required this.paused,
      this.lastRun});

  factory ReminderStats.fromJson(Map<String, dynamic> json) {
    final q = json['queue'] as Map<String, dynamic>;
    return ReminderStats(
      pending: q['pending'],
      processing: q['processing'],
      sent: q['sent'],
      failed: q['failed'],
      paused: json['paused'],
      lastRun: json['lastRun'],
    );
  }
}

class ReminderLog {
  final String id;
  final String status;
  final int daysBefore;
  final int retryCount;
  final String? error;
  final String? sentAt;
  final String userEmail;
  final String documentTitle;
  final String documentType;

  ReminderLog({
    required this.id,
    required this.status,
    required this.daysBefore,
    required this.retryCount,
    this.error,
    this.sentAt,
    required this.userEmail,
    required this.documentTitle,
    required this.documentType,
  });

  factory ReminderLog.fromJson(Map<String, dynamic> json) {
    return ReminderLog(
      id: json['id'],
      status: json['status'],
      daysBefore: json['daysBefore'],
      retryCount: json['retryCount'],
      error: json['error'],
      sentAt: json['sentAt'],
      userEmail: json['user']?['email'] ?? '',
      documentTitle: json['document']?['title'] ?? '',
      documentType: json['document']?['type'] ?? '',
    );
  }
}

class ReminderLogPage {
  final List<ReminderLog> logs;
  final int total;
  final int pages;

  ReminderLogPage(
      {required this.logs, required this.total, required this.pages});

  factory ReminderLogPage.fromJson(Map<String, dynamic> json) {
    return ReminderLogPage(
      logs: (json['logs'] as List).map((l) => ReminderLog.fromJson(l)).toList(),
      total: json['total'],
      pages: json['pages'],
    );
  }
}

class SupportTicket {
  final String id;
  final String requesterEmail;
  final String category;
  final String subject;
  final String description;
  final String status;
  final String? internalNotes;
  final String? assigneeEmail;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupportTicket({
    required this.id,
    required this.requesterEmail,
    required this.category,
    required this.subject,
    required this.description,
    required this.status,
    this.internalNotes,
    this.assigneeEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'],
      requesterEmail: json['requesterEmail'],
      category: json['category'],
      subject: json['subject'],
      description: json['description'],
      status: json['status'],
      internalNotes: json['internalNotes'],
      assigneeEmail: json['assignee']?['email'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class TicketPage {
  final List<SupportTicket> tickets;
  final int total;
  final int pages;

  TicketPage({required this.tickets, required this.total, required this.pages});

  factory TicketPage.fromJson(Map<String, dynamic> json) {
    return TicketPage(
      tickets: (json['tickets'] as List)
          .map((t) => SupportTicket.fromJson(t))
          .toList(),
      total: json['total'],
      pages: json['pages'],
    );
  }
}

class SystemConfigEntry {
  final String key;
  final String value;
  final DateTime updatedAt;
  final String reason;

  SystemConfigEntry(
      {required this.key,
      required this.value,
      required this.updatedAt,
      required this.reason});

  factory SystemConfigEntry.fromJson(Map<String, dynamic> json) {
    return SystemConfigEntry(
      key: json['key'],
      value: json['value'],
      updatedAt: DateTime.parse(json['updatedAt']),
      reason: json['reason'],
    );
  }
}

class AdminSession {
  final String id;
  final String userId;
  final String? deviceName;
  final String? deviceType;
  final DateTime lastUsedAt;
  final DateTime expiresAt;
  final String userEmail;
  final String? userName;

  AdminSession({
    required this.id,
    required this.userId,
    this.deviceName,
    this.deviceType,
    required this.lastUsedAt,
    required this.expiresAt,
    required this.userEmail,
    this.userName,
  });

  factory AdminSession.fromJson(Map<String, dynamic> json) {
    return AdminSession(
      id: json['id'],
      userId: json['userId'],
      deviceName: json['deviceName'],
      deviceType: json['deviceType'],
      lastUsedAt: DateTime.parse(json['lastUsedAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      userEmail: json['user']?['email'] ?? '',
      userName: json['user']?['displayName'],
    );
  }
}

// ─── State ───────────────────────────────────────────────────────────────────

class AdminUsersFilter {
  final String search;
  final String? suspended;
  final int page;

  const AdminUsersFilter({this.search = '', this.suspended, this.page = 1});

  AdminUsersFilter copyWith({String? search, String? suspended, int? page}) {
    return AdminUsersFilter(
      search: search ?? this.search,
      suspended: suspended ?? this.suspended,
      page: page ?? this.page,
    );
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final adminUsersFilterProvider =
    StateProvider<AdminUsersFilter>((ref) => const AdminUsersFilter());

final adminUsersProvider =
    FutureProvider.autoDispose<AdminUserPage>((ref) async {
  final filter = ref.watch(adminUsersFilterProvider);
  final client = ref.watch(adminDioProvider);
  final params = <String, String>{
    'page': filter.page.toString(),
    'limit': '30',
  };
  if (filter.search.isNotEmpty) params['search'] = filter.search;
  if (filter.suspended != null) params['suspended'] = filter.suspended!;
  final response = await client.get<Map<String, dynamic>>('/api/admin/users',
      queryParameters: params);
  return AdminUserPage.fromJson(response.data!);
});

class AuditLogFilter {
  final String? action;
  final String? result;
  final int page;

  const AuditLogFilter({this.action, this.result, this.page = 1});

  AuditLogFilter copyWith({String? action, String? result, int? page}) {
    return AuditLogFilter(
        action: action ?? this.action,
        result: result ?? this.result,
        page: page ?? this.page);
  }
}

final auditLogFilterProvider =
    StateProvider<AuditLogFilter>((ref) => const AuditLogFilter());

final adminAuditLogsProvider =
    FutureProvider.autoDispose<AuditLogPage>((ref) async {
  final filter = ref.watch(auditLogFilterProvider);
  final client = ref.watch(adminDioProvider);
  final params = <String, String>{
    'page': filter.page.toString(),
    'limit': '50'
  };
  if (filter.action != null && filter.action!.isNotEmpty) {
    params['action'] = filter.action!;
  }
  if (filter.result != null) params['result'] = filter.result!;
  final response = await client.get<Map<String, dynamic>>(
      '/api/admin/audit-logs',
      queryParameters: params);
  return AuditLogPage.fromJson(response.data!);
});

final adminMetricsProvider =
    FutureProvider.autoDispose<AdminMetrics>((ref) async {
  final client = ref.watch(adminDioProvider);
  final response = await client.get<Map<String, dynamic>>('/api/admin/metrics');
  return AdminMetrics.fromJson(response.data!);
});

final adminReminderStatsProvider =
    FutureProvider.autoDispose<ReminderStats>((ref) async {
  final client = ref.watch(adminDioProvider);
  final response =
      await client.get<Map<String, dynamic>>('/api/admin/reminders/stats');
  return ReminderStats.fromJson(response.data!);
});

final reminderLogFilterProvider =
    StateProvider<String?>((ref) => null); // status filter

final adminReminderLogsProvider =
    FutureProvider.autoDispose<ReminderLogPage>((ref) async {
  final status = ref.watch(reminderLogFilterProvider);
  final client = ref.watch(adminDioProvider);
  final params = <String, String>{'page': '1', 'limit': '50'};
  if (status != null) params['status'] = status;
  final response = await client.get<Map<String, dynamic>>(
      '/api/admin/reminders/logs',
      queryParameters: params);
  return ReminderLogPage.fromJson(response.data!);
});

final adminSecuritySessionsProvider =
    FutureProvider.autoDispose<List<AdminSession>>((ref) async {
  final client = ref.watch(adminDioProvider);
  final response = await client.get<List>('/api/admin/security/sessions');
  return response.data!.map((s) => AdminSession.fromJson(s)).toList();
});

final adminSecurityEventsProvider =
    FutureProvider.autoDispose<List<AuditLogEntry>>((ref) async {
  final client = ref.watch(adminDioProvider);
  final response = await client.get<List>('/api/admin/security/events');
  return response.data!.map((e) => AuditLogEntry.fromJson(e)).toList();
});

final ticketFilterProvider =
    StateProvider<String?>((ref) => null); // status filter

final adminSupportTicketsProvider =
    FutureProvider.autoDispose<TicketPage>((ref) async {
  final status = ref.watch(ticketFilterProvider);
  final client = ref.watch(adminDioProvider);
  final params = <String, String>{'page': '1', 'limit': '50'};
  if (status != null) params['status'] = status;
  final response = await client.get<Map<String, dynamic>>('/api/admin/support',
      queryParameters: params);
  return TicketPage.fromJson(response.data!);
});

final adminSystemConfigProvider =
    FutureProvider.autoDispose<List<SystemConfigEntry>>((ref) async {
  final client = ref.watch(adminDioProvider);
  final response = await client.get<List>('/api/admin/config');
  return response.data!.map((c) => SystemConfigEntry.fromJson(c)).toList();
});

// ─── Action Providers ─────────────────────────────────────────────────────────

final adminActionsProvider = Provider((ref) => AdminActions(ref));

class AdminActions {
  final Ref _ref;
  AdminActions(this._ref);

  Dio get _client => _ref.read(adminDioProvider);

  Future<void> revokeUserSessions(String userId) async {
    await _client.post('/api/admin/users/$userId/sessions/revoke');
    _ref.invalidate(adminUsersProvider);
    _ref.invalidate(adminAuditLogsProvider);
  }

  Future<void> suspendUser(String userId, String reason) async {
    await _client
        .post('/api/admin/users/$userId/suspend', data: {'reason': reason});
    _ref.invalidate(adminUsersProvider);
    _ref.invalidate(adminAuditLogsProvider);
  }

  Future<void> reactivateUser(String userId) async {
    await _client.post('/api/admin/users/$userId/reactivate');
    _ref.invalidate(adminUsersProvider);
    _ref.invalidate(adminAuditLogsProvider);
  }

  Future<void> changeUserRole(String userId, String role) async {
    await _client.patch('/api/admin/users/$userId/role', data: {'role': role});
    _ref.invalidate(adminUsersProvider);
    _ref.invalidate(adminAuditLogsProvider);
  }

  Future<void> retryReminder(String logId) async {
    await _client.post('/api/admin/reminders/retry/$logId');
    _ref.invalidate(adminReminderLogsProvider);
    _ref.invalidate(adminReminderStatsProvider);
  }

  Future<void> pauseEngine() async {
    await _client.post('/api/admin/reminders/pause');
    _ref.invalidate(adminReminderStatsProvider);
  }

  Future<void> resumeEngine() async {
    await _client.post('/api/admin/reminders/resume');
    _ref.invalidate(adminReminderStatsProvider);
  }

  Future<void> updateTicket(String id, {String? status, String? notes}) async {
    await _client.patch('/api/admin/support/$id', data: {
      if (status != null) 'status': status,
      if (notes != null) 'internalNotes': notes,
    });
    _ref.invalidate(adminSupportTicketsProvider);
    _ref.invalidate(adminAuditLogsProvider);
  }

  Future<void> sendTicketMessage(String id, String message) async {
    await _client
        .post('/api/admin/support/$id/message', data: {'message': message});
    _ref.invalidate(adminAuditLogsProvider);
  }

  Future<void> updateConfig(String key, String value, String reason) async {
    await _client.put('/api/admin/config/$key',
        data: {'value': value, 'reason': reason});
    _ref.invalidate(adminSystemConfigProvider);
    _ref.invalidate(adminAuditLogsProvider);
  }

  Future<void> startDeletionWorkflow(String userId) async {
    await _client.post('/api/admin/users/$userId/delete-workflow');
    _ref.invalidate(adminSupportTicketsProvider);
    _ref.invalidate(adminAuditLogsProvider);
  }
}

final adminHealthProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final client = ref.watch(adminDioProvider);
  final response = await client.get<Map<String, dynamic>>('/health/ready');
  return response.data!;
});
