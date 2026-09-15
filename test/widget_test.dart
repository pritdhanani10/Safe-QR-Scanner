import 'package:flutter_test/flutter_test.dart';
import 'package:qr/main.dart';

void main() {
  testWidgets('SafeQRApp smoke test - verifies navigation items and philosophy tagline', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SafeQRApp());
    await tester.pump(const Duration(milliseconds: 200));

    // Verify presence of brand title or tagline
    expect(find.text('Safe QR'), findsOneWidget);
    expect(find.text('Scan first. Trust later.'), findsOneWidget);

    // Verify navigation tabs
    expect(find.text('Scanner'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);
  });
}
