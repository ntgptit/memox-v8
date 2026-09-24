import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/card/domain/models/card_due_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/presentation/widgets/items/card_row_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_flag_mark.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

CardListItem _item({
  String front = 'front',
  String back = 'back',
  bool isFlagged = false,
  CardDue due = const CardDue.newCard(),
  List<String> tags = const [],
  CardDisplayStatus status = CardDisplayStatus.newCard,
}) => CardListItem(
  id: 'c',
  front: front,
  back: back,
  isFlagged: isFlagged,
  dueAt: null,
  displayStatus: status,
  due: due,
  tags: [
    for (final (index, name) in tags.indexed)
      TagEntity(id: 't$index', name: name),
  ],
);

void main() {
  Future<void> pump(
    WidgetTester tester,
    LibraryEnv env,
    CardListItem item, {
    bool isSelecting = false,
    bool isSelected = false,
    double textScale = 1,
  }) => pumpLibraryScreen(
    tester,
    env,
    Scaffold(
      body: Center(
        child: CardRowWidget(
          item: item,
          isSelecting: isSelecting,
          isSelected: isSelected,
          onTap: () {},
          onLongPress: () {},
        ),
      ),
    ),
    textScale: textScale,
  );

  libraryTest(
    'a row: front, back, status label, two tags and +N, flag, due chip',
    (tester, env) async {
      await pump(
        tester,
        env,
        _item(
          isFlagged: true,
          due: const CardDue.overdue(30),
          tags: ['bà', 'Cấu trúc thường gặp', 'TOPIK', 'động từ'],
          status: CardDisplayStatus.reviewing,
        ),
      );

      expect(find.text('front'), findsOneWidget);
      expect(find.text('back'), findsOneWidget);
      expect(
        find.text(_en.cardStatus(CardDisplayStatus.reviewing).toUpperCase()),
        findsOneWidget,
      );
      expect(find.byType(MxTagChip), findsNWidgets(2));
      expect(find.text(_en.cardTagsMore(2)), findsOneWidget);
      expect(find.byType(MxFlagMark), findsOneWidget);
      expect(
        find.widgetWithText(MxBadge, _en.cardDueOverdue(30)),
        findsOneWidget,
      );
    },
  );

  libraryTest('the due chip reads new, today, in N days, N days overdue', (
    tester,
    env,
  ) async {
    for (final (due, label) in [
      (const CardDue.newCard(), _en.cardDueNew),
      (const CardDue.today(), _en.cardDueToday),
      (const CardDue.later(17), _en.cardDueIn(17)),
      (const CardDue.overdue(3), _en.cardDueOverdue(3)),
    ]) {
      await pump(tester, env, _item(due: due));
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  libraryTest('no tags and no flag leave only the status label and the chip', (
    tester,
    env,
  ) async {
    await pump(tester, env, _item());

    expect(find.byType(MxTagChip), findsNothing);
    expect(find.byType(MxFlagMark), findsNothing);
    expect(find.widgetWithText(MxBadge, _en.cardDueNew), findsOneWidget);
  });

  libraryTest('selecting shows a checkbox and edges the selected card', (
    tester,
    env,
  ) async {
    await pump(tester, env, _item(), isSelecting: true, isSelected: true);

    expect(find.byType(MxSelectionCheckbox), findsOneWidget);
    expect(tester.widget<MxCard>(find.byType(MxCard)).isSelected, isTrue);
  });

  libraryTest('a long row at 2x on a 360 phone does not overflow', (
    tester,
    env,
  ) async {
    await pump(
      tester,
      env,
      _item(
        front: '-(으)ㄹ 뿐만 아니라: không những… mà còn…',
        back: 'Nối hai mệnh đề, nhấn mạnh rằng ngoài điều thứ nhất còn có điều thứ hai',
        isFlagged: true,
        due: const CardDue.overdue(30),
        tags: ['Cấu trúc thường gặp trong đề thi', 'TOPIK II nâng cao', 'x'],
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
  });
}
