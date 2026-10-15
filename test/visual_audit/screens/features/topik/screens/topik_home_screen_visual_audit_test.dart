import 'package:flutter/widgets.dart';
import 'package:memox/features/topik/presentation/screens/topik_home_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/topik_screen_fixtures.dart';
import '../../../../screen_audit.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    libraryTest('screen 34, ${locale.languageCode}', (tester, env) async {
      await auditProductionScreen(
        tester,
        screen: TopikHomeScreen,
        pump: (brightness, scale) => pumpLibraryScreen(
          tester,
          env,
          TopikHomeScreen(onOpenLevel: (_) {}),
          brightness: brightness,
          textScale: scale,
          locale: locale,
          overrides: topikContentOverrides(topikScreenTests()),
        ),
      );
    });
  }
}
