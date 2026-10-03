import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/overlays/import_undo_dialog_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/library_harness.dart';

// The count confirm on a 360dp phone (SP2a audit M3): "Move 12 cards to
// Trash" is too long for its share of the row, so MxActionPair stacks the
// pair and the label stays whole on one line.

const _count = 12;
final _ids = {for (var i = 0; i < _count; i++) 'card$i'};

void main() {
  final dialogs = <String, Widget Function()>{
    'delete': () => CardDeleteDialogWidget(cardIds: _ids),
    'undo import': () =>
        const ImportUndoDialogWidget(deckId: 'deck', count: _count),
  };
  for (final MapEntry(key: name, value: dialog) in dialogs.entries) {
    for (final locale in AppLocalizations.supportedLocales) {
      libraryTest(
        '$name dialog, ${locale.languageCode}: the count label stays whole '
        'on a 360dp phone',
        (tester, env) async {
          await pumpLibraryScreen(tester, env, dialog(), locale: locale);
          final l10n = lookupAppLocalizations(locale);
          final confirm = find.widgetWithText(
            MxButton,
            l10n.cardMoveToTrashCount(_count),
          );
          final cancel = find.widgetWithText(MxButton, l10n.commonCancel);

          final label = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: confirm,
              matching: find.text(l10n.cardMoveToTrashCount(_count)),
            ),
          );
          expect(label.didExceedMaxLines, isFalse);
          expect(label.size.width, label.getMaxIntrinsicWidth(double.infinity));
          // Stacked: Cancel on top, the confirm under it, both full width.
          expect(
            tester.getTopLeft(confirm).dy,
            greaterThanOrEqualTo(tester.getBottomLeft(cancel).dy),
          );
          expect(tester.getSize(confirm).width, tester.getSize(cancel).width);
        },
      );
    }
  }
}
