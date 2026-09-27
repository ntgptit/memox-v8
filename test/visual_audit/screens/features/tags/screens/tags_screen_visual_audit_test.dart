import 'package:flutter/widgets.dart';
import 'package:memox/features/tags/presentation/screens/tags_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/tag_screen_fixtures.dart';
import '../../../../screen_audit.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    libraryTest('screen 05, ${locale.languageCode}', (tester, env) async {
      // Kit 05's catalog, with its name longer than a row.
      await seedTags(env);
      final store = TagRepositoryFake(env);
      await auditProductionScreen(
        tester,
        screen: TagsScreen,
        pump: (brightness, scale) => pumpLibraryScreen(
          tester,
          env,
          TagsScreen(onFindCards: (_) {}),
          brightness: brightness,
          textScale: scale,
          locale: locale,
          overrides: [store.asOverride],
        ),
      );
    });
  }
}
