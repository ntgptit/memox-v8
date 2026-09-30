import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/domain/models/local_library_model.dart';
import 'package:memox/features/account/domain/repositories/account_device_repository.dart';
import 'package:memox/features/account/domain/usecases/count_local_library_use_case.dart';
import 'package:memox/features/account/presentation/providers/count_local_library_use_case_provider.dart';
import 'package:memox/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import '../../../support/account_harness.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

final class _UncountableDevice implements AccountDeviceRepository {
  @override
  Future<LocalLibrary> countLibrary() async =>
      throw const UnknownDatabaseFailure(cause: 'disk');

  @override
  Future<bool> isWelcomeSeen() async => true;

  @override
  Future<void> markWelcomeSeen() async {}
}

/// A button that starts the switch for [email], as screen 30 does.
Widget _host({String? email = 'b@example.com'}) => Scaffold(
  body: Consumer(
    builder: (context, ref, _) => TextButton(
      onPressed: () => startLinkSwitch(context, ref, email: email),
      child: const Text('go'),
    ),
  ),
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  accountTest('a phone with decks asks, and merge is the default', (
    tester,
    env,
    world,
  ) async {
    await env.decks.root('Korean');
    await pumpLibraryScreen(
      tester,
      env,
      _host(),
      overrides: accountOverrides(world),
    );

    await tester.tap(find.text('go'));
    await _settle(tester);

    expect(find.text(_en.accountTakenEmail('b@example.com')), findsOneWidget);
    expect(find.text(_en.accountMergeCounts(1, 0)), findsOneWidget);
    expect(find.text(_en.accountDiscardWarning), findsNothing);

    await tester.tap(find.text(_en.accountContinue));
    await _settle(tester);

    expect(
      world.state,
      isA<Transitioning>()
          .having((s) => s.transition.choice, 'choice', TransitionChoice.merge)
          .having((s) => s.transition.targetHint, 'hint', 'b@example.com'),
    );
  });

  accountTest('discarding is its own choice, confirmed in the destructive '
      'tone', (tester, env, world) async {
    await env.decks.root('Korean');
    await pumpLibraryScreen(
      tester,
      env,
      _host(),
      overrides: accountOverrides(world),
    );
    await tester.tap(find.text('go'));
    await _settle(tester);

    await tester.tap(find.text(_en.accountDiscard));
    await tester.pump();

    expect(find.text(_en.accountDiscardWarning), findsOneWidget);
    final actions = tester.widget<MxSheetActions>(find.byType(MxSheetActions));
    expect(actions.isDestructive, isTrue);
    expect(actions.confirmLabel, _en.accountDiscardContinue);

    await tester.tap(find.text(_en.accountDiscardContinue));
    await _settle(tester);
    expect(
      world.state,
      isA<Transitioning>().having(
        (s) => s.transition.choice,
        'choice',
        TransitionChoice.discard,
      ),
    );
  });

  accountTest('an empty phone moves without asking', (
    tester,
    env,
    world,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(),
      overrides: accountOverrides(world),
    );

    await tester.tap(find.text('go'));
    await _settle(tester);

    expect(find.byType(MergeChoiceSheetWidget), findsNothing);
    expect(
      world.state,
      isA<Transitioning>().having(
        (s) => s.transition.choice,
        'choice',
        TransitionChoice.discard,
      ),
    );
  });

  accountTest('Cancel starts nothing', (tester, env, world) async {
    await env.decks.root('Korean');
    await pumpLibraryScreen(
      tester,
      env,
      _host(),
      overrides: accountOverrides(world),
    );
    await tester.tap(find.text('go'));
    await _settle(tester);

    await tester.tap(find.text(_en.commonCancel));
    await _settle(tester);

    expect(world.state, isA<Ready>());
  });

  accountTest('Google\'s title, and a failed count still asks, without '
      'numbers', (tester, env, world) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(email: null),
      overrides: [
        ...accountOverrides(world),
        countLocalLibraryUseCaseProvider.overrideWithValue(
          CountLocalLibraryUseCase(_UncountableDevice()),
        ),
      ],
    );

    await tester.tap(find.text('go'));
    await _settle(tester);

    expect(find.text(_en.accountTakenGoogle), findsOneWidget);
    expect(find.text(_en.accountMergePlain), findsOneWidget);
  });
}
