import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/brand_mark.dart';
import '../../shared/design_tokens.dart';
import '../../shared/glass.dart';
import '../../shared/theme_mode.dart';
import '../auth/auth_models.dart';
import '../auth/api_client_platform.dart';
import '../documents/document_dialog.dart';
import '../documents/document_models.dart';
import '../documents/documents_controller.dart';
import 'user_profile_dialog.dart';

// ─── Resting card shadow ───────────────────────────────────────────────────────
List<BoxShadow> _cardShadowRest(bool isDark) => [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];

// ─── Hover card shadow — deeper ────────────────────────────────────────────────
List<BoxShadow> _cardShadowHover(bool isDark) => [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.07),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.12),
        blurRadius: 24,
        offset: const Offset(0, 10),
        spreadRadius: -2,
      ),
    ];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.session});

  final AuthSession session;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();

  // Nav-bar slide-down reveal on mount
  late final AnimationController _navAnim;
  late final Animation<double> _navFade;
  late final Animation<Offset> _navSlide;

  @override
  void initState() {
    super.initState();
    _navAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _navFade = CurvedAnimation(parent: _navAnim, curve: Curves.easeOut);
    _navSlide = Tween<Offset>(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _navAnim, curve: Curves.easeOutCubic));

    // Small delay so the page settles before animating in
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) _navAnim.forward();
    });
  }

  @override
  void dispose() {
    _navAnim.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, TrackedDocument doc) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Delete tracked item?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to delete "${doc.title}"? This cannot be undone.',
          style: const TextStyle(
              fontSize: 14, color: AppColors.charcoal, height: 1.4),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF791F1F),
              foregroundColor: AppColors.white,
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
                    // ── Animated nav bar ────────────────────────────────
                    FadeTransition(
                      opacity: _navFade,
                      child: SlideTransition(
                        position: _navSlide,
                        child: Row(
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
                                    color: isDark
                                        ? AppColors.inkDark
                                        : AppColors.ink,
                                  ),
                                ),
                                Text(
                                  'Welcome back, $name',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.charcoalDark
                                        : AppColors.charcoal,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const ThemeToggleButton(),
                            const SizedBox(width: 8),
                            IconButton.outlined(
                              tooltip: 'Contact Support',
                              onPressed: () => _showSupportDialog(
                                  context, widget.session.accessToken),
                              icon: Icon(Icons.support_agent_rounded,
                                  size: 17,
                                  color: isDark
                                      ? AppColors.charcoalDark
                                      : AppColors.charcoal),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => showDialog(
                                context: context,
                                builder: (context) => UserProfileDialog(user: widget.session.user),
                              ),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: isDark ? AppColors.charcoal : AppColors.fog,
                                foregroundColor: isDark ? AppColors.white : AppColors.ink,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Search + Add ─────────────────────────────────────
                    FadeTransition(
                      opacity: _navFade,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _searchController,
                              onChanged: (val) => ref
                                  .read(documentSearchQueryProvider.notifier)
                                  .state = val,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.inkDark
                                      : AppColors.ink),
                              decoration: InputDecoration(
                                hintText: 'Search documents, providers…',
                                prefixIcon: Icon(Icons.search_rounded,
                                    color: AppColors.gray),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear_rounded,
                                            size: 16, color: AppColors.gray),
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
                    ),
                    const SizedBox(height: 12),

                    // ── Filter chips ────────────────────────────────────
                    FadeTransition(
                      opacity: _navFade,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('All'),
                              labelStyle: TextStyle(
                                color: (selectedType == null && !showArchived)
                                    ? (isDark
                                        ? AppColors.inkDark
                                        : AppColors.white)
                                    : (isDark
                                        ? AppColors.charcoalDark
                                        : AppColors.charcoal),
                              ),
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
                                      color:
                                          selectedType == type && !showArchived
                                              ? (isDark
                                                  ? AppColors.inkDark
                                                  : AppColors.white)
                                              : AppColors.gray),
                                  label: Text(type.label),
                                  labelStyle: TextStyle(
                                    color:
                                        (selectedType == type && !showArchived)
                                            ? (isDark
                                                ? AppColors.inkDark
                                                : AppColors.white)
                                            : (isDark
                                                ? AppColors.charcoalDark
                                                : AppColors.charcoal),
                                  ),
                                  selected:
                                      selectedType == type && !showArchived,
                                  onSelected: (_) {
                                    ref
                                        .read(
                                            documentTypeFilterProvider.notifier)
                                        .state = type;
                                    ref
                                        .read(documentShowArchivedProvider
                                            .notifier)
                                        .state = false;
                                  },
                                ),
                              ),
                            ),
                            FilterChip(
                              avatar: Icon(Icons.archive_outlined,
                                  size: 14,
                                  color: showArchived
                                      ? (isDark
                                          ? AppColors.inkDark
                                          : AppColors.white)
                                      : AppColors.gray),
                              label: const Text('Archived'),
                              labelStyle: TextStyle(
                                color: showArchived
                                    ? (isDark
                                        ? AppColors.inkDark
                                        : AppColors.white)
                                    : (isDark
                                        ? AppColors.charcoalDark
                                        : AppColors.charcoal),
                              ),
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
                    ),
                    const SizedBox(height: 16),

                    // ── Document list ────────────────────────────────────
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: docsAsync.when(
                          loading: () => Center(
                            key: const ValueKey('loading'),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDark ? AppColors.inkDark : AppColors.ink,
                            ),
                          ),
                          error: (err, stack) => Center(
                            key: const ValueKey('error'),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline_rounded,
                                    size: 32,
                                    color: isDark
                                        ? AppColors.charcoalDark
                                        : AppColors.charcoal),
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
                              return _EmptyDashboard(
                                  key: const ValueKey('empty'), isDark: isDark);
                            }

                            return Column(
                              key: ValueKey('data_${docs.length}_$selectedType'),
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
                                          // Staggered entry: each card slides up + fades in
                                          return _StaggeredCard(
                                            key: ValueKey(doc.id),
                                            index: index,
                                            child: _DocumentCard(
                                              doc: doc,
                                              isDark: isDark,
                                              onEdit: () => showDocumentDialog(
                                                  context,
                                                  document: doc),
                                              onToggleArchive: () => ref
                                                  .read(
                                                      documentsControllerProvider
                                                          .notifier)
                                                  .toggleArchive(
                                                      doc.id, !doc.isArchived),
                                              onDelete: () =>
                                                  _confirmDelete(context, doc),
                                            ),
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

// ─── Staggered entry wrapper ───────────────────────────────────────────────────
/// Wraps a card with a staggered fade + upward-slide entry animation.
/// Each card's delay = index × 40ms, capped at 360ms total.
class _StaggeredCard extends StatefulWidget {
  const _StaggeredCard({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggeredCard> createState() => _StaggeredCardState();
}

class _StaggeredCardState extends State<_StaggeredCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    // Delay capped so late items don't feel sluggish
    final delay = (widget.index * 40).clamp(0, 360);
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

// ─── Metrics row ──────────────────────────────────────────────────────────────
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
    // Upcoming (31–90d) merged into Valid for a cleaner 4-tile layout
    final valid = docs
        .where((d) =>
            d.urgency == ExpiryUrgency.valid ||
            d.urgency == ExpiryUrgency.upcoming)
        .length;

    return Row(
      children: [
        _MetricTile(
          label: 'Expired',
          count: expired,
          urgency: ExpiryUrgency.expired,
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        _MetricTile(
          label: 'Critical',
          count: critical,
          urgency: ExpiryUrgency.critical,
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        _MetricTile(
          label: 'Expiring',
          count: expiringSoon,
          urgency: ExpiryUrgency.expiringSoon,
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        _MetricTile(
          label: 'Valid',
          count: valid,
          urgency: ExpiryUrgency.valid,
          isDark: isDark,
        ),
      ],
    );
  }
}

// ─── Metric tile ──────────────────────────────────────────────────────────────
/// The badge color fills the entire tile — count + label share the same
/// brand-specified text color. No border stroke.
class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.count,
    required this.urgency,
    required this.isDark,
  });

  final String label;
  final int count;
  final ExpiryUrgency urgency;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Dark mode: blend the vivid badgeText hue into the dark surface
    // so each tile has a clearly saturated color tint.
    // Light mode: badge bg fills the tile, dark text on it.
    final Color bg;
    final Color textColor;
    if (isDark) {
      bg = Color.alphaBlend(
        urgency.badgeText.withValues(alpha: 0.25),
        const Color(0xFF0E0E0C),
      );
      textColor = urgency.badgeBg; // lighter variant — readable on dark tint
    } else {
      bg = urgency.badgeBg;
      textColor = urgency.badgeText;
    }

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated count
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale:
                      Tween<double>(begin: 0.75, end: 1.0).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                '$count',
                key: ValueKey<int>(count),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: textColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textColor.withValues(alpha: 0.80),
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
/// Hover-reactive card with animated shadow depth and scale lift.
class _DocumentCard extends StatefulWidget {
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
  State<_DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<_DocumentCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final isDark = widget.isDark;
    final urgency = doc.urgency;
    final days = doc.daysRemaining;

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

    final IconData badgeIcon;
    if (urgency == ExpiryUrgency.expired) {
      badgeIcon = Icons.warning_amber_outlined;
    } else if (urgency == ExpiryUrgency.critical ||
        urgency == ExpiryUrgency.expiringSoon) {
      badgeIcon = Icons.schedule_rounded;
    } else {
      badgeIcon = Icons.check_circle_outline_rounded;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onEdit,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          transform: _hovered
              ? Matrix4.translationValues(0, -2, 0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow:
                _hovered ? _cardShadowHover(isDark) : _cardShadowRest(isDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────────────────
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _hovered
                          ? (isDark
                              ? const Color(0xFF303030)
                              : const Color(0xFFE8E6DF))
                          : (isDark ? const Color(0xFF252523) : AppColors.fog),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(doc.type.icon, size: 17, color: AppColors.gray),
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
                        color: isDark ? AppColors.inkDark : AppColors.ink,
                      ),
                    ),
                  ),
                  // Stop tap-to-edit propagating from the menu button
                  GestureDetector(
                    onTap: () {}, // absorb
                    behavior: HitTestBehavior.opaque,
                    child: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded,
                          size: 17,
                          color: isDark
                              ? AppColors.charcoalDark
                              : AppColors.charcoal),
                      color: isDark ? AppColors.surfaceDark : AppColors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      onSelected: (val) {
                        if (val == 'edit') widget.onEdit();
                        if (val == 'archive') widget.onToggleArchive();
                        if (val == 'delete') widget.onDelete();
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
                  ),
                ],
              ),
              const Spacer(),

              // ── Subscription meta ───────────────────────────────────
              if (doc.type == DocumentType.subscription &&
                  doc.providerName != null) ...[
                Text(
                  doc.providerName!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.charcoalDark : AppColors.charcoal,
                  ),
                ),
                if (doc.renewalAmount != null)
                  Text(
                    '${doc.renewalAmount!.toStringAsFixed(2)}'
                    '${doc.billingCycle != null ? " / ${doc.billingCycle!.label}" : ""}',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.charcoalDark
                            : AppColors.charcoal,
                        fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                const SizedBox(height: 5),
              ],

              // ── Notes ───────────────────────────────────────────────
              if (doc.notes != null && doc.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    doc.notes!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark ? AppColors.charcoalDark : AppColors.gray),
                  ),
                ),

              // ── Date + status badge ─────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormatted,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isDark ? AppColors.charcoalDark : AppColors.charcoal,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  // Status badge — colored text/icon only, no bg fill
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 12, color: urgency.badgeText),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty dashboard ──────────────────────────────────────────────────────────
class _EmptyDashboard extends StatefulWidget {
  const _EmptyDashboard({super.key, required this.isDark});

