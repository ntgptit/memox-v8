import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/trash/presentation/providers/trash_entries_provider.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:flutter/rendering.dart';
import 'package:memox/shared/widgets/mx_badge.dart';

import '../../../support/library_harness.dart';
import '../../../support/trash_screen_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Finder _chip(String label) =>
    find.descendant(of: find.byType(MxFilterChip), matching: find.text(label));

void main() {
  libraryTest('entries read newest first with their kind, age, time left and '
      'origin (UC-TRASH-001 step 3)', (tester, env) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());

    expect(find.text(_en.trashNote), findsOneWidget);
    expect(find.text(_en.trashEntriesHeader(4).toUpperCase()), findsOneWidget);
    final names = ['meokda · eat', 'Basics', 'Places', 'homework · bai tap'];
    final tops = [
      for (final name in names) tester.getTopLeft(find.text(name)).dy,
    ];
    expect(tops, [...tops]..sort());

    expect(
      find.text(_en.trashCardMeta(_en.trashDeletedMinutes(4))),
      findsOneWidget,
    );
    expect(
      find.text(_en.trashDeckMeta(1, 2, _en.trashDeletedYesterday)),
      findsOneWidget,
    );
    expect(find.text(_en.trashDaysLeft(30)), findsOneWidget);
    expect(find.text(_en.trashDaysLeft(2)), findsOneWidget);
    expect(find.text(_en.trashHoursLeft(1)), findsOneWidget);
    expect(find.text(_en.trashWasIn('Korean › Words')), findsNWidgets(2));
    expect(find.text(_en.trashWasIn(_en.trashTopLevel)), findsOneWidget);
  });

  libraryTest('each filter counts its kind and shows only it (A6)', (
    tester,
    env,
  ) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());

    await tester.tap(_chip(_en.trashFilterDecks));
    await tester.pumpAndSettle();
    expect(find.text('Basics'), findsOneWidget);
    expect(find.text('meokda · eat'), findsNothing);
    expect(find.text(_en.trashEntriesHeader(2).toUpperCase()), findsOneWidget);

    await tester.tap(_chip(_en.trashFilterCards));
    await tester.pumpAndSettle();
    expect(find.text('Basics'), findsNothing);
    expect(find.text('homework · bai tap'), findsOneWidget);
  });

  libraryTest('an empty Trash says so, with no note and no filters', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, const TrashScreen());

    expect(find.text(_en.trashEmptyTitle), findsOneWidget);
    expect(find.text(_en.trashEmptyBody), findsOneWidget);
    expect(find.text(_en.trashNote), findsNothing);
    expect(find.byType(MxFilterChip), findsNothing);
  });

  libraryTest('a failed read says so; Retry reads again (E5)', (
    tester,
    env,
  ) async {
    var reads = 0;
    await pumpLibraryScreen(
      tester,
      env,
      const TrashScreen(),
      overrides: [
        trashEntriesProvider.overrideWith((ref) {
          reads++;
          return Stream.error(StateError('read failed'));
        }),
      ],
    );

    expect(find.text(_en.trashLoadErrorTitle), findsOneWidget);
    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();
    expect(reads, 2);
  });

  libraryTest('while the entries load, skeleton rows stand in', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      const TrashScreen(),
      overrides: [
        trashEntriesProvider.overrideWith((ref) => const Stream.empty()),
      ],
    );

    expect(find.byType(MxSkeletonList), findsOneWidget);
  });

  libraryTest('⋮ offers Restore… and Delete permanently for its entry', (
    tester,
    env,
  ) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());

    await tester.tap(find.byTooltip(_en.trashEntryActions('meokda · eat')));
    await tester.pumpAndSettle();
    expect(
      find.text(_en.trashCardActionsMeta(_en.trashDeletedMinutes(4), 'Words')),
      findsOneWidget,
    );
    expect(find.text(_en.trashRestore), findsOneWidget);
    expect(find.text(_en.trashDeletePermanently), findsOneWidget);
  });

  libraryTest('a row is one TalkBack node with every fact (spec D15)', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());

    expect(
      find.bySemanticsLabel(
        'Places, ${_en.trashDeckMeta(0, 3, _en.trashDeletedDays(28))}, '
        '${_en.trashDaysLeft(2)}, ${_en.trashWasIn('Korean')}',
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  libraryTest('a long meta line wraps to two lines instead of ellipsizing', (
    tester,
    env,
  ) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());

    final meta = find.textContaining('3 cards');
    expect(tester.widget<Text>(meta).maxLines, 2);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: meta, matching: find.byType(RichText)),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
  });

  libraryTest('an entry that expires within three days shows a warning pill; '
      'the others keep plain text', (tester, env) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());

    final pill = tester.widget<MxBadge>(
      find.widgetWithText(MxBadge, _en.trashDaysLeft(2)),
    );
    expect(pill.tone, MxBadgeTone.warning);
    expect(find.widgetWithText(MxBadge, _en.trashDaysLeft(30)), findsNothing);
    expect(find.text(_en.trashDaysLeft(30)), findsOneWidget);
  });
}
