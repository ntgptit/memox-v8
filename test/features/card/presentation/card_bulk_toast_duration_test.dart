import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/library_harness.dart';
import 'card_bulk_actions_harness.dart';

// A bulk toast that carries news past its first sentence stays longer than a
// plain confirmation (WCAG 2.2.1, SP2a audit m7).

Duration _toastDuration(WidgetTester tester) =>
    tester.widget<SnackBar>(find.byType(SnackBar)).duration;

Future<void> _moveTo(WidgetTester tester, String deck) async {
  await tapBulk(tester, enL10n.cardMove);
  await tester.tap(find.text(deck));
  await tester.pumpAndSettle();
}

Future<void> _tag(WidgetTester tester) async {
  await tapBulk(tester, enL10n.cardTag);
  await tester.enterText(find.byType(EditableText).last, 'extra');
  await tester.tap(inDialog(enL10n.cardTagConfirm));
  await tester.pumpAndSettle();
}

/// Two cards selected on the Words list; [gone] go behind the screen's back.
Future<void> _selectTwo(
  WidgetTester tester,
  LibraryEnv env, {
  Set<String> gone = const {},
}) async {
  final ids = await seedBulkCards(env);
  await pumpLibraryScreen(tester, env, bulkSection(ids.words));
  await selectCards(tester, ['annyeong', 'gamsa']);
  if (gone.isEmpty) return;
  await env.cards.deleteCards(cardIds: gone);
  await tester.pumpAndSettle();
}

const _verbs = 'Korean › Verbs';

void main() {
  libraryTest('a plain Move keeps the 4 s toast', (tester, env) async {
    await _selectTwo(tester, env);
    await _moveTo(tester, _verbs);

    expect(find.text(enL10n.cardMovedToast(2, 'Verbs')), findsOneWidget);
    expect(_toastDuration(tester), AppDurations.toast);
  });

  libraryTest('Move that skipped a gone card stays longer', (
    tester,
    env,
  ) async {
    await _selectTwo(tester, env, gone: {'due1'});
    await _moveTo(tester, _verbs);

    expect(_toastDuration(tester), AppDurations.undoWindow);
  });

  libraryTest('Flag that skipped a gone card stays longer', (
    tester,
    env,
  ) async {
    await _selectTwo(tester, env, gone: {'due1'});
    await tapBulk(tester, enL10n.cardFlag);
    await tapBulk(tester, enL10n.cardFlagSet);

    expect(_toastDuration(tester), AppDurations.undoWindow);
  });

  libraryTest('Tag that skipped a gone card stays longer', (tester, env) async {
    await _selectTwo(tester, env, gone: {'due1'});
    await _tag(tester);

    expect(_toastDuration(tester), AppDurations.undoWindow);
  });

  libraryTest('Move when every card is gone stays longer', (tester, env) async {
    await _selectTwo(tester, env, gone: {'new1', 'due1'});
    await _moveTo(tester, _verbs);

    expect(find.text(enL10n.cardBulkAllGone(2)), findsOneWidget);
    expect(_toastDuration(tester), AppDurations.undoWindow);
  });

  libraryTest('Tag when every card is gone stays longer', (tester, env) async {
    await _selectTwo(tester, env, gone: {'new1', 'due1'});
    await _tag(tester);

    expect(find.text(enL10n.cardBulkAllGone(2)), findsOneWidget);
    expect(_toastDuration(tester), AppDurations.undoWindow);
  });

  libraryTest('Trash when every card is gone stays longer', (
    tester,
    env,
  ) async {
    await _selectTwo(tester, env, gone: {'new1', 'due1'});
    await tapBulk(tester, enL10n.cardDelete);
    await tester.tap(inDialog(enL10n.cardMoveToTrashCount(2)));
    await tester.pumpAndSettle();

    expect(find.text(enL10n.cardBulkAllGone(2)), findsOneWidget);
    expect(_toastDuration(tester), AppDurations.undoWindow);
  });

  libraryTest('Flag when every card is gone stays longer', (tester, env) async {
    await _selectTwo(tester, env, gone: {'new1', 'due1'});
    await tapBulk(tester, enL10n.cardFlag);
    await tapBulk(tester, enL10n.cardFlagSet);

    expect(find.text(enL10n.cardBulkAllGone(2)), findsOneWidget);
    expect(_toastDuration(tester), AppDurations.undoWindow);
  });

  libraryTest('a tag limit refusal stays longer', (tester, env) async {
    final tags = TagRepositoryImpl(env.db);
    await _selectTwo(tester, env);
    for (var i = 0; i < 10; i++) {
      await tags.attachByName(cardIds: {'new1'}, name: 'tag $i');
    }
    await tester.pumpAndSettle();
    await _tag(tester);

    expect(find.text(enL10n.cardTagLimitReached(1)), findsOneWidget);
    expect(_toastDuration(tester), AppDurations.undoWindow);
  });
}
