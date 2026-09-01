import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/brand_mark.dart';
import '../../shared/glass.dart';
import '../../shared/theme_mode.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_models.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = session.user.displayName?.trim().isNotEmpty == true
        ? session.user.displayName!.trim()
        : session.user.email.split('@').first;
    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const BrandMark(size: 38),
                        const SizedBox(width: 10),
                        const Text('DueNest',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        const ThemeToggleButton(),
                        TextButton.icon(
                            onPressed: () => ref
                                .read(authControllerProvider.notifier)
                                .signOut(),
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Sign out')),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: AdvancedGlassPanel(
                        padding: const EdgeInsets.all(34),
                        tint: const Color(0xFF17213B),
                        radius: 30,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                color: Color(0xFF9AB7FF), size: 34),
                            const SizedBox(height: 24),
                            Text('You’re signed in, $name.',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    letterSpacing: -1.2,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 12),
                            const Text(
                                'Your protected reminder space is ready. Next, we’ll add the documents that keep your deadlines in view.',
                                style: TextStyle(
                                    color: Color(0xFFD1D5DB),
                                    fontSize: 16,
                                    height: 1.5)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _NextStep(),
                    const Spacer(),
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

class _NextStep extends StatelessWidget {
  const _NextStep();

  @override
  Widget build(BuildContext context) => AdvancedGlassPanel(
        padding: const EdgeInsets.all(22),
        radius: 22,
        child: const Row(
          children: [
            Icon(Icons.add_task_rounded, color: Color(0xFF2864DC)),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your tracker comes next',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text(
                      'Add a document, licence, or subscription and choose when you want to be reminded.',
                      style: TextStyle(color: Color(0xFF6B7280), height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );
}
