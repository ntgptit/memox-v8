import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/presentation/screens/monitoring_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/monitoring_fakes.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 28', (tester, env) async {
    final repository = FakeMonitoringRepository()
      ..autoPage = LogPage(
        items: [
          summary('a', event: 'sync.push_failed'),
          summary('b', level: LogLevel.warning, event: 'db.slow_query'),
          summary('c', status: LogStatus.fixed),
        ],
      );
    await auditProductionScreen(
      tester,
      screen: MonitoringScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        MonitoringScreen(onOpenServerLog: (_) {}, onOpenPendingLog: (_) {}),
        brightness: brightness,
        textScale: scale,
        overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
      ),
    );
  });
}
