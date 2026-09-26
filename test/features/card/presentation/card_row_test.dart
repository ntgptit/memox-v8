import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/card/domain/models/card_due_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/presentation/widgets/items/card_row_widget.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

CardListItem _item({
  String front = 'gongbuhada',
  String back = 'hoc, hoc tap',
  bool isFlagged = false,
  CardDisplayStatus status = CardDisplayStatus.reviewing,
  CardDue due = const CardDue.later(17),
  List<String> tags = const [],
}) => CardListItem(
  id: 'c',
  front: front,
  back: back,
  isFlagged: isFlagged,
  dueAt: null,
  displayStatus: status,
  due: due,
  tags: [
    for (final (i, name) in tags.indexed) TagEntity(id: 't$i', name: name),
  ],
);

Widget _host(List<Widget> rows) => Scaffold(body: ListView(children: rows));

void main() {
  libraryTest('a row shows front, back, status, two tags and +N, the flag '
      'and when it is due', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host([
        CardRowWidget(
          item: _item(
            isFlagged: true,
            due: const CardDue.overdue(30),
            tags: ['hay nham', 'TOPIK I', 'dong tu', 'bai 12'],
          ),
          isSelecting: false,
          isSelected: false,
        ),
      ]),
    );

    expect(find.text('gongbuhada'), findsOneWidget);
    expect(find.text('hoc, hoc tap'), findsOneWidget);
    expect(find.text(_en.cardStatusReviewing.toUpperCase()), findsOneWidget);
    expect(find.text('hay nham'), findsOneWidget);
    expect(find.text('TOPIK I'), findsOneWidget);
    expect(find.text('dong tu'), findsNothing);
    expect(find.text(_en.cardMoreTags(2)), findsOneWidget);
    expect(find.text(_en.cardDueOverdue(30)), findsOneWidget);
    expect(find.byIcon(Icons.flag), findsOneWidget);
  });

  libraryTest('the row names its status once to a screen reader', (
    tester,
    env,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpLibraryScreen(
      tester,
      env,
      _host([
        CardRowWidget(item: _item(), isSelecting: false, isSelected: false),
      ]),
    );
    // The front's node is the row's merged node.
    final label = tester
        .getSemantics(find.text('gongbuhada'))
        .getSemanticsData()
        .label
        .toLowerCase();
    final status = _en.cardStatusReviewing.toLowerCase();

    expect(status.allMatches(label), hasLength(1), reason: label);
    semantics.dispose();
  });

  libraryTest('selecting shows a checkbox, checked when selected', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host([
        CardRowWidget(item: _item(), isSelecting: true, isSelected: true),
      ]),
    );

    expect(find.byType(MxSelectionCheckbox), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(CardRowWidget)),
      isSemantics(isChecked: true),
    );
  });

  libraryTest('each due kind reads as the handoff says', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host([
        for (final due in const [
          CardDue.newCard(),
          CardDue.today(),
          CardDue.later(17),
          CardDue.overdue(30),
        ])
          CardRowWidget(
            item: _item(due: due),
            isSelecting: false,
            isSelected: false,
          ),
      ]),
    );

    for (final label in [
      _en.cardDueNew,
      _en.cardDueToday,
      _en.cardDueIn(17),
      _en.cardDueOverdue(30),
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  libraryTest('a row holds at 2x and meets the target guidelines', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host([
        CardRowWidget(
          item: _item(
            front: 'a long front that runs well past the row width',
            back: 'and a long back that also runs past it',
            isFlagged: true,
            due: const CardDue.overdue(30),
            tags: [
              'Cau truc thuong gap trong de thi',
              'TOPIK II',
              'a',
              'b',
              'c',
            ],
          ),
          isSelecting: false,
          isSelected: false,
          onTap: () {},
        ),
      ]),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });

  libraryTest('while selecting, the checkbox is centred on a tall row', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host([
        CardRowWidget(
          item: _item(
            back: 'a back long enough to need its full line in the row',
            isFlagged: true,
            tags: ['hay nham', 'TOPIK I', 'dong tu'],
          ),
          isSelecting: true,
          isSelected: false,
        ),
      ]),
    );
    final box = tester.getRect(find.byType(MxSelectionCheckbox));
    final card = tester.getRect(
      find.descendant(
        of: find.byType(CardRowWidget),
        matching: find.byType(MxCard),
      ),
    );

    expect(box.center.dy, closeTo(card.center.dy, 0.5));
  });
}
