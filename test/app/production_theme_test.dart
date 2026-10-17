import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_delete_dialog_widget.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';

import '../support/app_harness.dart';
import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';
import '../support/forui_expect.dart';

// The theme gates that run through the production root (`MemoxApp` with its
// real theme mode), never through a test-built MaterialApp (ADR-026): the
// mode picks the ForUI theme, the routes and overlays the root navigator
// shows inherit it, and the SDK host theme follows it.

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _pumpApp(
  WidgetTester tester,
  LibraryEnv env,
  ThemeChoice choice,
  Brightness os,
) async {
  tester.platformDispatcher.platformBrightnessTestValue = os;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await SettingsRepositoryImpl(env.db).setTheme(theme: choice);
  await pumpMemoxApp(tester, env);
}

Finder get _navProbe => find
    .descendant(of: find.byType(MxBottomNav), matching: find.byType(Text))
    .first;

Future<void> _openActionSheet(WidgetTester tester) async {
  await tester.tap(byControlLabel(_en.deckMoreActions('Words')));
  await tester.pumpAndSettle();
}

/// The border the shell draws under the app bar: the side of the decorated
/// ground nearest above the bar.
Color _barEdge(WidgetTester tester) {
  final ground = find
      .ancestor(
        of: find.byType(MxAppBar),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).border != null,
        ),
      )
      .first;
  expect(
    find.ancestor(of: ground, matching: find.byType(MxAppShell)),
    findsWidgets,
    reason: 'the bar ground belongs to MxAppShell',
  );
  final decoration = tester.widget<DecoratedBox>(ground).decoration;
  return ((decoration as BoxDecoration).border! as Border).bottom.color;
}

Future<void> _scrollUnder(WidgetTester tester) async {
  final body = find.byWidgetPredicate(
    (widget) => widget is Scrollable && widget.axis == Axis.vertical,
  );
  await tester.drag(body.first, const Offset(0, -600));
  await tester.pumpAndSettle();
}

void main() {
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
    libraryTest('production root: the ForUI theme and its host follow '
        'choice=${scenario.choice.name} os=${scenario.os.name}', (
      tester,
      env,
    ) async {
      await _pumpApp(tester, env, scenario.choice, scenario.os);
      final element = tester.element(_navProbe);

      expect(FTheme.of(element), themeFor(scenario.expected));
      expect(
        FTheme.of(element).colors,
        scenario.expected == Brightness.light ? appLightColors : appDarkColors,
      );
      final host = Theme.of(element);
      expect(host.colorScheme.brightness, scenario.expected);
      expect(host.scaffoldBackgroundColor, element.colors.background);
    });
  }

  for (final brightness in Brightness.values) {
    final choice = brightness == Brightness.light
        ? ThemeChoice.light
        : ThemeChoice.dark;
    final colors = brightness == Brightness.light
        ? appLightColors
        : appDarkColors;

    Future<void> pumpWithDeck(WidgetTester tester, LibraryEnv env) async {
      await env.decks.root('Words');
      await _pumpApp(tester, env, choice, brightness);
    }

    libraryTest('action sheet: the root-navigator route inherits the ForUI '
        "theme and draws ForUI's barrier, ${brightness.name}", (
      tester,
      env,
    ) async {
      await pumpWithDeck(tester, env);
      await _openActionSheet(tester);
      final sheet = find.byType(MxBottomSheet).first;

      expect(FTheme.of(tester.element(sheet)).colors, colors);
      expect(
        ModalRoute.of(tester.element(sheet)),
        isA<FModalSheetRoute<Object?>>(),
      );
      expect(colors.barrier.a, greaterThan(0));
    });

    libraryTest('delete dialog: the route inherits the ForUI theme, '
        '${brightness.name}', (tester, env) async {
      await pumpWithDeck(tester, env);
      await _openActionSheet(tester);
      await tester.tap(find.text(_en.deckDelete));
      await tester.pumpAndSettle();

      final dialog = find.byType(DeckDeleteDialogWidget);
      expect(dialog, findsOneWidget);
      expect(FTheme.of(tester.element(dialog)).colors, colors);
      expect(
        ModalRoute.of(tester.element(dialog)),
        isA<FDialogRoute<Object?>>(),
      );
    });

    libraryTest('the app bar ground is the page, with ForUI\'s border once '
        'content scrolls under it, ${brightness.name}', (tester, env) async {
      for (var i = 0; i < 40; i++) {
        await env.decks.root('Deck $i');
      }
      await _pumpApp(tester, env, choice, brightness);

      expect(_barEdge(tester).a, 0);

      await _scrollUnder(tester);

      expect(_barEdge(tester), colors.border);
    });
  }

  libraryTest('switching the theme keeps the route and its stack '
      '(BR-SETTINGS-005)', (tester, env) async {
    final parent = await env.decks.root('Parent');
    await env.decks.sub(parent.id, 'Child');
    await _pumpApp(tester, env, ThemeChoice.light, Brightness.light);
    await tester.tap(find.text('Parent'));
    await tester.pumpAndSettle();
    expect(find.text('Child'), findsOneWidget);

    await SettingsRepositoryImpl(env.db).setTheme(theme: ThemeChoice.dark);
    await tester.pumpAndSettle();

    expect(find.text('Child'), findsOneWidget, reason: 'still on Parent');
    expect(FTheme.of(tester.element(find.text('Child'))).colors, appDarkColors);
  });

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
