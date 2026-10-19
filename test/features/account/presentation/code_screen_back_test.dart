import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/features/account/presentation/screens/code_screen.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import '../../../support/account_harness.dart';

import 'package:forui/forui.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  late int signIns;

  setUp(() => signIns = 0);

  CodeScreen screen() =>
      CodeScreen(email: 'a@example.com', onSignedIn: () => signIns++);

  accountTest('Back is held while the code is checked, so the sign-in ends '
      'on this screen (audit 2026-10-17 ACC-3)', (tester, env, world) async {
    await pumpCode(
      tester,
      env,
      world,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => unawaited(
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => screen())),
          ),
          child: const Text('open'),
        ),
      ),
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

    releaseHeldRequests(world, held);
    await _settle(tester);
    expect(signIns, 1);
    expect(tester.widget<MxIconButton>(back).onPressed, isNotNull);
  });
}
