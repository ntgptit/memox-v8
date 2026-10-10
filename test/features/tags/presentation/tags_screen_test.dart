import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/tags/presentation/screens/tags_screen.dart';
import 'package:memox/features/tags/presentation/widgets/overlays/tag_rename_dialog_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../../support/library_harness.dart';
import '../../../support/tag_fixtures.dart';
import '../../../support/tag_screen_fixtures.dart';

// Screen 05 (FE-B2, UC-TAG-001): the twelve kit states and the read error.

final _en = lookupAppLocalizations(const Locale('en'));

Future<TagRepositoryFake> _pump(
  WidgetTester tester,
  LibraryEnv env, {
  bool isSeeded = true,
  ValueChanged<String>? onFindCards,
  void Function(TagRepositoryFake store)? arrange,
  Brightness brightness = Brightness.light,
}) async {
  if (isSeeded) await seedTags(env);
  final store = TagRepositoryFake(env);
  arrange?.call(store);
  await pumpLibraryScreen(
    tester,
    env,
    TagsScreen(onFindCards: onFindCards ?? (_) {}),
    overrides: [store.asOverride],
    brightness: brightness,
  );
  await tester.pumpAndSettle();
  return store;
}

Future<void> _actions(WidgetTester tester, String tag) async {
  await tester.ensureVisible(find.byTooltip(_en.tagsRowActions(tag)));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip(_en.tagsRowActions(tag)));
  await tester.pumpAndSettle();
}

Future<void> _openRename(WidgetTester tester, String tag) async {
  await _actions(tester, tag);
  await tester.tap(find.text(_en.tagsRename));
  await tester.pumpAndSettle();
}

/// Types [name] into the rename field and lets its plan settle.
Future<void> _type(WidgetTester tester, String name) async {
  await tester.enterText(find.byType(TextField).last, name);
  await tester.pump(tagRenameSettle);
  await tester.pumpAndSettle();
}

MxButton _confirm(WidgetTester tester, String label) =>
    tester.widget<MxButton>(find.widgetWithText(MxButton, label));

