import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/presentation/widgets/support/card_deck_path_label_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/tag_rejection_message_widget.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';

final _technical = RegExp(
  r'sql|sqlite|exception|/|\\|null|[0-9a-f]{8}-',
  caseSensitive: false,
);

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    final l10n = lookupAppLocalizations(locale);
    final code = locale.languageCode;

    test('screen 07 has $code copy', () {
      for (final copy in [
        l10n.cardSummaryOverline('SM-2'),
        l10n.cardSummaryMastered(80, 420),
        l10n.cardStudyThisDue(40),
        l10n.cardListShowing(7, 420),
        l10n.cardListSelectedOf(2, 420),
        l10n.cardSelectAllCount(420),
        l10n.cardDueIn(17),
        l10n.cardDueOverdue(30),
        l10n.cardTagsMore(8),
        l10n.deckImportCards,
        l10n.deckExportAll,
      ]) {
        expect(copy.trim(), isNotEmpty);
        expect(copy, isNot(contains('{')));
      }
    });

    test('every card and tag rejection has plain $code copy', () {
      for (final reason in CardRejection.values) {
        final copy = l10n.cardRejection(reason);
        expect(copy.trim(), isNotEmpty, reason: reason.name);
        expect(_technical.hasMatch(copy), isFalse, reason: reason.name);
      }
      for (final reason in TagRejection.values) {
        final copy = l10n.tagRejection(reason);
        expect(copy.trim(), isNotEmpty, reason: reason.name);
        expect(_technical.hasMatch(copy), isFalse, reason: reason.name);
      }
    });

    test('every filter, sort and status has $code copy', () {
      for (final filter in CardListFilter.values) {
        expect(l10n.cardFilter(filter).trim(), isNotEmpty);
      }
      for (final sort in CardListSort.values) {
        expect(l10n.cardSort(sort).trim(), isNotEmpty);
      }
      for (final status in CardDisplayStatus.values) {
        expect(l10n.cardStatus(status).trim(), isNotEmpty);
      }
    });
  }

  test('each display status has its badge colour', () {
    expect(CardDisplayStatus.values.map(mxCardStatus), [
      MxCardStatus.newCard,
      MxCardStatus.learning,
      MxCardStatus.reviewing,
      MxCardStatus.mastered,
    ]);
  });

  test('a card target reads root first', () {
    expect(cardDeckPathLabel(['Korean', 'Verbs']), 'Korean › Verbs');
  });
}
