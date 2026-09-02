import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/design_tokens.dart';
import '../auth/auth_controller.dart';
import 'admin_login_screen.dart';
import 'admin_providers.dart';

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Helpers Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

String _fmt(DateTime dt) {
  final local = dt.toLocal();
  final y = local.year;
  final mo = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final mi = local.minute.toString().padLeft(2, '0');
  return '$y-$mo-$d  $h:$mi';
}

String _fmtDate(DateTime dt) {
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

Widget _chip(String label, Color bg, Color fg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );

Widget _statusChip(String status) {
  return switch (status.toUpperCase()) {
    'SENT' => _chip('SENT', const Color(0xFF1A4731), Colors.greenAccent),
    'FAILED' => _chip('FAILED', const Color(0xFF4C1415), Colors.redAccent),
    'PENDING' => _chip('PENDING', const Color(0xFF3D2B05), Colors.amber),
    'PROCESSING' =>
      _chip('PROCESSING', const Color(0xFF1A2E4C), Colors.lightBlueAccent),
    'OPEN' => _chip('OPEN', const Color(0xFF1A2E4C), Colors.lightBlueAccent),
    'IN_PROGRESS' =>
      _chip('IN PROGRESS', const Color(0xFF3D2B05), Colors.amber),
    'RESOLVED' =>
      _chip('RESOLVED', const Color(0xFF1A4731), Colors.greenAccent),
    'SUCCESS' => _chip('OK', const Color(0xFF1A4731), Colors.greenAccent),
    'FAILURE' => _chip('FAIL', const Color(0xFF4C1415), Colors.redAccent),
    _ => _chip(status, const Color(0xFF2A2A28), AppColors.gray),
  };
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Shared Widgets Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _TabHeader extends StatelessWidget {
  const _TabHeader({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: isDark ? AppColors.inkDark : AppColors.ink)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                style: const TextStyle(fontSize: 13, color: AppColors.gray)),
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      spaced.add(Expanded(child: children[i]));
      if (i < children.length - 1) spaced.add(const SizedBox(width: 12));
    }
    return Row(children: spaced);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      this.sub,
      this.color});
  final String label;
  final String value;
  final IconData icon;
  final String? sub;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.selectedDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: color ?? AppColors.gray),
            const SizedBox(width: 6),
            Flexible(
                child: Text(label,
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.gray))),
          ]),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color:
                      color ?? (isDark ? AppColors.inkDark : AppColors.ink))),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub!,
                style: const TextStyle(fontSize: 11, color: AppColors.gray))
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.selectedDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border, width: 1),
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(fontSize: 12, color: AppColors.gray))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.inkDark : AppColors.ink))),
        ],
      ),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Dashboard Shell Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _tab = 0;

  static const _tabs = [
    (icon: Icons.dashboard_rounded, label: 'Overview'),
    (icon: Icons.people_rounded, label: 'Users'),
    (icon: Icons.history_rounded, label: 'Audit Logs'),
    (icon: Icons.notifications_rounded, label: 'Reminders'),
    (icon: Icons.shield_rounded, label: 'Security'),
    (icon: Icons.support_agent_rounded, label: 'Support'),
    (icon: Icons.settings_rounded, label: 'System'),
    (icon: Icons.account_circle_rounded, label: 'My Account'),
  ];

  void _refresh() {
    ref.invalidate(adminMetricsProvider);
    ref.invalidate(adminUsersProvider);
    ref.invalidate(adminAuditLogsProvider);
    ref.invalidate(adminReminderStatsProvider);
    ref.invalidate(adminReminderLogsProvider);
    ref.invalidate(adminSecuritySessionsProvider);
    ref.invalidate(adminSecurityEventsProvider);
    ref.invalidate(adminSupportTicketsProvider);
    ref.invalidate(adminSystemConfigProvider);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).value;
    if (session?.user.role != 'ADMIN') return const AdminLoginScreen();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg = isDark ? const Color(0xFF0F0F0D) : AppColors.ink;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.fog,
      body: Row(
        children: [
          Container(
            width: 220,
            color: sidebarBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DueNest',
                          style: TextStyle(
                              color: AppColors.inkDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5)),
                      const Text('Admin',
                          style: TextStyle(
                              color: AppColors.charcoalDark,
                              fontSize: 12,
                              letterSpacing: 1.2)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _tabs.length,
                    itemBuilder: (context, i) {
                      final tab = _tabs[i];
                      final selected = _tab == i;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Material(
                          color: selected
                              ? AppColors.charcoal.withValues(alpha: 0.5)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(() => _tab = i),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  Icon(tab.icon,
                                      size: 17,
                                      color: selected
                                          ? AppColors.inkDark
                                          : AppColors.gray),
                                  const SizedBox(width: 12),
                                  Text(tab.label,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: selected
                                              ? AppColors.inkDark
                                              : AppColors.gray)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(color: Color(0xFF2A2A28), height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      IconButton(
                          icon: const Icon(Icons.refresh_rounded,
                              color: AppColors.gray, size: 18),
                          tooltip: 'Refresh all',
                          onPressed: _refresh),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded,
                            color: AppColors.gray, size: 18),
                        tooltip: 'Sign out',
                        onPressed: () async =>
                            ref.read(authControllerProvider.notifier).signOut(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) {
                final slideAnim = Tween<Offset>(
                  begin: const Offset(0.0, 0.05),
                  end: Offset.zero,
                ).animate(anim);
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: slideAnim,
                    child: child,
                  ),
                );
              },
              child: _buildTab(_tab),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index) {
    return switch (index) {
      0 => const _OverviewTab(key: ValueKey('overview')),
      1 => const _UsersTab(key: ValueKey('users')),
      2 => const _AuditLogsTab(key: ValueKey('audit')),
      3 => const _RemindersTab(key: ValueKey('reminders')),
      4 => const _SecurityTab(key: ValueKey('security')),
      5 => const _SupportTab(key: ValueKey('support')),
      6 => const _SystemTab(key: ValueKey('system')),
      7 => const _MyAccountTab(key: ValueKey('account')),
      _ => const SizedBox.shrink(),
    };
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Tab 0: Overview Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(adminMetricsProvider);
    final reminderAsync = ref.watch(adminReminderStatsProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TabHeader(
              title: 'Overview', subtitle: 'Live operational snapshot'),
          metricsAsync.when(
            loading: () => const Padding(
                padding: EdgeInsets.all(64),
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error: $e',
                    style: const TextStyle(color: Colors.redAccent))),
            data: (m) => Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Users',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  _StatRow(children: [
                    _StatCard(
                        label: 'Total Users',
                        value: '${m.usersTotal}',
                        icon: Icons.people_rounded),
                    _StatCard(
                        label: 'New (7d)',
                        value: '+${m.usersNewLast7Days}',
                        icon: Icons.person_add_rounded,
                        color: Colors.greenAccent.shade400),
                  ]),
                  const SizedBox(height: 24),
                  const Text('Documents',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  _StatRow(children: [
                    _StatCard(
                        label: 'Total',
                        value: '${m.docsTotal}',
                        icon: Icons.description_rounded),
                    _StatCard(
                        label: 'Expired',
                        value: '${m.docsExpired}',
                        icon: Icons.cancel_rounded,
                        color: Colors.redAccent),
                    _StatCard(
                        label: 'Critical <7d',
                        value: '${m.docsCritical}',
                        icon: Icons.warning_rounded,
                        color: Colors.orange),
                    _StatCard(
                        label: 'Expiring Soon',
                        value: '${m.docsSoon}',
                        icon: Icons.schedule_rounded,
                        color: Colors.amber),
                  ]),
                  const SizedBox(height: 24),
                  const Text('Reminders',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  reminderAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Reminder error: $e',
                        style: const TextStyle(color: Colors.redAccent)),
                    data: (r) => _StatRow(children: [
                      _StatCard(
                          label: 'Delivery Rate',
                          value: '${m.deliveryRate}%',
                          icon: Icons.send_rounded,
                          color: Colors.greenAccent.shade400),
                      _StatCard(
                          label: 'Pending',
                          value: '${r.pending}',
                          icon: Icons.hourglass_bottom_rounded),
                      _StatCard(
                          label: 'Failed',
                          value: '${r.failed}',
                          icon: Icons.error_outline_rounded,
                          color: r.failed > 0 ? Colors.redAccent : null),
                      _StatCard(
                        label: 'Engine',
                        value: r.paused ? 'PAUSED' : 'RUNNING',
                        icon: r.paused
                            ? Icons.pause_circle_rounded
                            : Icons.play_circle_rounded,
                        color: r.paused
                            ? Colors.orange
                            : Colors.greenAccent.shade400,
                        sub: r.lastRun != null
                            ? 'Last: ${r.lastRun!.substring(0, 16).replaceAll('T', ' ')}'
                            : null,
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  const Text('System Health',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  ref.watch(adminHealthProvider).when(
                        loading: () => const CircularProgressIndicator(),
                        error: (e, _) => Text('Health check failed: $e',
                            style: const TextStyle(color: Colors.redAccent)),
                        data: (h) => _StatRow(children: [
                          _StatCard(
                              label: 'API Server',
                              value: h['status'] == 'ok' ? 'ONLINE' : 'DOWN',
                              icon: Icons.api_rounded,
                              color: h['status'] == 'ok'
                                  ? Colors.greenAccent.shade400
                                  : Colors.redAccent),
                          _StatCard(
                              label: 'Database',
                              value:
                                  h['database'] == 'ok' ? 'CONNECTED' : 'DOWN',
                              icon: Icons.storage_rounded,
                              color: h['database'] == 'ok'
                                  ? Colors.greenAccent.shade400
                                  : Colors.redAccent),
                          _StatCard(
                              label: 'Version',
                              value: h['version'] ?? 'Unknown',
                              icon: Icons.verified_rounded),
                        ]),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Tab 1: Users Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _UsersTab extends ConsumerStatefulWidget {
  const _UsersTab({super.key});
  @override
  ConsumerState<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<_UsersTab> {
  final _searchCtrl = TextEditingController();
  AdminUser? _selected;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TabHeader(
                  title: 'Users', subtitle: 'Search and manage user accounts'),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by email or name...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref
                                  .read(adminUsersFilterProvider.notifier)
                                  .state = const AdminUsersFilter();
                            })
                        : null,
                  ),
                  onChanged: (v) => ref
                      .read(adminUsersFilterProvider.notifier)
                      .update((s) => s.copyWith(search: v, page: 1)),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: usersAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                      child: Text('Error: $e',
                          style: const TextStyle(color: Colors.redAccent))),
                  data: (page) => ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    itemCount: page.users.length,
                    itemBuilder: (context, i) {
                      final u = page.users[i];
                      final isSelected = _selected?.id == u.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: isSelected
                              ? AppColors.ink
                              : (isDark
                                  ? AppColors.selectedDark
                                  : AppColors.white),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => setState(
                                () => _selected = isSelected ? null : u),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: isDark
                                        ? AppColors.borderDark
                                        : AppColors.fog,
                                    child: Text(u.email[0].toUpperCase(),
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? AppColors.ink
                                                : (isDark
                                                    ? AppColors.inkDark
                                                    : AppColors.ink))),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(u.email,
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: isSelected
                                                    ? AppColors.inkDark
                                                    : (isDark
                                                        ? AppColors.inkDark
                                                        : AppColors.ink))),
                                        if (u.displayName != null)
                                          Text(u.displayName!,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.gray)),
                                      ],
                                    ),
                                  ),
                                  if (u.isSuspended) ...[
                                    _chip('SUSPENDED', Colors.red.shade900,
                                        Colors.redAccent),
                                    const SizedBox(width: 6)
                                  ],
                                  if (u.role == 'ADMIN') ...[
                                    _chip('ADMIN', const Color(0xFF2A2A28),
                                        AppColors.inkDark),
                                    const SizedBox(width: 8)
                                  ],
                                  Text(
                                      '${u.documentCount}d  ${u.activeSessionCount}s',
                                      style: const TextStyle(
                                          fontSize: 11, color: AppColors.gray)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_selected != null)
          SizedBox(
            width: 340,
            child: _UserDetailPanel(
                user: _selected!,
                onClose: () => setState(() => _selected = null)),
          ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _UserDetailPanel extends ConsumerWidget {
  const _UserDetailPanel({required this.user, required this.onClose});
  final AdminUser user;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actions = ref.read(adminActionsProvider);

    Future<void> suspendDialog() async {
      final ctrl = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Suspend Account'),
          content: TextField(
              controller: ctrl,
              decoration:
                  const InputDecoration(labelText: 'Reason (minimum 5 chars)'),
              maxLines: 3),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Suspend')),
          ],
        ),
      );
      if (ok == true && ctrl.text.trim().length >= 5) {
        await actions.suspendUser(user.id, ctrl.text.trim());
      }
    }

    Future<void> confirm(
        String title, String body, Future<void> Function() fn) async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirm')),
          ],
        ),
      );
      if (ok == true) await fn();
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F0D) : AppColors.white,
        border: Border(
            left: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 12, 0),
            child: Row(
              children: [
                Text('User Detail',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.inkDark : AppColors.ink)),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: onClose),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user.isSuspended) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: const Color(0xFF4C1415),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('SUSPENDED: ${user.suspendedReason ?? 'Ã¢â‚¬â€'}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.redAccent)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _DetailRow(label: 'Email', value: user.email),
                  _DetailRow(label: 'Name', value: user.displayName ?? 'Ã¢â‚¬â€'),
                  _DetailRow(label: 'Role', value: user.role),
                  _DetailRow(label: 'Timezone', value: user.timeZone),
                  _DetailRow(label: 'Joined', value: _fmtDate(user.createdAt)),
                  _DetailRow(
                      label: 'Documents', value: '${user.documentCount}'),
                  _DetailRow(
                      label: 'Active Sessions',
                      value: '${user.activeSessionCount}'),
                  _DetailRow(
                      label: 'Email Reminders',
                      value: user.emailNotificationsEnabled
                          ? 'Enabled'
                          : 'Disabled'),
                  const SizedBox(height: 20),
                  const Text('ACTIONS',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray,
                          letterSpacing: 1)),
                  const SizedBox(height: 12),
                  if (!user.isSuspended)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: suspendDialog,
                        icon: const Icon(Icons.block_rounded, size: 14),
                        label: const Text('Suspend Account'),
                      ),
                    ),
                  if (user.isSuspended)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => confirm(
                            'Reactivate User',
                            'This will restore access to this account.',
                            () => actions.reactivateUser(user.id)),
                        icon: const Icon(Icons.check_circle_outline_rounded,
                            size: 14),
                        label: const Text('Reactivate Account'),
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => confirm(
                          'Force Sign Out',
                          'Revoke all active sessions for ${user.email}?',
                          () => actions.revokeUserSessions(user.id)),
                      icon: const Icon(Icons.logout_rounded, size: 14),
                      label: const Text('Force Sign Out'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => confirm('Start Deletion Workflow',
                          'Open a privacy deletion ticket for ${user.email}?',
                          () async {
                        await actions.startDeletionWorkflow(user.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Deletion ticket created')));
                        }
                      }),
                      icon: const Icon(Icons.delete_forever_rounded, size: 14),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent),
                      label: const Text('Start Deletion Workflow'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Tab 2: Audit Logs Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _AuditLogsTab extends ConsumerWidget {
  const _AuditLogsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(adminAuditLogsProvider);
    final filter = ref.watch(auditLogFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TabHeader(
            title: 'Audit Logs',
            subtitle: 'Append-only Ã¢â‚¬â€ no admin can edit or delete entries'),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 8),
          child: Row(
            children: ['', 'SUCCESS', 'FAILURE'].map((r) {
              final selected = filter.result == (r.isEmpty ? null : r);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                    label: Text(r.isEmpty ? 'All' : r),
                    selected: selected,
                    onSelected: (_) => ref
                        .read(auditLogFilterProvider.notifier)
                        .update((s) => AuditLogFilter(
                              action: s.action,
                              result: r.isEmpty ? null : r,
                              page: 1,
                            ))),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: logsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: Colors.redAccent))),
            data: (page) => ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              itemCount: page.logs.length,
              itemBuilder: (context, i) {
                final log = page.logs[i];
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.selectedDark : AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color:
                              isDark ? AppColors.borderDark : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _statusChip(log.result),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log.action,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.inkDark
                                          : AppColors.ink)),
                              Text(
                                  'Actor: ${log.actorId}${log.targetId != null ? "  |  Target: ${log.targetId}" : ""}',
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.gray)),
                              if (log.reason != null)
                                Text('Reason: ${log.reason}',
                                    style: const TextStyle(
                                        fontSize: 11, color: AppColors.gray)),
                            ],
                          ),
                        ),
                        Text(_fmt(log.timestamp),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.gray)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Tab 3: Reminders Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _RemindersTab extends ConsumerWidget {
  const _RemindersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminReminderStatsProvider);
    final logsAsync = ref.watch(adminReminderLogsProvider);
    final statusFilter = ref.watch(reminderLogFilterProvider);
    final actions = ref.read(adminActionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TabHeader(
            title: 'Reminder Operations',
            subtitle: 'Queue health, delivery history, and controls'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                statsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e',
                      style: const TextStyle(color: Colors.redAccent)),
                  data: (s) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionCard(
                        child: Row(
                          children: [
                            Icon(
                                s.paused
                                    ? Icons.pause_circle_rounded
                                    : Icons.play_circle_rounded,
                                color: s.paused
                                    ? Colors.orange
                                    : Colors.greenAccent,
                                size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(
                                      s.paused
                                          ? 'Engine is PAUSED'
                                          : 'Engine is RUNNING',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.inkDark
                                              : AppColors.ink)),
                                  if (s.lastRun != null)
                                    Text(
                                        'Last run: ${s.lastRun!.substring(0, 16).replaceAll('T', ' ')}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.gray)),
                                ])),
                            TextButton(
                              onPressed: s.paused
                                  ? () => actions.resumeEngine()
                                  : () => actions.pauseEngine(),
                              child: Text(
                                  s.paused ? 'Resume Engine' : 'Pause Engine'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _StatRow(children: [
                        _StatCard(
                            label: 'Pending',
                            value: '${s.pending}',
                            icon: Icons.hourglass_bottom_rounded),
                        _StatCard(
                            label: 'Processing',
                            value: '${s.processing}',
                            icon: Icons.sync_rounded),
                        _StatCard(
                            label: 'Sent',
                            value: '${s.sent}',
                            icon: Icons.check_circle_outline_rounded,
                            color: Colors.greenAccent.shade400),
                        _StatCard(
                            label: 'Failed',
                            value: '${s.failed}',
                            icon: Icons.error_outline_rounded,
                            color: s.failed > 0 ? Colors.redAccent : null),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text('Delivery Log',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray,
                            letterSpacing: 0.5)),
                    const SizedBox(width: 12),
                    ...['', 'PENDING', 'SENT', 'FAILED'].map((s) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                              label: Text(s.isEmpty ? 'All' : s),
                              selected: statusFilter == (s.isEmpty ? null : s),
                              onSelected: (_) => ref
                                  .read(reminderLogFilterProvider.notifier)
                                  .state = s.isEmpty ? null : s),
                        )),
                  ],
                ),
                const SizedBox(height: 12),
                logsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e',
                      style: const TextStyle(color: Colors.redAccent)),
                  data: (page) => Column(
                    children: page.logs.map((log) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.selectedDark
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.border),
                          ),
                          child: Row(
                            children: [
                              _statusChip(log.status),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${log.documentTitle} (${log.documentType})',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? AppColors.inkDark
                                                : AppColors.ink)),
                                    Text(
                                        '${log.userEmail}  |  ${log.daysBefore}d before  |  Retries: ${log.retryCount}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.gray)),
                                    if (log.error != null)
                                      Text('Error: ${log.error}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.redAccent)),
                                  ],
                                ),
                              ),
                              if (log.status == 'FAILED')
                                TextButton.icon(
                                    onPressed: () =>
                                        actions.retryReminder(log.id),
                                    icon: const Icon(Icons.refresh_rounded,
                                        size: 14),
                                    label: const Text('Retry')),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Tab 4: Security Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _SecurityTab extends ConsumerWidget {
  const _SecurityTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(adminSecuritySessionsProvider);
    final eventsAsync = ref.watch(adminSecurityEventsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TabHeader(
              title: 'Security Center',
              subtitle: 'Active admin sessions and recent security events'),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ACTIVE ADMIN SESSIONS',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray,
                        letterSpacing: 1)),
                const SizedBox(height: 12),
                sessionsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e',
                      style: const TextStyle(color: Colors.redAccent)),
                  data: (sessions) => _SectionCard(
                    padding: EdgeInsets.zero,
                    child: sessions.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('No active admin sessions',
                                style: TextStyle(color: AppColors.gray)))
                        : Column(
                            children: sessions
                                .map((s) => ListTile(
                                      leading: const Icon(
                                          Icons.computer_rounded,
                                          size: 16,
                                          color: AppColors.gray),
                                      title: Text(s.userEmail,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: isDark
                                                  ? AppColors.inkDark
                                                  : AppColors.ink)),
                                      subtitle: Text(
                                          '${s.deviceName ?? s.deviceType ?? 'Web'}  |  Last seen: ${_fmt(s.lastUsedAt)}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.gray)),
                                      trailing: Text(
                                          'Exp ${_fmtDate(s.expiresAt)}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.gray)),
                                    ))
                                .toList(),
                          ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text('RECENT SECURITY EVENTS',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray,
                        letterSpacing: 1)),
                const SizedBox(height: 12),
                eventsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e',
                      style: const TextStyle(color: Colors.redAccent)),
                  data: (events) => Column(
                    children: events.take(30).map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.selectedDark
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.border),
                          ),
                          child: Row(
                            children: [
                              _statusChip(e.result),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(e.action,
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? AppColors.inkDark
                                                : AppColors.ink)),
                                    Text(
                                        'Actor: ${e.actorId}${e.targetId != null ? "  Target: ${e.targetId}" : ""}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.gray)),
                                  ])),
                              Text(_fmt(e.timestamp),
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.gray)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Tab 5: Support Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _SupportTab extends ConsumerStatefulWidget {
  const _SupportTab({super.key});
  @override
  ConsumerState<_SupportTab> createState() => _SupportTabState();
}

