import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';

import '../support/approved_palette.dart';
import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';
import '../support/app_harness.dart';

// The one approved scrim (tokens.json `scrim` at `opacityScrim`) on the
// route barriers of the overlays the production helpers push (ledger DSD-28,
// DSD-35). The Drawer test is NOT_APPLICABLE: lib/ has no Drawer (DSD-02).

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _openActionSheet(WidgetTester tester) async {
  await tester.tap(find.byTooltip(_en.deckMoreActions('Words')));
  await tester.pumpAndSettle();
}

Color _expectedBarrier(
  WidgetTester tester,
  Finder overlay,
  Brightness brightness,
) {
  final dimens = Theme.of(tester.element(overlay.first))
      .extension<AppDimens>()!;
  return approvedRole(
    'scrim',
    brightness,
  ).withValues(alpha: dimens.opacityScrim);
}

void main() {
  for (final brightness in Brightness.values) {
    final choice = brightness == Brightness.light
        ? ThemeChoice.light
        : ThemeChoice.dark;

    Future<void> pumpWithDeck(WidgetTester tester, LibraryEnv env) async {
      await SettingsRepositoryImpl(env.db).setTheme(theme: choice);
      await env.decks.root('Words');
      await pumpMemoxApp(tester, env);
    }

    libraryTest('action sheet: the pushed route carries the approved scrim, '
        '${brightness.name}', (tester, env) async {
      await pumpWithDeck(tester, env);
      await _openActionSheet(tester);

      final route = ModalRoute.of(
        tester.element(find.byType(MxBottomSheet).first),
      )!;
      expect(route, isA<ModalBottomSheetRoute<Object?>>());
      expect(
        route.barrierColor,
        _expectedBarrier(tester, find.byType(MxBottomSheet), brightness),
      );
    });

    libraryTest('action sheet: Material elevation, shadow and tint are the '
        'theme\'s sheet, ${brightness.name}', (tester, env) async {
      await pumpWithDeck(tester, env);
      await _openActionSheet(tester);

      final sheets = Theme.of(tester.element(find.byType(MxBottomSheet).first))
          .bottomSheetTheme;
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(MxBottomSheet),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.elevation, sheets.modalElevation);
      expect(material.shadowColor, sheets.shadowColor);
      // MxBottomSheet passes no tint, and a Material with none draws none:
      // the same "no tint" the theme's transparent slot states.
      expect(sheets.surfaceTintColor, Colors.transparent);
      expect(
        material.surfaceTintColor ?? Colors.transparent,
        Colors.transparent,
      );
      expect(sheets.modalElevation, 1);
      expect(sheets.shadowColor, Colors.transparent);
    });

    libraryTest('delete dialog: the pushed route carries the approved scrim, '
        '${brightness.name}', (tester, env) async {
      await pumpWithDeck(tester, env);
      await _openActionSheet(tester);
      await tester.tap(find.text(_en.deckDelete));
      await tester.pumpAndSettle();

      final dialog = find.byType(DeckDeleteDialogWidget);
      expect(dialog, findsOneWidget);
      final route = ModalRoute.of(tester.element(dialog))!;
      expect(route, isA<RawDialogRoute<Object?>>());
      expect(route.barrierColor, _expectedBarrier(tester, dialog, brightness));
    });
  }
}
