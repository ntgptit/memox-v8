import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_rejection_message_widget.dart';
import 'package:memox/features/trash/presentation/widgets/support/trash_rejection_message_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    final l10n = lookupAppLocalizations(locale);

    test('a refused restore reads as the card and deck features say it '
        '(${locale.languageCode})', () {
      for (final reason in CardRejection.values) {
        expect(
          l10n.trashCardRejection(reason),
          l10n.cardRejection(reason),
          reason: reason.name,
        );
      }
      for (final reason in DeckRejection.values) {
        expect(
          l10n.trashDeckRejection(reason),
          l10n.deckRejection(reason),
          reason: reason.name,
        );
      }
    });
  }
}
