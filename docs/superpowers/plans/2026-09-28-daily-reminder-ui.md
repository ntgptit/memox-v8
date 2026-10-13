# FE-B5 Daily reminder UI Implementation Plan

> **Historical (ADR-019).** Written against the "Mobile UI Kit v3", retired on 2026-09-30; its kit references and screen captures are history, not authority. The app, `DESIGN.md` and the goldens decide the UI; each screen's current state is in its detail file under `docs/shared/ui/screen-handoff/`.

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build screen 24 "Daily reminder" on the six BE-B5a use cases and the BE-B5b adapter, and give screen 23 its Daily reminder row, the reset copy that names the reminder, and a reconcile after a reset.

**Architecture:** The stream of `WatchReminderUseCase` is the data (`reminderStatusProvider`). `ReminderController` holds only the operation in flight and the last outcome (`ReminderActionState`). Enable, Disable and Change time are providers that return a function running the use case through `reminderOperationGateProvider`, the pattern of `reconcile_reminder_provider.dart`. Screen 23 reads `AppSettingsEntity.reminder` and never imports `reminders`; `app/` wires the reconcile after a reset.

**Tech Stack:** Flutter 3.47.5, Riverpod 3 with `riverpod_generator`, GoRouter, `flutter_test` goldens (Linux), ARB l10n (en, vi).

**Spec:** `docs/superpowers/specs/2026-09-28-daily-reminder-ui-design.md` (D1–D10). Read it with this plan.

## Global Constraints

- No schema change, no new dependency, no native code, no change to the use cases, the port or the adapter (spec §10).
- `settings` never imports `reminders` (`test/architecture/boundary_rules.dart`; spec D6, D7).
- Every reminder write from screen 24 goes through `reminderOperationGateProvider` (spec D4).
- The notification permission is requested only by Enable, and Enable runs only on the toggle or on Try again / Retry after `permDenied` / `couldNotTurnOn` (BR-REMINDER-011).
- Times show as 24-hour `HH:mm` in en and vi: `MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: m ~/ 60, minute: m % 60), alwaysUse24HourFormat: true)` (spec D9).
- No hardcoded colour, spacing or text: tokens from `lib/core/theme/`, strings from ARB (en with `@key` description, vi without), icons from `AppIcons`.
- No message carries a table, path, id or plugin text (BR-CORE-005).
- Goldens are written only on this Linux host, and only after the existing goldens of the touched test files pass unchanged on it (CLAUDE.md, Hooks; screen 13 on 2026-09-28).
- The gate is `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` (export `FLUTTER_ROOT` first: `export FLUTTER_ROOT=$(dirname $(dirname $(readlink -f $(which flutter))))`).
- Commit messages end with the session's attribution lines.

## Review Focus

1. **A stream re-emission while a banner shows** (the settings row is re-read after any save elsewhere, or a reconcile on resume) must keep `permDenied` / `couldNotTurnOn` / `mayStillShow` on screen until the next operation. Test in Task 1 (`the outcome survives a stream re-emission`).
2. **A double tap on the toggle** (or toggle then Try again) while Enable runs must start one operation and ask for the permission once. Test in Task 1 (`a second operation is ignored while one runs`) and Task 2 (`busy: the toggle becomes a spinner, the permission is asked once`).
3. **Changing the time while the reminder is off** — the kit dims the time row; the use case would save only the minute. The screen disables the row while off, so no dialog opens. Test in Task 3 (`off: the time row is disabled`).
4. **Typed minute out of range** (`75`) in the dialog must not reach the use case: the stepper shows invalid and Save is disabled. Test in Task 3 (`a typed minute outside 0–59 disables Save`).
5. **Reset fails** — the reconcile must not run, and nothing about the reminder changes. Test in Task 4 (`reset: onAppOptionsReset runs once on success, never on failure`).

---

## File Structure

| File | Responsibility |
|---|---|
| `lib/features/reminders/presentation/providers/reminder_status_provider.dart` (create) | `Stream<ReminderStatus>` from `WatchReminderUseCase` |
| `lib/features/reminders/presentation/providers/enable_reminder_provider.dart` (create) | Enable through the gate |
| `lib/features/reminders/presentation/providers/disable_reminder_provider.dart` (create) | Disable through the gate |
| `lib/features/reminders/presentation/providers/change_reminder_time_provider.dart` (create) | Change time through the gate |
| `lib/features/reminders/presentation/states/reminder_action_state.dart` (create) | `ReminderOperation`, `ReminderProblem`, `ReminderSaveFailed`, `ReminderActionState` |
| `lib/features/reminders/presentation/controllers/reminder_controller.dart` (create) | turnOn, turnOff, changeTime, retry; one at a time |
| `lib/features/reminders/presentation/screens/reminder_screen.dart` (create) | Screen 24: app bar, body per stream state, E4 snackbar |
| `lib/features/reminders/presentation/widgets/sections/reminder_settings_section_widget.dart` (create) | Toggle row, time row, note |
| `lib/features/reminders/presentation/widgets/sections/reminder_banners_widget.dart` (create) | The banner of the last problem |
| `lib/features/reminders/presentation/widgets/sections/reminder_preview_section_widget.dart` (create) | "What it says" |
| `lib/features/reminders/presentation/widgets/overlays/reminder_time_dialog_widget.dart` (create) | The hour/minute dialog |
| `lib/core/theme/foundations/app_icons.dart` (modify) | `reminderOff` |
| `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (modify) | Strings of screens 24 and 23 |
| `lib/features/settings/presentation/widgets/sections/settings_app_section_widget.dart` (modify) | Daily reminder row |
| `lib/features/settings/presentation/screens/settings_screen.dart` (modify) | `onOpenReminder`, `onAppOptionsReset` |
| `lib/app/router/app_routes.dart`, `lib/app/router/app_router.dart` (modify) | `/settings/reminder`, wiring |
| `test/features/reminders/presentation/reminder_controller_test.dart` (create) | Controller |
| `test/features/reminders/presentation/reminder_screen_test.dart` (create) | Screen 24 widget tests |
| `test/features/reminders/presentation/reminder_screen_golden_test.dart` (create) | Goldens |
| `test/visual_audit/screens/features/reminders/screens/reminder_screen_visual_audit_test.dart` (create) | Audit companion |
| `test/features/settings/presentation/settings_screen_test.dart`, `settings_screen_golden_test.dart` (modify) | Row, reset |
| docs (Task 6) | detail file 24, index, checklist, register row 123, `reminders/ui.md`, UC, `navigation.md`, WBS |

The spec's §4 named one `reminder_operations_provider.dart`; this plan uses three providers, one per operation, because that is the shape of `reconcile_reminder_provider.dart` and each is overridden alone in tests.

---

### Task 1: Operation providers, action state and controller

**Files:**
- Create: the four providers, `states/reminder_action_state.dart`, `controllers/reminder_controller.dart` (paths in File Structure)
- Test: `test/features/reminders/presentation/reminder_controller_test.dart`

**Interfaces:**
- Consumes: `WatchReminderUseCase(SettingsRepository, ReminderPlatformRepository)`, `EnableReminderUseCase(settings, platform, DayClock)`, `DisableReminderUseCase(settings, platform)`, `ChangeReminderTimeUseCase(settings, platform, DayClock)`, `reminderOperationGateProvider`, `settingsRepositoryProvider`, `reminderPlatformRepositoryProvider`, `dayClockProvider`.
- Produces:
  - `reminderStatusProvider` → `Stream<ReminderStatus>`
  - `enableReminderProvider` → `Future<Outcome<DateTime, ReminderRejection>> Function(int minuteOfDay)`
  - `disableReminderProvider` → `Future<Outcome<void, ReminderRejection>> Function()`
  - `changeReminderTimeProvider` → `Future<Outcome<DateTime?, ReminderRejection>> Function(int minuteOfDay)`
  - `enum ReminderOperation { turnOn, turnOff, changeTime }`
  - `enum ReminderProblem { permissionDenied, couldNotTurnOn, couldNotChangeTime, mayStillShow }`
  - `final class ReminderSaveFailed { ReminderSaveFailed(this.operation); final ReminderOperation operation; }`
  - `ReminderActionState { ReminderOperation? running; ReminderProblem? problem; ReminderSaveFailed? saveFailed; bool get isBusy }`
  - `reminderControllerProvider` (`ReminderController`): `Future<void> turnOn()`, `Future<void> turnOff()`, `Future<void> changeTime(int minuteOfDay)`, `Future<void> retry()`

- [ ] **Step 1: Write the failing controller test**

```dart
// test/features/reminders/presentation/reminder_controller_test.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/presentation/controllers/reminder_controller.dart';
import 'package:memox/features/reminders/presentation/providers/reminder_status_provider.dart';
import 'package:memox/features/reminders/presentation/states/reminder_action_state.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

import '../../../support/fake_reminder_platform.dart';
import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

// Screen 24's operations (UC-REMINDER-001; FE-B5 spec D3, D4).

({ProviderContainer container, FakeReminderPlatform platform, FlakySettingsRepository store})
    _setUp(LibraryEnv env, {FakeReminderPlatform? platform}) {
  final fake = platform ?? FakeReminderPlatform();
  final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db));
  final container = libraryContainer(env, overrides: [
    reminderPlatformRepositoryProvider.overrideWithValue(fake),
    settingsRepositoryProvider.overrideWithValue(store),
  ]);
  // The screen keeps the stream alive; so does the test.
  container.listen(reminderStatusProvider, (_, _) {});
  return (container: container, platform: fake, store: store);
}

