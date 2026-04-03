import 'package:askula/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dashboard renders and scan flow opens from quick action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AskulaApp());

    expect(find.text('Welcome back, Mr. Daniel'), findsOneWidget);
    expect(find.text('Scan Papers'), findsOneWidget);

    await tester.tap(find.text('Scan Papers').first);
    await tester.pumpAndSettle();

    expect(find.text('Select Context'), findsOneWidget);
    expect(find.text('Start Scanning'), findsOneWidget);
  });
}
