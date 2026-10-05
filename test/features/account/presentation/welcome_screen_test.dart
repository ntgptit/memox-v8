import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/features/account/data/repositories/account_device_repository_impl.dart';
import 'package:memox/features/account/presentation/providers/welcome_due_provider.dart';
import 'package:memox/features/account/presentation/screens/welcome_screen.dart';
import 'package:memox/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

import '../../../support/account_harness.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  late int dones;
  late int emails;

  setUp(() {
    dones = 0;
    emails = 0;
  });

  WelcomeScreen screen() =>
      WelcomeScreen(onDone: () => dones++, onEmail: () => emails++);

  final shown = welcomeDueProvider.overrideWithBuild((ref, _) => true);

  bool isDue(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(WelcomeScreen)))
          .read(welcomeDueProvider);

  accountTest('the title names the route for TalkBack', (
    tester,
    env,
    world,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [...accountOverrides(world), shown],
    );

    final node = tester.getSemantics(find.text(_en.appTitle));
    expect(node.hasFlag(SemanticsFlag.namesRoute), isTrue);
    expect(node.hasFlag(SemanticsFlag.isHeader), isTrue);
    handle.dispose();
  });

  accountTest('Continue without an account answers Welcome for good and '
      'goes on', (tester, env, world) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [...accountOverrides(world), shown],
    );

    await tester.tap(find.text(_en.accountContinueWithout));
    await _settle(tester);

    expect(dones, 1);
    expect(isDue(tester), isFalse);
    expect(await AccountDeviceRepositoryImpl(env.db).isWelcomeSeen(), isTrue);
  });

  accountTest('Google attaches the account, says so and goes on', (
    tester,
    env,
    world,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [...accountOverrides(world), shown],
    );

    await tester.tap(find.text(_en.accountContinueGoogle));
    await _settle(tester);

    expect(dones, 1);
    expect(isDue(tester), isFalse);
    expect(find.text(_en.accountSignedInAs('g@example.com')), findsOneWidget);
  });

  accountTest('while Google signs in, Welcome keeps its ways and never '
      'looks offline (final review F2)', (tester, env, world) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [...accountOverrides(world), shown],
    );
    final held = world.api.holdMe = Completer<void>();

    await tester.tap(find.text(_en.accountContinueGoogle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(_en.accountContinueGoogle), findsOneWidget);
    expect(find.text(_en.accountContinueEmail), findsOneWidget);
    expect(find.text(_en.accountOfflineNote), findsNothing);
    final without = tester.widget<MxButton>(
      find.widgetWithText(MxButton, _en.accountContinueWithout),
    );
    expect(without.tone, MxButtonTone.text);

    held.complete();
    world.api.holdMe = null;
    await _settle(tester);
    expect(dones, 1);
  });

  accountTest('Continue with email goes to screen 30', (
    tester,
    env,
    world,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [...accountOverrides(world), shown],
    );

    await tester.tap(find.text(_en.accountContinueEmail));
    await _settle(tester);

    expect(emails, 1);
    expect(isDue(tester), isFalse);
  });

  accountTest('first launch offline: sign-in waits and says why, and '
      'without still leaves (Review Focus 1)', (tester, env, world) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [
        ...accountOverrides(world),
        shown,
        authStateOf(const LocalOnly()),
      ],
    );

    expect(find.text(_en.accountContinueGoogle), findsNothing);
    expect(find.text(_en.accountContinueEmail), findsNothing);
    final without = tester.widget<MxButton>(
      find.widgetWithText(MxButton, _en.accountContinueWithout),
    );
    expect(without.tone, MxButtonTone.primary);
    expect(
      find.descendant(
        of: find.byType(MxFooterBar),
        matching: find.text(_en.accountOfflineNote),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text(_en.accountContinueWithout));
    await _settle(tester);
    expect(dones, 1);
  });

  accountTest('the lead says MemoX works without an account, and two '
      'benefits follow', (tester, env, world) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [...accountOverrides(world), shown],
    );

    expect(find.text(_en.welcomeLead), findsOneWidget);
    expect(find.text(_en.welcomeBenefitReinstall), findsOneWidget);
    expect(find.text(_en.welcomeBenefitPhones), findsOneWidget);
    expect(find.byType(MxSettingsRow), findsNWidgets(2));
    expect(
      tester
          .widget<MxButton>(
            find.widgetWithText(MxButton, _en.accountContinueGoogle),
          )
          .tone,
      MxButtonTone.primary,
    );
  });

  accountTest('when the account becomes ready, the three ways come back '
      '(Review Focus 4)', (tester, env, world) async {
    final auth = ValueNotifier<AuthState>(const LocalOnly());
    addTearDown(auth.dispose);
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [
        ...accountOverrides(world),
        shown,
        authStateOfListenable(auth),
      ],
    );
    expect(find.text(_en.accountContinueGoogle), findsNothing);

    auth.value = world.state;
    await _settle(tester);

    expect(find.text(_en.accountContinueGoogle), findsOneWidget);
    expect(find.text(_en.accountContinueEmail), findsOneWidget);
    expect(find.text(_en.accountOfflineNote), findsNothing);
  });

  accountTest("a Google account that is another account's asks to merge, "
      'and the choice leaves Welcome', (tester, env, world) async {
    world.server.addUser(email: 'g@example.com');
    await env.decks.root('Korean');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [...accountOverrides(world), shown],
    );

    await tester.tap(find.text(_en.accountContinueGoogle));
    await _settle(tester);
    expect(find.byType(MergeChoiceSheetWidget), findsOneWidget);
    expect(find.text(_en.accountTakenGoogle), findsOneWidget);

    await tester.tap(find.text(_en.accountContinue));
    await _settle(tester);

    expect(dones, 1);
    expect(world.state, isA<Transitioning>());
  });
}