ReminderController _controller(ProviderContainer c) =>
    c.read(reminderControllerProvider.notifier);

void main() {
  libraryTest('turnOn: Enable at the stored minute, then idle', (tester, env) async {
    final s = _setUp(env);
    await s.container.read(reminderStatusProvider.future);

    await _controller(s.container).turnOn();

    expect(s.platform.calls, contains(PlatformCall.requestPermission));
    expect(s.platform.pending, isNotNull);
    expect(s.container.read(reminderControllerProvider).problem, isNull);
    expect(s.container.read(reminderControllerProvider).isBusy, isFalse);
  });

  libraryTest('turnOn refused: permissionDenied, then Retry asks again', (tester, env) async {
    final s = _setUp(env, platform: FakeReminderPlatform(permission: ReminderPermission.denied));
    await s.container.read(reminderStatusProvider.future);

    await _controller(s.container).turnOn();
    expect(s.container.read(reminderControllerProvider).problem, ReminderProblem.permissionDenied);

    s.platform.permission = ReminderPermission.granted;
    await _controller(s.container).retry();
    expect(s.container.read(reminderControllerProvider).problem, isNull);
    expect(s.platform.calls.where((c) => c == PlatformCall.requestPermission), hasLength(2));
  });

  libraryTest('couldNotSchedule is couldNotTurnOn on Enable and couldNotChangeTime on a change',
      (tester, env) async {
    final s = _setUp(env);
    await s.container.read(reminderStatusProvider.future);
    await _controller(s.container).turnOn();
    s.platform.refusing.add(PlatformCall.schedule);

    await _controller(s.container).changeTime(21 * 60);
    expect(s.container.read(reminderControllerProvider).problem, ReminderProblem.couldNotChangeTime);

    await _controller(s.container).turnOff();
    await _controller(s.container).turnOn();
    expect(s.container.read(reminderControllerProvider).problem, ReminderProblem.couldNotTurnOn);
  });

  libraryTest('turnOff with a refused cancel: mayStillShow; Retry only cancels', (tester, env) async {
    final s = _setUp(env);
    await s.container.read(reminderStatusProvider.future);
    await _controller(s.container).turnOn();
    s.platform.refusing.add(PlatformCall.cancel);

    await _controller(s.container).turnOff();
    expect(s.container.read(reminderControllerProvider).problem, ReminderProblem.mayStillShow);

    s.platform.refusing.clear();
    final writes = s.store.writes;
    await _controller(s.container).retry();
    expect(s.container.read(reminderControllerProvider).problem, isNull);
    expect(s.store.writes, writes, reason: 'E6: Try again writes nothing');
  });

  libraryTest('a failed save is ReminderSaveFailed, never a problem (E4)', (tester, env) async {
    final s = _setUp(env);
    await s.container.read(reminderStatusProvider.future);
    s.store.isFailing = true;

    await _controller(s.container).turnOn();

    final state = s.container.read(reminderControllerProvider);
    expect(state.problem, isNull);
    expect(state.saveFailed?.operation, ReminderOperation.turnOn);
    expect(s.platform.pending, isNull, reason: 'Enable takes the schedule back');
  });

  libraryTest('a second operation is ignored while one runs', (tester, env) async {
    final s = _setUp(env);
    await s.container.read(reminderStatusProvider.future);
    final hold = Completer<void>();
    s.store.hold = hold;

    final first = _controller(s.container).turnOn();
    await Future<void>.delayed(Duration.zero);
    expect(s.container.read(reminderControllerProvider).running, ReminderOperation.turnOn);
    await _controller(s.container).turnOff();
    hold.complete();
    await first;

    expect(s.platform.calls.where((c) => c == PlatformCall.requestPermission), hasLength(1));
    expect(s.platform.calls, isNot(contains(PlatformCall.cancel)));
  });

  libraryTest('the outcome survives a stream re-emission', (tester, env) async {
    final s = _setUp(env, platform: FakeReminderPlatform(permission: ReminderPermission.denied));
    await s.container.read(reminderStatusProvider.future);
    await _controller(s.container).turnOn();

    // Another write to app_settings re-emits the stream.
    await s.store.saveReminder(reminder: const ReminderSettings(isEnabled: false, minuteOfDay: 1260));
    await s.container.read(reminderStatusProvider.future);

    expect(s.container.read(reminderControllerProvider).problem, ReminderProblem.permissionDenied);
  });
}
```

Note: `libraryTest` gives a `WidgetTester`; these tests do not pump, they drive the container. If `libraryTest` requires a pump for timers, wrap each body's awaits in `tester.runAsync(() async { ... })`.

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/reminders/presentation/reminder_controller_test.dart`
Expected: compile failure — `reminder_controller.dart` and the providers do not exist.

- [ ] **Step 3: Write the providers**

```dart
// lib/features/reminders/presentation/providers/reminder_status_provider.dart
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/domain/models/reminder_status_model.dart';
import 'package:memox/features/reminders/domain/usecases/watch_reminder_use_case.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_status_provider.g.dart';

/// Screen 24's data (UC-REMINDER-001 step 1): the platform's capability and
/// the stored reminder, again after every save; a read that fails is E7.
@riverpod
Stream<ReminderStatus> reminderStatus(Ref ref) => WatchReminderUseCase(
  ref.watch(settingsRepositoryProvider),
  ref.watch(reminderPlatformRepositoryProvider),
)();
```

```dart
// lib/features/reminders/presentation/providers/enable_reminder_provider.dart
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/di/reminder_operation_gate_provider.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/usecases/enable_reminder_use_case.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'enable_reminder_provider.g.dart';

/// Enable (UC-REMINDER-001 steps 2-3) as screen 24 runs it: through the
/// gate, so it never interleaves with another reminder operation (§14).
@riverpod
Future<Outcome<DateTime, ReminderRejection>> Function(int minuteOfDay)
enableReminder(Ref ref) {
  final enable = EnableReminderUseCase(
    ref.watch(settingsRepositoryProvider),
    ref.watch(reminderPlatformRepositoryProvider),
    ref.watch(dayClockProvider),
  );
  final gate = ref.watch(reminderOperationGateProvider);
  return (minuteOfDay) => gate.run(() => enable(minuteOfDay: minuteOfDay));
}
```

```dart
// lib/features/reminders/presentation/providers/disable_reminder_provider.dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/di/reminder_operation_gate_provider.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/usecases/disable_reminder_use_case.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'disable_reminder_provider.g.dart';

/// Disable (UC-REMINDER-001 A2) as screen 24 runs it, through the gate.
@riverpod
Future<Outcome<void, ReminderRejection>> Function() disableReminder(Ref ref) {
  final disable = DisableReminderUseCase(
    ref.watch(settingsRepositoryProvider),
    ref.watch(reminderPlatformRepositoryProvider),
  );
  final gate = ref.watch(reminderOperationGateProvider);
  return () => gate.run(disable.call);
}
```

```dart
// lib/features/reminders/presentation/providers/change_reminder_time_provider.dart
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/di/reminder_operation_gate_provider.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/usecases/change_reminder_time_use_case.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'change_reminder_time_provider.g.dart';

/// Change time (UC-REMINDER-001 A1) as screen 24 runs it, through the gate.
@riverpod
Future<Outcome<DateTime?, ReminderRejection>> Function(int minuteOfDay)
changeReminderTime(Ref ref) {
  final change = ChangeReminderTimeUseCase(
    ref.watch(settingsRepositoryProvider),
    ref.watch(reminderPlatformRepositoryProvider),
    ref.watch(dayClockProvider),
  );
  final gate = ref.watch(reminderOperationGateProvider);
  return (minuteOfDay) => gate.run(() => change(minuteOfDay: minuteOfDay));
}
```

- [ ] **Step 4: Write the state and the controller**

```dart
// lib/features/reminders/presentation/states/reminder_action_state.dart
import 'package:flutter/foundation.dart';

/// A reminder operation screen 24 starts (UC-REMINDER-001).
enum ReminderOperation { turnOn, turnOff, changeTime }

/// What the last operation left for screen 24 to say. Held in the
/// controller, never stored (reminders spec §9, "For FE-B5").
enum ReminderProblem {
  /// E1: the permission was refused; the reminder stays off.
  permissionDenied,

  /// E3 on Enable: nothing was scheduled; the reminder stays off.
  couldNotTurnOn,

  /// E3 on Change time: the old time and its schedule stand.
  couldNotChangeTime,

  /// E6: the reminder is off, but one already scheduled may still fire.
  mayStillShow,
}

/// E4: a save failed and nothing changed. A new object per failure, so a
/// listener hears two in a row.
final class ReminderSaveFailed {
  ReminderSaveFailed(this.operation);

  final ReminderOperation operation;
}

/// Screen 24's own state: the operation in flight and what the last one
/// left. The reminder itself is the stream's (FE-B5 spec D3).
@immutable
final class ReminderActionState {
  const ReminderActionState({this.running, this.problem, this.saveFailed});

  final ReminderOperation? running;
  final ReminderProblem? problem;
  final ReminderSaveFailed? saveFailed;

  bool get isBusy => running != null;
}
```

