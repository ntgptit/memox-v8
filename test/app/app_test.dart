import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';

void main() {
  testWidgets('MemoxApp renders a placeholder route with no crash', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MemoxApp()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('MemoX foundation'), findsOneWidget);
  });
}
