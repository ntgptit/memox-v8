import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/presentation/widgets/support/session_footer_hint_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/session_context_line_widget.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/study/presentation/widgets/support/study_choice_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/recall_countdown_bar_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_cta_row_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_face_card_widget.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/library_harness.dart';

// FE-A6 P4: the turn clock (19; pre-plan rulings V2, V3, V5, V9) and the
// kit's StudyCtaRow.

Widget _host(Widget child, {bool isStill = false}) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: isStill),
    child: Scaffold(body: Center(child: child)),
  ),
);

double _fillOf(WidgetTester tester) => tester
    .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
    .widthFactor!;

void main() {
  libraryTest('the clock is one node, its caption with the seconds left as '
      'its value, and its fill is the time left (V3, V5)', (tester, env) async {
    final handle = tester.ensureSemantics();
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        const RecallCountdownBarWidget(
          caption: 'Time to recall',
          remainingMs: 13400,
          isTimedOut: false,
        ),
      ),
    );

    expect(find.text('14s / 20s'), findsOneWidget);
    final node = tester.getSemantics(find.byType(RecallCountdownBarWidget));
    expect(node.label, 'Time to recall');
    expect(node.value, '14 seconds left');
    expect(_fillOf(tester), closeTo(13400 / 20000, 1e-9));
    // M3-F2: the app's thin track, M3's 4dp.
    expect(tester.getSize(find.byType(FractionallySizedBox)).height, 4);
    handle.dispose();
  });

  libraryTest('under Remove animations the fill steps by whole seconds (V9)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        const RecallCountdownBarWidget(
          caption: 'c',
          remainingMs: 13400,
          isTimedOut: false,
        ),
        isStill: true,
      ),
    );

    expect(_fillOf(tester), 14000 / 20000);
  });

  libraryTest('two actions share the row', (tester, env) async {
    const row = StudyCtaRowWidget(
      children: [
        MxButton(label: 'Forgot', isBlock: true, onPressed: null),
        MxButton(label: 'Remembered', isBlock: true, onPressed: null),
      ],
    );
    await pumpLibraryScreen(tester, env, _host(row));
    expect(
      tester.getCenter(find.text('Forgot')).dy,
      tester.getCenter(find.text('Remembered')).dy,
    );
    expect(tester.getSize(find.byType(MxButton).first).width, 160);
  });
  libraryTest('a face with more below fades its bottom edge (audit P1)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        SizedBox(
          height: 200,
          child: StudyFaceCardWidget(
            label: 'Meaning',
            child: Text(List.filled(30, 'a long meaning line').join('\n')),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('study-scroll-fade')), findsOneWidget);
  });

  libraryTest('a face that fits shows no fade', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        const SizedBox(
          height: 400,
          child: StudyFaceCardWidget(label: 'Term', child: Text('reserve')),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('study-scroll-fade')), findsNothing);
  });
  libraryTest('the context line holds two lines at most, ends in an '
      'ellipsis, and is heard whole (critique 2026-09-30 part 3c-2, R9)', (
    tester,
    env,
  ) async {
    const text =
        'Tiếng Hàn TOPIK I · Từ vựng sơ cấp · Learning · Stage 1 of 3 · Match';
    await pumpLibraryScreen(
      tester,
      env,
      _host(SessionContextLineWidget(text: text, shown: text.toUpperCase())),
    );
    final line = tester.widget<Text>(find.text(text.toUpperCase()));

    expect((line.maxLines, line.overflow), (2, TextOverflow.ellipsis));
    expect(line.semanticsLabel, text);
  });

  libraryTest('the footer hint wraps, never cut, its glyph inline on the '
      'first line (critique 2026-09-30 part 3c-2, R6)', (tester, env) async {
    const text =
        'Swipe left for next, right to look back · nothing is graded here';
    await pumpLibraryScreen(
      tester,
      env,
      _host(const SessionFooterHintWidget(icon: AppIcons.check, text: text)),
    );
    final hint = tester.widget<Text>(find.textContaining(text));

    expect((hint.maxLines, hint.overflow), (null, null));
    expect(hint.semanticsLabel, text);
    expect(
      find.descendant(
        of: find.byType(RichText),
        matching: find.byIcon(AppIcons.check),
      ),
      findsOneWidget,
    );
  });

  libraryTest('a one-line and a two-line hint take the same height, so the '
      'CTA stands still (critique 2026-09-30 part 3c-2, R6)', (
    tester,
    env,
  ) async {
    Future<double> heightOf(String text, {double textScale = 1}) async {
      await pumpLibraryScreen(
        tester,
        env,
        _host(SessionFooterHintWidget(icon: AppIcons.check, text: text)),
        textScale: textScale,
      );
      return tester.getSize(find.byType(SessionFooterHintWidget)).height;
    }

    const short = 'Tap to flip';
    const long =
        'Swipe left for next, right to look back · nothing is graded here';
    const threeLines =
        'Swipe left for next, right to look back · nothing is graded here, '
        'and nothing you do on this screen changes when a card comes back';

    expect(await heightOf(short), await heightOf(long));
    expect(await heightOf(threeLines), greaterThan(await heightOf(long)));
    // Review Focus 4: the reserve follows the text scale.
    expect(
      await heightOf(short, textScale: 2),
      greaterThan(await heightOf(short)),
    );
  });

  libraryTest('the footer hint steps aside while the keyboard is up (Fill), '
      'inside the shell whose Scaffold strips the inset', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const MxAppShell(
        body: SizedBox.expand(),
        footer: SessionFooterHintWidget(icon: AppIcons.edit, text: 'Type it'),
      ),
    );
    expect(find.textContaining('Type it'), findsOneWidget);

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();

    expect(find.textContaining('Type it'), findsNothing);
  });

  libraryTest('an option out of play stays readable: it fades to the muted '
      'opacity, not the disabled one (critique 2026-09-30)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        StudyChoiceWidget(
          tone: StudyChoiceTone.idle,
          isFaded: true,
          semanticsLabel: 'a',
          builder: (ink) => const Text('a'),
        ),
      ),
    );

    final fade = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
    expect(fade.opacity, AppOpacity.muted);
  });

  libraryTest('one action spans the width of a two-action row, not its own '
      'label (critique 2026-09-30, S6)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        const StudyCtaRowWidget(
          children: [MxButton(label: 'Continue', onPressed: null)],
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(MxButton)).width,
      2 * 160 + AppSpacing.control,
    );
  });

  libraryTest('the face label and the context line are eyebrows (critique '
      '2026-09-30 part 2, P2)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        const Column(
          children: [
            SessionContextLineWidget(
              text: 'Words · Review',
              shown: 'WORDS · REVIEW',
            ),
            SizedBox(
              height: 300,
              child: StudyFaceCardWidget(label: 'Term', child: Text('x')),
            ),
          ],
        ),
      ),
    );
    for (final text in ['WORDS · REVIEW', 'TERM']) {
      final label = find.text(text);
      expect(
        tester.widget<Text>(label).style,
        tester.element(label).textStyles.eyebrow,
        reason: text,
      );
    }
  });
}
