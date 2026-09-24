@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../support/golden_harness.dart';
import '../support/library_harness.dart';

Future<void> _pumpApp(
  WidgetTester tester,
  LibraryEnv env,
  Brightness brightness,
) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 72, bottom: 60);
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
  }
}
