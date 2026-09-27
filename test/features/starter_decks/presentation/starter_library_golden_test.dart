@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/starter_decks/presentation/screens/starter_library_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/starter_screen_fixtures.dart';

// Screen 03 (FE-B4) against the kit's ten frames: the everyday template is
// in the library, as the kit draws it.

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    /// The library with the everyday copy, unless [isSeeded] is false.
    Future<StarterLibraryFake> library(
      LibraryEnv env, {
      bool isSeeded = true,
      StarterLibraryFake? fake,
    }) async {
      final library = fake ?? StarterLibraryFake(env);
      if (isSeeded) {
        await library.addStarterDeck(
          templateId: everydayTemplate.templateId,
          schedulerType: everydayTemplate.suggestedScheduler,
        );
      }
      return library;
    }

    Future<void> shoot(
      WidgetTester tester,
      LibraryEnv env,
      StarterLibraryFake library,
      String name, {
      Future<void> Function()? before,
    }) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          StarterLibraryScreen(onOpenDeck: (_) {}, onCreateDeck: () {}),
          brightness,
          overrides: [library.asOverride],
        );
        await before?.call();
        await expectBoundaryGolden(
          tester,
          'goldens/starter_${name}_$theme.png',
        );
      });
    }

    Future<void> openHangul(WidgetTester tester) async {
      await tester.tap(
        find.widgetWithText(MxButton, _en.starterAddToLibrary).last,
      );
      await tester.pumpAndSettle();
    }

    Future<void> add(WidgetTester tester) async {
      await tester.tap(find.text(_en.starterAddDeck));
      await tester.pumpAndSettle();
    }

    libraryTest('starter, list, $theme', (tester, env) async {
      await shoot(tester, env, await library(env), 'list');
    });

    libraryTest('starter, choose, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        await library(env),
        'choose',
        before: () => openHangul(tester),
      );
    });

    libraryTest('starter, adding, $theme', (tester, env) async {
      final fake = await library(env);
      fake.hold = Completer<void>();
      await shoot(
        tester,
        env,
        fake,
        'adding',
        before: () async {
          await openHangul(tester);
          await tester.tap(find.text(_en.starterAddDeck));
          await tester.pump(const Duration(milliseconds: 300));
        },
      );
      fake.hold!.complete();
      await tester.pumpAndSettle();
    });

    libraryTest('starter, added, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        await library(env),
        'added',
        before: () async {
          await openHangul(tester);
          await add(tester);
        },
      );
    });

    libraryTest('starter, alreadyPresent, $theme', (tester, env) async {
      final fake = await library(env);
      await shoot(
        tester,
        env,
        fake,
        'already_present',
        before: () async {
          await openHangul(tester);
          await fake.addStarterDeck(
            templateId: hangulTemplate.templateId,
            schedulerType: hangulTemplate.suggestedScheduler,
          );
          await add(tester);
        },
      );
    });

    libraryTest('starter, secondCopy, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        await library(env),
        'second_copy',
        before: () async {
          await tester.tap(find.text(_en.starterAddAnotherCopy));
          await tester.pumpAndSettle();
        },
      );
    });

    libraryTest('starter, addFailed, $theme', (tester, env) async {
      final fake = await library(env);
      fake.failsAdds = true;
      await shoot(
        tester,
        env,
        fake,
        'add_failed',
        before: () async {
          await openHangul(tester);
          await add(tester);
        },
      );
    });

    libraryTest('starter, loading, $theme', (tester, env) async {
      final loaded = Completer<void>();
      await shoot(
        tester,
        env,
        StarterLibraryFake(env, loaded: loaded.future),
        'loading',
      );
      loaded.complete();
    });

    libraryTest('starter, none, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        StarterLibraryFake(env, templates: const []),
        'none',
      );
    });

    libraryTest('starter, loadFailed, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        StarterLibraryFake(env, failsLoad: true),
        'load_failed',
        before: () => tester.pumpAndSettle(),
      );
    });
  }
}
