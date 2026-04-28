import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/app.dart';

void main() {
  testWidgets('DriveOps app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DriveOpsApp(),
      ),
    );

    expect(find.text('Dashboard'), findsOneWidget);
  });
}
