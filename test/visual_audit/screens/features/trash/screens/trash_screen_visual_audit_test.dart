import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/trash_screen_fixtures.dart';
import '../../../../screen_audit.dart';

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('screen 06, the list', (tester, env) async {
    await seedTrash(env);
    await auditProductionScreen(
      tester,
      screen: TrashScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        const TrashScreen(),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });

  libraryTest('screen 06, selecting', (tester, env) async {
    await seedTrash(env);
    await auditProductionScreen(
      tester,
      screen: TrashScreen,
      pump: (brightness, scale) async {
        await pumpLibraryScreen(
          tester,
          env,
          const TrashScreen(),
          brightness: brightness,
          textScale: scale,
        );
        // The scope outlives a re-pump: select only the first time.
        if (find.text(_en.trashSelect).evaluate().isEmpty) return;
        await tester.tap(find.text(_en.trashSelect));
        await tester.pumpAndSettle();
        await tester.tap(find.text('meokda · eat'));
        await tester.pumpAndSettle();
      },
    );
  });
}
