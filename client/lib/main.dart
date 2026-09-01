import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: LicenseTrackerApp()));
}

class LicenseTrackerApp extends StatelessWidget {
  const LicenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFFF7F8FA);
    return MaterialApp(
      title: 'DeuNest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2864DC)),
        scaffoldBackgroundColor: surface,
        useMaterial3: true,
      ),
      home: const FoundationScreen(),
    );
  }
}

class FoundationScreen extends StatelessWidget {
  const FoundationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.calendar_month_rounded, size: 48),
                SizedBox(height: 20),
                Text(
                  'DeuNest',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 12),
                Text(
                  'Never miss what’s due. Your secure reminder space is being prepared, with sign-in and document management next in the implementation sequence.',
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
