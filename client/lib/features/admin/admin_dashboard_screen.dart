import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_animate/flutter_animate.dart';

import '../auth/auth_controller.dart';
import 'admin_providers.dart';

// Helper for date formatting since intl is missing
String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
String _formatDateShort(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text('ADMINISTRATION', style: TextStyle(color: Colors.white, letterSpacing: 1.5, fontSize: 16))
            .animate().fade(duration: 400.ms).slideX(begin: -0.1),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reload Data',
            onPressed: () {
              ref.invalidate(adminUsersProvider);
              ref.invalidate(adminAuditLogsProvider);
              ref.invalidate(adminMetricsProvider);
            },
          ).animate().fade(delay: 200.ms),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () async {
              final authNotifier = ref.read(authControllerProvider.notifier);
              await authNotifier.signOut();
              if (context.mounted) {
                context.go('/admin/login');
              }
            },
            icon: const Icon(Icons.logout, color: Colors.white70, size: 18),
            label: const Text('SIGN OUT', style: TextStyle(color: Colors.white70)),
          ).animate().fade(delay: 300.ms),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: const Color(0xFF0A0A0A),
            child: ListView(
              children: [
                _buildNavItem(0, Icons.people_outline, 'User Accounts'),
                _buildNavItem(1, Icons.security_outlined, 'Audit Logs'),
                _buildNavItem(2, Icons.analytics_outlined, 'Analytics & Metrics'),
              ]
                  .animate(interval: 100.ms)
                  .fade(duration: 300.ms)
                  .slideX(begin: -0.2),
            ),
          ),
          // Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.02, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _selectedIndex == 0 
                  ? const _UsersView(key: ValueKey('users')) 
                  : _selectedIndex == 1 
                      ? const _AuditLogsView(key: ValueKey('logs'))
                      : const _AnalyticsView(key: ValueKey('analytics')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.white54),
      title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white54)),
      selected: isSelected,
      selectedTileColor: const Color(0xFF222222),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }
}

class _UsersView extends ConsumerWidget {
  const _UsersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search by email or name...',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: Color(0xFF1A1A1A),
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  onChanged: (val) {
                    ref.read(adminSearchQueryProvider.notifier).state = val;
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
            data: (users) {
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: users.length,
                separatorBuilder: (context, index) => const Divider(color: Color(0xFF222222)),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(user.email, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      'Joined ${_formatDateShort(user.createdAt)} • ${user.documentCount} docs • ${user.activeSessionCount} sessions',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: user.role == 'ADMIN'
                        ? const Chip(label: Text('ADMIN', style: TextStyle(fontSize: 10)), backgroundColor: Color(0xFF333333))
                        : TextButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFF222222),
                                  title: const Text('Revoke Sessions?', style: TextStyle(color: Colors.white)),
                                  content: Text('Force sign out all active sessions for ${user.email}?', style: const TextStyle(color: Colors.white70)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Revoke', style: TextStyle(color: Colors.redAccent)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(adminRevokeSessionsProvider)(user.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Sessions revoked.')),
                                  );
                                }
                              }
                            },
                            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                            child: const Text('REVOKE SESSIONS'),
                          ),
                  ).animate().fade(duration: 300.ms, delay: (index * 50).ms).slideY(begin: 0.1);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AuditLogsView extends ConsumerWidget {
  const _AuditLogsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(adminAuditLogsProvider);

    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      data: (logs) {
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: logs.length,
          separatorBuilder: (context, index) => const Divider(color: Color(0xFF222222)),
          itemBuilder: (context, index) {
            final log = logs[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(log.action, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${_formatDate(log.timestamp)}\nActor: ${log.actorId} • Target: ${log.targetId ?? 'N/A'}\nIP: ${log.ipAddress ?? 'N/A'} • Reason: ${log.reason ?? 'N/A'}',
                style: const TextStyle(color: Colors.white54, height: 1.5),
              ),
              isThreeLine: true,
            ).animate().fade(duration: 300.ms, delay: (index * 30).ms).slideY(begin: 0.1);
          },
        );
      },
    );
  }
}

class _AnalyticsView extends ConsumerWidget {
  const _AnalyticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(adminMetricsProvider);

    return metricsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      data: (metrics) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Platform Overview'),
              Row(
                children: [
                  _buildStatCard('Total Users', metrics.usersTotal.toString(), Icons.people),
                  const SizedBox(width: 16),
                  _buildStatCard('Total Documents', metrics.docsTotal.toString(), Icons.folder_copy),
                ],
              ),
              const SizedBox(height: 32),
              
              _buildSectionTitle('Demographics'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildBreakdownCard('Age Distribution', metrics.ageBreakdown, metrics.usersTotal)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildBreakdownCard('Gender Ratio', metrics.genderBreakdown, metrics.usersTotal)),
                ],
              ),
              const SizedBox(height: 32),
              
              _buildSectionTitle('Document Categories'),
              _buildBreakdownCard('Documents by Type', metrics.documentBreakdown, metrics.docsTotal),
            ].animate(interval: 100.ms).fade(duration: 400.ms).slideY(begin: 0.1),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white38, size: 28),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownCard(String title, Map<String, int> breakdown, int total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          if (breakdown.isEmpty || total == 0)
            const Text('No data available', style: TextStyle(color: Colors.white38))
          else
            ...breakdown.entries.map((e) {
              final percentage = total > 0 ? (e.value / total) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key.replaceAll('_', ' '), style: const TextStyle(color: Colors.white70)),
                        Text('${(percentage * 100).toStringAsFixed(1)}% (${e.value})', style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: const Color(0xFF222222),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF444444)),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
