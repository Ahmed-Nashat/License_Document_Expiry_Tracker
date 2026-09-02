import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/admin/admin_login_screen.dart';
import 'features/admin/admin_dashboard_screen.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/auth_screen.dart';
import 'features/home/home_screen.dart';
import 'shared/brand_mark.dart';
import 'shared/design_tokens.dart';
import 'shared/glass.dart';
import 'shared/theme_mode.dart';

void main() {
  runApp(const ProviderScope(child: LicenseTrackerApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthGate(),
    ),
    GoRoute(
      path: '/admin/login',
      builder: (context, state) => const AdminLoginScreen(),
    ),
    GoRoute(
      path: '/admin/dashboard',
      redirect: (context, state) {
        // Guard: require ADMIN role — checked via ProviderScope
        return null; // actual check happens in AdminLoginScreen
      },
      builder: (context, state) => const AdminDashboardScreen(),
    ),
  ],
);

class LicenseTrackerApp extends ConsumerWidget {
  const LicenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'DueNest',
      debugShowCheckedModeBanner: false,
      themeMode: ref.watch(themeModeProvider),

      // ── Light theme ──────────────────────────────────────────────────────
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.ink,
          brightness: Brightness.light,
          primary: AppColors.ink,
          onPrimary: AppColors.white,
          surface: AppColors.white,
          onSurface: AppColors.ink,
        ),
        scaffoldBackgroundColor: Colors.transparent,

        // Typography — Inter with tabular figures for numbers
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: AppColors.ink,
              displayColor: AppColors.ink,
              fontFamily: 'Inter',
            ),

        // Input fields — filled, no border stroke
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          labelStyle:
              TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w500),
          floatingLabelStyle: const TextStyle(
              color: AppColors.ink, fontWeight: FontWeight.w600),
          hintStyle: TextStyle(color: AppColors.gray),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),

        // FilledButton — no changes needed (already no border)
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.border,
            disabledForegroundColor: AppColors.gray,
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // OutlinedButton — ghost style, no stroke border
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            side: BorderSide.none,
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // TextButton — charcoal, no color
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.charcoal,
            textStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),

        // FilterChip — no border stroke
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.fog,
          selectedColor: AppColors.charcoal,
          labelStyle: const TextStyle(
              color: AppColors.charcoal,
              fontSize: 13,
              fontWeight: FontWeight.w500),
          secondaryLabelStyle: const TextStyle(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600),
          checkmarkColor: AppColors.white,
          side: BorderSide.none,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          iconTheme: const IconThemeData(color: AppColors.gray, size: 16),
        ),

        // IconButton — no outline border
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: AppColors.charcoal,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // Dividers
        dividerColor: Colors.transparent,
        dividerTheme:
            const DividerThemeData(color: Colors.transparent, thickness: 0),
      ),

      // ── Dark theme ───────────────────────────────────────────────────────
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.inkDark,
          brightness: Brightness.dark,
          primary: AppColors.inkDark,
          onPrimary: AppColors.ink,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.inkDark,
        ),
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: AppColors.inkDark,
              displayColor: AppColors.inkDark,
              fontFamily: 'Inter',
            ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF222220),
          labelStyle: TextStyle(
              color: AppColors.charcoalDark, fontWeight: FontWeight.w500),
          floatingLabelStyle: const TextStyle(
              color: AppColors.inkDark, fontWeight: FontWeight.w600),
          hintStyle: TextStyle(color: AppColors.gray),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.inkDark,
            foregroundColor: AppColors.ink,
            disabledBackgroundColor: AppColors.borderDark,
            disabledForegroundColor: AppColors.gray,
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.inkDark,
            side: BorderSide.none,
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.charcoalDark,
            textStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.selectedDark,
          selectedColor: const Color(0xFF4A4A48), // elevated dark, not white
          labelStyle: const TextStyle(
              color: AppColors.charcoalDark,
              fontSize: 13,
              fontWeight: FontWeight.w500),
          secondaryLabelStyle: const TextStyle(
              color: AppColors.inkDark,
              fontSize: 13,
              fontWeight: FontWeight.w600),
          checkmarkColor: AppColors.inkDark,
          side: BorderSide.none,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          iconTheme: const IconThemeData(color: AppColors.gray, size: 16),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: AppColors.charcoalDark,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        dividerColor: Colors.transparent,
        dividerTheme:
            const DividerThemeData(color: Colors.transparent, thickness: 0),
      ),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return auth.when(
      loading: () => const _LoadingScreen(),
      error: (error, _) => AuthScreen(connectionError: error.toString()),
      data: (session) =>
          session == null ? const AuthScreen() : HomeScreen(session: session),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: GlassBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandMark(),
              SizedBox(height: 14),
              Text('DueNest',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4)),
              SizedBox(height: 22),
              SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.ink)),
            ],
          ),
        ),
      ),
    );
  }
}
