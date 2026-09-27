# Local backend G5 — the daily reminder on Android Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `ReminderPlatformRepository` gets its Android adapter on
`android_alarm_manager_plus` and `flutter_local_notifications`; Enable, Disable
and Reconcile run one at a time; the fire runs `DeliverReminderUseCase` in the
background; a tap opens Study Home; the app reconciles at start. Everything
that can be verified on the host is; the device check waits for an SDK or a
device (spec D5).

**Architecture:** The two plugins are reached from one data source,
`ReminderPluginsDataSource`, a thin interface whose one real implementation
calls the plugins and whose test fake records calls; the adapter
`AndroidReminderPlatformRepositoryImpl` maps its results to the port's typed
reasons. `ReminderOperationGate` (a queue of futures) serialises Enable,
Disable and Reconcile. The background entry point lives in
`features/reminders/di/`, the composition side a feature may own; the app
listens to the data source's tap stream and routes. Web and the host keep the
unsupported adapter.

**Tech Stack:** Flutter 3.47.5, Riverpod 3, `android_alarm_manager_plus` 5.1.1,
`flutter_local_notifications` 22.3.1, gen-l10n.

**Spec:** `docs/superpowers/specs/2026-09-27-local-backend-completion-design.md` §8
(and `docs/superpowers/specs/2026-09-26-reminders-backend-design.md` §6, §13, §14).

## Global Constraints

- Dependencies: `android_alarm_manager_plus` (inexact one-shot, `allowWhileIdle`,
  rescheduled on reboot, a Dart callback) and `flutter_local_notifications`
  (show under a fixed id, the tap payload); versions pinned here: `^5.1.1`,
  `^22.3.1`.
- `AndroidReminderPlatformRepository` implements the existing
  `ReminderPlatformRepository` port; the use cases do not change and keep their
  tests; Web keeps the unsupported adapter.
- A data-layer `ReminderOperationGate` runs Enable, Disable and Reconcile one at
  a time; the background Deliver runs in its own isolate and reads the settings
  at fire time.
- Entry points: a `@pragma('vm:entry-point')` background callback opens its own
  database connection and runs `DeliverReminderUseCase`; a tap on the
  notification opens Study Home; app start runs Reconcile through the gate.
- Platform files: `AndroidManifest.xml` gets `POST_NOTIFICATIONS` and the boot
  receiver; gradle gets core-library desugaring.
- The alarm is inexact (`exact: false`), so `SCHEDULE_EXACT_ALARM` is not
  requested (BR-REMINDER-009).
- What the notification says: the most urgent root deck's name, its due count
  and how many other roots have cards due, never a card, tag or history
  (BR-REMINDER-005, reminders spec D9). The kit (screen 24, "What it says")
  words it: "86 cards are due in 한국어 TOPIK I · Từ vựng, and 2 other decks
  have cards waiting." Body only, no title.
- Without an SDK or a device the package stops before the device check; the PR
  ships the host-verified part and WBS BE-B5b reads `đang làm`.
- Rollback: back to the unsupported adapter, and remove the two packages.

## Review Focus

1. A plugin call that throws (a `PlatformException`) must come back as the
   port's typed reason, never escape (the port promises no call throws).
2. `schedule` twice must leave one pending alarm (same fixed id, cancel first).
3. `LanguageChoice.system` on a device language that is neither English nor
   Vietnamese falls back to English.
4. Two gate calls started together must not interleave (the second starts only
   after the first completes, even when the first fails).
5. The background callback must close its database and container even when the
   use case throws.

---

### Task 1: Dependencies and the plugin data source

**Files:**
- Modify: `pubspec.yaml` (two dependencies)
- Create: `lib/features/reminders/data/datasources/reminder_plugins_data_source.dart`
  (the interface), `lib/features/reminders/data/datasources/plugin_reminder_plugins_data_source.dart`
  (the one file that imports the plugins)
- Modify: `code-verification-guard-v2/rulesets/memox-v8/memox-architecture-rules.yaml`
  (one rule: the two plugin packages are imported only by that file)
- Test: `code-verification-guard-v2/tests/test_memox_v8_architecture_guard_rules.py`

