import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/features/study/presentation/widgets/overlays/study_deck_location_sheet_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_session_title_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import '../../../support/library_harness.dart';
import '../../../support/text_cut.dart';
import '../../../support/widget_harness.dart';

// The session's deck by its name in the card, its location one tap away
// (owner 2026-10-21, spec D2, D3).

final _en = lookupAppLocalizations(const Locale('en'));

Widget _title(List<String> path, {bool isLocked = false}) => Align(
  alignment: Alignment.topLeft,
  child: SizedBox(
    width: 280,
    child: Builder(
      builder: (context) => StudySessionTitleWidget(
        path: path,
        line: const Text('Learning · Browse'),
        onShowLocation: isLocked
            ? null
            : () => showStudyDeckLocationSheet(context, path),
      ),
    ),
  ),
);

const _deep = [
  'Tiếng Hàn TOPIK I',
  'Từ vựng sơ cấp theo chủ đề',
  'Chủ đề gia đình và trường học',
  'Bài 12',
  'Phần một',
  'Phần hai',
  'Phần ba',
  'Phần bốn',
  'Phần năm',
  'Độngtừthườnggặptrongđờisốnghằngngàykhôngcókhoảngtrắng',
];

void main() {
  libraryTest('the card names the deck alone, two lines then an ellipsis, '
      'and reads it whole', (tester, env) async {
    final handle = tester.ensureSemantics();
    await pumpLibraryScreen(tester, env, _title(_deep), textScale: 2);
    final name = tester.widget<Text>(find.text(_deep.last));
    expect((name.maxLines, name.overflow), (2, TextOverflow.ellipsis));
    expect(find.text(_deep.first), findsNothing);
    expect(find.bySemanticsLabel(_deep.last), findsOneWidget);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  libraryTest('ⓘ is a 48 target named Deck location; null disables it', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _title(_deep));
    await expectAccessibleTargets(tester);
    expect(
      tester.widget<MxIconButton>(find.byType(MxIconButton)).semanticLabel,
      _en.studyDeckLocationTitle,
    );
    // Final review 2026-10-21: the null case itself.
    await pumpLibraryScreen(tester, env, _title(_deep, isLocked: true));
    await tester.tap(find.byType(MxIconButton));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MxIconButton>(find.byType(MxIconButton)).onPressed,
      isNull,
    );
    expect(find.byType(StudyDeckLocationSheetWidget), findsNothing);
  });

  // Every level whole, the session's deck marked, each read with its depth;
  // at 1.0, 1.3 and 2.0 in bold on 320 dp it scrolls to the last level.
  for (final textScale in [1.0, 1.3, 2.0]) {
    libraryTest('the sheet lists every level whole and scrolls (scale '
        '$textScale, bold)', (tester, env) async {
      tester.view.physicalSize = const Size(320, 800);
      final handle = tester.ensureSemantics();
      await pumpLibraryScreen(
        tester,
        env,
        _title(_deep),
        textScale: textScale,
        isBoldText: true,
      );
      tester.view.physicalSize = const Size(320, 800);
      await tester.tap(find.byType(MxIconButton));
      await tester.pumpAndSettle();

      expect(find.text(_en.studyDeckLocationTitle), findsOneWidget);
      final sheet = find.byType(StudyDeckLocationSheetWidget);
      expectNoTextCut(tester, sheet);
      await tester.scrollUntilVisible(
        find.descendant(of: sheet, matching: find.text(_deep.last)),
        200,
        scrollable: find
            .descendant(of: sheet, matching: find.byType(Scrollable))
            .first,
      );
      expect(
        find.bySemanticsLabel(
          _en.studyDeckLocationSessionDeck(_deep.last, 10, 10),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(_en.studyDeckLocationLevel(_deep.first, 1, 10)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  }

  libraryTest("a root-only session lists one level, marked as the session's "
      "deck; the card stops a margin above the sheet's edge (Impeccable "
      'audit 2026-10-21)', (tester, env) async {
    final handle = tester.ensureSemantics();
    await pumpLibraryScreen(tester, env, _title(const ['Korean']));
    await tester.tap(find.byType(MxIconButton));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(_en.studyDeckLocationSessionDeck('Korean', 1, 1)),
      findsOneWidget,
    );
    // No footer closes this sheet, so the card's edge must not meet its own.
    final sheet = tester.getRect(find.byType(MxBottomSheet));
    final card = tester.getRect(
      find.descendant(
        of: find.byType(StudyDeckLocationSheetWidget),
        matching: find.byType(MxCard),
      ),
    );
    final margin = tester
        .element(find.byType(StudyDeckLocationSheetWidget))
        .screenMargin;
    expect(sheet.bottom - card.bottom, margin);
    handle.dispose();
  });

  // A snapshot: the sheet shows the path it opened with.
  libraryTest('the sheet keeps the path it opened with', (tester, env) async {
    var path = const ['Korean', 'Grammar', 'Lesson'];
    late StateSetter rebuild;
    await pumpLibraryScreen(
      tester,
      env,
      StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return _title(path);
        },
      ),
    );
    await tester.tap(find.byType(MxIconButton));
    await tester.pumpAndSettle();
    rebuild(() => path = const ['Korean', 'Grammar II', 'Lesson']);
    await tester.pumpAndSettle();
    final sheet = find.byType(StudyDeckLocationSheetWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('Grammar')),
      findsOneWidget,
    );
  });
}
