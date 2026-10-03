import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/usecases/add_tag_to_cards_use_case.dart';
import 'package:memox/features/card/domain/usecases/move_cards_use_case.dart';
import 'package:memox/features/card/presentation/providers/add_tag_to_cards_use_case_provider.dart';
import 'package:memox/features/card/presentation/providers/move_cards_use_case_provider.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';

import '../../../support/held_writes.dart';
import '../../../support/library_harness.dart';
import 'card_bulk_actions_harness.dart';

const _exit = Duration(milliseconds: 500);

Finder _banner(String message) => find.descendant(
  of: find.byType(MxInlineBanner),
  matching: find.text(message),
);

Future<void> _backAndScrim(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pump(_exit);
  await tester.tapAt(const Offset(2, 2));
  await tester.pump(_exit);
}

void main() {
  libraryTest('Move: Back, a scrim tap and Cancel wait for the move; a failure '
      'keeps the sheet with a banner and choosing again retries (SP2b 2.26, '
      '2.27)', (tester, env) async {
    final ids = await seedBulkCards(env);
    final hold = WriteHold();
    await pumpLibraryScreen(
      tester,
      env,
      bulkSection(ids.words),
      overrides: [
        moveCardsUseCaseProvider.overrideWithValue(
          MoveCardsUseCase(HeldCards(env.cards, hold)),
        ),
      ],
    );
    await selectCards(tester, ['annyeong', 'gamsa']);
    await tapBulk(tester, enL10n.cardMove);
    await tester.tap(find.text('Korean › Verbs'));
    await tester.pump();

    await _backAndScrim(tester);
    expect(find.byType(MxDeckPickerSheet), findsOneWidget);
    expect(
      tester
          .widget<MxButton>(find.widgetWithText(MxButton, enL10n.commonCancel))
          .onPressed,
      isNull,
    );

    hold
      ..failNext()
      ..open();
    await tester.pumpAndSettle();
    expect(find.byType(MxDeckPickerSheet), findsOneWidget);
    expect(_banner(enL10n.failure(WriteHold.failure)), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.text('Korean › Verbs'));
    await tester.pumpAndSettle();
    expect(find.byType(MxDeckPickerSheet), findsNothing);
    expect(find.text(enL10n.cardMovedToast(2, 'Verbs')), findsOneWidget);
  });

  libraryTest('Tag: Back, a scrim tap and Cancel wait for the write; a failure '
      'keeps the dialog, the name and the selection (SP2b 2.26, 2.27)', (
    tester,
    env,
  ) async {
    final ids = await seedBulkCards(env);
    final hold = WriteHold();
    await pumpLibraryScreen(
      tester,
      env,
      bulkSection(ids.words),
      overrides: [
        addTagToCardsUseCaseProvider.overrideWithValue(
          AddTagToCardsUseCase(HeldTags(TagRepositoryImpl(env.db), hold)),
        ),
      ],
    );
    await selectCards(tester, ['annyeong', 'gamsa']);
    await tapBulk(tester, enL10n.cardTag);
    await tester.enterText(find.byType(EditableText).last, 'greetings');
    await tester.tap(inDialog(enL10n.cardTagConfirm));
    await tester.pump();
    // The confirm says it is busy (audit m1).
    expect(
      tester
          .widget<MxSheetActions>(find.byType(MxSheetActions))
          .isConfirmLoading,
      isTrue,
    );

    await _backAndScrim(tester);
    expect(find.byType(MxDialog), findsOneWidget);

    hold
      ..failNext()
      ..open();
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsOneWidget);
    expect(find.text('greetings'), findsOneWidget);
    expect(_banner(enL10n.failure(WriteHold.failure)), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is MxSelectionCheckbox && widget.isChecked,
      ),
      findsNWidgets(2),
    );

    await tester.tap(inDialog(enL10n.cardTagConfirm));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
    expect(find.text(enL10n.cardTaggedToast(2, 'greetings')), findsOneWidget);
  });

  libraryTest(
    'Move: a second tap while the move runs does nothing (SP2b 2.26)',
    (tester, env) async {
      final ids = await seedBulkCards(env);
      final hold = WriteHold();
      await pumpLibraryScreen(
        tester,
        env,
        bulkSection(ids.words),
        overrides: [
          moveCardsUseCaseProvider.overrideWithValue(
            MoveCardsUseCase(HeldCards(env.cards, hold)),
          ),
        ],
      );
      await selectCards(tester, ['annyeong', 'gamsa']);
      await tapBulk(tester, enL10n.cardMove);
      await tester.tap(find.text('Korean › Verbs'));
      await tester.pump();
      expect(
        tester
            .widget<MxListRow>(find.widgetWithText(MxListRow, 'Korean › Verbs'))
            .isEnabled,
        isFalse,
      );
      await tester.tap(find.text('Korean › Verbs'), warnIfMissed: false);
      await tester.pump();

      hold.open();
      await tester.pumpAndSettle();
      expect(hold.calls, 1);
      expect(find.text(enL10n.cardMovedToast(2, 'Verbs')), findsOneWidget);
    },
  );
}
