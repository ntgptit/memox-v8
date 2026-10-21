import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_resume_widget.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/features/study/presentation/widgets/overlays/study_deck_location_sheet_widget.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_linear_progress.dart';

import '../../../support/library_harness.dart';

final _en = AppLocalizationsEn();

ResumableSession _session({
  String deck = 'Words',
  String? root = 'Korean',
  RoundProgress? progress = const RoundProgress(completed: 2, total: 5),
}) => ResumableSession(
  sessionId: 's1',
  deckId: 'd1',
  deckPath: [?root, deck],
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
  bool isResuming = false,
  bool isBoldText = false,
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
          isResuming: isResuming,
          onResume: () {},
        ),
      ),
    ),
  ),
  textScale: textScale,
  isBoldText: isBoldText,
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

  libraryTest('the title names the deck alone, a root or a sub-deck; the '
      'session line and the count are apart (Study home spec H3; owner '
      '2026-10-21)', (tester, env) async {
    await _pump(tester, env, _session());
    expect(find.text('Words'), findsOneWidget);
    expect(find.textContaining('›'), findsNothing);
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
    final long = ('IELTS Academic Word List ' * 4).trim();
    await _pump(tester, env, _session(deck: long));

    final title = tester.widget<Text>(find.text(long));
    expect((title.maxLines, title.overflow), (2, TextOverflow.ellipsis));
    expect(tester.takeException(), isNull);
  });

  libraryTest('the card names the deck alone with an ⓘ that opens its '
      'location; nothing is written', (tester, env) async {
    await _pump(tester, env, _session(deck: 'Words', root: 'Korean'));
    await tester.tap(find.byType(MxIconButton));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(StudyDeckLocationSheetWidget),
        matching: find.text('Korean'),
      ),
      findsOneWidget,
    );
  });

  // Spec §5: TalkBack meets the card in reading order.
  libraryTest('the card reads overline, name, ⓘ, Resume in that order', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, env, _session(deck: 'Words'));
    final labels = [
      // A tooltip's button merges its label up into the tooltip's node.
      for (final node in tester.semantics.simulatedAccessibilityTraversal())
        node.getSemanticsData().label,
    ].where((label) => label.isNotEmpty).toList();
    final order = [
      _en.studyHomeResumeOverline,
      'Words',
      _en.studyDeckLocationTitle,
      _en.studyHomeResume,
    ].map((label) => labels.indexWhere((l) => l.contains(label))).toList();
    expect(order, everyElement(isNonNegative));
    expect(order, orderedEquals([...order]..sort()));
    handle.dispose();
  });

  libraryTest('while Resume runs the ⓘ is locked', (tester, env) async {
    await _pump(tester, env, _session(), isResuming: true);
    expect(
      tester.widget<MxIconButton>(find.byType(MxIconButton)).onPressed,
      isNull,
    );
  });

  // D9: the name before the decorative tile. The tile shows only under a
  // 1.3 text scale while the name, as drawn, fits two lines beside it.
  const long =
      'Từ vựng chủ đề gia đình, trường học và nghề nghiệp cho kỳ thi TOPIK '
      'trung cấp';
  for (final (width, textScale, name, hasTile) in [
    (360.0, 1.0, 'Words', true),
    (360.0, 1.0, long, false),
    (320.0, 1.0, 'Words', true),
    (360.0, 1.3, 'Words', false),
    (320.0, 2.0, 'Words', false),
  ]) {
    libraryTest('the paused tile at $width dp, scale $textScale, '
        '${name.length} letters: ${hasTile ? 'shown' : 'gone'}; ⓘ stays; '
        'nothing overflows (bold)', (tester, env) async {
      await _pump(
        tester,
        env,
        _session(deck: name),
        width: width,
        textScale: textScale,
        isBoldText: true,
      );
      expect(find.byType(MxIconTile), hasTile ? findsOneWidget : findsNothing);
      expect(find.byType(MxIconButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