void main() {
  libraryTest('loaded: every tag with its cards, by folded name; the header '
      'counts them and A→Z is not a control', (tester, env) async {
    await _pump(tester, env);

    expect(find.text(_en.tagsCount(16).toUpperCase()), findsOneWidget);
    expect(find.text(_en.tagsOrder), findsOneWidget);
    expect(find.widgetWithText(MxButton, _en.tagsOrder), findsNothing);
    expect(find.text('bài12'), findsOneWidget);
    expect(find.text(_en.tagsCardCount(46)), findsOneWidget);
  });

  libraryTest('search uses the catalog\'s fold: ĐỘNG TỪ finds động từ '
      '(BR-TAG-003)', (tester, env) async {
    await _pump(tester, env);
    await tester.enterText(find.byType(TextField), 'ĐỘNG TỪ');
    await tester.pump();

    expect(find.text(_en.tagsCount(1).toUpperCase()), findsOneWidget);
    expect(find.byType(MxListRow), findsOneWidget);
    expect(find.text('động từ'), findsOneWidget);
  });

  libraryTest('searchEmpty: no tag matches, which is not "no tags" (A6)', (
    tester,
    env,
  ) async {
    await _pump(tester, env);
    await tester.enterText(find.byType(TextField), 'phras');
    await tester.pump();

    expect(find.text(_en.tagsNoMatches.toUpperCase()), findsOneWidget);
    expect(find.text(_en.tagsSearchEmptyTitle('phras')), findsOneWidget);
    expect(find.text(_en.tagsEmptyTitle), findsNothing);
  });

  libraryTest('empty: a library without tags says where they come from', (
    tester,
    env,
  ) async {
    await _pump(tester, env, isSeeded: false);

    // Only the empty state: no search over nothing, no header that says it
    // twice (critique 2026-09-30 part 3d-2).
    expect(find.text(_en.tagsEmptyTitle), findsOneWidget);
    expect(find.text(_en.tagsGoToLibrary), findsOneWidget);
    expect(find.byType(MxSearchField), findsNothing);
    expect(find.byType(MxListSectionHeader), findsNothing);
  });

  libraryTest('a failed read shows the error with Retry (E1, D10)', (
    tester,
    env,
  ) async {
    await _pump(tester, env, arrange: (store) => store.failsReads = true);

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.text(_en.tagsLoadErrorTitle), findsOneWidget);
    expect(find.textContaining('read failed'), findsNothing);
  });

  libraryTest('sheet: the tag with its count and three commands; Find cards '
      'hands over the name (D11)', (tester, env) async {
    String? found;
    await _pump(tester, env, onFindCards: (name) => found = name);
    await _actions(tester, 'động từ');

    expect(find.text('động từ · 46'), findsOneWidget);
    expect(find.text(_en.tagsFindCardsHint('động từ')), findsOneWidget);
    expect(find.text(_en.tagsDeleteHint(46)), findsOneWidget);
    await tester.tap(find.text(_en.tagsFindCards));
    await tester.pumpAndSettle();
    expect(found, 'động từ');
  });

  libraryTest('rename: prefilled, nothing to write until the name changes; a '
      'new name renames in place (step 5)', (tester, env) async {
    await _pump(tester, env);
    await _openRename(tester, 'động từ');

    expect(find.text(_en.tagsRenameBody('động từ')), findsOneWidget);
    expect(find.text(_en.tagsCaseHint), findsOneWidget);
    expect(_confirm(tester, _en.tagsRenameConfirm).onPressed, isNull);

    await _type(tester, 'verb');
    await tester.tap(find.text(_en.tagsRenameConfirm));
    await tester.pumpAndSettle();

    expect(find.text('verb'), findsOneWidget);
    expect(find.text('động từ'), findsNothing);
    expect((await tagRowsOf(env.db)).map((row) => row.$1), contains('t-dong'));
  });

  libraryTest('renameMerge: the merge is told before it is confirmed, with '
      'the union count, and confirmed in the warning tone (A1)', (
    tester,
    env,
  ) async {
    await _pump(tester, env);
    await _openRename(tester, 'động từ');
    await _type(tester, 'NGỮ PHÁP');

    expect(
      find.text(_en.tagsMergeNotice('ngữ pháp', 'động từ')),
      findsOneWidget,
    );
    expect(find.text('động từ · 46'), findsOneWidget);
    expect(find.text('ngữ pháp · 77'), findsOneWidget);
    expect(find.text(_en.tagsLengthUnique(8, 50)), findsOneWidget);
    expect(_confirm(tester, _en.tagsMergeConfirm).tone, MxButtonTone.warning);

    await tester.tap(find.text(_en.tagsMergeConfirm));
    await tester.pumpAndSettle();

    expect(await tagRowsOf(env.db), hasLength(15));
    expect(find.text(_en.tagsCardCount(77)), findsOneWidget);
    expect(find.text('động từ'), findsNothing);
  });

  libraryTest('Night: the merge panel is a soft ground, so its notice reads '
      'Day\'s text (spec 2026-10-10 D4)', (tester, env) async {
    await _pump(tester, env, brightness: Brightness.dark);
    await _openRename(tester, 'động từ');
    await _type(tester, 'NGỮ PHÁP');

    expect(
      tester
          .widget<Text>(find.text(_en.tagsMergeNotice('ngữ pháp', 'động từ')))
          .style
          ?.color,
      AppColorSchemes.light.onSurfaceVariant,
    );
  });

  libraryTest('nameTooLong: the counter and the field say so, and Rename is '
      'off; a blank name has its own message (E2)', (tester, env) async {
    await _pump(tester, env);
    await _openRename(tester, 'động từ');
    await _type(
      tester,
      'Động từ bất quy tắc thường gặp trong đề thi TOPIK II phần đọc',
    );

    expect(find.text(_en.tagsLength(61, 50)), findsOneWidget);
    expect(find.text(_en.tagsNameTooLong(50)), findsOneWidget);
    expect(_confirm(tester, _en.tagsRenameConfirm).onPressed, isNull);

    await _type(tester, '   ');
    expect(find.text(_en.tagRejectionBlankName), findsOneWidget);
    expect(_confirm(tester, _en.tagsRenameConfirm).onPressed, isNull);
  });

  libraryTest('a merge that appeared after the plan opens the dialog again '
      'on the name typed (mergeNotConfirmed)', (tester, env) async {
    await _pump(tester, env);
    await _openRename(tester, 'tạm');
    await _type(tester, 'verbs');
    await insertTag(env.db, 't-verbs', 'Verbs', cardIds: ['c0']);
    await tester.tap(find.text(_en.tagsRenameConfirm));
    await tester.pumpAndSettle();
    await tester.pump(tagRenameSettle);
    await tester.pumpAndSettle();

    expect(find.text(_en.tagsMergeNotice('Verbs', 'tạm')), findsOneWidget);
    expect(find.text('tạm'), findsWidgets);
  });

  libraryTest('a tag deleted elsewhere while its rename dialog is open closes '
      'the dialog and says it is gone (E3)', (tester, env) async {
    await _pump(tester, env);
    await _openRename(tester, 'tạm');
    await env.db.customStatement(
      "DELETE FROM card_tags WHERE tag_id = 't-tam'",
    );
    await env.db.customStatement("DELETE FROM tags WHERE id = 't-tam'");
    await _type(tester, 'tạm thời');

    expect(find.text(_en.tagsRenameConfirm), findsNothing);
    expect(find.text(_en.tagsGone('tạm')), findsOneWidget);
  });

  libraryTest('del: the dialog says no card is deleted; the tag goes and '
      'every card stays (A3)', (tester, env) async {
    await _pump(tester, env);
    await _actions(tester, 'động từ');
    await tester.tap(find.text(_en.tagsDelete));
    await tester.pumpAndSettle();

    expect(find.text(_en.tagsDeleteBody('động từ', 46)), findsOneWidget);
    expect(find.text(_en.tagsDeleteSafe(46)), findsOneWidget);
    // A neutral note, not a success card beside a destructive confirm
    // (critique 2026-09-30 part 3d-2, E7).
    expect(
      find.ancestor(
        of: find.text(_en.tagsDeleteSafe(46)),
        matching: find.byType(MxNote),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate((widget) => widget is MxCard && widget.isSuccess),
      findsNothing,
    );
    expect(
      _confirm(tester, _en.tagsDeleteConfirm).tone,
      MxButtonTone.destructive,
    );
    await tester.tap(find.text(_en.tagsDeleteConfirm));
    await tester.pumpAndSettle();

    expect(find.text('động từ'), findsNothing);
    final cards = await env.db
        .customSelect('SELECT COUNT(*) AS n FROM card')
        .getSingle();
    expect(cards.read<int>('n'), 213);
  });

  libraryTest('busy: the row spins instead of ⋮ while its write runs', (
    tester,
    env,
  ) async {
    final store = await _pump(tester, env);
    store.hold = Completer<void>();
    await _actions(tester, 'tạm');
    await tester.tap(find.text(_en.tagsDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.tagsDeleteConfirm));
    await tester.pump();
    await tester.pump();

    expect(find.byType(MxSpinner), findsOneWidget);
    expect(find.byTooltip(_en.tagsRowActions('tạm')), findsNothing);

    store.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(MxSpinner), findsNothing);
    expect(find.text('tạm'), findsNothing);
  });

  libraryTest('opError: a failed delete changes nothing and offers Retry, '
      'which deletes (E5)', (tester, env) async {
    final store = await _pump(tester, env);
    store.failsWrites = true;
    await _actions(tester, 'tạm');
    await tester.tap(find.text(_en.tagsDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.tagsDeleteConfirm));
    await tester.pumpAndSettle();

    expect(find.text(_en.tagsDeleteFailed), findsOneWidget);
    expect(find.text('tạm'), findsOneWidget);

    store.failsWrites = false;
    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();
    expect(find.text('tạm'), findsNothing);
  });

  libraryTest('tagGone: a tag deleted elsewhere says so and writes nothing '
      '(E3)', (tester, env) async {
    await _pump(tester, env);
    await _actions(tester, 'tạm');
    await tester.tap(find.text(_en.tagsDelete));
    await tester.pumpAndSettle();
    await env.db.customStatement(
      "DELETE FROM card_tags WHERE tag_id = 't-tam'",
    );
    await env.db.customStatement("DELETE FROM tags WHERE id = 't-tam'");
    await tester.tap(find.text(_en.tagsDeleteConfirm));
    await tester.pumpAndSettle();

    expect(find.text(_en.tagsGone('tạm')), findsOneWidget);
  });

  libraryTest('the rename field label is sentence case (critique 2026-09-30 '
      'part 2, P3)', (tester, env) async {
    await _pump(tester, env);
    await _openRename(tester, 'động từ');

    final label = find.text(_en.tagsNewName);
    expect(
      tester.widget<Text>(label).style,
      tester.element(label).textStyles.fieldLabel,
    );
    expect(find.text(_en.tagsNewName.toUpperCase()), findsNothing);
  });
}
