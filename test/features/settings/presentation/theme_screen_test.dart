import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/screens/theme_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_note.dart';

import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

final _en = lookupAppLocalizations(const Locale('en'));

String _card(String name, String hint) => _en.settingsThemeCard(name, hint);

final _system = _card(_en.settingsThemeSystem, _en.settingsThemeSystemHint);
final _dark = _card(_en.settingsThemeDark, _en.settingsThemeDarkHint);

bool _isSelected(WidgetTester tester, String label) => tester
    .getSemantics(find.bySemanticsLabel(label))
    .flagsCollection
    .isSelected
    .toBoolOrNull()!;

void main() {
  libraryTest('the stored theme is selected; a tap saves another and selects '
      'it (UC-SETTINGS-001 step 4)', (tester, env) async {
    final handle = tester.ensureSemantics();
    await pumpLibraryScreen(tester, env, const ThemeScreen());
    expect(_isSelected(tester, _system), isTrue);

    await tester.tap(find.text(_en.settingsThemeDark));
    await tester.pumpAndSettle();

    expect(_isSelected(tester, _dark), isTrue);
    expect(_isSelected(tester, _system), isFalse);
    handle.dispose();
  });

  libraryTest('a failed save keeps the stored theme and offers Retry, which '
      'saves it (E2)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
      ..isFailing = true;
    await pumpLibraryScreen(
      tester,
      env,
      const ThemeScreen(),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );
    await tester.tap(find.text(_en.settingsThemeDark));
    await tester.pumpAndSettle();

    expect(find.text(_en.settingsThemeSaveFailed), findsOneWidget);
    expect(_isSelected(tester, _system), isTrue);

    store.isFailing = false;
    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();
    expect(_isSelected(tester, _dark), isTrue);
    handle.dispose();
  });

  libraryTest('at 1x the three cards sit side by side, as the kit draws '
      'them', (tester, env) async {
    await pumpLibraryScreen(tester, env, const ThemeScreen());

    expect(
      tester.getTopLeft(find.text(_en.settingsThemeLight)).dy,
      tester.getTopLeft(find.text(_en.settingsThemeSystem)).dy,
    );
  });

  libraryTest('a failed read shows the error with Retry and no invented '
      'choice (E3)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const ThemeScreen(),
      overrides: [
        appSettingsProvider.overrideWith(
          (ref) => Stream.error(FlakySettingsRepository.failure),
        ),
      ],
    );

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.text(_en.settingsLoadErrorTitle), findsOneWidget);
    expect(find.text(_en.settingsThemeDark), findsNothing);
    expect(find.textContaining('memox.sqlite'), findsNothing);
  });

  libraryTest('the applies-at-once note is the footnote form, as Language and '
      'Settings have it (critique 2026-09-30 3a)', (tester, env) async {
    await pumpLibraryScreen(tester, env, const ThemeScreen());

    final note = find.byWidgetPredicate((w) => w is MxNote && w.isHint);
    expect(note, findsOneWidget);
    expect(
      find.descendant(of: note, matching: find.text(_en.settingsAppliesAtOnce)),
      findsOneWidget,
    );
  });

  // SW-REV-005: the card's one TalkBack node keeps the tap its excluded
  // child offered.
  libraryTest('TalkBack can choose a theme: the card keeps its tap', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpLibraryScreen(tester, env, const ThemeScreen());
    expect(
      tester.getSemantics(find.bySemanticsLabel(_dark)),
      isSemantics(hasTapAction: true),
    );
    handle.dispose();
  });

  libraryTest('the chosen theme wears a check in the primary foreground role', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, const ThemeScreen());

    final check = find.byIcon(AppIcons.check);
    expect(check, findsOneWidget);
    expect(
      tester.widget<Icon>(check).color,
      tester.element(check).semanticColors.primaryForeground,
    );
  });
}
