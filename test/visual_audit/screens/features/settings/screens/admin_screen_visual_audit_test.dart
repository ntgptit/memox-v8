import 'package:memox/features/settings/presentation/screens/admin_screen.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 23b', (tester, env) async {
    await auditProductionScreen(
      tester,
      screen: AdminScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        const AdminScreen(
          logsRows: [MxSettingsRow(label: 'Monitoring', subtitle: 'Logs')],
          peopleRows: [
            MxSettingsRow(label: 'Users', subtitle: 'Who can manage'),
          ],
        ),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });
}
