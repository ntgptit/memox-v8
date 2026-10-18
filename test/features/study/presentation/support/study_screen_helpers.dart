import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study/presentation/widgets/support/session_footer_hint_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_linear_progress.dart';
import 'package:memox/shared/widgets/mx_study_top_bar.dart';

import '../../../../support/forui_expect.dart' show textColor;

// What the study session screen's widget tests share: the screen over a
// session, and the reads of it more than one mode's test makes.

/// The study session screen of [id], with its exits ignored.
StudySessionScreen studySessionScreen(String id) => StudySessionScreen(
  sessionId: id,
  onDone: (_) {},
  onStudyDeck: (_) {},
  onLeave: (_) {},
);

/// The footer hint's glyph (critique 2026-10-02, F7).
IconData footerHintIcon(WidgetTester tester) => tester
    .widget<SessionFooterHintWidget>(find.byType(SessionFooterHintWidget))
    .icon;

/// The front of the one card shown (`front …`), which the order of a
/// session's rows does not fix.
String shownFront(WidgetTester tester) => tester
    .widgetList<Text>(find.textContaining(RegExp(r'^front ')))
    .single
    .data!;

/// Three frames: the state after a tap or a text change has reached the tree
/// (a screen with a running clock is never settled).
Future<void> pumpThreeFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

/// The top bar of the pumped [mode] screen is Indigo, as in every mode:
/// ForUI paints the progress track, then the fill, and the mode chip reads
/// the primary colour (critique 2026-09-30 part 3c-2, R8).
void expectIndigoTopBar(WidgetTester tester, StudyMode mode) {
  final bar = find.byType(MxStudyTopBar);
  final fill =
      tester
              .widgetList<DecoratedBox>(
                find.descendant(
                  of: find.descendant(
                    of: bar,
                    matching: find.byType(MxLinearProgress),
                  ),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .last
              .decoration
          as ShapeDecoration;
  final chip = find.descendant(
    of: bar,
    matching: find.text(
      lookupAppLocalizations(const Locale('en')).studyMode(mode).toUpperCase(),
    ),
  );

  expect(fill.color, appLightColors.primary);
  expect(textColor(tester, chip), tester.element(chip).colors.primary);
}
