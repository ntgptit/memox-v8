import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_level_query_label_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_rejection_message_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

final _technical = RegExp(
  r'sql|sqlite|exception|/|\\|null|[0-9a-f]{8}-',
  caseSensitive: false,
);

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    final l10n = lookupAppLocalizations(locale);

    test('every deck rejection has plain ${locale.languageCode} copy', () {
      for (final reason in DeckRejection.values) {
        final copy = l10n.deckRejection(reason);
        expect(copy.trim(), isNotEmpty, reason: reason.name);
        expect(_technical.hasMatch(copy), isFalse, reason: reason.name);
      }
    });

    test('every sort and filter has ${locale.languageCode} copy', () {
      for (final sort in DeckLevelSort.values) {
        expect(l10n.deckSort(sort).trim(), isNotEmpty);
      }
      for (final filter in DeckLevelFilter.values) {
        expect(l10n.deckFilter(filter).trim(), isNotEmpty);
      }
    });
  }
}
