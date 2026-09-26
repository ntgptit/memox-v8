@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/trash/presentation/providers/trash_entries_provider.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/trash_screen_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('trash, $theme', (tester, env) async {
      await seedTrash(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, const TrashScreen(), brightness);
        await expectBoundaryGolden(tester, 'goldens/trash_all_$theme.png');
      });
    });

    libraryTest('trash actions, $theme', (tester, env) async {
      await seedTrash(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, const TrashScreen(), brightness);
        await tester.tap(find.byTooltip(_en.trashEntryActions('meokda · eat')));
        await _settle(tester);
        await expectBoundaryGolden(tester, 'goldens/trash_actions_$theme.png');
      });
    });

    libraryTest('trash empty, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, const TrashScreen(), brightness);
        await expectBoundaryGolden(tester, 'goldens/trash_empty_$theme.png');
      });
    });

    libraryTest('trash error, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          const TrashScreen(),
          brightness,
          overrides: [
            trashEntriesProvider.overrideWith(
              (ref) => Stream.error(StateError('read failed')),
            ),
          ],
        );
        await expectBoundaryGolden(tester, 'goldens/trash_error_$theme.png');
      });
    });
  }
}
