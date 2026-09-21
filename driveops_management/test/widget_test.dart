import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/app.dart';

void main() {
  testWidgets('DriveOps app smoke test - shows login when not authenticated', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DriveOpsApp(),
      ),
    );

    await tester.pump();

    expect(find.text('DriveOps'), findsOneWidget);
    expect(find.text('Management Console'), findsOneWidget);
  });
}
