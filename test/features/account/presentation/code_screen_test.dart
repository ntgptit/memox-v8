import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/features/account/presentation/screens/code_screen.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/sections/code_form_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_code_field.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../../support/account_harness.dart';
import '../../../support/fake_auth_server.dart';
import '../../../support/library_harness.dart';
import '../../../support/route_naming.dart';

import 'package:forui/forui.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  late int signIns;

  setUp(() => signIns = 0);

  CodeScreen screen() =>
      CodeScreen(email: 'a@example.com', onSignedIn: () => signIns++);

  accountTest('six digits sign in and say so', (tester, env, world) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    expect(find.text(_en.accountCodeSentTo), findsOneWidget);
    expect(find.text('a@example.com'), findsOneWidget);
    await tester.enterText(find.byType(FTextField), '123456');
    await _settle(tester);

    expect(signIns, 1);
    expect(find.text(_en.accountSignedInAs('a@example.com')), findsOneWidget);
  });

  accountTest('the title names the route for TalkBack', (
    tester,
    env,
    world,
  ) async {
    await world.coordinator.requestCode('a@example.com');
    final handle = tester.ensureSemantics();
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    final node = tester.getSemantics(find.text(_en.accountCodeTitle));
    expect(node.hasFlag(SemanticsFlag.namesRoute), isTrue);
    expect(node.hasFlag(SemanticsFlag.isHeader), isTrue);
    // M3F-08: the bar's title slot is empty here, so this is the only one.
    expect(routeNamingNodes(tester), 1);
    handle.dispose();
  });

  accountTest('a code being checked is read-only and its digits stay at '
      'full strength', (tester, env, world) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    final held = world.gateway.holdRequests = Completer<void>();
    await tester.enterText(find.byType(FTextField), '123456');
    await tester.pump();

    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byType(FTextField),
              matching: find.byType(EditableText),
            ),
          )
          .readOnly,
      isTrue,
    );
    expect(
      find.descendant(
        of: find.byKey(MxCodeField.slotKey(0)),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    final disabledOpacity = tester
        .element(find.byKey(MxCodeField.slotKey(0)))
        .colors
        .disabledOpacity;
    expect(
      find.ancestor(
        of: find.byKey(MxCodeField.slotKey(0)),
        matching: find.byWidgetPredicate(
          (w) => w is Opacity && w.opacity == disabledOpacity,
        ),
      ),
      findsNothing,
    );

    held.complete();
    world.gateway.holdRequests = null;
    await _settle(tester);
  });

  accountTest('Back is held while the code is checked, so the sign-in ends '
      'on this screen (audit 2026-10-17 ACC-3)', (tester, env, world) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => unawaited(
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => screen())),
          ),
          child: const Text('open'),
        ),
      ),
      overrides: accountOverrides(world),
    );
    await tester.tap(find.text('open'));
    await _settle(tester);
    await tester.pumpAndSettle();

    final held = world.gateway.holdRequests = Completer<void>();
    await tester.enterText(find.byType(FTextField), '123456');
    await tester.pump();

    final back = find.widgetWithIcon(MxIconButton, AppIcons.back);
    expect(tester.widget<MxIconButton>(back).onPressed, isNull);
    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.byType(CodeScreen), findsOneWidget);

    held.complete();
    world.gateway.holdRequests = null;
    await _settle(tester);
    expect(signIns, 1);
    expect(tester.widget<MxIconButton>(back).onPressed, isNotNull);
  });

  accountTest('a wrong code clears the field and says so; the right one then '
      'signs in (Review Focus 4)', (tester, env, world) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(FTextField), '000000');
    await _settle(tester);

    expect(find.text(_en.accountCodeWrong), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byType(FTextField),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text,
      '',
    );
    expect(signIns, 0);

    await tester.enterText(find.byType(FTextField), '123456');
    await _settle(tester);
    expect(signIns, 1);
  });

  accountTest('Resend waits a minute, then sends a new code and waits again', (
    tester,
    env,
    world,
  ) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    expect(find.text(_en.accountResendIn('1:00')), findsOneWidget);
    expect(
      find.widgetWithText(MxButton, _en.accountResendIn('1:00')),
      findsNothing,
    );

    await tester.pump(const Duration(seconds: 60));
    await tester.tap(find.text(_en.accountResend));
    await _settle(tester);

    expect(find.text(_en.accountCodeResent), findsOneWidget);
    expect(find.text(_en.accountResendIn('1:00')), findsOneWidget);
  });

  accountTest('a resend in flight spins on the button, not "New code in '
      '0:00" (final review F1)', (tester, env, world) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );
    await tester.pump(const Duration(seconds: 60));

    final held = world.gateway.holdRequests = Completer<void>();
    await tester.tap(find.text(_en.accountResend));
    await tester.pump();

    expect(find.text(_en.accountResendIn('0:00')), findsNothing);
    final resend = find.widgetWithText(MxButton, _en.accountResend);
    expect(resend, findsOneWidget);
    expect(tester.widget<MxButton>(resend).isLoading, isTrue);

    held.complete();
    world.gateway.holdRequests = null;
    await _settle(tester);

    expect(find.text(_en.accountResendIn('1:00')), findsOneWidget);
  });

  accountTest('a re-auth resend to another address names the unsent '
      'changes again (P3b minor M7)', (tester, env, world) async {
    await refuseSession(world);
    await world.coordinator.requestCode('b@example.com', confirmedLoss: true);
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: CodeFormWidget(
          email: 'b@example.com',
          purpose: SignInPurpose.reauth,
          onUseAnotherEmail: () {},
          onSignedIn: () {},
        ),
      ),
      overrides: accountOverrides(world),
    );
    await tester.pump(const Duration(seconds: 60));

    await tester.tap(find.text(_en.accountResend));
    await _settle(tester);
    expect(find.text(_en.accountUnsentTitle(2)), findsOneWidget);
    await tester.tap(find.text(_en.commonCancel));
    await _settle(tester);
    expect(find.text(_en.accountCodeResent), findsNothing);

    await tester.tap(find.text(_en.accountResend));
    await _settle(tester);
    await tester.tap(find.widgetWithText(MxButton, _en.accountUnsentConfirm));
    await _settle(tester);
    expect(find.text(_en.accountCodeResent), findsOneWidget);
  });

  accountTest('a re-auth resend to its own address asks nothing', (
    tester,
    env,
    world,
  ) async {
    await refuseSession(world);
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: CodeFormWidget(
          email: 'a@example.com',
          purpose: SignInPurpose.reauth,
          onUseAnotherEmail: () {},
          onSignedIn: () {},
        ),
      ),
      overrides: accountOverrides(world),
    );
    await tester.pump(const Duration(seconds: 60));

    await tester.tap(find.text(_en.accountResend));
    await _settle(tester);

    expect(find.text(_en.accountUnsentTitle(2)), findsNothing);
    expect(find.text(_en.accountCodeResent), findsOneWidget);
  });

  accountTest('a code typed while a new one is on its way is kept and '
      'checked', (tester, env, world) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );
    await tester.pump(const Duration(seconds: 60));
    final held = world.gateway.holdRequests = Completer<void>();
    await tester.tap(find.text(_en.accountResend));
    await tester.pump();

    await tester.enterText(find.byType(FTextField), '123456');
    await tester.pump();
    held.complete();
    world.gateway.holdRequests = null;
    await _settle(tester);
    await _settle(tester);

    expect(signIns, 1);
  });

  accountTest('after a wrong code the field keeps the keyboard', (
    tester,
    env,
    world,
  ) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(FTextField), '000000');
    await _settle(tester);

    expect(find.text(_en.accountCodeWrong), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });

  accountTest('a re-auth code signs in again', (tester, env, world) async {
    await refuseSession(world);
    await world.coordinator.requestCode('a@example.com');
    var signedIn = 0;
    await pumpLibraryScreen(
      tester,
      env,
      CodeScreen(
        email: 'a@example.com',
        purpose: SignInPurpose.reauth,
        onSignedIn: () => signedIn++,
      ),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(FTextField), FakeAuthGateway.code);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(signedIn, 1);
    expect(world.state, isA<Ready>());
  });

  accountTest('a sign-in that worked but is not confirmed yet still says '
      '"Signed in" (P3b minor M2, final review I1)', (
    tester,
    env,
    world,
  ) async {
    await refuseSession(world);
    await world.coordinator.requestCode('a@example.com');
    // Signed in, then `me()` meets no network: the state stays Validating.
    world.gateway.afterSignIn = () => world.server.offline = true;
    await pumpLibraryScreen(
      tester,
      env,
      const CodeScreen(
        email: 'a@example.com',
        purpose: SignInPurpose.reauth,
        onSignedIn: _noop,
      ),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(FTextField), FakeAuthGateway.code);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(world.state, isA<Validating>());
    expect(find.text(_en.accountSignedIn), findsOneWidget);
  });

  accountTest('a re-auth into another account that stops on the way says '
      'no "Signed in"; the layer says what happened (P3b minor M2)', (
    tester,
    env,
    world,
  ) async {
    await refuseSession(world);
    await world.coordinator.requestCode('b@example.com', confirmedLoss: true);
    // The switch that follows the sign-in meets no network.
    world.gateway.afterSignIn = () => world.server.offline = true;
    await pumpLibraryScreen(
      tester,
      env,
      const CodeScreen(
        email: 'b@example.com',
        purpose: SignInPurpose.reauth,
        onSignedIn: _noop,
      ),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(FTextField), FakeAuthGateway.code);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(world.state, isNot(isA<Ready>()));
    expect(find.text(_en.accountSignedIn), findsNothing);
    expect(find.text(_en.accountSignedInAs('b@example.com')), findsNothing);
  });

  accountTest('the code step leads with its title, the address and the spam '
      'hint, and opens on the code', (tester, env, world) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );
    await tester.pump();

    expect(find.text(_en.accountCodeTitle), findsOneWidget);
    expect(find.text(_en.accountCodeSpamHint), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });

  accountTest('while six digits are checked a spinner takes the wait line, '
      'and nothing under it moves', (tester, env, world) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );
    final before = tester.getTopLeft(find.text(_en.accountUseAnotherEmail));

    final held = world.gateway.holdRequests = Completer<void>();
    await tester.enterText(find.byType(FTextField), '123456');
    await tester.pump();

    expect(find.byType(MxSpinner), findsOneWidget);
    expect(find.text(_en.accountResendIn('1:00')), findsNothing);
    expect(tester.getTopLeft(find.text(_en.accountUseAnotherEmail)), before);

    held.complete();
    world.gateway.holdRequests = null;
    await _settle(tester);
  });

  accountTest('a wrong code no longer asks for a new one while the wait runs', (
    tester,
    env,
    world,
  ) async {
    await world.coordinator.requestCode('a@example.com');
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(FTextField), '000000');
    await _settle(tester);

    expect(find.text(_en.accountCodeWrong), findsOneWidget);
    expect(_en.accountCodeWrong, isNot(contains('new code')));
  });
}

void _noop() {}
