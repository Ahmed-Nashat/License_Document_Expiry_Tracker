import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/auth_screen.dart';
import 'features/home/home_screen.dart';
import 'shared/brand_mark.dart';
import 'shared/glass.dart';
import 'shared/theme_mode.dart';

// ─── Design tokens ──────────────────────────────────────────────────────────
const _ink = Color(0xFF111111);       // primary text & solid buttons
const _charcoal = Color(0xFF444441);  // secondary text
const _gray = Color(0xFFB4B2A9);      // muted text / icons
const _fog = Color(0xFFF1EFE8);       // subtle backgrounds & borders
const _white = Color(0xFFFFFFFF);     // card surfaces

// Dark-mode equivalents
const _inkDark = Color(0xFFFAFAFA);
const _charcoalDark = Color(0xFFB4B2A9);
const _surfaceDark = Color(0xFF1A1A18);

void main() {
  runApp(const ProviderScope(child: LicenseTrackerApp()));
}

class LicenseTrackerApp extends ConsumerWidget {
  const LicenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'DueNest',
      debugShowCheckedModeBanner: false,
      themeMode: ref.watch(themeModeProvider),

      // ── Light theme ──────────────────────────────────────────────────────
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _ink,
          brightness: Brightness.light,
          primary: _ink,
          onPrimary: _white,
          surface: _white,
          onSurface: _ink,
        ),
        scaffoldBackgroundColor: Colors.transparent,

        // Typography — Inter with tabular figures for numbers
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: _ink,
              displayColor: _ink,
              fontFamily: 'Inter',
            ),

        // Input fields — filled, no border stroke
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _white,
          labelStyle: TextStyle(color: _charcoal, fontWeight: FontWeight.w500),
          floatingLabelStyle:
              const TextStyle(color: _ink, fontWeight: FontWeight.w600),
          hintStyle: TextStyle(color: _gray),
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
            backgroundColor: _ink,
            foregroundColor: _white,
            disabledBackgroundColor: const Color(0xFFD3D1C7),
            disabledForegroundColor: _gray,
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
            foregroundColor: _ink,
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
            foregroundColor: _charcoal,
            textStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),

        // FilterChip — no border stroke
        chipTheme: ChipThemeData(
          backgroundColor: _fog,
          selectedColor: _ink,
          labelStyle: const TextStyle(
              color: _charcoal, fontSize: 13, fontWeight: FontWeight.w500),
          secondaryLabelStyle: const TextStyle(
              color: _white, fontSize: 13, fontWeight: FontWeight.w600),
          side: BorderSide.none,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          iconTheme: const IconThemeData(color: _gray, size: 16),
        ),

        // IconButton — no outline border
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: _charcoal,
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
          seedColor: _inkDark,
          brightness: Brightness.dark,
          primary: _inkDark,
          onPrimary: _ink,
          surface: _surfaceDark,
          onSurface: _inkDark,
        ),
        scaffoldBackgroundColor: Colors.transparent,

        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: _inkDark,
              displayColor: _inkDark,
              fontFamily: 'Inter',
            ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF222220),
          labelStyle:
              TextStyle(color: _charcoalDark, fontWeight: FontWeight.w500),
          floatingLabelStyle:
              const TextStyle(color: _inkDark, fontWeight: FontWeight.w600),
          hintStyle: TextStyle(color: _gray),
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
            backgroundColor: _inkDark,
            foregroundColor: _ink,
            disabledBackgroundColor: const Color(0xFF3A3A38),
            disabledForegroundColor: _gray,
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _inkDark,
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
            foregroundColor: _charcoalDark,
            textStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF2A2A28),
          selectedColor: _inkDark,
          labelStyle: const TextStyle(
              color: _charcoalDark,
              fontSize: 13,
              fontWeight: FontWeight.w500),
          secondaryLabelStyle: const TextStyle(
              color: _surfaceDark, fontSize: 13, fontWeight: FontWeight.w600),
          side: BorderSide.none,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          iconTheme: const IconThemeData(color: _gray, size: 16),
        ),

        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: _charcoalDark,
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

      home: const AuthGate(),
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
                      strokeWidth: 2,
                      color: Color(0xFF111111))),
            ],
          ),
        ),
      ),
    );
  }
}
