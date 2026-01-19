import 'package:flutter_test/flutter_test.dart';
import 'package:khmerscan/main.dart';

void main() {
  testWidgets('App loads home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KhmerScanApp());

    // Verify that the app title is displayed
    expect(find.text('KhmerScan'), findsOneWidget);
  });
}
