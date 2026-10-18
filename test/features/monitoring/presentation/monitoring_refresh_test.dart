import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

import '../../../support/library_harness.dart';
import '../../../support/monitoring_fakes.dart';
import '../../../support/monitoring_screen_harness.dart';

MxIconButton _refreshButton(WidgetTester tester) =>
    tester.widget<MxIconButton>(monitoringRefreshAction);

void main() {
  libraryTest('Refresh is off while its read runs, so the tap is seen and '
      'heard (closing audit 2026-10-17)', (tester, env) async {
    final repository = FakeMonitoringRepository();
    await pumpMonitoring(tester, env, repository);
    repository.lastQuery.answer(pageOf(2));
    await settleMonitoring(tester);
    expect(_refreshButton(tester).onPressed, isNotNull);

    await tester.tap(monitoringRefreshAction);
    await tester.pump();
    expect(repository.queries, hasLength(2));
    expect(_refreshButton(tester).onPressed, isNull);

    repository.lastQuery.answer(pageOf(2));
    await tester.pump(const Duration(seconds: 1));
    expect(_refreshButton(tester).onPressed, isNotNull);
  });

  libraryTest('a failed refresh banner keeps one gap below it, not its own '
      'margin on top (closing audit 2026-10-17)', (tester, env) async {
    final repository = FakeMonitoringRepository();
    await pumpMonitoring(tester, env, repository);
    repository.lastQuery.answer(pageOf(2));
    await settleMonitoring(tester);

    await tester.tap(monitoringRefreshAction);
    await tester.pump();
    repository.lastQuery.fail(const OfflineFailure(cause: 'x'));
    await tester.pump(const Duration(seconds: 1));

    final banner = tester.widget<MxInlineBanner>(find.byType(MxInlineBanner));
    expect(banner.hasBottomMargin, isFalse);
    expect(_refreshButton(tester).onPressed, isNotNull);
  });
}
