import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_decks_widget.dart';
import 'package:memox/shared/widgets/mx_term_line.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/term_line.dart';

StudyHomeScreen _screen({ValueChanged<String>? onOpenDeck}) => StudyHomeScreen(
  onOpenSession: (_) {},
  onOpenDeck: onOpenDeck ?? (_) {},
  onOpenLibrary: () {},
  onOpenStarterDecks: () {},
  onOpenSync: () {},
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  // Owner review 2026-10-21: a very long deck name stops at two lines with
  // an ellipsis on its row, at the default and a large text scale; TalkBack
  // still reads it whole, and the row opens. "Review {deck}" is
  // study_home_workload_test's.
  const name =
      'Thuật ngữ Kinh tế – Tài chính – Ngân hàng cho kỳ thi chứng chỉ quốc tế '
      'về kế toán, kiểm toán và thị trường chứng khoán';
  for (final textScale in [1.0, 1.3]) {
    libraryTest('a very long deck name: two lines and an ellipsis on its '
        'row, read whole, still a target (scale $textScale)', (
      tester,
      env,
    ) async {
      final handle = tester.ensureSemantics();
      final root = await env.decks.root(name);
      final leaf = await env.decks.sub(root.id, 'Leaf');
      await insertCard(
        env.db,
        id: 'late',
        deckId: leaf.id,
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, 20),
        box: 2,
      );
      await lockScheduler(env.db, root.id);
      final opened = <String>[];
      await pumpLibraryScreen(
        tester,
        env,
        _screen(onOpenDeck: opened.add),
        textScale: textScale,
      );
      await _settle(tester);

      final title = tester.widget<Text>(
        find.descendant(
          of: find.byType(StudyHomeDecksWidget),
          matching: find.text(name),
        ),
      );
      expect((title.maxLines, title.overflow), (2, TextOverflow.ellipsis));
      expect(
        find.bySemanticsLabel(RegExp(RegExp.escape(name))),
        findsWidgets,
        reason: 'the whole name is read',
      );
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.descendant(
          of: find.byType(StudyHomeDecksWidget),
          matching: find.text(name),
        ),
      );
      await tester.pumpAndSettle();
      expect(opened, [root.id]);
      handle.dispose();
    });
  }

  // Plan Review Focus 2: on a 360 dp phone at a 1.3 text scale the rows'
  // counts wrap between whole terms with no dot at a line edge.
  libraryTest('at a 1.3 text scale a row\'s counts keep the Wrap Rule '
      '(spec W1)', (tester, env) async {
    final root = await env.decks.root('Kanji N5 Vocabulary');
    final leaf = await env.decks.sub(root.id, 'Leaf');
    for (final (id, dueAt) in [
      ('late', DateTime(2026, 9, 20)),
      ('now', DateTime(2026, 9, 24, 8)),
      ('new', null),
    ]) {
      await insertCard(
        env.db,
        id: id,
        deckId: leaf.id,
        learnedAt: dueAt == null ? null : DateTime(2026, 9, 1),
        dueAt: dueAt,
        box: 2,
      );
    }
    await lockScheduler(env.db, root.id);
    await pumpLibraryScreen(tester, env, _screen(), textScale: 1.3);
    await _settle(tester);

    final lines = find.descendant(
      of: find.byType(StudyHomeDecksWidget),
      matching: find.byType(MxTermLine),
    );
    expect(lines, findsWidgets);
    for (final element in lines.evaluate()) {
      expectTermLineRule(tester, find.byWidget(element.widget));
    }
  });
}
