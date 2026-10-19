import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/presentation/screens/monitoring_detail_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';

import '../../../support/library_harness.dart';
import '../../../support/monitoring_fakes.dart';

// The States rows of screen 28 (Monitoring) whose detail file cites no
// executed test and that no test of monitoring_screen_test.dart or
// monitoring_detail_screen_test.dart covers: the detail's "error" (a failure
// that is neither offline nor FORBIDDEN).
//
// The other rows of the list are covered by
// - list, error: monitoring_screen_test.dart::another failure is a
//   local-first error with a Retry;
// - list, not an admin: monitoring_screen_test.dart::FORBIDDEN says only an
//   admin can see this;
// - detail, loading / offline / gone: monitoring_detail_screen_test.dart.

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('detail, error: a failure that is neither offline nor FORBIDDEN '
      'is the local-first error with Retry and no actions; Retry reads again', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()
      ..servers['a'] = record('a')
      ..readError = const ServerFailure(cause: 'HTTP 500 at /rest/v1/logs');
    await pumpLibraryScreen(
      tester,
      env,
      const MonitoringDetailScreen(logId: 'a', isLocal: false),
      overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.text(_en.monitoringDetailErrorTitle), findsOneWidget);
    expect(find.text(_en.libraryLoadErrorBody), findsOneWidget);
    expect(find.textContaining('HTTP 500'), findsNothing);
    expect(find.text(_en.commonRetry), findsOneWidget);
    expect(find.byType(MxFooterBar), findsNothing);

    repository.readError = null;
    await tester.tap(find.text(_en.commonRetry));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MxErrorState), findsNothing);
  });
}
