import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/brand_mark.dart';
import '../../shared/glass.dart';
import '../../shared/theme_mode.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_models.dart';
import '../documents/document_dialog.dart';
import '../documents/document_models.dart';
import '../documents/documents_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.session});

  final AuthSession session;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, TrackedDocument doc) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete tracked item?'),
        content: Text(
            'Are you sure you want to delete "${doc.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(documentsControllerProvider.notifier)
                  .deleteDocument(doc.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final docsAsync = ref.watch(documentsControllerProvider);
    final selectedType = ref.watch(documentTypeFilterProvider);
    final showArchived = ref.watch(documentShowArchivedProvider);

    final name = widget.session.user.displayName?.trim().isNotEmpty == true
        ? widget.session.user.displayName!.trim()
        : widget.session.user.email.split('@').first;

    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Navigation Bar
                    Row(
                      children: [
                        const BrandMark(size: 38),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DueNest',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              'Welcome back, $name',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const ThemeToggleButton(),
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          tooltip: 'Sign out',
                          onPressed: () => ref
                              .read(authControllerProvider.notifier)
                              .signOut(),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Top Action & Search Bar
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _searchController,
                            onChanged: (val) => ref
                                .read(documentSearchQueryProvider.notifier)
                                .state = val,
                            decoration: InputDecoration(
                              hintText: 'Search documents, providers, notes...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded,
                                          size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref
                                            .read(documentSearchQueryProvider
                                                .notifier)
                                            .state = '';
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        FilledButton.icon(
                          onPressed: () => showDocumentDialog(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add item'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Filter category pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('All items'),
                            selected: selectedType == null && !showArchived,
                            onSelected: (_) {
                              ref
                                  .read(documentTypeFilterProvider.notifier)
                                  .state = null;
                              ref
                                  .read(documentShowArchivedProvider.notifier)
                                  .state = false;
                            },
                          ),
                          const SizedBox(width: 8),
                          ...DocumentType.values.map(
                            (type) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                avatar: Icon(type.icon, size: 16),
                                label: Text(type.label),
                                selected: selectedType == type && !showArchived,
                                onSelected: (_) {
                                  ref
                                      .read(documentTypeFilterProvider.notifier)
                                      .state = type;
                                  ref
                                      .read(
                                          documentShowArchivedProvider.notifier)
                                      .state = false;
                                },
                              ),
                            ),
                          ),
                          FilterChip(
                            avatar:
                                const Icon(Icons.archive_outlined, size: 16),
                            label: const Text('Archived'),
                            selected: showArchived,
                            onSelected: (val) {
                              ref
                                  .read(documentShowArchivedProvider.notifier)
                                  .state = val;
                              if (val) {
                                ref
                                    .read(documentTypeFilterProvider.notifier)
                                    .state = null;
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Document List & Status Breakdown
                    Expanded(
                      child: docsAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 36, color: Colors.red),
                              const SizedBox(height: 12),
                              const Text('Failed to load documents.'),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () => ref
                                    .read(documentsControllerProvider.notifier)
                                    .reload(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                        data: (docs) {
                          if (docs.isEmpty) {
                            return _EmptyDashboard(isDark: isDark);
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Urgency Metrics Cards
                              _MetricsRow(docs: docs, isDark: isDark),
                              const SizedBox(height: 18),

                              // Grid of Documents
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final width = constraints.maxWidth;
                                    final crossAxisCount =
                                        width > 900 ? 3 : (width > 600 ? 2 : 1);

                                    return GridView.builder(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        mainAxisSpacing: 16,
                                        crossAxisSpacing: 16,
                                        mainAxisExtent: 195,
                                      ),
                                      itemCount: docs.length,
                                      itemBuilder: (context, index) {
                                        final doc = docs[index];
                                        return _DocumentCard(
                                          doc: doc,
                                          isDark: isDark,
                                          onEdit: () => showDocumentDialog(
                                              context,
                                              document: doc),
                                          onToggleArchive: () => ref
                                              .read(documentsControllerProvider
                                                  .notifier)
                                              .toggleArchive(
                                                  doc.id, !doc.isArchived),
                                          onDelete: () =>
                                              _confirmDelete(context, doc),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.docs, required this.isDark});

  final List<TrackedDocument> docs;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final critical =
        docs.where((d) => d.urgency == ExpiryUrgency.critical).length;
    final expiringSoon =
        docs.where((d) => d.urgency == ExpiryUrgency.expiringSoon).length;
    final upcoming =
        docs.where((d) => d.urgency == ExpiryUrgency.upcoming).length;
    final valid = docs.where((d) => d.urgency == ExpiryUrgency.valid).length;
    final expired =
        docs.where((d) => d.urgency == ExpiryUrgency.expired).length;

    return Row(
      children: [
        if (expired > 0) ...[
          Expanded(
              child: _MetricBadge(
                  label: 'Expired',
                  count: expired,
                  color: const Color(0xFFEF4444),
                  isDark: isDark)),
          const SizedBox(width: 8),
        ],
        Expanded(
            child: _MetricBadge(
                label: 'Critical',
                count: critical,
                color: const Color(0xFFF87171),
                isDark: isDark)),
        const SizedBox(width: 8),
        Expanded(
            child: _MetricBadge(
                label: 'Expiring soon',
                count: expiringSoon,
                color: const Color(0xFFFBBF24),
                isDark: isDark)),
        const SizedBox(width: 8),
        Expanded(
            child: _MetricBadge(
                label: 'Upcoming',
                count: upcoming,
                color: const Color(0xFF60A5FA),
                isDark: isDark)),
        const SizedBox(width: 8),
        Expanded(
            child: _MetricBadge(
                label: 'Valid',
                count: valid,
                color: const Color(0xFF34D399),
                isDark: isDark)),
      ],
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({
    required this.label,
    required this.count,
    required this.color,
    required this.isDark,
  });

  final String label;
  final int count;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0x201E293B)
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: count > 0 ? 0.6 : 0.2),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 13, color: color),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.doc,
    required this.isDark,
    required this.onEdit,
    required this.onToggleArchive,
    required this.onDelete,
  });

  final TrackedDocument doc;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onToggleArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final urgency = doc.urgency;
    final days = doc.daysRemaining;

    String daysText;
    if (days < 0) {
      daysText = '${-days}d overdue';
    } else if (days == 0) {
      daysText = 'Expires today';
    } else {
      daysText = '${days}d left';
    }

    final dateFormatted =
        "${doc.expiryDate.year}-${doc.expiryDate.month.toString().padLeft(2, '0')}-${doc.expiryDate.day.toString().padLeft(2, '0')}";

    return AdvancedGlassPanel(
      radius: 18,
      blurLevel: GlassBlurLevel.medium,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x303B82F6)
                      : const Color(0x182563EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(doc.type.icon,
                    size: 18, color: const Color(0xFF3B82F6)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  doc.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 18),
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'archive') onToggleArchive();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(
                          doc.isArchived
                              ? Icons.unarchive_outlined
                              : Icons.archive_outlined,
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Text(doc.isArchived ? 'Unarchive' : 'Archive'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          if (doc.type == DocumentType.subscription &&
              doc.providerName != null) ...[
            Text(
              doc.providerName!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            if (doc.renewalAmount != null)
              Text(
                '${doc.renewalAmount!.toStringAsFixed(2)}${doc.billingCycle != null ? " / ${doc.billingCycle!.label}" : ""}',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 6),
          ],
          if (doc.notes != null && doc.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                doc.notes!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateFormatted,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF475569),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? urgency.darkBg : urgency.lightBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  daysText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: urgency.baseColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: AdvancedGlassPanel(
          radius: 26,
          blurLevel: GlassBlurLevel.strong,
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 54,
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 20),
              const Text(
                'No tracked documents found',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                'Start tracking your national IDs, driver licenses, passports, and subscriptions to get timely reminders.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => showDocumentDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Track your first document'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