**Interfaces:**
- Produces:
  ```dart
  /// The two plugins behind one door (BE-B5b): the adapter's tests fake this,
  /// since the plugins do nothing on the host.
  abstract interface class ReminderPluginsDataSource {
    Future<bool?> requestNotificationPermission();
    Future<bool> scheduleAlarm(DateTime at);
    Future<bool> cancelAlarm();
    Future<void> showNotification(String body);
    Future<void> cancelNotification();
    /// The payload of a tap while the app runs.
    Stream<String?> get taps;
    /// The payload that launched the app, if a tap did.
    Future<String?> launchPayload();
  }
  const int reminderAlarmId = 7001;
  const int reminderNotificationId = 7001;
  const String reminderTapPayload = 'study-home';
  ```
  `PluginReminderPluginsDataSource(Future<void> Function() onAlarm)` calls
  `AndroidAlarmManager.oneShotAt(at, reminderAlarmId, onAlarm, exact: false,
  allowWhileIdle: true, wakeup: true, rescheduleOnReboot: true)` after
  `AndroidAlarmManager.cancel(reminderAlarmId)`; `showNotification` uses one
  channel (`daily_reminder`, importance default), `payload: reminderTapPayload`.

- [ ] **Step 1: Add the dependencies**

Run: `flutter pub add android_alarm_manager_plus:^5.1.1 flutter_local_notifications:^22.3.1`
Expected: `Got dependencies!`; `flutter analyze` clean.

- [ ] **Step 2: Write the guard test first** (a file other than the data source
  importing either plugin is reported; the data source is not), run it → FAIL.

- [ ] **Step 3: Add the guard rule** (same shape as
  `memox_v8.architecture.unicode_normalisation_has_one_door`), run → PASS.

- [ ] **Step 4: Write both data source files** as in Interfaces; `flutter analyze` clean.

- [ ] **Step 5: Commit** `feat(reminders): the two plugins behind one data source (BE-B5b G5)`.

---

### Task 2: The Android adapter and the notification text

**Files:**
- Create: `lib/features/reminders/data/repositories/android_reminder_platform_repository_impl.dart`
- Create: `lib/features/reminders/data/mappers/reminder_notification_mapper.dart`
  (`String reminderNotificationBody(ReminderDigest digest, Locale locale)`)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (four keys)
- Test: `test/features/reminders/data/android_reminder_platform_repository_test.dart`,
  `test/features/reminders/data/reminder_notification_mapper_test.dart`

**Interfaces:**
- Consumes: `ReminderPluginsDataSource`, `reminderAlarmId`, `reminderTapPayload`.
- Produces: `AndroidReminderPlatformRepositoryImpl(ReminderPluginsDataSource
  plugins, {Locale Function() systemLocale})`.

ARB (English from the kit; Vietnamese is this package's wording, FE-B5 may
restate both when it builds screen 24):

| Key | en | vi |
|---|---|---|
| `reminderDueCards` | `{count, plural, =1{1 card is due} other{{count} cards are due}}` | `{count} thẻ đến hạn` |
| `reminderOtherDecks` | `{count, plural, =1{1 other deck has cards} other{{count} other decks have cards}}` | `{count} deck khác có thẻ` |
| `reminderBody` | `{due} in {deck}.` | `{due} trong {deck}.` |
| `reminderBodyWithOthers` | `{due} in {deck}, and {others} waiting.` | `{due} trong {deck}, và {others} đang chờ.` |

- [ ] **Step 1: Write the failing tests**
  - mapper: `(deck 'Korean', 86, 2)` en → `86 cards are due in Korean, and 2 other decks have cards waiting.`; `(…, 1, 0)` en → `1 card is due in Korean.`; vi → `86 thẻ đến hạn trong Korean, và 2 deck khác có thẻ đang chờ.`.
  - adapter, against a recording fake:
    - `capability()` → `supported`;
    - `requestPermission()`: `true`/`null` → `granted` (no permission on Android < 13), `false` → `denied`, a throw → `denied`;
    - `schedule(at)`: calls `scheduleAlarm(at)` once and is `Ok`; `false` or a throw → `couldNotSchedule`;
    - `cancel()`: cancels the alarm and the notification, `Ok`; a throw → `couldNotCancel`;
    - `show(digest, language)`: shows the mapper's text for `en`, for `vi`, and for `system` with a system locale `fr` → English; a throw → `couldNotShow`.
