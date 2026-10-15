import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

import '../support/approved_palette.dart';
import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';

// The M3 gates that run through the production root (`MemoxApp` with its real
// theme mode), never through a test-built MaterialApp. Ledger DSD-27 (the
// approved surfaceTint) and M3C-30 (the contrast policy is owned by
// token_contrast_test, so textContrastGuideline is not a gate here).

final _en = lookupAppLocalizations(const Locale('en'));

ColorScheme _schemeOf(Map<String, Color> roles, Brightness brightness) {
  Color role(String name) => roles[name]!;
  return ColorScheme(
    brightness: brightness,
    primary: role('primary'),
    onPrimary: role('onPrimary'),
    primaryContainer: role('primaryContainer'),
    onPrimaryContainer: role('onPrimaryContainer'),
    primaryFixed: role('primaryFixed'),
    primaryFixedDim: role('primaryFixedDim'),
    onPrimaryFixed: role('onPrimaryFixed'),
    onPrimaryFixedVariant: role('onPrimaryFixedVariant'),
    secondary: role('secondary'),
    onSecondary: role('onSecondary'),
    secondaryContainer: role('secondaryContainer'),
    onSecondaryContainer: role('onSecondaryContainer'),
    secondaryFixed: role('secondaryFixed'),
    secondaryFixedDim: role('secondaryFixedDim'),
    onSecondaryFixed: role('onSecondaryFixed'),
    onSecondaryFixedVariant: role('onSecondaryFixedVariant'),
    tertiary: role('tertiary'),
    onTertiary: role('onTertiary'),
    tertiaryContainer: role('tertiaryContainer'),
    onTertiaryContainer: role('onTertiaryContainer'),
    tertiaryFixed: role('tertiaryFixed'),
    tertiaryFixedDim: role('tertiaryFixedDim'),
    onTertiaryFixed: role('onTertiaryFixed'),
    onTertiaryFixedVariant: role('onTertiaryFixedVariant'),
    error: role('error'),
    onError: role('onError'),
    errorContainer: role('errorContainer'),
    onErrorContainer: role('onErrorContainer'),
    surface: role('surface'),
    onSurface: role('onSurface'),
    surfaceDim: role('surfaceDim'),
    surfaceBright: role('surfaceBright'),
    surfaceContainerLowest: role('surfaceContainerLowest'),
    surfaceContainerLow: role('surfaceContainerLow'),
    surfaceContainer: role('surfaceContainer'),
    surfaceContainerHigh: role('surfaceContainerHigh'),
    surfaceContainerHighest: role('surfaceContainerHighest'),
    onSurfaceVariant: role('onSurfaceVariant'),
    outline: role('outline'),
    outlineVariant: role('outlineVariant'),
    shadow: role('shadow'),
    scrim: role('scrim'),
    inverseSurface: role('inverseSurface'),
    onInverseSurface: role('onInverseSurface'),
    inversePrimary: role('inversePrimary'),
  );
}

Future<ThemeData> _pumpApp(
  WidgetTester tester,
  LibraryEnv env,
  ThemeChoice choice,
  Brightness os,
) async {
  tester.platformDispatcher.platformBrightnessTestValue = os;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await SettingsRepositoryImpl(env.db).setTheme(theme: choice);
  await pumpMemoxApp(tester, env);
  final probe = find
      .descendant(of: find.byType(MxBottomNav), matching: find.byType(Text))
      .first;
  return Theme.of(tester.element(probe));
}

/// The colour the shell paints behind the app bar: the `ColoredBox` of its
/// `_AppBarGround`, the nearest one above the bar.
Color _barGround(WidgetTester tester) {
  final ground = find
      .ancestor(of: find.byType(MxAppBar), matching: find.byType(ColoredBox))
      .first;
  expect(
    find.ancestor(of: ground, matching: find.byType(MxAppShell)),
    findsWidgets,
    reason: 'the bar ground belongs to MxAppShell',
  );
  return tester.widget<ColoredBox>(ground).color;
}

Color? _glyphColor(WidgetTester tester, IconData icon) =>
    IconTheme.of(tester.element(find.byIcon(icon))).color;

Finder _barIcons() =>
    find.descendant(of: find.byType(MxAppBar), matching: find.byType(Icon));

Color? _firstBarGlyph(WidgetTester tester) =>
    IconTheme.of(tester.element(_barIcons().first)).color;

Color? _lastBarGlyph(WidgetTester tester) =>
    IconTheme.of(tester.element(_barIcons().last)).color;

Future<void> _scrollUnder(WidgetTester tester) async {
  // The search field's own horizontal scrollable comes first in the tree.
  final body = find.byWidgetPredicate(
    (widget) => widget is Scrollable && widget.axis == Axis.vertical,
  );
  await tester.drag(body.first, const Offset(0, -600));
  await tester.pumpAndSettle();
}

