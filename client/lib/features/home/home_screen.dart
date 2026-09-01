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

// ─── Monochromatic tokens ─────────────────────────────────────────────────────
const _ink = Color(0xFF111111);
const _charcoal = Color(0xFF444441);
const _gray = Color(0xFFB4B2A9);
const _fog = Color(0xFFF1EFE8);
const _border = Color(0xFFD3D1C7);
const _white = Color(0xFFFFFFFF);

const _inkDark = Color(0xFFFAFAFA);
const _charcoalDark = Color(0xFFB4B2A9);
const _borderDark = Color(0xFF3A3A38);
const _surfaceDark = Color(0xFF1A1A18);

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
        backgroundColor: _white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _border),
        ),
        title: const Text('Delete tracked item?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to delete "${doc.title}"? This cannot be undone.',
          style: const TextStyle(fontSize: 14, color: _charcoal, height: 1.4),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF791F1F),
              foregroundColor: _white,
            ),
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
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Navigation bar ───────────────────────────────────
                    Row(
                      children: [
                        const BrandMark(size: 36),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DueNest',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.4,
                                color: isDark ? _inkDark : _ink,
                              ),
                            ),
                            Text(
                              'Welcome back, $name',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? _charcoalDark : _charcoal,
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
                          icon: Icon(Icons.logout_rounded,
                              size: 17,
                              color: isDark ? _charcoalDark : _charcoal),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Search + Add button ──────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _searchController,
                            onChanged: (val) => ref
                                .read(documentSearchQueryProvider.notifier)
                                .state = val,
                            style: TextStyle(
                                fontSize: 14,
                                color: isDark ? _inkDark : _ink),
                            decoration: InputDecoration(
                              hintText: 'Search documents, providers…',
                              prefixIcon:
                                  Icon(Icons.search_rounded, color: _gray),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear_rounded,
                                          size: 16, color: _gray),
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
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: () => showDocumentDialog(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add item'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Filter chips ─────────────────────────────────────
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('All'),
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
                                avatar: Icon(type.icon,
                                    size: 14,
                                    color: selectedType == type && !showArchived
                                        ? (isDark ? _surfaceDark : _white)
                                        : _gray),
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
                            avatar: Icon(Icons.archive_outlined,
                                size: 14,
                                color: showArchived
                                    ? (isDark ? _surfaceDark : _white)
                                    : _gray),
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

                    // ── Document list ────────────────────────────────────
                    Expanded(
                      child: docsAsync.when(
                        loading: () => Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? _inkDark : _ink,
                          ),
                        ),
                        error: (err, stack) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  size: 32,
                                  color: isDark ? _charcoalDark : _charcoal),
                              const SizedBox(height: 12),
                              const Text('Failed to load documents.',
                                  style: TextStyle(fontSize: 14)),
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
                              _MetricsRow(docs: docs, isDark: isDark),
                              const SizedBox(height: 16),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final w = constraints.maxWidth;
                                    final cols =
                                        w > 900 ? 3 : (w > 600 ? 2 : 1);
                                    return GridView.builder(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: cols,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                        mainAxisExtent: 188,
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

// ─── Metrics row ─────────────────────────────────────────────────────────────

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.docs, required this.isDark});

  final List<TrackedDocument> docs;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final expired =
        docs.where((d) => d.urgency == ExpiryUrgency.expired).length;
    final critical =
        docs.where((d) => d.urgency == ExpiryUrgency.critical).length;
    final expiringSoon =
        docs.where((d) => d.urgency == ExpiryUrgency.expiringSoon).length;
    final upcoming =
        docs.where((d) => d.urgency == ExpiryUrgency.upcoming).length;
    final valid = docs.where((d) => d.urgency == ExpiryUrgency.valid).length;

    return Row(
      children: [
        _MetricTile(
            label: 'Expired',
            count: expired,
            badgeBg: ExpiryUrgency.expired.badgeBg,
            badgeText: ExpiryUrgency.expired.badgeText,
            isDark: isDark),
        const SizedBox(width: 8),
        _MetricTile(
            label: 'Critical',
            count: critical,
            badgeBg: ExpiryUrgency.critical.badgeBg,
            badgeText: ExpiryUrgency.critical.badgeText,
            isDark: isDark),
        const SizedBox(width: 8),
        _MetricTile(
            label: 'Expiring',
            count: expiringSoon,
            badgeBg: ExpiryUrgency.expiringSoon.badgeBg,
            badgeText: ExpiryUrgency.expiringSoon.badgeText,
            isDark: isDark),
        const SizedBox(width: 8),
        _MetricTile(
            label: 'Upcoming',
            count: upcoming,
            badgeBg: ExpiryUrgency.upcoming.badgeBg,
            badgeText: ExpiryUrgency.upcoming.badgeText,
            isDark: isDark),
        const SizedBox(width: 8),
        _MetricTile(
            label: 'Valid',
            count: valid,
            badgeBg: ExpiryUrgency.valid.badgeBg,
            badgeText: ExpiryUrgency.valid.badgeText,
            isDark: isDark),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.count,
    required this.badgeBg,
    required this.badgeText,
    required this.isDark,
  });

  final String label;
  final int count;
  final Color badgeBg;
  final Color badgeText;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surfaceBg = isDark ? _surfaceDark : _white;
    final borderC = isDark ? _borderDark : _border;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: surfaceBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderC),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Colored dot — the only color in this widget
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badgeText,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isDark ? _inkDark : _ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? _charcoalDark : _charcoal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Document card ────────────────────────────────────────────────────────────

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

    // Calm, plain copy — no exclamation marks
    String daysText;
    if (days < 0) {
      daysText = '${-days}d overdue';
    } else if (days == 0) {
      daysText = 'Expires today';
    } else {
      daysText = 'Expires in $days days';
    }

    final dateFormatted =
        '${doc.expiryDate.year}-${doc.expiryDate.month.toString().padLeft(2, '0')}-${doc.expiryDate.day.toString().padLeft(2, '0')}';

    final cardBg = isDark ? _surfaceDark : _white;
    final cardBorder = isDark ? _borderDark : _border;

    // Badge icon
    final IconData badgeIcon;
    if (urgency == ExpiryUrgency.expired) {
      badgeIcon = Icons.warning_amber_outlined;
    } else if (urgency == ExpiryUrgency.critical ||
        urgency == ExpiryUrgency.expiringSoon) {
      badgeIcon = Icons.schedule_rounded;
    } else {
      badgeIcon = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Category icon — gray, no color
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252523) : _fog,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(doc.type.icon, size: 17, color: _gray),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  doc.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark ? _inkDark : _ink,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    size: 17, color: isDark ? _charcoalDark : _charcoal),
                color: isDark ? _surfaceDark : _white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                        color: isDark ? _borderDark : _border)),
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'archive') onToggleArchive();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 16),
                      SizedBox(width: 10),
                      Text('Edit', style: TextStyle(fontSize: 14)),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: Row(children: [
                      Icon(
                        doc.isArchived
                            ? Icons.unarchive_outlined
                            : Icons.archive_outlined,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(doc.isArchived ? 'Unarchive' : 'Archive',
                          style: const TextStyle(fontSize: 14)),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 16, color: Color(0xFF791F1F)),
                      SizedBox(width: 10),
                      Text('Delete',
                          style: TextStyle(
                              fontSize: 14, color: Color(0xFF791F1F))),
                    ]),
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
                fontWeight: FontWeight.w500,
                color: isDark ? _charcoalDark : _charcoal,
              ),
            ),
            if (doc.renewalAmount != null)
              Text(
                '${doc.renewalAmount!.toStringAsFixed(2)}'
                '${doc.billingCycle != null ? " / ${doc.billingCycle!.label}" : ""}',
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? _charcoalDark : _charcoal,
                    fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            const SizedBox(height: 5),
          ],
          if (doc.notes != null && doc.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                doc.notes!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? _charcoalDark : _gray),
              ),
            ),
          // Date row + status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateFormatted,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? _charcoalDark : _charcoal,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              // Status badge — the only color in the card
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: urgency.badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 11, color: urgency.badgeText),
                    const SizedBox(width: 4),
                    Text(
                      daysText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: urgency.badgeText,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: isDark ? _surfaceDark : _white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? _borderDark : _border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 48,
                color: isDark ? _charcoalDark : _gray,
              ),
              const SizedBox(height: 18),
              Text(
                'Nothing tracked yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? _inkDark : _ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Add your national IDs, driving licences, passports, and subscriptions to see expiry dates at a glance.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? _charcoalDark : _charcoal,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => showDocumentDialog(context),
                icon: const Icon(Icons.add_rounded, size: 17),
                label: const Text('Track your first item'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
