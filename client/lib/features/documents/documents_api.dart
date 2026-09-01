import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/api_client_platform.dart';
import '../auth/auth_controller.dart';
import 'document_models.dart';

final documentsApiProvider = Provider<DocumentsApi>((ref) {
  final dio = createDio();
  final token = ref.watch(authControllerProvider).value?.accessToken;
  if (token != null) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }
  return DocumentsApi(dio);
});

class DocumentsApi {
  DocumentsApi(this._dio);

  final Dio _dio;

  Future<List<TrackedDocument>> getDocuments({
    DocumentType? type,
    bool? archived,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (type != null) queryParams['type'] = type.code;
    if (archived != null) queryParams['archived'] = archived.toString();
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _dio.get<List<dynamic>>(
      '/api/documents',
      queryParameters: queryParams,
    );

    return (response.data ?? [])
        .map((json) => TrackedDocument.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<TrackedDocument> createDocument({
    required DocumentType type,
    required String title,
    required DateTime expiryDate,
    String? notes,
    String? providerName,
    double? renewalAmount,
    BillingCycle? billingCycle,
    List<int>? reminderDays,
  }) async {
    final dateStr =
        "${expiryDate.year.toString().padLeft(4, '0')}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}";

    final payload = <String, dynamic>{
      'type': type.code,
      'title': title.trim(),
      'expiryDate': dateStr,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      if (providerName != null && providerName.trim().isNotEmpty)
        'providerName': providerName.trim(),
      if (renewalAmount != null) 'renewalAmount': renewalAmount,
      if (billingCycle != null) 'billingCycle': billingCycle.code,
      if (reminderDays != null) 'reminderDays': reminderDays,
    };

    final response = await _dio.post<Map<String, dynamic>>(
      '/api/documents',
      data: payload,
    );

    return TrackedDocument.fromJson(response.data!);
  }

  Future<TrackedDocument> updateDocument(
    String id, {
    DocumentType? type,
    String? title,
    DateTime? expiryDate,
    String? notes,
    String? providerName,
    double? renewalAmount,
    BillingCycle? billingCycle,
    bool? isArchived,
    List<int>? reminderDays,
  }) async {
    final payload = <String, dynamic>{};
    if (type != null) payload['type'] = type.code;
    if (title != null) payload['title'] = title.trim();
    if (expiryDate != null) {
      payload['expiryDate'] =
          "${expiryDate.year.toString().padLeft(4, '0')}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}";
    }
    if (notes != null) {
      payload['notes'] = notes.trim().isEmpty ? null : notes.trim();
    }
    if (providerName != null) {
      payload['providerName'] =
          providerName.trim().isEmpty ? null : providerName.trim();
    }
    if (renewalAmount != null) payload['renewalAmount'] = renewalAmount;
    if (billingCycle != null) payload['billingCycle'] = billingCycle.code;
    if (isArchived != null) payload['isArchived'] = isArchived;
    if (reminderDays != null) payload['reminderDays'] = reminderDays;

    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/documents/$id',
      data: payload,
    );

    return TrackedDocument.fromJson(response.data!);
  }

  Future<void> deleteDocument(String id) async {
    await _dio.delete<void>('/api/documents/$id');
  }
}
