import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/usecases/set_cards_flagged_use_case.dart';
import 'package:memox/features/card/presentation/providers/set_cards_flagged_use_case_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/library_harness.dart';
import 'support/card_list_section_host.dart';
import 'support/card_list_seed.dart';

/// Screen 07's Retry of a failed bulk flag while it runs (critique
/// 2026-09-30 part 3d-2).
final _en = lookupAppLocalizations(const Locale('en'));

/// Fails the first write; holds the next until [release].
final class _HeldFlags implements CardRepository {
  final calls = <(Set<String>, bool)>[];
  Completer<void>? held;

  void release() => held?.complete();

  @override
  Future<Outcome<void, CardRejection>> setFlagged({
    required Set<String> cardIds,
    required bool isFlagged,
    DateTime? now,
  }) async {
    calls.add((cardIds, isFlagged));
    if (calls.length == 1) {
      throw const UnknownDatabaseFailure(cause: 'locked');
    }
    await (held = Completer<void>()).future;
    return const Ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  libraryTest('while Retry runs the banner stays with a spinning Retry, and '
      'neither Retry nor the bulk bar takes a tap (critique 2026-09-30 part '
      '3d-2; Review Focus 3)', (tester, env) async {
    final flags = _HeldFlags();
    final deckId = await seedAnnyeongGamsa(env);
    await pumpLibraryScreen(
      tester,
      env,
      cardListSectionWithExport(deckId),
      overrides: [
        setCardsFlaggedUseCaseProvider.overrideWithValue(
          SetCardsFlaggedUseCase(flags),
        ),
      ],
    );
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.cardFlag));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.cardFlagSet));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(MxButton, _en.commonRetry));
    await tester.pump();

    expect(find.text(_en.cardBulkFailedTitle), findsOneWidget);
    expect(
      tester
          .widget<MxButton>(find.widgetWithText(MxButton, _en.commonRetry))
          .isLoading,
      isTrue,
    );
    await tester.tap(find.widgetWithText(MxButton, _en.commonRetry));
    await tester.tap(find.text(_en.cardFlag), warnIfMissed: false);
    await tester.pump();
    expect(flags.calls, hasLength(2));
    expect(find.text(_en.cardFlagSet), findsNothing);

    flags.release();
    await tester.pumpAndSettle();
    expect(find.text(_en.cardBulkFailedTitle), findsNothing);
    expect(find.text(_en.cardFlaggedToast(1)), findsOneWidget);
  });
}
