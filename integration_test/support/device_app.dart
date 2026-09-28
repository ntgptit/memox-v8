import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/main.dart' as app;

// The device scenarios' harness (FE-D3, spec
// docs/superpowers/specs/2026-09-28-device-e2e-design.md). Each test file is
// one phase; tools/device/run_device_e2e.sh runs the phases and does what
// only the OS can.

/// Lines the runner script reads from `flutter test` output (spec D3).
const _prefix = 'MEMOX-E2E:';

/// How long a debug cold start may take, and any other wait (spec §6).
const _timeout = Duration(seconds: 30);

void initDeviceBinding() =>
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();

/// The installed app as a person starts it: the real `main()`, database and
/// assets (spec §1).
Future<void> launchApp(WidgetTester tester) async {
  await app.main();
  await waitFor(tester, find.byType(Scaffold));
}

/// Pumps until [isMet] holds; false after [timeout]. A stopwatch, not the
/// wall clock: a wait measures elapsed time.
Future<bool> _pumpUntil(
  WidgetTester tester,
  bool Function() isMet,
  Duration timeout,
) async {
  final watch = Stopwatch()..start();
  while (watch.elapsed < timeout) {
    await tester.pump(const Duration(milliseconds: 200));
    if (isMet()) return true;
  }
  return false;
}

/// Pumps until [finder] finds something; fails naming it after [timeout].
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = _timeout,
}) async {
  if (await _pumpUntil(tester, () => finder.evaluate().isNotEmpty, timeout)) {
    return;
  }
  await _fail(tester, 'Timed out after $timeout waiting for $finder');
}

/// Pumps until [isMet] holds; fails naming [what] after [timeout].
Future<void> waitUntil(
  WidgetTester tester,
  bool Function() isMet,
  String what, {
  Duration timeout = _timeout,
}) async {
  if (await _pumpUntil(tester, isMet, timeout)) return;
  await _fail(tester, 'Timed out after $timeout waiting until $what');
}

/// Pumps until one of [finders] finds something, and returns it.
Future<Finder> waitForAny(
  WidgetTester tester,
  List<Finder> finders, {
  Duration timeout = _timeout,
}) async {
  Finder? found;
  bool isMet() {
    found = finders.where((f) => f.evaluate().isNotEmpty).firstOrNull;
    return found != null;
  }

  if (await _pumpUntil(tester, isMet, timeout)) return found!;
  return _fail(tester, 'Timed out after $timeout waiting for any of $finders');
}

/// Pumps until [finder] finds nothing; fails naming it after [timeout].
Future<void> waitGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = _timeout,
}) async {
  if (await _pumpUntil(tester, () => finder.evaluate().isEmpty, timeout)) {
    return;
  }
  await _fail(tester, 'Timed out after $timeout waiting for $finder to go');
}

/// Fails with [message] and the texts on screen, after the script took a
/// screenshot (`MEMOX-E2E: snap`, saved under build/device_e2e/).
Future<Never> _fail(WidgetTester tester, String message) async {
  signal('snap');
  await tester.pump(const Duration(seconds: 2));
  throw TestFailure('$message; on screen: ${_onScreen()}');
}

/// The texts on screen, for a failure that says where the app stood.
String _onScreen() => find
    .byType(RichText)
    .evaluate()
    .map((element) => (element.widget as RichText).text.toPlainText())
    .where((text) => text.trim().isNotEmpty)
    .take(40)
    .join(' | ');

/// The app's strings in the device's language (spec D7).
AppLocalizations l10nOf(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first));

/// Tells the runner script something (spec D3).
void signal(String message) => debugPrint('$_prefix $message');

/// A value an earlier phase signalled, which the script passed on.
String valueOf(String key) => switch (key) {
  'DECK_ID' => const String.fromEnvironment('MEMOX_E2E_DECK_ID'),
  'CHECKPOINT' => const String.fromEnvironment('MEMOX_E2E_CHECKPOINT'),
  _ => throw ArgumentError.value(key, 'key', 'unknown E2E value'),
};

/// Waits for [text], then taps its last match (a dialog's button sits above
/// the page that opened it).
Future<void> tapText(WidgetTester tester, String text) async {
  await waitFor(tester, find.text(text));
  await tester.tap(find.text(text).last);
  await tester.pump(const Duration(milliseconds: 300));
}