void main() {
  group('the approved palette fixture', () {
    final light = approvedRoles(Brightness.light);

    test('a scheme built from it passes expectM3Roles', () {
      expectM3Roles(_schemeOf(light, Brightness.light), light);
    });

    test('expectM3Roles names the role that differs', () {
      final scheme = _schemeOf(
        light,
        Brightness.light,
      ).copyWith(primary: const Color(0xFF123456));
      expect(
        () => expectM3Roles(scheme, light),
        throwsA(
          isA<TestFailure>().having(
            (failure) => failure.message,
            'message',
            allOf(
              contains('primary: observed='),
              isNot(contains('onPrimary:')),
            ),
          ),
        ),
      );
    });

    test('a fixture short of a role is refused', () {
      final short = {...light}..remove('scrim');
      expect(
        () => expectM3Roles(_schemeOf(light, Brightness.light), short),
        throwsA(isA<TestFailure>()),
      );
    });
  });

  for (final scenario
      in <({ThemeChoice choice, Brightness os, Brightness expected})>[
        (
          choice: ThemeChoice.system,
          os: Brightness.light,
          expected: Brightness.light,
        ),
        (
          choice: ThemeChoice.system,
          os: Brightness.dark,
          expected: Brightness.dark,
        ),
        (
          choice: ThemeChoice.light,
          os: Brightness.dark,
          expected: Brightness.light,
        ),
        (
          choice: ThemeChoice.dark,
          os: Brightness.light,
          expected: Brightness.dark,
        ),
      ]) {
    libraryTest('production root: 45 roles '
        'choice=${scenario.choice.name} os=${scenario.os.name}', (
      tester,
      env,
    ) async {
      final theme = await _pumpApp(tester, env, scenario.choice, scenario.os);
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, scenario.expected);
      expectM3Roles(theme.colorScheme, approvedRoles(scenario.expected));
      expect(
        theme.colorScheme.surfaceTint,
        approvedRole('surfaceTint', scenario.expected),
        reason: 'surfaceTint must equal the approved token (ledger DSD-27)',
      );
    });
  }

  for (final brightness in Brightness.values) {
    final choice = brightness == Brightness.light
        ? ThemeChoice.light
        : ThemeChoice.dark;

    // MxAppBar is a custom bar and MxAppShell paints its ground with a
    // ColoredBox: there is no Material, so no elevation, shadow or tint.
    libraryTest(
      'custom bar: Material elevation/shadow/tint N/A; library root ground '
      'and trailing icons while content scrolls under it, ${brightness.name}',
      (tester, env) async {
        for (var i = 0; i < 40; i++) {
          await env.decks.root('Deck $i');
        }
        final theme = await _pumpApp(tester, env, choice, brightness);
        final scheme = theme.colorScheme;

        expect(_barGround(tester), scheme.surface);
        expect(_glyphColor(tester, AppIcons.tag), scheme.onSurfaceVariant);
        expect(
          _lastBarGlyph(tester),
          scheme.onSurfaceVariant,
          reason: 'trailing actions',
        );

        await _scrollUnder(tester);

        expect(_barGround(tester), scheme.surfaceContainer);
        expect(_glyphColor(tester, AppIcons.tag), scheme.onSurfaceVariant);
        expect(_lastBarGlyph(tester), scheme.onSurfaceVariant);
      },
    );

    libraryTest(
      'custom bar: Material elevation/shadow/tint N/A; open deck ground, '
      'back glyph and trailing action while content scrolls under it, '
      '${brightness.name}',
      (tester, env) async {
        final parent = await env.decks.root('Parent');
        for (var i = 0; i < 40; i++) {
          await env.decks.sub(parent.id, 'Child $i');
        }
        final theme = await _pumpApp(tester, env, choice, brightness);
        final scheme = theme.colorScheme;
        await tester.tap(find.text('Parent'));
        await tester.pumpAndSettle();
        expect(find.byIcon(AppIcons.back), findsOneWidget);

        expect(_barGround(tester), scheme.surface);
        expect(_glyphColor(tester, AppIcons.back), scheme.onSurface);
        expect(_firstBarGlyph(tester), scheme.onSurface, reason: 'leading');
        expect(_lastBarGlyph(tester), scheme.onSurfaceVariant);

        await _scrollUnder(tester);

        expect(_barGround(tester), scheme.surfaceContainer);
        expect(_glyphColor(tester, AppIcons.back), scheme.onSurface);
        expect(_firstBarGlyph(tester), scheme.onSurface);
        expect(_lastBarGlyph(tester), scheme.onSurfaceVariant);
      },
    );
  }

  for (final (label, name) in <(String, String)>[
    (_en.navLibrary, 'library'),
    (_en.navStudy, 'study'),
    (_en.navProgress, 'progress'),
    (_en.navSettings, 'settings'),
  ]) {
    libraryTest('Android guidelines on the $name tab, light', (
      tester,
      env,
    ) async {
      await env.decks.root('Words');
      await _pumpApp(tester, env, ThemeChoice.light, Brightness.light);
      final semantics = tester.ensureSemantics();
      try {
        await tester.tap(
          find.descendant(
            of: find.byType(MxBottomNav),
            matching: find.text(label),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      } finally {
        semantics.dispose();
      }
    });
  }
}
