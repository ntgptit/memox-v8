import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/presentation/screens/monitoring_detail_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/monitoring_fakes.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 28, detail', (tester, env) async {
    final repository = FakeMonitoringRepository()..servers['a'] = record('a');
    await auditProductionScreen(
      tester,
      screen: MonitoringDetailScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        const MonitoringDetailScreen(logId: 'a', isLocal: false),
        brightness: brightness,
        textScale: scale,
        overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
      ),
    );
  });
}
