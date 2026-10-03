import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/widgets/overlays/settings_reset_dialog_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// Watches the controller as screen 23 does, so its busy flags outlive a
/// write: a dialog alone would let the provider dispose between tries.
Widget _host() => Scaffold(
  body: Consumer(
    builder: (context, ref, _) {
      ref.watch(settingsControllerProvider);
      return MxButton(
        label: 'Open',
        onPressed: () => showSettingsResetDialog(context),
      );
    },
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  libraryTest('a failed reset keeps the dialog with the banner; the confirm '
      'keeps its name and runs again (SP2b 2.33, audit m6)', (
    tester,
    env,
  ) async {
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
      ..isFailing = true;
    await pumpLibraryScreen(
      tester,
      env,
      _host(),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );
    await _open(tester);
    await tester.tap(find.text(_en.settingsResetConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MxInlineBanner),
        matching: find.text(_en.settingsResetFailed),
      ),
      findsOneWidget,
    );
    expect(find.text(_en.settingsResetConfirm), findsOneWidget);
    expect(find.text(_en.commonRetry), findsNothing);
    expect(find.byType(SnackBar), findsNothing);

    store.isFailing = false;
    await tester.tap(find.text(_en.settingsResetConfirm));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
    expect(store.writes, 2);
  });

  libraryTest('a write that throws a non-Failure is reported, shows the banner '
      'and frees Retry (SP2b 2.33)', (tester, env) async {
    final reported = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = previous);
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
      ..errorOnce = StateError('disk full');
    await pumpLibraryScreen(
      tester,
      env,
      _host(),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );
    await _open(tester);
    await tester.tap(find.text(_en.settingsResetConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(find.text(_en.settingsResetFailed), findsOneWidget);
    expect(reported.single.exception, isA<StateError>());

    await tester.tap(find.text(_en.settingsResetConfirm));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
    expect(store.writes, 2);
  });

  libraryTest('Back and a scrim tap wait while the reset runs; released, the '
      'dialog closes (SP2b 2.33)', (tester, env) async {
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
      ..hold = Completer<void>();
    await pumpLibraryScreen(
      tester,
      env,
      _host(),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );
    await _open(tester);
    await tester.tap(find.text(_en.settingsResetConfirm));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tapAt(const Offset(2, 2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MxDialog), findsOneWidget);

    store.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
  });
}
