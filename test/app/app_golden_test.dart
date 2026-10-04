@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../support/deck_fixtures.dart';
import '../support/golden_harness.dart';
import '../support/library_harness.dart';

/// The phone: 1080×2400 at 3x with its status and gesture insets.
const _phone = (size: Size(1080, 2400), ratio: 3.0);

Future<void> _pumpApp(
  WidgetTester tester,
  LibraryEnv env,
  Brightness brightness, {
  ({Size size, double ratio}) view = _phone,
}) async {
  tester.view.physicalSize = view.size;
  tester.view.devicePixelRatio = view.ratio;
  // 24 top and 20 bottom logical, at any ratio.
  tester.view.padding = FakeViewPadding(
    top: 24 * view.ratio,
    bottom: 20 * view.ratio,
  );
  addTearDown(tester.view.reset);
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.pumpWidget(
    RepaintBoundary(
      key: goldenBoundaryKey,
      child: ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(env.db),
          dayClockProvider.overrideWithValue(env.clock),
        ],
        child: const MemoxApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// A route push or a theme switch starts its animation on the next frame; a
/// single long pump would capture that first frame. Pump once to start it,
/// then past its end. (The gallery's spinner keeps pumpAndSettle from ending.)
Future<void> _settleFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  for (final brightness in Brightness.values) {
    libraryTest('Library tab, ${brightness.name}', (tester, env) async {
      await withRealShadows(() async {
        await _pumpApp(tester, env, brightness);
        await expectBoundaryGolden(
          tester,
          'goldens/app_library_${brightness.name}.png',
        );
      });
    });

    libraryTest('Gallery, ${brightness.name}', (tester, env) async {
      await withRealShadows(() async {
        await _pumpApp(tester, env, brightness);
        await tester.tap(find.text(en.navSettings));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(en.openGallery));
        await _settleFrames(tester);
        if (brightness == Brightness.dark) {
          await tester.tap(find.byTooltip('Dark theme'));
          await _settleFrames(tester);
        }
        await expectBoundaryGolden(
          tester,
          'goldens/app_gallery_${brightness.name}.png',
        );
      });
    });

    // FE-C5: a rail and the 720 column on a tablet, with the tap-target
    // rules the phone screens are audited against.
    for (final (name, size, open) in [
      ('landscape_library', const Size(1280, 800), false),
      ('portrait_deck', const Size(800, 1280), true),
    ]) {
      libraryTest('tablet $name, ${brightness.name}', (tester, env) async {
        final korean = await env.decks.root('Korean TOPIK I');
        await env.decks.sub(korean.id, 'Vocabulary');
        await env.decks.sub(korean.id, 'Grammar');
        await env.decks.root('Spanish A2');
        await withRealShadows(() async {
          await _pumpApp(tester, env, brightness, view: (size: size, ratio: 1));
          if (open) {
            await tester.tap(find.text('Korean TOPIK I'));
            await tester.pumpAndSettle();
          }
          await expectBoundaryGolden(
            tester,
            'goldens/app_tablet_${name}_${brightness.name}.png',
            pixelRatio: 1.5,
          );
        });
        final semantics = tester.ensureSemantics();
        for (final guideline in [
          androidTapTargetGuideline,
          iOSTapTargetGuideline,
          labeledTapTargetGuideline,
        ]) {
          await expectLater(tester, meetsGuideline(guideline));
        }
        semantics.dispose();
      });
    }
  }
}
