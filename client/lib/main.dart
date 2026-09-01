import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/auth_screen.dart';
import 'features/home/home_screen.dart';
import 'shared/brand_mark.dart';
import 'shared/glass.dart';
import 'shared/theme_mode.dart';

void main() {
  runApp(const ProviderScope(child: LicenseTrackerApp()));
}

class LicenseTrackerApp extends ConsumerWidget {
  const LicenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const navy = Color(0xFF111827);
    const blue = Color(0xFF2864DC);
    return MaterialApp(
      title: 'DueNest',
      debugShowCheckedModeBanner: false,
      themeMode: ref.watch(themeModeProvider),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: blue,
          brightness: Brightness.light,
          surface: const Color(0xFFF7F8FC),
        ),
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: navy,
              displayColor: navy,
              fontFamily: 'Arial',
            ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(
              color: Color(0xFF475569), fontWeight: FontWeight.w500),
          floatingLabelStyle: const TextStyle(
              color: Color(0xFF1D4ED8), fontWeight: FontWeight.w600),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: blue, width: 2),
          ),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF94B5FF),
          brightness: Brightness.dark,
          surface: const Color(0xFF0E1424),
        ),
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: const Color(0xFFF3F6FF),
              displayColor: const Color(0xFFF3F6FF),
              fontFamily: 'Arial',
            ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0x541A2741),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0x70D7E3FF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0x70D7E3FF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF9AB7FF), width: 2),
          ),
        ),
        useMaterial3: true,
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
              SizedBox(height: 12),
              Text('DueNest',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              SizedBox(height: 20),
              SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5)),
            ],
          ),
        ),
      ),
    );
  }
}
