import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_lock_strip_widget.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

// DEV-359 (check similar): the locked strip sits on the warning container,
// so its title and body read in the on-container (spec 4.6), at 4.5:1 or
// more on it in both themes.

final _en = lookupAppLocalizations(const Locale('en'));

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final brightness in Brightness.values) {
    final semantic = brightness == Brightness.light
        ? MxSemanticColors.light
        : MxSemanticColors.dark;
    final scheme = brightness == Brightness.light
        ? AppColorSchemes.light
        : AppColorSchemes.dark;

    libraryTest('locked strip, ${brightness.name}: title and body read in '
        'the warning on-container', (tester, env) async {
      final korean = await env.decks.root('Korean', SchedulerType.sm2);
      await lockScheduler(env.db, korean.id);
      await pumpLibraryScreen(
        tester,
        env,
        deckAlgorithmScreen(deckId: korean.id),
        brightness: brightness,
      );
      final date = DateFormat.yMMMd('en').format(DateTime(2026, 9, 20));
      final strip = find.byType(DeckLockStripWidget);
      final ground = tester
          .widget<Material>(
            find.descendant(of: strip, matching: find.byType(Material)).first,
          )
          .color!;

      expect(ground, semantic.warningContainer);
      for (final text in [
        _en.algorithmLockedTitle(1),
        _en.algorithmLockedBody(date),
      ]) {
        final ink = tester.widget<Text>(find.text(text)).style!.color!;
        expect(ink, semantic.onWarningContainer, reason: text);
        expect(_contrast(ink, ground), greaterThanOrEqualTo(4.5));
      }
    });

    libraryTest('unlocked strip, ${brightness.name}: the neutral roles stand', (
      tester,
      env,
    ) async {
      final korean = await env.decks.root('Korean', SchedulerType.sm2);
      await pumpLibraryScreen(
        tester,
        env,
        deckAlgorithmScreen(deckId: korean.id),
        brightness: brightness,
      );

      expect(
        tester.widget<Text>(find.text(_en.algorithmUnlockedTitle)).style!.color,
        scheme.onSurface,
      );
      expect(
        tester.widget<Text>(find.text(_en.algorithmUnlockedBody)).style!.color,
        scheme.onSurfaceVariant,
      );
    });
  }
}