  final bool isDark;

  @override
  State<_EmptyDashboard> createState() => _EmptyDashboardState();
}

class _EmptyDashboardState extends State<_EmptyDashboard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 100),
        () => mounted ? _ctrl.forward() : null);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Center(
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _cardShadowRest(isDark),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 48,
                    color: isDark ? AppColors.charcoalDark : AppColors.gray,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Nothing tracked yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.inkDark : AppColors.ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Add your national IDs, driving licences, passports, and subscriptions to see expiry dates at a glance.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          isDark ? AppColors.charcoalDark : AppColors.charcoal,
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
        ),
      ),
    );
  }
}

Future<void> _showSupportDialog(
    BuildContext context, String accessToken) async {
  final subjectCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  String category = 'OTHER';

  bool isLoading = false;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
          title: Text('Contact Support',
              style:
                  TextStyle(color: isDark ? AppColors.inkDark : AppColors.ink)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(
                      labelText: 'Category', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(
                        value: 'ACCOUNT_ACCESS', child: Text('Account Access')),
                    DropdownMenuItem(
                        value: 'REMINDER_DELIVERY',
                        child: Text('Reminder Delivery')),
                    DropdownMenuItem(
                        value: 'PRIVACY_DELETION',
                        child: Text('Privacy / Data Deletion')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => category = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: subjectCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Subject', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      labelText: 'Description', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (subjectCtrl.text.trim().length < 5 ||
                          descCtrl.text.trim().length < 10) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Please provide a detailed subject and description.')));
                        return;
                      }
                      setState(() => isLoading = true);
                      try {
                        final client = createDio();
                        client.options.headers['Authorization'] =
                            'Bearer $accessToken';
                        await client.post('/api/support/tickets', data: {
                          'category': category,
                          'subject': subjectCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                        });
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  'Support ticket created. We will be in touch!')));
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')));
                        }
                      } finally {
                        if (ctx.mounted) {
                          setState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit Ticket'),
            ),
          ],
        );
      },
    ),
  );
}