- [ ] **Step 2: Run** → FAIL (classes missing).
- [ ] **Step 3: Implement** the ARB keys (`flutter gen-l10n`), the mapper (`lookupAppLocalizations`), the adapter (every plugin call in `try`/`on Object`, mapped to the port's reason).
- [ ] **Step 4: Run** → PASS; `flutter analyze` clean.
- [ ] **Step 5: Commit** `feat(reminders): the Android adapter of the reminder port (BE-B5b G5)`.

---

### Task 3: The operation gate and the use-case providers

**Files:**
- Create: `lib/features/reminders/data/datasources/reminder_operation_gate_data_source.dart`
  (`final class ReminderOperationGate { Future<T> run<T>(Future<T> Function() operation); }`)
- Create: `lib/features/reminders/di/reminder_use_case_providers.dart`
  (`reminderOperationGateProvider` keepAlive; `reconcileReminderProvider`,
  `enableReminderProvider`, `disableReminderProvider` returning gated calls;
  `deliverReminderUseCaseProvider`)
- Modify: `lib/features/reminders/di/reminder_platform_repository_provider.dart`
  (Android adapter when `!kIsWeb && defaultTargetPlatform == TargetPlatform.android`)
- Test: `test/features/reminders/data/reminder_operation_gate_test.dart`

- [ ] **Step 1: Failing tests**: two `run` calls started together run in order
  (the second's body starts after the first completes); a first call that
  throws still lets the second run, and the throw reaches its own caller;
  results come back to their own callers.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement** (chain on a `Future<void>
  _tail`, `whenComplete`). **Step 4: Run** → PASS; the reminders tests still pass
  (`flutter test test/features/reminders`).
- [ ] **Step 5: Commit** `feat(reminders): Enable, Disable and Reconcile run one at a time (BE-B5b G5)`.

---

### Task 4: Entry points — the background fire, the tap, the app start

**Files:**
- Create: `lib/features/reminders/di/reminder_background_bindings.dart`
  (`@pragma('vm:entry-point') Future<void> deliverReminderInBackground()`:
  `WidgetsFlutterBinding.ensureInitialized()`, a `ProviderContainer`, the use
  case, then `container.dispose()` in `finally`, which closes the database)
- Modify: `lib/main.dart` (`AndroidAlarmManager.initialize()` on Android only,
  through the data source; the reconcile after the first frame)
- Modify: `lib/app/app.dart` (listen to `taps` and the launch payload; a
  `reminderTapPayload` goes to `AppRoutes.study`; run `reconcileReminderProvider`
  at start)
- Test: `test/app/reminder_tap_test.dart` (a fake data source: a tap and a
  launch payload open Study Home; another payload does nothing);
  `test/features/reminders/di/reminder_background_bindings_test.dart` (the
  callback runs Deliver once against an in-memory database and disposes the
  container even when Deliver throws)

- [ ] Steps: failing tests → run → implement → run → commit
  `feat(reminders): the fire runs in the background, a tap opens Study Home (BE-B5b G5)`.

---

### Task 5: Platform files

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`: `POST_NOTIFICATIONS`,
  `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`; inside `<application>` the plugin's
  `AlarmService`, `AlarmBroadcastReceiver`, `RebootBroadcastReceiver` (as the
  plugin README gives them).
- Modify: `android/app/build.gradle.kts`: `isCoreLibraryDesugaringEnabled = true`
  in `compileOptions`; `dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }`.

- [ ] **Step 1:** Edit both files exactly as the two plugins' READMEs give them.
- [ ] **Step 2:** Verify what the host can: `xmllint --noout` on the manifest;
  `flutter build apk --debug` → expected to stop at "No Android SDK found"
  (record the exact line). Without an SDK the gradle change is unverified: say
  so in the PR.
- [ ] **Step 3: Commit** `build(android): notification permission, alarm receivers and desugaring (BE-B5b G5)`.

---

### Task 6: Records

- `docs/features/reminders/README.md`: the adapter, the gate, the entry points.
- UC-REMINDER-001 `code:` gains the adapter and the data source (only that field changes).
- WBS BE-B5b → `đang làm`: host part done; next step the device check
  (`flutter build apk`, the reminder fires, the tap opens Study Home, it
  survives a reboot).
- [ ] Verify: `python3 tools/docs/generate.py && python3 tools/docs/check.py` → PASS.
- [ ] Commit `docs(reminders): BE-B5b host part (G5)`.
