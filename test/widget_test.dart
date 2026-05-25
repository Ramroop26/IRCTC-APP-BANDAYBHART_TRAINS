import 'package:flutter_test/flutter_test.dart';
import 'package:irctc_app/main.dart';

void main() {
  testWidgets('IRCTC App launch and login screen render test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const IRCTCApp());

    // Verify that our login page loaded.
    expect(find.text('IRCTC NEXT-GEN'), findsOneWidget);
    expect(find.text('ENTER SECURITY PIN'), findsOneWidget);
  });
}