```dart
// lib/features/reminders/presentation/controllers/reminder_controller.dart
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/presentation/providers/change_reminder_time_provider.dart';
import 'package:memox/features/reminders/presentation/providers/disable_reminder_provider.dart';
import 'package:memox/features/reminders/presentation/providers/enable_reminder_provider.dart';
import 'package:memox/features/reminders/presentation/providers/reminder_status_provider.dart';
import 'package:memox/features/reminders/presentation/states/reminder_action_state.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_controller.g.dart';

/// Screen 24's operations (UC-REMINDER-001): one at a time (spec D4), each
/// leaving at most one problem or one failed save, and Retry repeats the
/// operation that left it. Widgets draw this state and the stream.
@riverpod
class ReminderController extends _$ReminderController {
  /// What Retry repeats; null once an operation ended well.
  Future<void> Function()? _again;

  @override
  ReminderActionState build() => const ReminderActionState();

  int get _storedMinute =>
      ref.read(reminderStatusProvider).value?.reminder.minuteOfDay ??
      ReminderSettings.defaultMinuteOfDay;

  /// The toggle on, or Try again after a refusal: only here is the
  /// permission asked (BR-REMINDER-011).
  Future<void> turnOn() => _run(
    ReminderOperation.turnOn,
    () => ref.read(enableReminderProvider)(_storedMinute),
    again: turnOn,
  );

  /// The toggle off, or Try again after `mayStillShow` (A2, E6).
  Future<void> turnOff() => _run(
    ReminderOperation.turnOff,
    () => ref.read(disableReminderProvider)(),
    again: turnOff,
  );

  /// Save in the time dialog (A1).
  Future<void> changeTime(int minuteOfDay) => _run(
    ReminderOperation.changeTime,
    () => ref.read(changeReminderTimeProvider)(minuteOfDay),
    again: () => changeTime(minuteOfDay),
  );

  /// Repeats the operation that left the current problem or failed save.
  Future<void> retry() async {
    final again = _again;
    if (again != null) await again();
  }

  Future<void> _run(
    ReminderOperation operation,
    Future<Outcome<Object?, ReminderRejection>> Function() call, {
    required Future<void> Function() again,
  }) async {
    if (state.isBusy) return;
    state = ReminderActionState(running: operation);
    ReminderProblem? problem;
    ReminderSaveFailed? saveFailed;
    try {
      if (await call() case Rejected(:final reason)) {
        problem = _problemOf(operation, reason);
      }
    } on Failure {
      saveFailed = ReminderSaveFailed(operation);
    }
    if (!ref.mounted) return;
    _again = problem != null || saveFailed != null ? again : null;
    state = ReminderActionState(problem: problem, saveFailed: saveFailed);
  }

  static ReminderProblem? _problemOf(
    ReminderOperation operation,
    ReminderRejection reason,
  ) => switch (reason) {
    ReminderRejection.permissionDenied => ReminderProblem.permissionDenied,
    ReminderRejection.couldNotSchedule =>
      operation == ReminderOperation.changeTime
          ? ReminderProblem.couldNotChangeTime
          : ReminderProblem.couldNotTurnOn,
    ReminderRejection.couldNotCancel => ReminderProblem.mayStillShow,
    // The stream already says the platform has none (BR-REMINDER-012); the
    // dialog's bounds keep the minute in range; only a delivery shows.
    ReminderRejection.unsupported ||
    ReminderRejection.minuteOutOfRange ||
    ReminderRejection.couldNotShow => null,
  };
}
```

- [ ] **Step 5: Generate code and run the test**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/features/reminders/presentation/reminder_controller_test.dart`
Expected: PASS (7 tests).

- [ ] **Step 6: Analyze and commit**

Run: `dart format lib/features/reminders test/features/reminders && flutter analyze`
Expected: `No issues found!`

```bash
git add lib/features/reminders/presentation test/features/reminders/presentation/reminder_controller_test.dart
git commit -m "feat(reminders): screen 24's operations through the gate, one at a time (FE-B5 D3, D4)"
```

---

### Task 2: Screen 24 — rows, banners, preview, loading, unavailable, E4, E7

**Files:**
- Create: `screens/reminder_screen.dart`, `widgets/sections/reminder_settings_section_widget.dart`, `widgets/sections/reminder_banners_widget.dart`, `widgets/sections/reminder_preview_section_widget.dart`
- Modify: `lib/core/theme/foundations/app_icons.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/reminders/presentation/reminder_screen_test.dart`

**Interfaces:**
- Consumes: Task 1's providers and controller.
- Produces: `class ReminderScreen extends ConsumerStatefulWidget { const ReminderScreen({super.key}); }`; `AppIcons.reminderOff`; the ARB keys below. Task 3 adds the dialog; the time button's `onPressed` calls `_pickTime` defined there.

- [ ] **Step 1: Add the strings and the icon**

`lib/core/theme/foundations/app_icons.dart`, after `reminder`:

```dart
  static const IconData reminderOff = Icons.notifications_off_outlined; // bell-off
```

`lib/l10n/app_en.arb` (each with `"@key": {"description": "Screen handoff 24 (FE-B5): …"}`; placeholders typed `String`):

| Key | en | vi |
|---|---|---|
| `reminderTitle` | Daily reminder | Nhắc học hằng ngày |
| `reminderNote` | Fires once a day, only when cards are due. Never for new cards, never twice. | Nhắc mỗi ngày một lần, chỉ khi có thẻ đến hạn. Không nhắc vì thẻ mới, không nhắc hai lần. |
| `reminderOnHint` | One notification a day at the time below | Một thông báo mỗi ngày vào giờ bên dưới |
| `reminderOffHint` | Off · nothing is scheduled | Tắt · chưa hẹn giờ nhắc nào |
| `reminderDeniedHint` | Off · notification permission was refused | Tắt · quyền thông báo đã bị từ chối |
| `reminderTime` | Time | Giờ nhắc |
| `reminderTimeOnHint` | Local time · stays the same if you travel | Giờ địa phương · giữ nguyên khi bạn đi nơi khác |
| `reminderTimeOffHint` | Turn the reminder on to choose a time | Bật nhắc học để chọn giờ |
| `reminderTimeButton` `{time}` | Reminder time, {time} | Giờ nhắc, {time} |
| `reminderPreviewTitle` | What it says | Nội dung thông báo |
| `reminderPreviewSample` | “86 cards are due in 한국어 TOPIK I · Từ vựng, and 2 other decks have cards waiting.” | “86 thẻ đến hạn trong 한국어 TOPIK I · Từ vựng, và 2 bộ thẻ khác đang có thẻ chờ.” |
| `reminderPreviewHint` | Deck name and counts only — never a card, tag or history, including on the lock screen. Opening it lands on Study. | Chỉ tên bộ thẻ và số lượng — không bao giờ có thẻ, tag hay lịch sử, kể cả trên màn hình khoá. Mở thông báo sẽ vào tab Học. |
| `reminderDeniedTitle` | Notifications are blocked for MemoX | Thông báo của MemoX đang bị chặn |
| `reminderDeniedBody` | Allow them in Android Settings › Apps › MemoX › Notifications, then turn the reminder on again. | Hãy cho phép trong Cài đặt Android › Ứng dụng › MemoX › Thông báo, rồi bật lại nhắc học. |
| `reminderTryAgain` | Try again | Thử lại |
| `reminderCouldNotTurnOnTitle` | Couldn’t schedule the reminder. | Không hẹn được giờ nhắc. |
| `reminderCouldNotTurnOnBody` | It stays off. Try turning it on again. | Nhắc học vẫn tắt. Hãy thử bật lại. |
| `reminderCouldNotChangeTimeTitle` | Couldn’t change the time. | Không đổi được giờ nhắc. |
| `reminderCouldNotChangeTimeBody` `{time}` | The reminder stays at {time}. | Nhắc học vẫn giữ lúc {time}. |
| `reminderMayStillShow` | Turned off. A reminder already scheduled for today may still appear once. | Đã tắt. Lượt nhắc đã hẹn cho hôm nay có thể vẫn hiện một lần. |
| `reminderUnavailable` | Reminders are not available on this device | Thiết bị này chưa hỗ trợ nhắc học |
| `reminderUnavailableHint` | This build cannot deliver notifications. Nothing to turn on here. | Bản ứng dụng này không gửi được thông báo. Không có gì để bật ở đây. |
| `reminderReadErrorTitle` | Couldn't read the reminder setting | Không đọc được cài đặt nhắc học |
| `reminderReadErrorBody` | Nothing was changed. Try reading it again. | Chưa có gì thay đổi. Hãy thử đọc lại. |
| `reminderSaveFailed` | Couldn't save the reminder. Nothing changed. | Không lưu được nhắc học. Chưa có gì thay đổi. |

Run: `flutter gen-l10n`
Expected: no output errors; `lib/l10n/generated/app_localizations.dart` has `reminderTitle`.

- [ ] **Step 2: Write the failing widget tests**

```dart
// test/features/reminders/presentation/reminder_screen_test.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_status_model.dart';
import 'package:memox/features/reminders/presentation/providers/reminder_status_provider.dart';
import 'package:memox/features/reminders/presentation/screens/reminder_screen.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../../support/fake_reminder_platform.dart';
import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

