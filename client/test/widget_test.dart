import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:license_document_expiry_tracker/features/auth/auth_controller.dart';
import 'package:license_document_expiry_tracker/features/auth/auth_models.dart';
import 'package:license_document_expiry_tracker/main.dart';

void main() {
  testWidgets('shows the product name', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(TestAuthController.new),
        ],
        child: const LicenseTrackerApp(),
      ),
    );
    await tester.pump();
    expect(find.text('DueNest'), findsOneWidget);
  });
}

class TestAuthController extends AuthController {
  @override
  FutureOr<AuthSession?> build() => null;
}
