import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'document_models.dart';
import 'documents_api.dart';

final documentTypeFilterProvider = StateProvider<DocumentType?>((ref) => null);
final documentSearchQueryProvider = StateProvider<String>((ref) => '');
final documentShowArchivedProvider = StateProvider<bool>((ref) => false);

final documentsControllerProvider =
    AsyncNotifierProvider<DocumentsController, List<TrackedDocument>>(
  DocumentsController.new,
);

class DocumentsController extends AsyncNotifier<List<TrackedDocument>> {
  @override
  FutureOr<List<TrackedDocument>> build() async {
    final type = ref.watch(documentTypeFilterProvider);
    final search = ref.watch(documentSearchQueryProvider);
    final archived = ref.watch(documentShowArchivedProvider);

    return ref.read(documentsApiProvider).getDocuments(
          type: type,
          search: search,
          archived: archived,
        );
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => await build());
  }

  Future<TrackedDocument> addDocument({
    required DocumentType type,
    required String title,
    required DateTime expiryDate,
    String? notes,
    String? providerName,
    double? renewalAmount,
    BillingCycle? billingCycle,
    List<int>? reminderDays,
  }) async {
    final created = await ref.read(documentsApiProvider).createDocument(
          type: type,
          title: title,
          expiryDate: expiryDate,
          notes: notes,
          providerName: providerName,
          renewalAmount: renewalAmount,
          billingCycle: billingCycle,
          reminderDays: reminderDays,
        );
    await reload();
    return created;
  }

  Future<void> editDocument(
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
    await ref.read(documentsApiProvider).updateDocument(
          id,
          type: type,
          title: title,
          expiryDate: expiryDate,
          notes: notes,
          providerName: providerName,
          renewalAmount: renewalAmount,
          billingCycle: billingCycle,
          isArchived: isArchived,
          reminderDays: reminderDays,
        );
    await reload();
  }

  Future<void> toggleArchive(String id, bool archive) async {
    await ref
        .read(documentsApiProvider)
        .updateDocument(id, isArchived: archive);
    await reload();
  }

  Future<void> deleteDocument(String id) async {
    await ref.read(documentsApiProvider).deleteDocument(id);
    await reload();
  }
}
