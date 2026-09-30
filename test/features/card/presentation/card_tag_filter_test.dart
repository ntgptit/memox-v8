import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/items/card_row_widget.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_tag_filter_sheet_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

// Screen 07's tag filter (FE-B2 spec D3, D12, D14; UC-TAG-001 steps 6-8,
// A4, A5, A7).

final _en = lookupAppLocalizations(const Locale('en'));

Widget _section(String deckId) => Scaffold(
  body: CardListSectionWidget(
    deckId: deckId,
    algorithm: 'Eight boxes',
    onAddCard: () {},
    onOpenCard: (_) {},
  ),
);

/// Korean › Words: annyeong and gamsa are verbs, mul is a noun, sarang has
/// no tag; "travel" is on a card of another deck only.
Future<String> _seed(LibraryEnv env, {int extraTags = 0}) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  final other = await env.decks.sub(korean.id, 'Other');
  for (final (id, front) in [
    ('a', 'annyeong'),
    ('g', 'gamsa'),
    ('m', 'mul'),
    ('s', 'sarang'),
  ]) {
    await insertCard(env.db, id: id, deckId: words.id, front: front);
  }
  await insertCard(env.db, id: 'o', deckId: other.id, front: 'yeohaeng');
  final tags = TagRepositoryImpl(env.db);
  await tags.attachByName(cardIds: {'a', 'g'}, name: 'verb');
  await tags.attachByName(cardIds: {'m'}, name: 'noun');
  await tags.attachByName(cardIds: {'o'}, name: 'travel');
  for (var i = 0; i < extraTags; i++) {
    await tags.attachByName(cardIds: {'s'}, name: 'extra $i');
  }
  return words.id;
}

/// [text] inside the sheet: a card's row also shows its tags.
Finder _inSheet(String text) => find.descendant(
  of: find.byType(CardTagFilterSheetWidget),
  matching: find.text(text),
);

MxFilterChip _tagsChip(WidgetTester tester) => tester.widget<MxFilterChip>(
  find.widgetWithText(MxFilterChip, _en.cardFilterTags),
);

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(MxFilterChip, _en.cardFilterTags));
  await tester.pumpAndSettle();
}

Future<void> _apply(WidgetTester tester) async {
  await tester.tap(find.text(_en.cardTagFilterApply));
  await tester.pumpAndSettle();
}

List<String> _fronts(WidgetTester tester) => [
  for (final row in tester.widgetList<CardRowWidget>(
    find.byType(CardRowWidget),
  ))
    row.item.front,
];

