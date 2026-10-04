import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/states/session_context_state.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/study_fixtures.dart';

// The context line shows the app's words upper-cased and the deck name as
// typed, in both languages (critique 2026-09-30 part 2, P4).
void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    test('the deck name keeps its case (${locale.languageCode})', () {
      final l10n = lookupAppLocalizations(locale);
      final view = summaryView(kind: SessionKind.reviewing);
      final shown = sessionContextShownOf(l10n, view);
      final plain = sessionContextOf(l10n, view);

      expect(view.deckName, 'Nhà hàng');
      expect(shown, contains('Nhà hàng'));
      expect(shown, isNot(contains('NHÀ HÀNG')));
      expect(
        shown.replaceAll('Nhà hàng', ''),
        plain.replaceAll('Nhà hàng', '').toUpperCase(),
      );
    });
  }
}
