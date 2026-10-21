import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_resume_widget.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_linear_progress.dart';
import 'package:memox/l10n/meta_line.dart';

import '../../../support/library_harness.dart';
import '../../../support/wrap_rule.dart';

final _en = AppLocalizationsEn();

ResumableSession _session({
  String deck = 'Words',
  String? root = 'Korean',
  RoundProgress? progress = const RoundProgress(completed: 2, total: 5),
}) => ResumableSession(
  sessionId: 's1',
  deckId: 'd1',
  deckName: deck,
  rootName: root,
  kind: SessionKind.reviewing,
  mode: StudyMode.match,
  progress: progress,
);

Future<void> _pump(
  WidgetTester tester,
  LibraryEnv env,
  ResumableSession session, {
  double width = 360,
  double textScale = 1,
}) => pumpLibraryScreen(
  tester,
  env,
  Scaffold(
    body: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        // The screen margin of a compact window around the card.
        width: width - 32,
        child: StudyHomeResumeWidget(
          session: session,
          isResuming: false,
          onResume: () {},
        ),
      ),
    ),
  ),
  textScale: textScale,
);

void main() {
  // Study home spec H3: Resume shares the progress row while it fits, and
  // takes a block row of its own on a narrow card or at a large text scale;
  // a 48 target either way.
  for (final (name, width, textScale, isCompact)
      in <(String, double, double, bool)>[
        ('a 360 dp phone: beside the progress', 360, 1, true),
        ('a narrower window: a block under it', 320, 1, false),
        ('a 1.3 text scale: a block under it', 360, 1.3, false),
      ]) {
    libraryTest('Resume on $name', (tester, env) async {
      await _pump(tester, env, _session(), width: width, textScale: textScale);

      final button = tester.widget<MxButton>(find.byType(MxButton));
      expect(button.isBlock, !isCompact);
      final track = tester.getRect(find.byType(MxLinearProgress));
      final resume = tester.getRect(find.byType(MxButton));
      expect(
        (resume.center.dy - track.center.dy).abs() < resume.height / 2,
        isCompact,
        reason: 'one row',
      );
      expect(resume.height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });
  }

  libraryTest('the title names the deck under its root, or the root alone; '
      'the session line and the count are apart (Study home spec H3)', (
    tester,
    env,
  ) async {
    await _pump(tester, env, _session());
    expect(
      find.text(breadcrumbLine(_en.studyHomeResumeTitle('Korean', 'Words'))),
      findsOneWidget,
    );
    // The session line holds the kind and the mode, not the count.
    final line = find.textContaining(_en.studyKindReview);
    expect(line, findsOneWidget);
    expect(tester.widget<Text>(line).data, isNot(contains('5')));
    expect(find.text(_en.studyHomeResumeProgress(2, 5)), findsOneWidget);

    await _pump(
      tester,
      env,
      _session(deck: 'Korean', root: null, progress: null),
    );
    expect(find.text('Korean'), findsOneWidget);
    expect(find.byType(MxLinearProgress), findsNothing);
    expect(find.byType(MxButton), findsOneWidget);
  });

  libraryTest('a long deck name stops at two lines with an ellipsis, '
      'nothing overflows', (tester, env) async {
    final long = 'IELTS Academic Word List ' * 4;
    await _pump(tester, env, _session(deck: long.trim()));

    final title = tester.widget<Text>(
      find.text(
        breadcrumbLine(_en.studyHomeResumeTitle('Korean', long.trim())),
      ),
    );
    expect((title.maxLines, title.overflow), (2, TextOverflow.ellipsis));
    expect(tester.takeException(), isNull);
  });

  // Spec B1: "›" stays with the deck after it, so the title never ends a
  // line on it, on a 360 dp phone or at a 1.3 text scale.
  for (final textScale in [1.0, 1.3]) {
    libraryTest('the title never ends a line on "›" (scale $textScale)', (
      tester,
      env,
    ) async {
      await _pump(
        tester,
        env,
        _session(root: 'IELTS Academic Word List'),
        textScale: textScale,
      );
      expectNoLineEndsOn(
        tester,
        find.textContaining('IELTS Academic Word List'),
        '›',
      );
    });
  }
}
