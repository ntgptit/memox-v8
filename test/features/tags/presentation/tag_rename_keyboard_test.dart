import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/features/tags/presentation/screens/tags_screen.dart';
import 'package:memox/features/tags/presentation/widgets/overlays/tag_rename_dialog_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../../../support/forui_expect.dart';
import '../../../support/library_harness.dart';
import '../../../support/tag_fixtures.dart';
import '../../../support/tag_screen_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _openRename(WidgetTester tester, String tag) async {
  await tester.ensureVisible(byControlLabel(_en.tagsRowActions(tag)));
  await tester.pumpAndSettle();
  await tester.tap(byControlLabel(_en.tagsRowActions(tag)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(_en.tagsRename));
  await tester.pumpAndSettle();
}

/// Types [name] into the rename field and lets its plan settle.
Future<void> _type(WidgetTester tester, String name) async {
  await tester.enterText(find.byType(FTextField).last, name);
  await tester.pump(tagRenameSettle);
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

Future<void> _pump(WidgetTester tester, LibraryEnv env) async {
  await seedTags(env);
  await pumpLibraryScreen(
    tester,
    env,
    TagsScreen(onFindCards: (_) {}),
    overrides: [TagRepositoryFake(env).asOverride],
  );
  await tester.pumpAndSettle();
}

Future<List<String>> _names(LibraryEnv env) async => [
  for (final row in await tagRowsOf(env.db)) row.$2,
];

// The rename field declares the Done action (tag_rename_dialog_widget.dart):
// the keyboard does what the dialog's confirm does, and nothing when the
// confirm is off (name unchanged, name breaking a rule, plan not read yet).
void main() {
  libraryTest('the keyboard Done renames once the plan has settled, as Rename '
      'does', (tester, env) async {
    await _pump(tester, env);
    await _openRename(tester, 'động từ');

    await _type(tester, 'verb');
    await _submit(tester);

    expect(find.byType(MxDialog), findsNothing);
    expect(await _names(env), contains('verb'));
    expect(await _names(env), isNot(contains('động từ')));
  });

  libraryTest('the keyboard Done on a name that merges, merges, as Merge tags '
      'does', (tester, env) async {
    await _pump(tester, env);
    await _openRename(tester, 'động từ');

    await _type(tester, 'NGỮ PHÁP');
    expect(
      find.text(_en.tagsMergeNotice('ngữ pháp', 'động từ')),
      findsOneWidget,
    );
    await _submit(tester);

    expect(find.byType(MxDialog), findsNothing);
    expect(await tagRowsOf(env.db), hasLength(15));
    expect(await _names(env), isNot(contains('động từ')));
  });

  libraryTest('the keyboard Done on the unchanged name does nothing, as the '
      'off Rename does', (tester, env) async {
    await _pump(tester, env);
    await _openRename(tester, 'động từ');

    await tester.tap(find.byType(FTextField).last);
    await tester.pump();
    await _submit(tester);

    expect(find.byType(MxDialog), findsOneWidget);
    expect(await _names(env), contains('động từ'));
  });

  libraryTest('the keyboard Done on a blank name does nothing and says why', (
    tester,
    env,
  ) async {
    await _pump(tester, env);
    await _openRename(tester, 'động từ');

    await _type(tester, '   ');
    await _submit(tester);

    expect(find.byType(MxDialog), findsOneWidget);
    expect(find.text(_en.tagRejectionBlankName), findsOneWidget);
    expect(await _names(env), contains('động từ'));
  });

  libraryTest('the keyboard Done on a name over the limit does nothing and '
      'says why', (tester, env) async {
    await _pump(tester, env);
    await _openRename(tester, 'động từ');

    await _type(tester, 'a' * 51);
    await _submit(tester);

    expect(find.byType(MxDialog), findsOneWidget);
    expect(find.text(_en.tagsNameTooLong(50)), findsOneWidget);
    expect(await _names(env), contains('động từ'));
  });

  libraryTest('the keyboard Done before the new name is planned does nothing, '
      'as the off Rename does', (tester, env) async {
    await _pump(tester, env);
    await _openRename(tester, 'động từ');

    await tester.enterText(find.byType(FTextField).last, 'verb');
    await _submit(tester);

    expect(find.byType(MxDialog), findsOneWidget);
    expect(await _names(env), contains('động từ'));
  });
}