class _SupportTabState extends ConsumerState<_SupportTab> {
  SupportTicket? _selected;

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(adminSupportTicketsProvider);
    final statusFilter = ref.watch(ticketFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TabHeader(
                  title: 'Support Inbox',
                  subtitle: 'User requests and privacy workflows'),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 12, 32, 8),
                child: Row(
                  children: ['', 'OPEN', 'IN_PROGRESS', 'RESOLVED']
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                                label: Text(
                                    s.isEmpty ? 'All' : s.replaceAll('_', ' ')),
                                selected:
                                    statusFilter == (s.isEmpty ? null : s),
                                onSelected: (_) => ref
                                    .read(ticketFilterProvider.notifier)
                                    .state = s.isEmpty ? null : s),
                          ))
                      .toList(),
                ),
              ),
              Expanded(
                child: ticketsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                      child: Text('Error: $e',
                          style: const TextStyle(color: Colors.redAccent))),
                  data: (page) => page.tickets.isEmpty
                      ? const Center(
                          child: Text('No tickets found',
                              style: TextStyle(color: AppColors.gray)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          itemCount: page.tickets.length,
                          itemBuilder: (context, i) {
                            final t = page.tickets[i];
                            final isSelected = _selected?.id == t.id;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Material(
                                color: isSelected
                                    ? AppColors.ink
                                    : (isDark
                                        ? AppColors.selectedDark
                                        : AppColors.white),
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => setState(
                                      () => _selected = isSelected ? null : t),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        _statusChip(t.status),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                              Text(t.subject,
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: isSelected
                                                          ? AppColors.inkDark
                                                          : (isDark
                                                              ? AppColors
                                                                  .inkDark
                                                              : AppColors
                                                                  .ink))),
                                              Text(
                                                  '${t.requesterEmail}  |  ${t.category.replaceAll('_', ' ')}',
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors.gray)),
                                            ])),
                                        Text(_fmtDate(t.createdAt),
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.gray)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return SizeTransition(
              sizeFactor: animation,
              axis: Axis.horizontal,
              axisAlignment: 1.0,
              child: child,
            );
          },
          child: _selected == null
              ? const SizedBox.shrink(key: ValueKey('empty'))
              : SizedBox(
                  key: ValueKey(_selected!.id),
                  width: 360,
                  child: _TicketDetailPanel(
                      ticket: ticketsAsync.value?.tickets.where((t) => t.id == _selected!.id).firstOrNull ?? _selected!,
                      onClose: () => setState(() => _selected = null)),
                ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _TicketDetailPanel extends ConsumerStatefulWidget {
  const _TicketDetailPanel({required this.ticket, required this.onClose});
  final SupportTicket ticket;
  final VoidCallback onClose;
  @override
  ConsumerState<_TicketDetailPanel> createState() => _TicketDetailPanelState();
}

class _TicketDetailPanelState extends ConsumerState<_TicketDetailPanel> {
  late TextEditingController _notesCtrl;
  Future<void> _showEmailDialog(BuildContext context, String ticketId, AdminActions actions) async {
    final msgCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            
            return AlertDialog(
              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
              title: Text('Send Email to Requester', style: TextStyle(color: isDark ? AppColors.inkDark : AppColors.ink)),
              content: SizedBox(
                width: 400,
                child: TextField(
                  controller: msgCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'Message content', border: OutlineInputBorder()),
                ),
              ),
              actions: [
                TextButton(onPressed: isLoading ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton.icon(
                  onPressed: isLoading ? null : () async {
                    if (msgCtrl.text.trim().isEmpty) return;
                    setState(() => isLoading = true);
                    try {
                      await actions.sendTicketMessage(ticketId, msgCtrl.text.trim());
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email sent successfully.')));
                      }
                    } catch (e) {
                      if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    } finally {
                      if (ctx.mounted) setState(() => isLoading = false);
                    }
                  },
                  icon: isLoading 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_rounded, size: 16),
                  label: Text(isLoading ? 'Sending...' : 'Send Email'),
                  style: FilledButton.styleFrom(
                    disabledBackgroundColor: isDark ? AppColors.charcoal : AppColors.gray,
                    disabledForegroundColor: isDark ? AppColors.white : AppColors.ink,
                  ),
                ),
            ],
          );
        },
      );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.ticket.internalNotes ?? '');
  }

  @override
  void didUpdateWidget(covariant _TicketDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ticket.internalNotes != widget.ticket.internalNotes) {
      _notesCtrl.text = widget.ticket.internalNotes ?? '';
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actions = ref.read(adminActionsProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F0D) : AppColors.white,
        border: Border(
            left: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 12, 0),
            child: Row(
              children: [
                Text('Ticket Detail',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.inkDark : AppColors.ink)),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: widget.onClose),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _statusChip(widget.ticket.status),
                  const SizedBox(height: 16),
                  _DetailRow(label: 'Subject', value: widget.ticket.subject),
                  _DetailRow(
                      label: 'Requester', value: widget.ticket.requesterEmail),
                  _DetailRow(
                      label: 'Category',
                      value: widget.ticket.category.replaceAll('_', ' ')),
                  _DetailRow(
                      label: 'Created',
                      value: _fmtDate(widget.ticket.createdAt)),
                  _DetailRow(
                      label: 'Assignee',
                      value: widget.ticket.assigneeEmail ?? 'Unassigned'),
                  const SizedBox(height: 16),
                  const Text('Description',
                      style: TextStyle(fontSize: 12, color: AppColors.gray)),
                  const SizedBox(height: 6),
                  Text(widget.ticket.description,
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: isDark ? AppColors.inkDark : AppColors.ink)),
                  const SizedBox(height: 20),
                  const Text('Internal Notes',
                      style: TextStyle(fontSize: 12, color: AppColors.gray)),
                  const SizedBox(height: 6),
                  TextField(
                      controller: _notesCtrl,
                      maxLines: 5,
                      enabled: widget.ticket.status != 'RESOLVED',
                      decoration: const InputDecoration(
                          hintText: 'Add internal notes...')),
                  const SizedBox(height: 16),
                  const Text('Actions',
                      style: TextStyle(fontSize: 12, color: AppColors.gray)),
                  const SizedBox(height: 8),
                  Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: widget.ticket.status == 'RESOLVED' ? null : () => _showEmailDialog(context, widget.ticket.id, actions),
                          icon: const Icon(Icons.mail_outline_rounded, size: 16),
                          label: const Text('Send Email to Requester'),
                        ),
                        OutlinedButton.icon(
                          onPressed: widget.ticket.status == 'RESOLVED' ? null : () async {
                            try {
                              await actions.updateTicket(widget.ticket.id, notes: _notesCtrl.text.trim());
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notes saved.')));
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          },
                          icon: const Icon(Icons.save_rounded, size: 16),
                          label: const Text('Save Notes'),
                        ),
                      ]),
                  const SizedBox(height: 20),
                  const Text('Update Status',
                      style: TextStyle(fontSize: 12, color: AppColors.gray)),
                  const SizedBox(height: 8),
                  Wrap(
                      spacing: 8,
                      children: ['OPEN', 'IN_PROGRESS', 'RESOLVED']
                          .map((s) {
                            final isActive = widget.ticket.status == s;
                            final isResolved = widget.ticket.status == 'RESOLVED';
                            
                            final onPressed = (isActive || isResolved) ? null : () async {
                              try {
                                await actions.updateTicket(
                                    widget.ticket.id,
                                    status: s,
                                    notes: _notesCtrl.text.trim());
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $s')));
                              } catch (e) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            };

                            final child = Text(s.replaceAll('_', ' '));

                            if (isActive) {
                              return FilledButton.tonal(
                                onPressed: onPressed,
                                style: FilledButton.styleFrom(
                                  backgroundColor: isDark ? AppColors.charcoal : AppColors.fog,
                                  foregroundColor: isDark ? AppColors.inkDark : AppColors.ink,
                                ),
                                child: child,
                              );
                            }

                            return OutlinedButton(
                              onPressed: onPressed,
                              child: child,
                            );
                          })
                          .toList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Tab 6: System Config Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _SystemTab extends ConsumerWidget {
  const _SystemTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(adminSystemConfigProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TabHeader(
            title: 'System Configuration',
            subtitle:
                'All changes require a reason and are automatically audited'),
        Expanded(
          child: configAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: Colors.redAccent))),
            data: (configs) => configs.isEmpty
                ? const Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        Icon(Icons.settings_rounded,
                            size: 40, color: AppColors.gray),
                        SizedBox(height: 12),
                        Text('No configuration entries yet.',
                            style: TextStyle(color: AppColors.gray)),
                        SizedBox(height: 4),
                        Text(
                            'Pause/Resume the reminder engine to create the first entry.',
                            style:
                                TextStyle(fontSize: 12, color: AppColors.gray)),
                      ]))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                    itemCount: configs.length,
                    itemBuilder: (context, i) => _ConfigTile(entry: configs[i]),
                  ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _ConfigTile extends ConsumerWidget {
  const _ConfigTile({required this.entry});
  final SystemConfigEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actions = ref.read(adminActionsProvider);

    void edit() async {
      final valCtrl = TextEditingController(text: entry.value);
      final reasonCtrl = TextEditingController();
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Edit: ${entry.key}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: valCtrl,
                decoration: const InputDecoration(labelText: 'New value')),
            const SizedBox(height: 12),
            TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                    labelText: 'Reason for change (required)')),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (reasonCtrl.text.trim().length >= 5) {
                  await actions.updateConfig(
                      entry.key, valCtrl.text.trim(), reasonCtrl.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _SectionCard(
        child: Row(
          children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(entry.key,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.inkDark : AppColors.ink)),
                  Text(entry.value,
                      style:
                          const TextStyle(fontSize: 13, color: AppColors.gray)),
                  const SizedBox(height: 4),
                  Text(
                      'Updated ${_fmtDate(entry.updatedAt)}  |  ${entry.reason}',
                      style:
                          const TextStyle(fontSize: 11, color: AppColors.gray)),
                ])),
            IconButton(
                icon: const Icon(Icons.edit_rounded,
                    size: 16, color: AppColors.gray),
                onPressed: edit),
          ],
        ),
      ),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Tab 7: My Account Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _MyAccountTab extends ConsumerStatefulWidget {
  const _MyAccountTab({super.key});
  @override
  ConsumerState<_MyAccountTab> createState() => _MyAccountTabState();
}

class _MyAccountTabState extends ConsumerState<_MyAccountTab> {
  final _nameCtrl = TextEditingController();
  final _curPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).value?.user;
    if (user != null) {
      _nameCtrl.text = user.displayName ?? '';
    }
  }

  Future<void> _updateProfile() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(name);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    final cur = _curPassCtrl.text;
    final newP = _newPassCtrl.text;
    if (cur.isEmpty || newP.length < 12) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter current password and new password (min 12 chars).')));
       return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider.notifier).updatePassword(cur, newP);
      if (mounted) {
        _curPassCtrl.clear();
        _newPassCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value?.user;
    if (user == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TabHeader(title: 'My Account', subtitle: 'Manage your admin profile and security'),
          const SizedBox(height: 32),
          _SectionCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        enabled: false,
                        initialValue: user.email,
                        decoration: const InputDecoration(labelText: 'Email address', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Display name', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  child: const Text('Save Profile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Change Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _curPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Current password', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password', helperText: 'At least 12 characters.', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isLoading ? null : _updatePassword,
                  child: const Text('Update Password'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