void main() {
  libraryTest('none chosen: every tag with its cards in this deck, 0 '
      'included, in the catalog order; Clear is off', (tester, env) async {
    await pumpLibraryScreen(tester, env, _section(await _seed(env)));

    expect(_tagsChip(tester).isSelected, isFalse);
    await _openSheet(tester);

    expect(find.text(_en.cardTagFilterTitle), findsOneWidget);
    expect(find.text(_en.cardTagFilterNone), findsOneWidget);
    for (final (name, count) in [('noun', 1), ('travel', 0), ('verb', 2)]) {
      expect(_inSheet(name), findsOneWidget);
      expect(find.text(_en.cardTagFilterCount(count)), findsWidgets);
    }
    expect(
      tester
          .widget<MxButton>(
            find.widgetWithText(MxButton, _en.cardTagFilterClear),
          )
          .onPressed,
      isNull,
    );
    expect(find.byType(MxSearchField), findsNothing);
  });

  libraryTest('one, then several: Apply shows the cards with any of them, '
      'and the chip says how many are applied (steps 7-8)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _section(await _seed(env)));
    await _openSheet(tester);
    await tester.tap(_inSheet('verb'));
    await tester.pump();
    expect(find.text(_en.cardTagFilterChosen(1)), findsOneWidget);
    await _apply(tester);

    expect(_fronts(tester)..sort(), ['annyeong', 'gamsa']);
    expect((_tagsChip(tester).isSelected, _tagsChip(tester).count), (true, 1));

    await _openSheet(tester);
    await tester.tap(_inSheet('noun'));
    await tester.pump();
    expect(find.text(_en.cardTagFilterChosen(2)), findsOneWidget);
    await _apply(tester);

    expect(_fronts(tester)..sort(), ['annyeong', 'gamsa', 'mul']);
    expect(_tagsChip(tester).count, 2);
  });

  libraryTest('closing without Apply keeps what was applied (A5)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _section(await _seed(env)));
    await _openSheet(tester);
    await tester.tap(_inSheet('verb'));
    await _apply(tester);
    await _openSheet(tester);
    await tester.tap(_inSheet('noun'));
    await tester.pump();
    await tester.tapAt(const Offset(180, 20));
    await tester.pumpAndSettle();

    expect(_fronts(tester)..sort(), ['annyeong', 'gamsa']);
    expect(_tagsChip(tester).count, 1);
  });

  libraryTest('Clear empties the choice and Apply shows every card again '
      '(A4)', (tester, env) async {
    await pumpLibraryScreen(tester, env, _section(await _seed(env)));
    await _openSheet(tester);
    await tester.tap(_inSheet('verb'));
    await _apply(tester);
    await _openSheet(tester);
    await tester.tap(find.text(_en.cardTagFilterClear));
    await tester.pump();

    expect(find.text(_en.cardTagFilterNone), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
    await _apply(tester);

    expect(_fronts(tester), hasLength(4));
    expect(_tagsChip(tester).isSelected, isFalse);
  });

  libraryTest('a tag with no card here shows none, and offers to clear the '
      'tag filter (A7)', (tester, env) async {
    await pumpLibraryScreen(tester, env, _section(await _seed(env)));
    await _openSheet(tester);
    await tester.tap(_inSheet('travel'));
    await _apply(tester);

    expect(find.text(_en.cardTagFilterEmptyTitle), findsOneWidget);
    await tester.tap(find.text(_en.cardClearTagFilter));
    await tester.pumpAndSettle();

    expect(_fronts(tester), hasLength(4));
    expect(_tagsChip(tester).isSelected, isFalse);
  });

  libraryTest('a tag deleted meanwhile leaves the applied set (D12)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _section(await _seed(env)));
    await _openSheet(tester);
    await tester.tap(_inSheet('verb'));
    await tester.tap(_inSheet('noun'));
    await _apply(tester);
    final verb = await env.db
        .customSelect(
          'SELECT id FROM tags WHERE name = ?',
          variables: [const Variable<String>('verb')],
        )
        .getSingle();
    await TagRepositoryImpl(env.db).deleteTag(tagId: verb.read<String>('id'));
    await tester.pumpAndSettle();

    expect(_tagsChip(tester).count, 1);
    expect(_fronts(tester), ['mul']);
  });

  libraryTest('above eight tags a search heads the list; a chosen tag it '
      'hides stays chosen', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _section(await _seed(env, extraTags: 6)),
    );
    await _openSheet(tester);
    expect(find.byType(MxSearchField), findsOneWidget);

    await tester.tap(_inSheet('noun'));
    await tester.enterText(find.byType(TextField), 'VER');
    await tester.pump();

    expect(_inSheet('noun'), findsNothing);
    expect(_inSheet('verb'), findsOneWidget);
    expect(find.text(_en.cardTagFilterChosen(1)), findsOneWidget);
    await tester.tap(_inSheet('verb'));
    await _apply(tester);
    expect(_tagsChip(tester).count, 2);
  });

  libraryTest('no tag in the library: the sheet says where tags come from '
      'and closes', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'a', deckId: words.id, front: 'annyeong');
    await pumpLibraryScreen(tester, env, _section(words.id));
    await _openSheet(tester);

    expect(find.text(_en.cardTagFilterEmpty), findsOneWidget);
    await tester.tap(find.text(_en.cardTagFilterClose));
    await tester.pumpAndSettle();
    expect(find.text(_en.cardTagFilterTitle), findsNothing);
  });

  libraryTest('in Vietnamese the sheet fits a 360 dp phone, '
      'with 48 dp targets', (tester, env) async {
    final vi = lookupAppLocalizations(const Locale('vi'));
    await pumpLibraryScreen(
      tester,
      env,
      _section(await _seed(env, extraTags: 6)),
      locale: const Locale('vi'),
    );
    await tester.ensureVisible(
      find.widgetWithText(MxFilterChip, vi.cardFilterTags),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MxFilterChip, vi.cardFilterTags));
    await tester.pumpAndSettle();
    await tester.tap(_inSheet('extra 0'));
    await tester.pump();

    expect(find.text(vi.cardTagFilterChosen(1)), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });
}
