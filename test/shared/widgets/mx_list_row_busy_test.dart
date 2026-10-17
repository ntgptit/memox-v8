import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import '../../support/widget_harness.dart';

void main() {
  testWidgets('a busy row says it is busy to TalkBack with the caller\'s '
      'label (audit 2026-10-17)', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const MxListRow(
        title: 'verb',
        isBusy: true,
        busyLabel: 'Saving this tag',
      ),
    );
    expect(find.bySemanticsLabel(RegExp('Saving this tag')), findsOneWidget);
    handle.dispose();
  });
}