// Screen 24, Daily reminder: UC-REMINDER-001; FE-B5 spec §5.1.

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<({FakeReminderPlatform platform, FlakySettingsRepository store})> _pump(
  WidgetTester tester,
  LibraryEnv env, {
  FakeReminderPlatform? platform,
}) async {
  final fake = platform ?? FakeReminderPlatform();
  final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db));
  await pumpLibraryScreen(
    tester,
    env,
    const ReminderScreen(),
    overrides: [
      reminderPlatformRepositoryProvider.overrideWithValue(fake),
      settingsRepositoryProvider.overrideWithValue(store),
    ],
  );
  await _settle(tester);
  return (platform: fake, store: store);
}

Future<void> _toggle(WidgetTester tester) async {
  await tester.tap(find.byType(MxToggle));
  await _settle(tester);
}

void main() {
  libraryTest('off: toggle off, time row disabled, note and preview (main 1)', (tester, env) async {
    final s = await _pump(tester, env);

    expect(find.text(_en.reminderOffHint), findsOneWidget);
    expect(find.text(_en.reminderTimeOffHint), findsOneWidget);
    expect(find.text(_en.reminderNote), findsOneWidget);
    expect(find.text(_en.reminderPreviewSample), findsOneWidget);
    expect(tester.widget<MxToggle>(find.byType(MxToggle)).isOn, isFalse);
    expect(s.platform.calls, isNot(contains(PlatformCall.requestPermission)),
        reason: 'BR-REMINDER-011: nothing is asked on open');
  });

  libraryTest('on: the toggle asks for the permission, then the time row opens (main 2-3)',
      (tester, env) async {
    final s = await _pump(tester, env);
    await _toggle(tester);

    expect(s.platform.calls.where((c) => c == PlatformCall.requestPermission), hasLength(1));
    expect(find.text(_en.reminderOnHint), findsOneWidget);
    expect(find.text(_en.reminderTimeOnHint), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);
  });

  libraryTest('busy: the toggle becomes a spinner, the permission is asked once',
      (tester, env) async {
    final s = await _pump(tester, env);
    final hold = Completer<void>();
    s.store.hold = hold;

    await tester.tap(find.byType(MxToggle));
    await tester.pump();
    expect(find.byType(MxSpinner), findsOneWidget);
    expect(find.byType(MxToggle), findsNothing);

    hold.complete();
    await _settle(tester);
    expect(s.platform.calls.where((c) => c == PlatformCall.requestPermission), hasLength(1));
  });

  libraryTest('permDenied: the guidance and Try again, which asks again (E1)', (tester, env) async {
    final s = await _pump(tester, env, platform: FakeReminderPlatform(permission: ReminderPermission.denied));
    await _toggle(tester);

    expect(find.text(_en.reminderDeniedTitle), findsOneWidget);
    expect(find.text(_en.reminderDeniedBody), findsOneWidget);
    expect(find.text(_en.reminderDeniedHint), findsOneWidget);
    expect(tester.widget<MxToggle>(find.byType(MxToggle)).isOn, isFalse);

    s.platform.permission = ReminderPermission.granted;
    await tester.tap(find.text(_en.reminderTryAgain));
    await _settle(tester);
    expect(find.byType(MxInlineBanner), findsNothing);
    expect(find.text(_en.reminderOnHint), findsOneWidget);
  });

  libraryTest('couldNotSchedule on Enable: danger banner, Retry enables (E3)', (tester, env) async {
    final platform = FakeReminderPlatform()..refusing.add(PlatformCall.schedule);
    await _pump(tester, env, platform: platform);
    await _toggle(tester);

    expect(find.text(_en.reminderCouldNotTurnOnTitle), findsOneWidget);
    platform.refusing.clear();
    await tester.tap(find.text(_en.commonRetry));
    await _settle(tester);
    expect(find.text(_en.reminderOnHint), findsOneWidget);
  });

  libraryTest('offMayShow: off, the warning and Try again, which only cancels (E6)',
      (tester, env) async {
    final s = await _pump(tester, env);
    await _toggle(tester);
    s.platform.refusing.add(PlatformCall.cancel);
    await _toggle(tester);

    expect(find.text(_en.reminderMayStillShow), findsOneWidget);
    expect(find.text(_en.reminderOffHint), findsOneWidget);
    s.platform.refusing.clear();
    final writes = s.store.writes;
    await tester.tap(find.text(_en.reminderTryAgain));
    await _settle(tester);
    expect(find.text(_en.reminderMayStillShow), findsNothing);
    expect(s.store.writes, writes);
  });

  libraryTest('unavailable: one row, no toggle, no time, no preview (E2)', (tester, env) async {
    await _pump(tester, env, platform: FakeReminderPlatform(capabilityValue: ReminderCapability.unsupported));

    expect(find.text(_en.reminderUnavailable), findsOneWidget);
    expect(find.byType(MxToggle), findsNothing);
    expect(find.text(_en.reminderTime), findsNothing);
    expect(find.text(_en.reminderPreviewTitle), findsNothing);
  });

  libraryTest('E4: a failed save says so with Retry; the toggle stays off', (tester, env) async {
    final s = await _pump(tester, env);
    s.store.isFailing = true;
    await _toggle(tester);

    expect(find.text(_en.reminderSaveFailed), findsOneWidget);
    expect(find.textContaining('/data/'), findsNothing, reason: 'BR-CORE-005');
    expect(tester.widget<MxToggle>(find.byType(MxToggle)).isOn, isFalse);

    s.store.isFailing = false;
    await tester.tap(find.text(_en.commonRetry));
    await _settle(tester);
    expect(find.text(_en.reminderOnHint), findsOneWidget);
  });

  libraryTest('loading: the list skeleton', (tester, env) async {
    final never = StreamController<ReminderStatus>();
    addTearDown(never.close);
    await pumpLibraryScreen(tester, env, const ReminderScreen(), overrides: [
      reminderStatusProvider.overrideWith((ref) => never.stream),
    ]);
    await tester.pump();
    expect(find.byType(MxSkeletonList), findsOneWidget);
  });

  libraryTest('E7: a failed read replaces the body, Retry reads again', (tester, env) async {
    await pumpLibraryScreen(tester, env, const ReminderScreen(), overrides: [
      reminderStatusProvider.overrideWith((ref) => Stream.error(FlakySettingsRepository.failure)),
    ]);
    await _settle(tester);

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.text(_en.reminderReadErrorTitle), findsOneWidget);
    expect(find.byType(MxToggle), findsNothing);
    expect(find.text(_en.commonRetry), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run it to verify it fails**

Run: `flutter test test/features/reminders/presentation/reminder_screen_test.dart`
Expected: compile failure — `reminder_screen.dart` does not exist.

- [ ] **Step 4: Write the section widgets**

```dart
// lib/features/reminders/presentation/widgets/sections/reminder_settings_section_widget.dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/reminders/presentation/states/reminder_action_state.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

/// Kit 24's first section: the toggle row and the time row, under the note
/// that says when it fires (UC-REMINDER-001 step 1). While an operation
/// runs, nothing here starts another (FE-B5 spec D4).
class ReminderSettingsSectionWidget extends StatelessWidget {
  const ReminderSettingsSectionWidget({
    super.key,
    required this.reminder,
    required this.action,
    required this.isPickingTime,
    required this.onToggle,
    required this.onPickTime,
  });

  final ReminderSettings reminder;
  final ReminderActionState action;

  /// The time dialog is open (kit `changingTime`).
  final bool isPickingTime;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isOn = reminder.isEnabled;
    final time = reminderTimeLabel(context, reminder.minuteOfDay);
    final isTurning =
        action.running == ReminderOperation.turnOn ||
        action.running == ReminderOperation.turnOff;
    return MxSection(
      note: l10n.reminderNote,
      children: [
        MxSettingsRow(
          label: l10n.reminderTitle,
          icon: AppIcons.reminder,
          subtitle: switch ((isOn, action.problem)) {
            (true, _) => l10n.reminderOnHint,
            (false, ReminderProblem.permissionDenied) =>
              l10n.reminderDeniedHint,
            (false, _) => l10n.reminderOffHint,
          },
          trailing: isTurning
              ? MxSpinner(semanticLabel: l10n.commonLoading)
              : MxToggle(
                  isOn: isOn,
                  semanticLabel: l10n.reminderTitle,
                  onChanged: action.isBusy ? null : onToggle,
                ),
        ),
        MxSettingsRow(
          label: l10n.reminderTime,
          icon: AppIcons.clock,
          isEnabled: isOn,
          subtitle: isOn ? l10n.reminderTimeOnHint : l10n.reminderTimeOffHint,
          trailing: Semantics(
            label: l10n.reminderTimeButton(time),
            excludeSemantics: true,
            button: true,
            child: MxButton(
              label: time,
              size: MxButtonSize.compact,
              tone: isPickingTime ? MxButtonTone.outline : MxButtonTone.secondary,
              isLoading: action.running == ReminderOperation.changeTime,
              onPressed: isOn && !action.isBusy ? onPickTime : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// A minute of the local day as 24-hour `HH:mm` in every language (FE-B5
/// spec D9).
String reminderTimeLabel(BuildContext context, int minuteOfDay) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: minuteOfDay ~/ 60, minute: minuteOfDay % 60),
      alwaysUse24HourFormat: true,
    );
```

If `60` trips the guard's magic-number rule, name it: `const int _minutesPerHour = Duration.minutesPerHour;` and use `Duration.minutesPerHour` directly.

```dart
// lib/features/reminders/presentation/widgets/sections/reminder_banners_widget.dart
import 'package:flutter/material.dart';
import 'package:memox/features/reminders/presentation/states/reminder_action_state.dart';
import 'package:memox/features/reminders/presentation/widgets/sections/reminder_settings_section_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

/// The last operation's problem, with the action that repeats it (E1, E3,
/// E6). Kit 24's "Open system settings" is hidden (FE-B5 spec D1).
class ReminderBannersWidget extends StatelessWidget {
  const ReminderBannersWidget({
    super.key,
    required this.problem,
    required this.storedMinute,
    required this.isBusy,
    required this.onRetry,
  });

  final ReminderProblem? problem;
  final int storedMinute;
  final bool isBusy;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget action(String label) => MxButton(
      label: label,
      size: MxButtonSize.compact,
      onPressed: isBusy ? null : onRetry,
    );
    return switch (problem) {
      null => const SizedBox.shrink(),
      ReminderProblem.permissionDenied => MxInlineBanner(
        tone: MxBannerTone.warning,
        title: l10n.reminderDeniedTitle,
        message: l10n.reminderDeniedBody,
        actions: [action(l10n.reminderTryAgain)],
      ),
      ReminderProblem.couldNotTurnOn => MxInlineBanner(
        tone: MxBannerTone.danger,
        title: l10n.reminderCouldNotTurnOnTitle,
        message: l10n.reminderCouldNotTurnOnBody,
        actions: [action(l10n.commonRetry)],
      ),
      ReminderProblem.couldNotChangeTime => MxInlineBanner(
        tone: MxBannerTone.danger,
        title: l10n.reminderCouldNotChangeTimeTitle,
        message: l10n.reminderCouldNotChangeTimeBody(
          reminderTimeLabel(context, storedMinute),
        ),
        actions: [action(l10n.commonRetry)],
      ),
      ReminderProblem.mayStillShow => MxInlineBanner(
        tone: MxBannerTone.warning,
        message: l10n.reminderMayStillShow,
        actions: [action(l10n.reminderTryAgain)],
      ),
    };
  }
}
```

```dart
// lib/features/reminders/presentation/widgets/sections/reminder_preview_section_widget.dart
import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// Kit 24's "What it says": the kind of sentence the notification carries,
/// and what it never carries (BR-REMINDER-005, BR-REMINDER-008).
class ReminderPreviewSectionWidget extends StatelessWidget {
  const ReminderPreviewSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxSection(
      title: l10n.reminderPreviewTitle,
      children: [
        MxSettingsRow(
          label: l10n.reminderPreviewSample,
          subtitle: l10n.reminderPreviewHint,
        ),
      ],
    );
  }
}
```

If `MxSettingsRow` ellipsizes its label, the sample is cut: in that case render the sample row as an `MxCard` with the label in `context.textStyles.listRowTitle` and the hint in `rowSubtitle`, and record it in the detail file.

- [ ] **Step 5: Write the screen**

```dart
// lib/features/reminders/presentation/screens/reminder_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_status_model.dart';
import 'package:memox/features/reminders/presentation/controllers/reminder_controller.dart';
import 'package:memox/features/reminders/presentation/providers/reminder_status_provider.dart';
import 'package:memox/features/reminders/presentation/states/reminder_action_state.dart';
import 'package:memox/features/reminders/presentation/widgets/sections/reminder_banners_widget.dart';
import 'package:memox/features/reminders/presentation/widgets/sections/reminder_preview_section_widget.dart';
import 'package:memox/features/reminders/presentation/widgets/sections/reminder_settings_section_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 24, Daily reminder (UC-REMINDER-001): the stored reminder from the
/// stream, the operation in flight and its outcome from the controller
/// (FE-B5 spec D3). Opening it asks nothing of the platform but its
/// capability (BR-REMINDER-011).
class ReminderScreen extends ConsumerStatefulWidget {
  const ReminderScreen({super.key});

  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends ConsumerState<ReminderScreen> {
  static const int _skeletonRows = 3;

  /// The time dialog is open (kit `changingTime`).
  var _isPickingTime = false;

  ReminderController get _controller =>
      ref.read(reminderControllerProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen(
      reminderControllerProvider.select((state) => state.saveFailed),
      (_, failed) {
        if (failed == null) return;
        showMxSnackbar(
          context,
          message: l10n.reminderSaveFailed,
          actionLabel: l10n.commonRetry,
          onAction: () => unawaited(_controller.retry()),
        );
      },
    );
    final action = ref.watch(reminderControllerProvider);
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.reminderTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: switch (ref.watch(reminderStatusProvider)) {
        AsyncData(:final value) => _loaded(context, value, action),
        AsyncError() => MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.reminderReadErrorTitle,
              body: l10n.reminderReadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(reminderStatusProvider),
            ),
          ],
        ),
        _ => MxScreenScroll(
          children: [
            MxSkeletonList(
              semanticLabel: l10n.commonLoading,
              rows: _skeletonRows,
            ),
          ],
        ),
      },
    );
  }

  Widget _loaded(
    BuildContext context,
    ReminderStatus status,
    ReminderActionState action,
  ) {
    final l10n = context.l10n;
    if (status.capability == ReminderCapability.unsupported) {
      return MxScreenScroll(
        children: [
          MxSection(
            children: [
              MxSettingsRow(
                label: l10n.reminderUnavailable,
                subtitle: l10n.reminderUnavailableHint,
                icon: AppIcons.reminderOff,
              ),
            ],
          ),
        ],
      );
    }
    return MxScreenScroll(
      children: [
        ReminderSettingsSectionWidget(
          reminder: status.reminder,
          action: action,
          isPickingTime: _isPickingTime,
          onToggle: (isOn) => unawaited(
            isOn ? _controller.turnOn() : _controller.turnOff(),
          ),
          onPickTime: () => unawaited(_pickTime(status.reminder.minuteOfDay)),
        ),
        ReminderBannersWidget(
          problem: action.problem,
          storedMinute: status.reminder.minuteOfDay,
          isBusy: action.isBusy,
          onRetry: () => unawaited(_controller.retry()),
        ),
        const SizedBox(height: AppSpacing.gutter),
        const ReminderPreviewSectionWidget(),
      ],
    );
  }

  /// Task 3 replaces this body with the dialog.
  Future<void> _pickTime(int minuteOfDay) async {}
}
```

Check `MxAppBarDensity` and `MxIconButton` imports against `theme_screen.dart` and copy its import lines exactly.

- [ ] **Step 6: Run the tests**

Run: `flutter test test/features/reminders/presentation/reminder_screen_test.dart`
Expected: PASS (10 tests). A failure on a banner means the banner sits outside the scroll; a failure on the spinner means `isTurning` misses the operation — fix the widget, not the test.

- [ ] **Step 7: Format, analyze, commit**

Run: `dart format lib test && flutter analyze && python3 tools/docs/check.py`
Expected: `No issues found!`; `PASS — 0 error(s)`.

```bash
git add lib/core/theme/foundations/app_icons.dart lib/l10n lib/features/reminders/presentation test/features/reminders/presentation/reminder_screen_test.dart
git commit -m "feat(reminders): screen 24's rows, banners, preview, loading, unavailable, E4 and E7 (FE-B5)"
```

---

### Task 3: The time dialog (A1)

**Files:**
- Create: `lib/features/reminders/presentation/widgets/overlays/reminder_time_dialog_widget.dart`
- Modify: `lib/features/reminders/presentation/screens/reminder_screen.dart` (`_pickTime`), `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/reminders/presentation/reminder_screen_test.dart` (append)

**Interfaces:**
- Consumes: `ReminderController.changeTime(int)`, `reminderTimeLabel(BuildContext, int)`.
- Produces: `Future<int?> showReminderTimeDialog(BuildContext context, {required int minuteOfDay})` returning the minute of the day, or null on Cancel.

- [ ] **Step 1: Add the strings**

| Key | en | vi |
|---|---|---|
| `reminderTimeDialogTitle` | Reminder time | Giờ nhắc |
| `reminderHour` | Hour | Giờ |
| `reminderMinute` | Minute | Phút |
| `reminderEarlierHour` | Earlier hour | Giờ sớm hơn |
| `reminderLaterHour` | Later hour | Giờ muộn hơn |
| `reminderEarlierMinute` | Earlier minute | Phút sớm hơn |
| `reminderLaterMinute` | Later minute | Phút muộn hơn |
| `reminderTimeSave` | Save | Lưu |

Run: `flutter gen-l10n`

- [ ] **Step 2: Append the failing tests**

```dart
  libraryTest('off: the time row is disabled', (tester, env) async {
    await _pump(tester, env);
    await tester.tap(find.text('20:00'));
    await _settle(tester);
    expect(find.text(_en.reminderTimeDialogTitle), findsNothing);
  });

  libraryTest('A1: Cancel changes nothing; Save stores and schedules the new minute',
      (tester, env) async {
    final s = await _pump(tester, env);
    await _toggle(tester);
    final scheduledBefore = s.platform.pending;

    await tester.tap(find.text('20:00'));
    await _settle(tester);
    await tester.tap(find.byTooltip(_en.reminderLaterHour));
    await tester.pump();
    await tester.tap(find.text(_en.commonCancel));
    await _settle(tester);
    expect(find.text('20:00'), findsOneWidget);
    expect(s.platform.pending, scheduledBefore);

    await tester.tap(find.text('20:00'));
    await _settle(tester);
    await tester.tap(find.byTooltip(_en.reminderLaterHour));
    await tester.pump();
    expect(find.text('21:00'), findsOneWidget, reason: 'the dialog reads the chosen time');
    await tester.tap(find.text(_en.reminderTimeSave));
    await _settle(tester);
    expect(find.text('21:00'), findsOneWidget);
    expect(s.platform.pending, isNot(scheduledBefore));
  });

  libraryTest('a typed minute outside 0–59 disables Save', (tester, env) async {
    await _pump(tester, env);
    await _toggle(tester);
    await tester.tap(find.text('20:00'));
    await _settle(tester);

    // The minute stepper's value; a tap makes it typeable (MxStepper).
    await tester.tap(find.text('0').last);
    await tester.pump();
    await tester.enterText(find.byType(EditableText).last, '75');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    final save = find.widgetWithText(MxButton, _en.reminderTimeSave);
    expect(tester.widget<MxButton>(save).onPressed, isNull);
  });

  libraryTest('couldNotChangeTime: the old time stands, the banner names it (E3)',
      (tester, env) async {
    final s = await _pump(tester, env);
    await _toggle(tester);
    s.platform.refusing.add(PlatformCall.schedule);

    await tester.tap(find.text('20:00'));
    await _settle(tester);
    await tester.tap(find.byTooltip(_en.reminderLaterHour));
    await tester.tap(find.text(_en.reminderTimeSave));
    await _settle(tester);

    expect(find.text(_en.reminderCouldNotChangeTimeTitle), findsOneWidget);
    expect(find.text(_en.reminderCouldNotChangeTimeBody('20:00')), findsOneWidget);
  });
```

Add `import 'package:memox/shared/widgets/mx_button.dart';` to the test.

- [ ] **Step 3: Run to verify they fail**

Run: `flutter test test/features/reminders/presentation/reminder_screen_test.dart`
Expected: the A1, typed-minute and couldNotChangeTime tests FAIL (no dialog opens); `off: the time row is disabled` passes already.

- [ ] **Step 4: Write the dialog**

```dart
// lib/features/reminders/presentation/widgets/overlays/reminder_time_dialog_widget.dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/reminders/presentation/widgets/sections/reminder_settings_section_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';

/// Opens the time dialog of screen 24 (UC-REMINDER-001 A1) on
/// [minuteOfDay]; completes with the chosen minute of the day, or null on
/// Cancel (FE-B5 spec D2, §5.2).
Future<int?> showReminderTimeDialog(
  BuildContext context, {
  required int minuteOfDay,
}) => showMxDialog<int>(
  context,
  builder: (_) => ReminderTimeDialogWidget(minuteOfDay: minuteOfDay),
);

/// An hour stepper 0–23 and a minute stepper 0–59, each repeating on hold
/// and typeable; a typed value out of range marks its stepper and keeps
/// Save off.
class ReminderTimeDialogWidget extends StatefulWidget {
  const ReminderTimeDialogWidget({super.key, required this.minuteOfDay});

  final int minuteOfDay;

  @override
  State<ReminderTimeDialogWidget> createState() =>
      _ReminderTimeDialogWidgetState();
}

class _ReminderTimeDialogWidgetState extends State<ReminderTimeDialogWidget> {
  static const int _lastHour = 23;
  static const int _lastMinute = 59;
  static const int _digits = 2;

  late int _hour = widget.minuteOfDay ~/ Duration.minutesPerHour;
  late int _minute = widget.minuteOfDay % Duration.minutesPerHour;
  var _isHourInvalid = false;
  var _isMinuteInvalid = false;

  bool get _canSave => !_isHourInvalid && !_isMinuteInvalid;

  int get _chosen => _hour * Duration.minutesPerHour + _minute;

  /// Digits within 0–[last] set the value; anything else marks it invalid.
  (int, bool) _typed(String text, int current, int last) {
    final value = int.tryParse(text);
    if (value == null || value < 0 || value > last) return (current, true);
    return (value, false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      title: l10n.reminderTimeDialogTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.control,
        children: [
          _labelled(
            context,
            l10n.reminderHour,
            MxStepper(
              value: _hour,
              valueLabel: l10n.reminderHour,
              editHint: l10n.commonEdit,
              decrementLabel: l10n.reminderEarlierHour,
              incrementLabel: l10n.reminderLaterHour,
              maxDigits: _digits,
              isInvalid: _isHourInvalid,
              onDecrement: _hour > 0 ? () => setState(() => _hour--) : null,
              onIncrement: _hour < _lastHour
                  ? () => setState(() => _hour++)
                  : null,
              onValueSubmitted: (text) => setState(() {
                (_hour, _isHourInvalid) = _typed(text, _hour, _lastHour);
              }),
            ),
          ),
          _labelled(
            context,
            l10n.reminderMinute,
            MxStepper(
              value: _minute,
              valueLabel: l10n.reminderMinute,
              editHint: l10n.commonEdit,
              decrementLabel: l10n.reminderEarlierMinute,
              incrementLabel: l10n.reminderLaterMinute,
              maxDigits: _digits,
              isInvalid: _isMinuteInvalid,
              onDecrement: _minute > 0
                  ? () => setState(() => _minute--)
                  : null,
              onIncrement: _minute < _lastMinute
                  ? () => setState(() => _minute++)
                  : null,
              onValueSubmitted: (text) => setState(() {
                (_minute, _isMinuteInvalid) = _typed(text, _minute, _lastMinute);
              }),
            ),
          ),
          Text(
            reminderTimeLabel(context, _chosen),
            style: context.textStyles.statValue,
          ),
        ],
      ),
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(),
        confirmLabel: l10n.reminderTimeSave,
        onConfirm: _canSave ? () => Navigator.of(context).pop(_chosen) : null,
      ),
    );
  }

  Widget _labelled(BuildContext context, String label, Widget stepper) => Row(
    children: [
      Expanded(child: Text(label, style: context.textStyles.listRowTitle)),
      stepper,
    ],
  );
}
```

Before writing, confirm the text-style names on `context.textStyles` (`grep -n "TextStyle get" lib/core/theme/*.dart`) and the import that provides `context.textStyles` (copy it from `settings_study_defaults_section_widget.dart`); use the nearest existing names for a row title and a large tabular number. `commonEdit` exists (used by screen 23's stepper).

- [ ] **Step 5: Wire `_pickTime`**

Replace the stub in `reminder_screen.dart`:

```dart
  /// A1: the dialog opens on the stored time; Save changes it, Cancel
  /// changes nothing.
  Future<void> _pickTime(int minuteOfDay) async {
    setState(() => _isPickingTime = true);
    final chosen = await showReminderTimeDialog(
      context,
      minuteOfDay: minuteOfDay,
    );
    if (!mounted) return;
    setState(() => _isPickingTime = false);
    if (chosen == null || chosen == minuteOfDay) return;
    await _controller.changeTime(chosen);
  }
```

and add `import 'package:memox/features/reminders/presentation/widgets/overlays/reminder_time_dialog_widget.dart';`.

- [ ] **Step 6: Run the tests**

Run: `flutter test test/features/reminders/presentation/`
Expected: PASS (all of Task 1–3).

- [ ] **Step 7: Format, analyze, commit**

Run: `dart format lib test && flutter analyze`
Expected: `No issues found!`

```bash
git add lib/l10n lib/features/reminders/presentation test/features/reminders/presentation/reminder_screen_test.dart
git commit -m "feat(reminders): screen 24's time dialog, two steppers (FE-B5 D2, A1)"
```

---

### Task 4: Route, screen 23's row, reset copy and reconcile after reset

**Files:**
- Modify: `lib/app/router/app_routes.dart`, `lib/app/router/app_router.dart`, `lib/features/settings/presentation/screens/settings_screen.dart`, `lib/features/settings/presentation/widgets/sections/settings_app_section_widget.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/settings/presentation/settings_screen_test.dart`, plus every file constructing `SettingsScreen(` (`grep -rln "SettingsScreen(" test lib`)

**Interfaces:**
- Consumes: `ReminderScreen`, `reconcileReminderProvider`.
- Produces: `AppRoutes.settingsReminderChild = 'reminder'`, `AppRoutes.settingsReminder`; `SettingsScreen({required onOpenTheme, required onOpenLanguage, required onOpenReminder, required onAppOptionsReset, onOpenGallery})`.

- [ ] **Step 1: Strings**

| Key | en | vi |
|---|---|---|
| `settingsReminder` | Daily reminder | Nhắc học hằng ngày |
| `settingsReminderOff` | Off | Tắt |
| `settingsReminderOn` `{time}` | On · {time} | Bật · {time} |

Change `settingsResetRowHint` to "Theme, language, study defaults, reminder" (vi: add ", nhắc học" to the existing value), and `settingsResetBody` to "Theme, language, cards per session, new-card order and the daily reminder (off, 20:00) go back to their defaults." (vi: rewrite the existing value to name "nhắc học hằng ngày (tắt, 20:00)"). Update both `@` descriptions to cite register row 123 closed by FE-B5.

- [ ] **Step 2: Write the failing tests**

In `settings_screen_test.dart`, replace the `_screen` helper and the first test's last expectation:

```dart
SettingsScreen _screen({
  VoidCallback? onOpenTheme,
  VoidCallback? onOpenLanguage,
  VoidCallback? onOpenReminder,
  VoidCallback? onAppOptionsReset,
}) => SettingsScreen(
  onOpenTheme: onOpenTheme ?? () {},
  onOpenLanguage: onOpenLanguage ?? () {},
  onOpenReminder: onOpenReminder ?? () {},
  onAppOptionsReset: onAppOptionsReset ?? () {},
);
```

Rename the first test to `'the three sections show the stored values, the reminder row included'` and replace `expect(find.textContaining('eminder'), findsNothing);` with:

```dart
    expect(find.text(_en.settingsReminder), findsOneWidget);
    expect(find.text(_en.settingsReminderOff), findsOneWidget);
```

Append:

```dart
  libraryTest('the reminder row names the time when on, and opens screen 24', (
    tester,
    env,
  ) async {
    await SettingsRepositoryImpl(env.db).saveReminder(
      reminder: const ReminderSettings(isEnabled: true, minuteOfDay: 21 * 60),
    );
    var opened = 0;
    await pumpLibraryScreen(tester, env, _screen(onOpenReminder: () => opened++));

    expect(find.text(_en.settingsReminderOn('21:00')), findsOneWidget);
    await tester.tap(find.text(_en.settingsReminder));
    expect(opened, 1);
  });

  libraryTest('reset: onAppOptionsReset runs once on success, never on failure', (
    tester,
    env,
  ) async {
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db));
    var resets = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(onAppOptionsReset: () => resets++),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );

    store.isFailing = true;
    await tester.tap(find.text(_en.settingsResetRow));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.settingsResetConfirm));
    await tester.pumpAndSettle();
    expect(resets, 0);

    store.isFailing = false;
    await tester.tap(find.text(_en.settingsResetRow));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.settingsResetConfirm));
    await tester.pumpAndSettle();
    expect(resets, 1);
    expect(find.textContaining('daily reminder'), findsNothing,
        reason: 'the dialog closed');
  });
```

Add `import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';`. Update every other `SettingsScreen(` construction in tests (golden test's `_screen`, visual audit companion, any gallery/app test) with `onOpenReminder: () {}, onAppOptionsReset: () {}`.

- [ ] **Step 3: Run to verify they fail**

Run: `flutter test test/features/settings/presentation/settings_screen_test.dart`
Expected: compile failure — no named parameter `onOpenReminder`.

- [ ] **Step 4: The row**

In `settings_app_section_widget.dart`, add `required this.onOpenReminder,` and `final VoidCallback onOpenReminder;`, replace the class comment's last sentence with "The Daily reminder row names the stored reminder and opens screen 24 (FE-B5 spec D6).", and append to `children`:

```dart
        MxSettingsRow(
          label: l10n.settingsReminder,
          subtitle: stored.reminder.isEnabled
              ? l10n.settingsReminderOn(
                  MaterialLocalizations.of(context).formatTimeOfDay(
                    TimeOfDay(
                      hour: stored.reminder.minuteOfDay ~/ Duration.minutesPerHour,
                      minute: stored.reminder.minuteOfDay % Duration.minutesPerHour,
                    ),
                    alwaysUse24HourFormat: true,
                  ),
                )
              : l10n.settingsReminderOff,
          icon: AppIcons.reminder,
          onTap: onOpenReminder,
        ),
```

- [ ] **Step 5: The screen's callbacks**

In `settings_screen.dart`: add `required this.onOpenReminder, required this.onAppOptionsReset,` to the constructor with fields

```dart
  final VoidCallback onOpenReminder;

  /// After Reset app options landed: `app/` reconciles the reminder, which
  /// the reset turned off (FE-B5 spec D7; reminders spec §9 "For FE-A3").
  final VoidCallback onAppOptionsReset;
```

pass `onOpenReminder: onOpenReminder` to `SettingsAppSectionWidget`, and in `_say`, before building the message:

```dart
    if (notice is SettingsSaved && notice.kind == SettingsSubmit.reset) {
      onAppOptionsReset();
    }
```

- [ ] **Step 6: Route and wiring**

`app_routes.dart`, after the language constants:

```dart
  /// The daily reminder (screen 24), relative to [settings], on the root
  /// navigator like Theme and Language (FE-B5 spec D5).
  static const String settingsReminderChild = 'reminder';
  static const String settingsReminder = '$settings/$settingsReminderChild';
```

`app_router.dart`, in the Settings `GoRoute`:

```dart
                builder: (context, state) => SettingsScreen(
                  onOpenTheme: () => context.push(AppRoutes.settingsTheme),
                  onOpenLanguage: () =>
                      context.push(AppRoutes.settingsLanguage),
                  onOpenReminder: () =>
                      context.push(AppRoutes.settingsReminder),
                  // The reset turned the reminder off; the pending alarm
                  // follows through the gate (FE-B5 spec D7).
                  onAppOptionsReset: () => unawaited(
                    _reconcileAfterReset(ProviderScope.containerOf(context)),
                  ),
                  onOpenGallery: hasGallery
                      ? () => context.push(AppRoutes.gallery)
                      : null,
                ),
```

with the child route

```dart
                  GoRoute(
                    path: AppRoutes.settingsReminderChild,
                    parentNavigatorKey: rootNavigator,
                    builder: (context, state) => const ReminderScreen(),
                  ),
```

and, at the bottom of the file:

```dart
/// A refusal or a read that fails changes nothing on screen; the next start
/// or resume reconciles again, as `app.dart` does.
Future<void> _reconcileAfterReset(ProviderContainer container) async {
  try {
    await container.read(reconcileReminderProvider)();
  } on Failure {
    // Retried at the next start or resume.
  }
}
```

Imports: `flutter_riverpod`, `core/error/failure.dart`, `reconcile_reminder_provider.dart`, `reminder_screen.dart`. If `context.push` returns a Future the file already wraps with `unawaited`, follow the file's form.

- [ ] **Step 7: Run the tests**

Run: `flutter test test/features/settings test/app test/features/reminders`
Expected: PASS.

- [ ] **Step 8: Format, analyze, architecture, commit**

Run: `dart format lib test && flutter analyze && bash .claude/skills/flutter-architecture/scripts/check_architecture.sh`
Expected: no issues; the architecture check clean (settings imports nothing from reminders).

```bash
git add lib test
git commit -m "feat(settings): screen 23's Daily reminder row, reset names the reminder and reconciles it (FE-B5 D5-D7)"
```

---

### Task 5: Goldens and the visual-audit companion

**Files:**
- Create: `test/features/reminders/presentation/reminder_screen_golden_test.dart`, `test/features/reminders/presentation/goldens/*.png`, `test/visual_audit/screens/features/reminders/screens/reminder_screen_visual_audit_test.dart`
- Modify: `test/features/settings/presentation/goldens/settings_loaded_{light,dark}.png` (the new row)

- [ ] **Step 1: Prove the host renders like the committed goldens**

Run: `bash .claude/skills/flutter-workflow/scripts/prepare_test_fonts.sh; TZ=UTC flutter test --tags golden test/features/settings/presentation/ test/features/study/presentation/study_home_golden_test.dart`
Expected: only `settings_loaded_*` fail (Task 4's row); every other golden passes. If anything else fails, stop: the host is not CI's renderer, and goldens must be written in the Docker image instead.

- [ ] **Step 2: Write the golden test**

```dart
// test/features/reminders/presentation/reminder_screen_golden_test.dart
@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_status_model.dart';
import 'package:memox/features/reminders/presentation/providers/reminder_status_provider.dart';
import 'package:memox/features/reminders/presentation/screens/reminder_screen.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../../support/fake_reminder_platform.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<FlakySettingsRepository> shoot(
      WidgetTester tester,
      LibraryEnv env,
      String state, {
      FakeReminderPlatform? platform,
      Future<void> Function(FlakySettingsRepository store)? act,
      List<Override> overrides = const [],
      double textScale = 1,
    }) async {
      final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db));
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          const ReminderScreen(),
          brightness,
          textScale: textScale,
          overrides: [
            reminderPlatformRepositoryProvider.overrideWithValue(platform ?? FakeReminderPlatform()),
            settingsRepositoryProvider.overrideWithValue(store),
            ...overrides,
          ],
        );
        await _settle(tester);
        if (act != null) await act(store);
        await expectBoundaryGolden(tester, 'goldens/reminder_${state}_$theme.png');
      });
      return store;
    }

    Future<void> toggle(WidgetTester tester) async {
      await tester.tap(find.byType(MxToggle));
      await _settle(tester);
    }

    libraryTest('reminder, off, $theme', (tester, env) => shoot(tester, env, 'off'));

    libraryTest('reminder, on, $theme', (tester, env) async {
      await shoot(tester, env, 'on', act: (_) => toggle(tester));
    });

    libraryTest('reminder, turning on, $theme', (tester, env) async {
      final hold = Completer<void>();
      await shoot(tester, env, 'turning_on', act: (store) async {
        store.hold = hold;
        await tester.tap(find.byType(MxToggle));
        await tester.pump();
      });
      hold.complete();
      await _settle(tester);
    });

    libraryTest('reminder, changing time, $theme', (tester, env) async {
      await shoot(tester, env, 'changing_time', act: (_) async {
        await toggle(tester);
        await tester.tap(find.text('20:00'));
        await _settle(tester);
      });
    });

    libraryTest('reminder, permission denied, $theme', (tester, env) async {
      await shoot(tester, env, 'perm_denied',
          platform: FakeReminderPlatform(permission: ReminderPermission.denied),
          act: (_) => toggle(tester));
    });

    libraryTest('reminder, could not schedule, $theme', (tester, env) async {
      await shoot(tester, env, 'could_not_schedule',
          platform: FakeReminderPlatform()..refusing.add(PlatformCall.schedule),
          act: (_) => toggle(tester));
    });

    libraryTest('reminder, off may show, $theme', (tester, env) async {
      final platform = FakeReminderPlatform();
      await shoot(tester, env, 'off_may_show', platform: platform, act: (_) async {
        await toggle(tester);
        platform.refusing.add(PlatformCall.cancel);
        await toggle(tester);
      });
    });

    libraryTest('reminder, unavailable, $theme', (tester, env) async {
      await shoot(tester, env, 'unavailable',
          platform: FakeReminderPlatform(capabilityValue: ReminderCapability.unsupported));
    });

    libraryTest('reminder, loading, $theme', (tester, env) async {
      final never = StreamController<ReminderStatus>();
      addTearDown(never.close);
      await shoot(tester, env, 'loading',
          overrides: [reminderStatusProvider.overrideWith((ref) => never.stream)]);
    });

    libraryTest('reminder, read error, $theme', (tester, env) async {
      await shoot(tester, env, 'read_error', overrides: [
        reminderStatusProvider.overrideWith((ref) => Stream.error(FlakySettingsRepository.failure)),
      ]);
    });

    libraryTest('reminder, on, large text, $theme', (tester, env) async {
      await shoot(tester, env, 'large_text', textScale: 2, act: (_) => toggle(tester));
    });
  }
}
```

Check `pumpLibraryGolden`'s parameters (`test/support/library_harness.dart:171`) and match them; the loading test's pump must not wait for a value (use `tester.pump()` if `_settle` hangs on the skeleton pulse).

- [ ] **Step 3: Write the goldens and look at every one**

Run: `TZ=UTC flutter test --tags golden test/features/reminders/presentation/reminder_screen_golden_test.dart --update-goldens && TZ=UTC flutter test --tags golden test/features/settings/presentation/settings_screen_golden_test.dart --plain-name "settings, loaded" --update-goldens`
Then open each new PNG (22 reminder, 2 settings) and compare with the kit (`/tmp/.../kit` render or `docs/shared/ui/screen-handoff/img/24-daily-reminder/` once Task 6 captures it). Fix a widget, not a golden, when a state is wrong.

- [ ] **Step 4: Re-run all goldens**

Run: `TZ=UTC flutter test --tags golden`
Expected: `All tests passed!`; the count grows by 22 (floor 60 in CI).

- [ ] **Step 5: The visual-audit companion**

```dart
// test/visual_audit/screens/features/reminders/screens/reminder_screen_visual_audit_test.dart
import 'package:flutter/material.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/presentation/screens/reminder_screen.dart';

import '../../../../../support/fake_reminder_platform.dart';
import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 24, Daily reminder off', (tester, env) async {
    await auditProductionScreen(
      tester,
      screen: ReminderScreen,
      pump: (brightness, scale) async {
        await tester.pumpWidget(const SizedBox());
        await pumpLibraryScreen(
          tester,
          env,
          const ReminderScreen(),
          brightness: brightness,
          textScale: scale,
          overrides: [
            reminderPlatformRepositoryProvider.overrideWithValue(FakeReminderPlatform()),
          ],
        );
      },
    );
  });
}
```

Run: `flutter test test/visual_audit/screens/features/reminders/`
Expected: PASS. A tap-target or text-scale finding is fixed in the widget.

- [ ] **Step 6: Commit**

```bash
git add test/features/reminders test/features/settings/presentation/goldens test/visual_audit/screens/features/reminders
git commit -m "test(reminders): screen 24 goldens light/dark and its visual-audit companion (FE-B5)"
```

---

### Task 6: Documents

**Files:**
- Create: `docs/shared/ui/screen-handoff/24-daily-reminder.md`, `docs/shared/ui/screen-handoff/img/24-daily-reminder/*.png`, `docs/features/reminders/ui.md`
- Modify: `tools/design/screen_states.json`, `docs/shared/ui/screen-handoff/00-index.md`, `docs/shared/ui/screen-state-checklist.md`, `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (register row 123), `docs/features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md`, `docs/shared/ui/navigation.md`, `docs/wbs_FE.md`, `docs/wbs_BE.md`, `docs/features/settings/ui.md` (row and reset copy)

- [ ] **Step 1: Capture the kit's states**

Add to `tools/design/screen_states.json` `screens`, after 23:

```json
{"num": "24", "dir": "24-daily-reminder", "title": "Daily reminder", "states": [
  {"id": "off", "label": "Off"}, {"id": "turningOn", "label": "Turning on"},
  {"id": "on", "label": "On"}, {"id": "changingTime", "label": "Changing time"},
  {"id": "permDenied", "label": "Permission denied"}, {"id": "couldNotSchedule", "label": "Could not schedule"},
  {"id": "offMayShow", "label": "Off · may still show"}, {"id": "unavailable", "label": "Unavailable"},
  {"id": "loading", "label": "Loading"}]}
```

Get the kit HTML with the Artifact tool (`action: read`, `url: https://claude.ai/artifact/UCesgHkzYHKsZwhwVshKRE`), then run: `node tools/design/capture_screens.mjs --html <saved.html> --only 24`
Expected: 18 PNGs under `docs/shared/ui/screen-handoff/img/24-daily-reminder/`. If a label does not match the kit's step label, the tool names it: correct the label from the kit and re-run. Run `node --test tools/design/capture_lib.test.mjs` if the manifest has a validator test.

- [ ] **Step 2: The detail file**

Write `24-daily-reminder.md` with the sections of `23-settings.md`: Layout (regions and widgets as in spec §5.1), States (the nine kit states with kit images and the V8 note, plus rows for E4 and E7 that the kit does not draw, naming the goldens), Built (route, providers, controller, goldens path), Deviations (D1 "Open system settings" hidden → FE-B6; D8 offMayShow as a warning banner with Try again, UC E6; D10 loading as `MxSkeletonList`; couldNotChangeTime's own copy, the kit drawing only Enable's; the time dialog, which the kit does not draw, D2), Accessibility (toggle label, time button read as "Reminder time, {time}", 48 targets, the spinner's label), Copy (every string of Task 2–3).

- [ ] **Step 3: The ledgers**

- Index: row 24 → `| 24 | Daily reminder | 9 | FE-B5 | aligned | [24-daily-reminder.md](24-daily-reminder.md) |`; check that no line of the index still calls screen 24 "out of V8".
- Checklist: the nine rows of screen 24 → `[x] … xong | FE-B5.` (offMayShow notes D8; changingTime notes D2); the summary line and the table row 24 recounted (211 states: 209 done, 0 to do, 2 not done).
- Register row 123: closed by FE-B5, with the new copy.
- UC-REMINDER-001: `code:` gains `lib/features/reminders/presentation/screens/reminder_screen.dart` and `lib/features/reminders/presentation/controllers/reminder_controller.dart`; the Scope line says screen 24 is FE-B5, built; the last criterion stays device-only.
- `navigation.md`: the route `/settings/reminder` under Settings, root navigator, back to 23.
- `docs/features/reminders/ui.md`: mirror `docs/features/settings/ui.md`'s headings for screen 24.
- `docs/features/settings/ui.md`: the reminder row and the reset copy.
- `wbs_FE.md`: FE-B5 `xong` (host), evidence spec, plan, detail file, tests; new row FE-B6 "Nút Open system settings ở `permDenied` của màn 24 (D1 của spec FE-B5)" `chưa bắt đầu`, depends BE-B5b, next step "cùng bước thiết bị của BE-B5b"; "Bước tiếp theo" and "Ngữ cảnh cập nhật" updated.
- `wbs_BE.md`: BE-B5b's next step also checks screen 24 on a device (the permission dialog, E1 twice denied).

Run: `python3 tools/docs/generate.py && python3 tools/docs/check.py`
Expected: `PASS — 0 error(s)`.

- [ ] **Step 4: Commit**

```bash
git add docs tools/design/screen_states.json
git commit -m "docs(reminders): screen 24 handoff, index aligned, checklist, UC, navigation, WBS (FE-B5)"
```

---

### Task 7: Impeccable audit, gate, final review

- [ ] **Step 1: Impeccable after the build**

Run the `impeccable` skill's `audit` on `lib/features/reminders/presentation/screens/reminder_screen.dart`, comparing the goldens of Task 5 with the kit images of Task 6. Fix everything it finds in one batch, re-run the affected tests and goldens once, record accepted deviations in the detail file (CLAUDE.md step 5: never loop on polish).

- [ ] **Step 2: The gate**

Run: `export FLUTTER_ROOT=$(dirname $(dirname $(readlink -f $(which flutter)))); bash .claude/skills/flutter-workflow/scripts/dod_check.sh`
Expected: `✓ mechanical gates passed`. Then `TZ=UTC flutter test --tags golden` → `All tests passed!`.

- [ ] **Step 3: Final whole-branch review**

Run the `requesting-code-review` skill over the branch diff against `origin/master`; fix blocking findings with TDD, re-run the gate once.

- [ ] **Step 4: Commit the fixes and push**

```bash
git push -u origin claude/check-pending-fe-be-tasks-qmi4qc
```
