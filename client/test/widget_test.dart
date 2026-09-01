import 'package:flutter_test/flutter_test.dart';
import 'package:license_document_expiry_tracker/main.dart';

void main() {
  testWidgets('shows the product name', (tester) async {
    await tester.pumpWidget(const LicenseTrackerApp());
    expect(find.text('DeuNest'), findsOneWidget);
  });
}
