# Study speech (read the term aloud) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** In a learning session, read the card's term aloud through the device's TTS engine when a new card comes up, with a speaker button to hear it again, a per-root-deck speech language with an app-wide default, and a device-only on/off switch.

**Architecture:** One door to `flutter_tts` in `lib/core/speech/` behind a `SpeechSynthesizer` interface (a silent one everywhere but Android). The language is a new field of `StudyOptions` (key `tts_language` in `deck.study_config`, column `tts_language` in `app_settings`); the switch is a new device-only column `tts_auto_play`. The session screen computes a pure `SpeechCue` from the view and the turn state and speaks it; the settings screens get one row (screen 15) and two rows (screen 23) that open a language sheet.

**Tech Stack:** Flutter 3.47 / Dart 3.13, Riverpod 3 codegen, Drift 2.35 (`.drift` queries, schema steps), `flutter_tts` 4.2.5, the repo's gate (`dod_check.sh`, `run_goldens.sh`), the code-verification guard (Python).

**Spec:** `docs/superpowers/specs/2026-10-07-study-speech-design.md`

## Global Constraints

- `flutter_tts: ^4.2.5` is the one new dependency (spec D2); `package:flutter_tts` is imported only in `lib/core/speech/plugin_speech_synthesizer.dart` (D1).
- The languages are the fixed list of spec §4, stored by BCP-47 tag; default `en-US` (D5).
- `app_settings` goes from schema 14 to 15 with `tts_language TEXT NOT NULL DEFAULT 'en-US'` (CHECK over the list) and `tts_auto_play INTEGER NOT NULL DEFAULT 1 CHECK (tts_auto_play IN (0, 1))`; neither column syncs, Supabase is untouched (D7).
- A `study_config` without `tts_language` reads as the default; a wrong type or unknown tag makes it unreadable (D6).
- Reading happens only in a `learning` session, in `browse`, `self_assess`, `guess`, `recall`, once per `(card, mode, round, turn)`, never while a write runs or a turn is held, never after the session ended (BR-STUDY-078, BR-STUDY-082).
- Speech is best-effort: every plugin call is wrapped, failures go to `appLogger.warning` with `LogCategory.ui`, never the term's text (BR-STUDY-081).
- Copy in English and Vietnamese ARBs; no hardcoded strings, colours or spacing (flutter-design-system).
- A feature imports another feature's `domain/{entities,models,repositories,failures}` and `di/` only (`test/architecture/boundary_rules.dart`); `study → settings` exists, `settings → study` never.
- Every Linear write is blocked in this workspace (free issue limit reached on 2026-10-07): record progress in the PR only and tell the owner.

## Review Focus

1. **A term that is blank or over 4000 characters.** Android's engine refuses input over `getMaxSpeechInputLength` (4000) and reading whitespace is noise: `speechTextOf` trims, drops the empty, caps the long (Task 1 tests it).
2. **A screen reader is on.** TalkBack reads the card itself; auto-play would talk over it, so the cue is skipped under `MediaQuery.accessibleNavigationOf` while the speaker button still works (spec D13; Task 4 tests it).
3. **Two advances within a second.** The second reading must cut the first: the door calls `stop()` before `speak()`; the screen reads each card once (Task 5's "two swipes" test).
4. **The same card comes back in one session** (`self_assess` Again on a one-card queue, a later `guess` round). The key carries `round` and `answersInSession`, so it is read again (Task 4 tests it).
5. **The first card appears before the settings stream has a value.** The cue waits for `speechSettingsProvider` and the screen cues again when it arrives, so the first card is read in the right language, not skipped (Task 5's "first card" test runs through the real streams).

---

### Task 1: The speech door in `lib/core/speech/`

**Files:**
- Modify: `pubspec.yaml` (dependency), `android/app/src/main/AndroidManifest.xml:74-79`
- Create: `lib/core/speech/speech_language.dart`, `lib/core/speech/speech_synthesizer.dart`, `lib/core/speech/plugin_speech_synthesizer.dart`, `lib/core/speech/di/speech_providers.dart`
- Create: `test/support/fake_speech_synthesizer.dart`, `test/core/speech/speech_language_test.dart`, `test/core/speech/speech_text_test.dart`
- Modify: `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-architecture-rules.yaml` (after the `reminder_plugins_have_one_door` rule), `code-verification-guard-v2/tests/test_memox_v8_architecture_guard_rules.py`
- Modify: `.claude/skills/flutter-project-setup/references/dependencies.md` (the package table), `.claude/skills/flutter-architecture/SKILL.md:19` area (the `core/` list, if it names folders)

**Interfaces:**
- Produces: `enum SpeechLanguage { enUs, enGb, viVn, koKr, jaJp, zhCn, zhTw, frFr, deDe, esEs }` with `String tag`, `static const defaultLanguage = enUs`, `static SpeechLanguage? fromTag(String? tag)`; `abstract interface class SpeechSynthesizer { Future<void> speak(String text, {required SpeechLanguage language}); Future<void> stop(); Future<Set<String>> availableLanguageTags(); }`; `const int maxSpeechInputLength = 4000`; `String? speechTextOf(String text)`; `final class SilentSpeechSynthesizer`; `final speechSynthesizerProvider` (keep-alive, `SpeechSynthesizer`); test support `FakeSpeechSynthesizer` with `List<(String, SpeechLanguage)> spoken`, `int stops`, `Set<String> available`.

- [ ] **Step 1: Add the dependency and the manifest query**

Run:
```bash
cd /home/user/memox-v8 && flutter pub add flutter_tts:^4.2.5
```
Expected: `pubspec.yaml` gains `flutter_tts: ^4.2.5` under `dependencies` (alphabetical, after `flutter_secure_storage`), `pubspec.lock` updated.

In `android/app/src/main/AndroidManifest.xml`, inside the existing `<queries>` block (line 74), add a second intent so Android 11+ lets the app see the TTS engine:

```xml
        <intent>
            <action android:name="android.intent.action.TTS_SERVICE"/>
        </intent>
```

- [ ] **Step 2: Write the failing tests for the language and the text**

`test/core/speech/speech_language_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/speech/speech_language.dart';

// Study speech spec §4, D5: the fixed list and its tags.

void main() {
  test('every language has a distinct BCP-47 tag', () {
    final tags = SpeechLanguage.values.map((l) => l.tag).toSet();
    expect(tags, hasLength(SpeechLanguage.values.length));
    for (final tag in tags) {
      expect(tag, matches(RegExp(r'^[a-z]{2}-[A-Z]{2}$')), reason: tag);
    }
  });

  test('the default is en-US', () {
    expect(SpeechLanguage.defaultLanguage, SpeechLanguage.enUs);
    expect(SpeechLanguage.enUs.tag, 'en-US');
  });

  test('fromTag reads every tag back and knows nothing else', () {
    for (final language in SpeechLanguage.values) {
      expect(SpeechLanguage.fromTag(language.tag), language);
    }
    expect(SpeechLanguage.fromTag('en_US'), isNull);
    expect(SpeechLanguage.fromTag('xx-XX'), isNull);
    expect(SpeechLanguage.fromTag(null), isNull);
  });
}
```

`test/core/speech/speech_text_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/core/speech/speech_synthesizer.dart';

// What reaches the engine (spec §7): trimmed, never empty, never over
// Android's input limit.

void main() {
  test('a term is read trimmed', () {
    expect(speechTextOf('  abandon \n'), 'abandon');
  });

  test('a blank term is nothing to read', () {
    expect(speechTextOf(''), isNull);
    expect(speechTextOf('   \n'), isNull);
  });

  test('a term over the limit is cut at the limit', () {
    final long = 'a' * (maxSpeechInputLength + 10);
    expect(speechTextOf(long), hasLength(maxSpeechInputLength));
  });

  test('the silent synthesizer does nothing and reports no language', () async {
    const silent = SilentSpeechSynthesizer();
    await silent.speak('abandon', language: SpeechLanguage.enUs);
    await silent.stop();
    expect(await silent.availableLanguageTags(), isEmpty);
  });
}
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `cd /home/user/memox-v8 && flutter test test/core/speech`
Expected: FAIL, "Target of URI doesn't exist: package:memox/core/speech/…".

- [ ] **Step 4: Write the language enum**

`lib/core/speech/speech_language.dart`:

```dart
/// The languages the term can be read in (study speech spec §4, D5): a
/// fixed list, each with the BCP-47 tag `app_settings.tts_language` and
/// `deck.study_config`'s `tts_language` store. Adding one is a code change,
/// a schema migration (the CHECK) and two ARB lines.
enum SpeechLanguage {
  enUs('en-US'),
  enGb('en-GB'),
  viVn('vi-VN'),
  koKr('ko-KR'),
  jaJp('ja-JP'),
  zhCn('zh-CN'),
  zhTw('zh-TW'),
  frFr('fr-FR'),
  deDe('de-DE'),
  esEs('es-ES');

  const SpeechLanguage(this.tag);

  /// The BCP-47 tag the engine and the store use.
  final String tag;

  /// What a fresh install and a root without a language read in.
  static const SpeechLanguage defaultLanguage = enUs;

  /// The language [tag] names, or null for one not in the list.
  static SpeechLanguage? fromTag(String? tag) {
    for (final language in values) {
      if (language.tag == tag) return language;
    }
    return null;
  }
}
```

- [ ] **Step 5: Write the interface, the text helper and the silent synthesizer**

`lib/core/speech/speech_synthesizer.dart`:

```dart
import 'package:memox/core/speech/speech_language.dart';

/// Android's `TextToSpeech.getMaxSpeechInputLength()`: longer input is
/// refused by the engine.
const int maxSpeechInputLength = 4000;

/// [text] as it is handed to the engine: trimmed and capped at
/// [maxSpeechInputLength]; null when nothing is left to read.
String? speechTextOf(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.length <= maxSpeechInputLength) return trimmed;
  return trimmed.substring(0, maxSpeechInputLength);
}

/// Reads text aloud through the device (study speech spec §7). The one
/// implementation on a device is `PluginSpeechSynthesizer`, the only file
/// that imports `flutter_tts` (guard `tts_plugin_has_one_door`); tests use a
/// fake. Nothing here throws: a failure is logged (BR-STUDY-081).
abstract interface class SpeechSynthesizer {
  /// Reads [text] in [language], stopping what is being read first
  /// (BR-STUDY-082). Returns once the engine has taken the text, not once
  /// it has finished reading.
  Future<void> speak(String text, {required SpeechLanguage language});

  /// Stops what is being read, if anything.
  Future<void> stop();

  /// The BCP-47 tags the device engine reports it can read; empty when it
  /// cannot say.
  Future<Set<String>> availableLanguageTags();
}

/// No engine: every platform but Android, and the host running the tests.
final class SilentSpeechSynthesizer implements SpeechSynthesizer {
  const SilentSpeechSynthesizer();

  @override
  Future<void> speak(String text, {required SpeechLanguage language}) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<Set<String>> availableLanguageTags() async => const {};
}
```

- [ ] **Step 6: Write the plugin door and its provider**

`lib/core/speech/plugin_speech_synthesizer.dart`:

```dart
import 'package:flutter_tts/flutter_tts.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/core/speech/speech_synthesizer.dart';

/// [SpeechSynthesizer] on the device engine: the one file that imports
/// `flutter_tts` (guard `memox_v8.architecture.tts_plugin_has_one_door`).
/// Every call is wrapped: a failing engine is a warning in the log, never
/// an error in the session (BR-STUDY-081). The text is never logged.
final class PluginSpeechSynthesizer implements SpeechSynthesizer {
  PluginSpeechSynthesizer({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  /// The language the engine was last set to; set again after a failure.
  SpeechLanguage? _language;

  @override
  Future<void> speak(String text, {required SpeechLanguage language}) async {
    final toRead = speechTextOf(text);
    if (toRead == null) return;
    try {
      await _tts.stop();
      if (_language != language) {
        await _tts.setLanguage(language.tag);
        _language = language;
      }
      await _tts.speak(toRead);
    } on Object catch (error, stackTrace) {
      _language = null;
      appLogger.warning(
        'speech.speak_failed',
        category: LogCategory.ui,
        error: error,
        stackTrace: stackTrace,
        context: {'language': language.tag},
      );
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } on Object catch (error, stackTrace) {
      appLogger.warning(
        'speech.stop_failed',
        category: LogCategory.ui,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Set<String>> availableLanguageTags() async {
    try {
      final languages = await _tts.getLanguages;
      if (languages is! List) return const {};
      return {for (final language in languages) language.toString()};
    } on Object catch (error, stackTrace) {
      appLogger.warning(
        'speech.languages_failed',
        category: LogCategory.ui,
        error: error,
        stackTrace: stackTrace,
      );
      return const {};
    }
  }
}
```

Check the import of `LogCategory`: it is in `lib/core/logging/log_entry.dart` (`enum LogCategory`); if `app_logger.dart` already exports it, drop the second import (the analyzer says).

`lib/core/speech/di/speech_providers.dart`:

```dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:memox/core/speech/plugin_speech_synthesizer.dart';
import 'package:memox/core/speech/speech_synthesizer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'speech_providers.g.dart';

/// The device engine on Android; silent everywhere else, the host running
/// the tests included (study speech spec §7). Kept alive: one engine for the
/// app's life.
@Riverpod(keepAlive: true)
SpeechSynthesizer speechSynthesizer(Ref ref) {
  if (kIsWeb || !Platform.isAndroid) return const SilentSpeechSynthesizer();
  return PluginSpeechSynthesizer();
}
```

Run: `cd /home/user/memox-v8 && dart run build_runner build --delete-conflicting-outputs`
Expected: `speech_providers.g.dart` generated.

- [ ] **Step 7: Write the test fake**

`test/support/fake_speech_synthesizer.dart`:

```dart
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/core/speech/speech_synthesizer.dart';

/// Records what the session asked the engine to read (study speech spec
/// §8); [available] is what the "device" reports it can read.
final class FakeSpeechSynthesizer implements SpeechSynthesizer {
  FakeSpeechSynthesizer({this.available = const {}});

  final Set<String> available;

  /// Every `speak`, in order: the text and its language.
  final spoken = <(String, SpeechLanguage)>[];

  /// How many times `stop` was called.
  var stops = 0;

  @override
  Future<void> speak(String text, {required SpeechLanguage language}) async {
    spoken.add((text, language));
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<Set<String>> availableLanguageTags() async => available;
}
```

- [ ] **Step 8: Run the tests to verify they pass**

Run: `cd /home/user/memox-v8 && flutter test test/core/speech`
Expected: PASS (7 tests).

- [ ] **Step 9: Add the guard rule and its test**

In `memox-architecture-rules.yaml`, right after the `reminder_plugins_have_one_door` rule (ends at the `tags:` of that rule, before the `auth_sdks_have_one_door` comment):

```yaml
  # Study speech spec D1: the TTS plugin is reached through one door, so a
  # failing engine is logged in one place and tests fake one interface.
  - id: memox_v8.architecture.tts_plugin_has_one_door
    type: regex
    severity: error
    enabled: true
    message: >-
      Import `flutter_tts` only in
      `lib/core/speech/plugin_speech_synthesizer.dart`; go through
      `SpeechSynthesizer` instead.
    scopes:
      - dart_lib
    exclude:
      - lib/core/speech/plugin_speech_synthesizer.dart
    patterns:
      - "^\\s*import\\s+'package:flutter_tts/"
    tags:
      - memox-v8
      - architecture
```

In `test_memox_v8_architecture_guard_rules.py`, after `test_reminder_plugins_are_imported_by_their_data_source_only`:

```python
TTS_PLUGIN = "memox_v8.architecture.tts_plugin_has_one_door"
SPEECH_DOOR = "lib/core/speech/plugin_speech_synthesizer.dart"


def test_tts_plugin_is_imported_by_its_door_only(tmp_path: Path) -> None:
    line = "import 'package:flutter_tts/flutter_tts.dart';\n"
    assert _violations_at(TTS_PLUGIN, tmp_path / "leak", {"lib/features/study/presentation/screens/study_session_screen.dart": line})
    assert not _violations_at(TTS_PLUGIN, tmp_path / "door", {SPEECH_DOOR: line})
```

Run: `cd /home/user/memox-v8/code-verification-guard-v2 && python3 -m pytest tests/test_memox_v8_architecture_guard_rules.py -q -k "tts or reminder"`
Expected: PASS. (If pytest is not installed, run `python3 -m pip install -r requirements-dev.txt` first; `.claude/hooks/install-guard-deps.sh` says which Python.)

- [ ] **Step 10: Record the dependency**

In `.claude/skills/flutter-project-setup/references/dependencies.md`, the package table (line 16), add in alphabetical place:

```markdown
| `flutter_tts` | 4.x | Reads a card's term through the device's TTS engine; one door in `lib/core/speech/` (study speech spec D1). |
```

In `.claude/skills/flutter-architecture/SKILL.md`, if the `core/` tree lists its folders, add `speech/  # TTS behind SpeechSynthesizer`; if it says only "one folder per concern", leave it.

- [ ] **Step 11: Analyze and commit**

Run: `cd /home/user/memox-v8 && dart analyze lib/core/speech test/core/speech test/support/fake_speech_synthesizer.dart`
Expected: No issues found.

```bash
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml lib/core/speech test/core/speech test/support/fake_speech_synthesizer.dart code-verification-guard-v2 .claude/skills/flutter-project-setup/references/dependencies.md .claude/skills/flutter-architecture/SKILL.md
git commit -m "feat(speech): one door to flutter_tts in core/speech

SpeechLanguage (the fixed list of spec §4), SpeechSynthesizer with a
silent host implementation, the flutter_tts door, its provider and the
guard rule that keeps the import in that one file."
```

---

### Task 2: `StudyOptions.speechLanguage` and the `study_config` key

**Files:**
- Modify: `lib/features/settings/domain/models/study_options_model.dart`, `lib/features/settings/data/mappers/study_config_mapper.dart`
- Test: `test/features/settings/data/study_config_mapper_test.dart`

**Interfaces:**
- Consumes: `SpeechLanguage` (Task 1).
- Produces: `StudyOptions({required int cardLimit, required NewCardOrder newCardOrder, SpeechLanguage speechLanguage = SpeechLanguage.defaultLanguage})`; `studyConfigOf` writes `tts_language`; `studyOptionsOf` reads it per D6.

- [ ] **Step 1: Write the failing tests**

In `study_config_mapper_test.dart`, change the first test's expected JSON and add tests:

```dart
  test('the options a save writes read back the same', () {
    const options = StudyOptions(
      cardLimit: 35,
      newCardOrder: NewCardOrder.random,
      speechLanguage: SpeechLanguage.koKr,
    );

    final studyConfig = studyConfigOf(options);
    final read = studyOptionsOf(studyConfig);

    expect(
      studyConfig,
      '{"card_limit":35,"new_card_order":"random","tts_language":"ko-KR"}',
    );
    expect(read?.cardLimit, 35);
    expect(read?.newCardOrder, NewCardOrder.random);
    expect(read?.speechLanguage, SpeechLanguage.koKr);
  });

  test('an override written before speech reads in the default language '
      '(spec D6)', () {
    final read = studyOptionsOf('{"card_limit":20,"new_card_order":"created"}');

    expect(read?.speechLanguage, SpeechLanguage.defaultLanguage);
  });

  for (final (shape, studyConfig) in [
    (
      'a tts_language that is a number',
      '{"card_limit":20,"new_card_order":"created","tts_language":7}',
    ),
    (
      'a tts_language the app does not know',
      '{"card_limit":20,"new_card_order":"created","tts_language":"xx-XX"}',
    ),
  ]) {
    test('$shape cannot be read (spec D6)', () {
      expect(studyOptionsOf(studyConfig), isNull);
    });
  }
```

Add `import 'package:memox/core/speech/speech_language.dart';` at the top.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd /home/user/memox-v8 && flutter test test/features/settings/data/study_config_mapper_test.dart`
Expected: FAIL, "No named parameter with the name 'speechLanguage'".

- [ ] **Step 3: Extend `StudyOptions`**

In `study_options_model.dart`, add the import and the field:

```dart
import 'package:memox/core/speech/speech_language.dart';
```

```dart
  const StudyOptions({
    required this.cardLimit,
    required this.newCardOrder,
    this.speechLanguage = SpeechLanguage.defaultLanguage,
  });
```

```dart
  final int cardLimit;
  final NewCardOrder newCardOrder;

  /// The language the term is read in (BR-SETTINGS-009, study speech spec
  /// D3). Defaulted: most callers set the two options a session opens with;
  /// the sites that write a root's override or the defaults pass it.
  final SpeechLanguage speechLanguage;
```

Update the class doc: "The study options of BR-STUDY-056 and BR-SETTINGS-009".

- [ ] **Step 4: Extend the mapper**

In `study_config_mapper.dart`:

```dart
import 'package:memox/core/speech/speech_language.dart';
```

```dart
// The keys of `deck.study_config` (spec D5; study speech spec §4).
const _cardLimitKey = 'card_limit';
const _newCardOrderKey = 'new_card_order';
const _speechLanguageKey = 'tts_language';

/// The JSON a root keeps [options] in (spec D5).
String studyConfigOf(StudyOptions options) => jsonEncode({
  _cardLimitKey: options.cardLimit,
  _newCardOrderKey: options.newCardOrder.name,
  _speechLanguageKey: options.speechLanguage.tag,
});
```

In `studyOptionsOf`, after `newCardOrder` is read:

```dart
  final speechLanguage = _speechLanguageOf(decoded[_speechLanguageKey]);
  if (cardLimit is! int || newCardOrder == null || speechLanguage == null) {
    return null;
  }
  final options = StudyOptions(
    cardLimit: cardLimit,
    newCardOrder: newCardOrder,
    speechLanguage: speechLanguage,
  );
```

and the helper at the end of the file:

```dart
/// Study speech spec D6: an override written before speech has no key and
/// reads in the default language; a key of another type or a tag the app
/// does not know makes the override unreadable, as the other keys do.
SpeechLanguage? _speechLanguageOf(Object? value) {
  if (value == null) return SpeechLanguage.defaultLanguage;
  if (value is! String) return null;
  return SpeechLanguage.fromTag(value);
}
```

Update the doc comment of `studyOptionsOf` to name the new case.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `cd /home/user/memox-v8 && flutter test test/features/settings/data/study_config_mapper_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/settings/domain/models/study_options_model.dart lib/features/settings/data/mappers/study_config_mapper.dart test/features/settings/data/study_config_mapper_test.dart
git commit -m "feat(settings): speech language as a study option in study_config

StudyOptions.speechLanguage, written as tts_language; a config without
the key reads in the default language (spec D6)."
```

---

### Task 3: `app_settings` schema 15, the entity, the repository and the use cases

**Files:**
- Modify: `lib/core/database/tables/settings.drift`, `lib/core/database/app_database.dart` (schemaVersion, `from14To15`), `lib/core/database/queries/settings_queries.drift` (one query)
- Generate: `drift_schemas/drift_schema_v15.json`, `lib/core/database/schema_versions.dart`, `test/drift/generated/schema_v15.dart`
- Modify: `lib/features/settings/domain/entities/app_settings_entity.dart`, `lib/features/settings/data/mappers/app_settings_mapper.dart`, `lib/features/settings/domain/repositories/settings_repository.dart`, `lib/features/settings/data/repositories/settings_repository_impl.dart`, `lib/features/settings/data/datasources/settings_dao.dart`, `lib/features/settings/domain/usecases/save_study_defaults_use_case.dart`
- Create: `lib/features/settings/domain/models/speech_settings_model.dart`, `lib/features/settings/domain/usecases/set_speech_auto_play_use_case.dart`, `lib/features/settings/presentation/providers/set_speech_auto_play_use_case_provider.dart`
- Modify: `test/support/settings_fakes.dart` (`FlakySettingsRepository`), any other `implements SettingsRepository` (`grep -rn "implements SettingsRepository" lib test`)
- Test: `test/features/settings/data/app_settings_repository_test.dart`, `test/core/database/schema_constants_parity_test.dart`, `test/database/schema_test.dart` (runs as is), `test/features/settings/data/settings_dao_test.dart`

**Interfaces:**
- Consumes: `SpeechLanguage`, `StudyOptions.speechLanguage`.
- Produces: `AppSettingsEntity.isSpeechAutoPlay` (bool, default true); `SpeechSettings({required bool isAutoPlay, required SpeechLanguage language})`; `SettingsRepository.saveStudyDefaults({int? cardLimit, NewCardOrder? newCardOrder, SpeechLanguage? speechLanguage})`; `SettingsRepository.setSpeechAutoPlay({required bool isOn})`; `SettingsRepository.watchSpeechSettings({required String deckId})` → `Stream<SpeechSettings?>`; `SetSpeechAutoPlayUseCase.call({required bool isOn})`; `setSpeechAutoPlayUseCaseProvider`.

- [ ] **Step 1: Write the failing repository tests**

In `test/features/settings/data/app_settings_repository_test.dart`, add (follow the file's existing `setUp`/`db` pattern; add `import 'package:memox/core/speech/speech_language.dart';` and `import 'package:memox/features/settings/domain/models/speech_settings_model.dart';`):

```dart
  test('a fresh row reads aloud by default, in en-US (BR-SETTINGS-010)', () async {
    final settings = await repo.watchAppSettings().first;

    expect(settings.isSpeechAutoPlay, isTrue);
    expect(settings.studyDefaults.speechLanguage, SpeechLanguage.enUs);
  });

  test('the speech language is a study default of its own column '
      '(BR-SETTINGS-007, BR-SETTINGS-009)', () async {
    await repo.saveStudyDefaults(speechLanguage: SpeechLanguage.jaJp);

    final settings = await repo.watchAppSettings().first;
    expect(settings.studyDefaults.speechLanguage, SpeechLanguage.jaJp);
    expect(settings.studyDefaults.cardLimit, 20);
  });

  test('the read-aloud switch is written alone (BR-SETTINGS-010)', () async {
    await repo.setSpeechAutoPlay(isOn: false);

    expect((await repo.watchAppSettings().first).isSpeechAutoPlay, isFalse);
  });

  test('Reset to defaults returns both speech values (BR-SETTINGS-008)', () async {
    await repo.saveStudyDefaults(speechLanguage: SpeechLanguage.viVn);
    await repo.setSpeechAutoPlay(isOn: false);

    await repo.resetToDefaults();

    final settings = await repo.watchAppSettings().first;
    expect(settings.isSpeechAutoPlay, isTrue);
    expect(settings.studyDefaults.speechLanguage, SpeechLanguage.enUs);
  });

  test('watchSpeechSettings joins the switch with the root language, and '
      'follows both (BR-STUDY-080)', () async {
    final root = await insertRootDeck(db, id: 'r');
    final sub = await insertSubDeck(db, id: 's', parentId: root, rootId: root);
    final seen = <SpeechSettings?>[];
    final sub1 = repo.watchSpeechSettings(deckId: sub).listen(seen.add);
    await pumpEventQueue();
    expect(seen.last, const SpeechSettings(isAutoPlay: true, language: SpeechLanguage.enUs));

    await repo.saveRootStudyOptions(
      rootDeckId: root,
      options: const StudyOptions(
        cardLimit: 20,
        newCardOrder: NewCardOrder.created,
        speechLanguage: SpeechLanguage.koKr,
      ),
    );
    await pumpEventQueue();
    expect(seen.last?.language, SpeechLanguage.koKr);

    await repo.setSpeechAutoPlay(isOn: false);
    await pumpEventQueue();
    expect(seen.last, const SpeechSettings(isAutoPlay: false, language: SpeechLanguage.koKr));
    await sub1.cancel();
  });

  test('watchSpeechSettings is null for a deck that is not there', () async {
    expect(await repo.watchSpeechSettings(deckId: 'nope').first, isNull);
  });
```

Use the deck helpers the file (or `test/support/deck_fixtures.dart`) already offers for a root and a sub-deck; if they have other names, use those. `SpeechSettings` needs `==` for the `expect`: give it `operator ==`/`hashCode` (Step 5).

Add to `schema_constants_parity_test.dart`, in the `Drift CHECKs` group:

```dart
    test('app_settings.tts_language lists SpeechLanguage.values', () {
      final sql = tableSql['app_settings']!;
      final match = RegExp(r"tts_language[^,]*IN \(([^)]*)\)").firstMatch(sql);
      expect(match, isNotNull, reason: 'one tts_language CHECK');
      final tags = {
        for (final m in RegExp("'([A-Za-z-]+)'").allMatches(match!.group(1)!))
          m.group(1)!,
      };
      expect(tags, SpeechLanguage.values.map((l) => l.tag).toSet());
    });
```

with `import 'package:memox/core/speech/speech_language.dart';`.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd /home/user/memox-v8 && flutter test test/features/settings/data/app_settings_repository_test.dart test/core/database/schema_constants_parity_test.dart`
Expected: FAIL (no `isSpeechAutoPlay`, no `tts_language` CHECK).

- [ ] **Step 3: Change the schema and the migration**

In `settings.drift`, after the `welcome_seen` column:

```sql
  -- Study speech spec §4: the default speech language and the read-aloud
  -- switch. Device-only: not in the account settings that sync; Reset to
  -- defaults returns both (BR-SETTINGS-008, BR-SETTINGS-010).
  tts_language TEXT NOT NULL DEFAULT 'en-US' CHECK (tts_language IN ('en-US', 'en-GB', 'vi-VN', 'ko-KR', 'ja-JP', 'zh-CN', 'zh-TW', 'fr-FR', 'de-DE', 'es-ES')),
  tts_auto_play INTEGER NOT NULL DEFAULT 1 CHECK (tts_auto_play IN (0, 1)),
```

In `app_database.dart`: `int get schemaVersion => 15;` and, after `from13To14`:

```dart
    from14To15: (m, schema) async {
      // Study speech spec §4: the speech language default and the read-aloud
      // switch, each with its default. No row changes.
      await m.addColumn(schema.appSettings, schema.appSettings.ttsLanguage);
      await m.addColumn(schema.appSettings, schema.appSettings.ttsAutoPlay);
    },
```

Then regenerate, in this order (`.claude/skills/flutter-drift/references/migrations.md`):

```bash
cd /home/user/memox-v8
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
dart run drift_dev schema steps drift_schemas/ lib/core/database/schema_versions.dart
dart run drift_dev schema generate drift_schemas/ test/drift/generated/
dart run build_runner build --delete-conflicting-outputs
```
Expected: `drift_schemas/drift_schema_v15.json` and `test/drift/generated/schema_v15.dart` exist; `schema_versions.dart` has `from14To15`.

- [ ] **Step 4: Add the speech-settings query**

In `settings_queries.drift`, the existing `rootAndSettingsOf` already returns the root and the settings row in one statement; no new SQL is needed. (The repository maps it, Step 6.)

- [ ] **Step 5: The entity, the model and the mapper**

`lib/features/settings/domain/models/speech_settings_model.dart`:

```dart
import 'package:memox/core/speech/speech_language.dart';

/// What a session reads with (BR-STUDY-079, BR-STUDY-080): the app-wide
/// switch and the language in force for the deck's root.
final class SpeechSettings {
  const SpeechSettings({required this.isAutoPlay, required this.language});

  final bool isAutoPlay;
  final SpeechLanguage language;

  @override
  bool operator ==(Object other) =>
      other is SpeechSettings &&
      other.isAutoPlay == isAutoPlay &&
      other.language == language;

  @override
  int get hashCode => Object.hash(isAutoPlay, language);
}
```

In `app_settings_entity.dart`:

```dart
  const AppSettingsEntity({
    required this.studyDefaults,
    required this.theme,
    required this.language,
    required this.reminder,
    required this.isSpeechAutoPlay,
  });

  static const defaults = AppSettingsEntity(
    studyDefaults: StudyOptions.defaults,
    theme: ThemeChoice.system,
    language: LanguageChoice.system,
    reminder: ReminderSettings.defaults,
    isSpeechAutoPlay: true,
  );
  ...
  /// Whether a learning session reads a new card's term aloud
  /// (BR-SETTINGS-010); device-only.
  final bool isSpeechAutoPlay;
```

Fix every other `AppSettingsEntity(` construction the analyzer reports (`grep -rn "AppSettingsEntity(" lib test`), passing `isSpeechAutoPlay: true` where the test does not care.

In `app_settings_mapper.dart`:

```dart
import 'package:memox/core/speech/speech_language.dart';
...
AppSettingsEntity appSettingsOf(AppSetting row) => AppSettingsEntity(
  studyDefaults: StudyOptions(
    cardLimit: row.cardLimit,
    newCardOrder: NewCardOrder.values.byName(row.newCardOrder),
    speechLanguage: _speechLanguageOf(row.ttsLanguage),
  ),
  theme: ThemeChoice.values.byName(row.themeMode),
  language: LanguageChoice.values.byName(row.language),
  reminder: _reminderOf(row),
  isSpeechAutoPlay: row.ttsAutoPlay == 1,
);

/// The table's CHECK keeps the tag in the list: an unknown one is corrupt
/// data and throws, as the other codes do.
SpeechLanguage _speechLanguageOf(String tag) =>
    SpeechLanguage.fromTag(tag) ??
    (throw ArgumentError.value(tag, 'tts_language', 'unknown speech language'));

/// Study speech spec §4: the switch and the root's language from the one
/// statement that reads both rows (BR-STUDY-080).
SpeechSettings speechSettingsOf(Deck root, AppSetting settings) =>
    SpeechSettings(
      isAutoPlay: settings.ttsAutoPlay == 1,
      language: effectiveStudyOptionsOf(root, settings).options.speechLanguage,
    );
```

(`speechSettingsOf` needs `import 'package:memox/features/settings/data/mappers/study_config_mapper.dart';` and the model import.)

- [ ] **Step 6: The repository**

In `settings_repository.dart`, add imports for `SpeechLanguage` and `SpeechSettings`, extend `saveStudyDefaults` and add two methods:

```dart
  /// The app-wide study defaults: only the columns given are written …
  /// (BR-SETTINGS-007, DEV-217); at least one is given. …
  Future<Outcome<void, SettingsRejection>> saveStudyDefaults({
    int? cardLimit,
    NewCardOrder? newCardOrder,
    SpeechLanguage? speechLanguage,
  });

  /// Whether a learning session reads a new card aloud (BR-SETTINGS-010);
  /// one column, device-only.
  Future<Outcome<void, SettingsRejection>> setSpeechAutoPlay({
    required bool isOn,
  });

  /// The switch and the language [deckId]'s root reads in, in one
  /// statement, again when either changes (BR-STUDY-080); null when the
  /// deck does not exist or is in the Trash.
  Stream<SpeechSettings?> watchSpeechSettings({required String deckId});
```

Update the `resetToDefaults` doc from "six values" to "the eight values a person can set".

In `settings_repository_impl.dart`:

```dart
  @override
  Future<Outcome<void, SettingsRejection>> saveStudyDefaults({
    int? cardLimit,
    NewCardOrder? newCardOrder,
    SpeechLanguage? speechLanguage,
  }) {
    if (cardLimit == null && newCardOrder == null && speechLanguage == null) {
      throw ArgumentError('saveStudyDefaults needs a limit, an order or a language');
    }
    ...
      await _dao.updateRow(
        AppSettingsCompanion(
          cardLimit: Value.absentIfNull(cardLimit),
          newCardOrder: Value.absentIfNull(newCardOrder?.name),
          ttsLanguage: Value.absentIfNull(speechLanguage?.tag),
          updatedAt: Value(at),
        ),
      );

  @override
  Future<Outcome<void, SettingsRejection>> setSpeechAutoPlay({
    required bool isOn,
  }) => _save(AppSettingsCompanion(ttsAutoPlay: Value(isOn ? 1 : 0)));

  @override
  Future<Outcome<void, SettingsRejection>> resetToDefaults() {
    const defaults = AppSettingsEntity.defaults;
    return _save(
      reminderColumnsOf(defaults.reminder).copyWith(
        cardLimit: Value(defaults.studyDefaults.cardLimit),
        newCardOrder: Value(defaults.studyDefaults.newCardOrder.name),
        themeMode: Value(defaults.theme.name),
        language: Value(defaults.language.name),
        ttsLanguage: Value(defaults.studyDefaults.speechLanguage.tag),
        ttsAutoPlay: Value(defaults.isSpeechAutoPlay ? 1 : 0),
      ),
    );
  }

  @override
  Stream<SpeechSettings?> watchSpeechSettings({required String deckId}) =>
      _dao.watchRootAndSettings(deckId).map(_speechOf).mapDatabaseErrors();
```

and at the bottom:

```dart
SpeechSettings? _speechOf((Deck, AppSetting)? rows) => switch (rows) {
  (final Deck root, final AppSetting settings) => speechSettingsOf(root, settings),
  null => null,
};
```

`settings_dao.dart`: `resetSyncedDefaults` stays as it is (device-only columns are left alone by the account reset, as `welcome_seen` is); update its doc to say "(reminder, welcome, speech)".

- [ ] **Step 7: Use case and provider**

`save_study_defaults_use_case.dart`: add the `SpeechLanguage? speechLanguage` parameter and pass it through; doc: "the app-wide card limit, new-card order and speech language".

`lib/features/settings/domain/usecases/set_speech_auto_play_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-SETTINGS-001 step 2: whether a learning session reads a new card's
/// term aloud, saved on the toggle (BR-SETTINGS-010).
final class SetSpeechAutoPlayUseCase {
  const SetSpeechAutoPlayUseCase(this._settings);

  final SettingsRepository _settings;

  Future<Outcome<void, SettingsRejection>> call({required bool isOn}) =>
      _settings.setSpeechAutoPlay(isOn: isOn);
}
```

`lib/features/settings/presentation/providers/set_speech_auto_play_use_case_provider.dart`:

```dart
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/usecases/set_speech_auto_play_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'set_speech_auto_play_use_case_provider.g.dart';

@riverpod
SetSpeechAutoPlayUseCase setSpeechAutoPlayUseCase(Ref ref) =>
    SetSpeechAutoPlayUseCase(ref.watch(settingsRepositoryProvider));
```

- [ ] **Step 8: The fakes**

In `test/support/settings_fakes.dart`, `FlakySettingsRepository`: add the parameter to `saveStudyDefaults` (pass it on), and

```dart
  @override
  Future<Outcome<void, SettingsRejection>> setSpeechAutoPlay({
    required bool isOn,
  }) => _write(() => _inner.setSpeechAutoPlay(isOn: isOn));

  @override
  Stream<SpeechSettings?> watchSpeechSettings({required String deckId}) =>
      _inner.watchSpeechSettings(deckId: deckId);
```

Run `grep -rn "implements SettingsRepository" lib test` and give every other implementation the same three changes.

- [ ] **Step 9: Generate, test, analyze**

```bash
cd /home/user/memox-v8 && dart run build_runner build --delete-conflicting-outputs
flutter test test/features/settings/data test/core/database test/database
dart analyze
```
Expected: all PASS; no analyzer issues. If `test/database/schema_test.dart` says the dump is stale, re-run the `schema dump` of Step 3.

- [ ] **Step 10: Commit**

```bash
git add lib/core/database drift_schemas test/drift/generated lib/features/settings test/features/settings test/core/database test/support/settings_fakes.dart
git commit -m "feat(settings): tts_language and tts_auto_play on app_settings (schema 15)

Two device-only columns with their defaults, the entity and mapper, the
repository's saveStudyDefaults(speechLanguage), setSpeechAutoPlay and
watchSpeechSettings over the root-and-settings statement; Reset to
defaults returns both."
```

---

### Task 4: `readsTermAloud` per mode and the pure speech cue

**Files:**
- Modify: `lib/features/study_mode/domain/models/study_mode.dart` (`StudyModeHandler`), `lib/features/study_mode/domain/models/fill_mode.dart` (`FillModeHandler`), `lib/features/study_mode/domain/models/match_mode.dart` (`MatchModeHandler`)
- Create: `lib/features/study/presentation/states/study_speech_cue_state.dart`
- Test: `test/features/study_mode/reads_term_aloud_test.dart`, `test/features/study/presentation/study_speech_cue_test.dart`

**Interfaces:**
- Consumes: `StudySessionView`, `StudyItem`, `StudyTurnState`, `HeldTurn`, `sessionEndingOf`.
- Produces: `bool get readsTermAloud` on `StudyModeHandler` (true; false for `fill`, `match`); `final class SpeechCue { String key; String text; }`; `SpeechCue? speechCueOf(StudySessionView view, StudyTurnState turn, {required String? lastKey, required bool isAutoPlay, required bool isAccessibleNavigation})`.

- [ ] **Step 1: Write the failing tests**

`test/features/study_mode/reads_term_aloud_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

// BR-STUDY-078: the modes that show the term as the prompt read it aloud.

void main() {
  test('browse, self_assess, guess and recall read the term aloud', () {
    for (final mode in [
      StudyMode.browse,
      StudyMode.selfAssess,
      StudyMode.guess,
      StudyMode.recall,
    ]) {
      expect(mode.handler.readsTermAloud, isTrue, reason: mode.code);
    }
  });

  test('fill (the term is the answer) and match (no one card) do not', () {
    expect(StudyMode.fill.handler.readsTermAloud, isFalse);
    expect(StudyMode.match.handler.readsTermAloud, isFalse);
  });
}
```

`test/features/study/presentation/study_speech_cue_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/presentation/states/study_speech_cue_state.dart';
import 'package:memox/features/study/presentation/states/study_turn_state.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

// BR-STUDY-078, BR-STUDY-079, BR-STUDY-082; study speech spec §5, D13.

StudyItem _item({
  String cardId = 'c1',
  String front = 'abandon',
  int round = 1,
  int answersInSession = 0,
}) => StudyItem(
  cardId: cardId,
  front: front,
  back: 'từ bỏ',
  example: null,
  hint: null,
  pronunciation: null,
  round: round,
  answersInSession: answersInSession,
  direction: null,
  remainingMs: null,
  isRevealed: false,
);

StudySessionView _view({
  StudyMode mode = StudyMode.browse,
  SessionKind kind = SessionKind.learning,
  SessionStatus status = SessionStatus.inProgress,
  StudyItem? item,
  bool hasItem = true,
}) => StudySessionView(
  sessionId: 's1',
  deckId: 'd1',
  deckName: 'Korean',
  kind: kind,
  status: status,
  endReason: null,
  currentMode: mode,
  direction: null,
  stages: const [StudyMode.browse, StudyMode.selfAssess],
  currentItem: hasItem ? (item ?? _item()) : null,
  progress: hasItem ? const RoundProgress(completed: 0, total: 3) : null,
  summary: null,
);

SpeechCue? _cue(
  StudySessionView view, {
  StudyTurnState turn = const StudyTurnState(),
  String? lastKey,
  bool isAutoPlay = true,
  bool isAccessibleNavigation = false,
}) => speechCueOf(
  view,
  turn,
  lastKey: lastKey,
  isAutoPlay: isAutoPlay,
  isAccessibleNavigation: isAccessibleNavigation,
);

void main() {
  test('a new card in browse is read: its front, keyed by card, mode, round '
      'and turn', () {
    final cue = _cue(_view());

    expect(cue?.text, 'abandon');
    expect(cue?.key, 'c1#browse#1#0');
  });

  test('the same card in the same turn is not read twice', () {
    expect(_cue(_view(), lastKey: 'c1#browse#1#0'), isNull);
  });

  test('the same card coming back as a later turn or round is read again', () {
    expect(_cue(_view(item: _item(answersInSession: 1)), lastKey: 'c1#browse#1#0'), isNotNull);
    expect(_cue(_view(mode: StudyMode.guess, item: _item(round: 2)), lastKey: 'c1#guess#1#0'), isNotNull);
  });

  test('self_assess, guess and recall read; fill and match do not', () {
    for (final mode in [StudyMode.selfAssess, StudyMode.guess, StudyMode.recall]) {
      expect(_cue(_view(mode: mode)), isNotNull, reason: mode.code);
    }
    expect(_cue(_view(mode: StudyMode.fill)), isNull);
    expect(_cue(_view(mode: StudyMode.match)), isNull);
  });

  test('a review session reads nothing', () {
    expect(_cue(_view(mode: StudyMode.selfAssess, kind: SessionKind.reviewing)), isNull);
  });

  test('nothing is read while a write runs or a turn is held', () {
    expect(_cue(_view(), turn: const StudyTurnState(isBusy: true)), isNull);
    final held = HeldTurn(_item(), const TurnResult(isCorrect: true));
    expect(_cue(_view(), turn: StudyTurnState(held: held)), isNull);
  });

  test('a stalled or ended session reads nothing', () {
    expect(_cue(_view(hasItem: false)), isNull);
    expect(_cue(_view(status: SessionStatus.completed, hasItem: false)), isNull);
  });

  test('the switch off reads nothing (BR-STUDY-079)', () {
    expect(_cue(_view(), isAutoPlay: false), isNull);
  });

  test('a screen reader on reads nothing (D13)', () {
    expect(_cue(_view(), isAccessibleNavigation: true), isNull);
  });
}
```

(`TurnResult({bool? isCorrect})` and `SessionStatus.completed` are the real names.)

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd /home/user/memox-v8 && flutter test test/features/study_mode/reads_term_aloud_test.dart test/features/study/presentation/study_speech_cue_test.dart`
Expected: FAIL ("The getter 'readsTermAloud' isn't defined", missing file).

- [ ] **Step 3: Add `readsTermAloud` to the handlers**

In `study_mode.dart`, inside `StudyModeHandler`, after `takesDirection`:

```dart
  /// Whether the mode shows the term as its prompt, so a new card is read
  /// aloud in a learning session (BR-STUDY-078): every mode but `fill`,
  /// where the term is the answer, and `match`, where no one card is
  /// served.
  bool get readsTermAloud => true;
```

In `FillModeHandler` and `MatchModeHandler`:

```dart
  @override
  bool get readsTermAloud => false;
```

- [ ] **Step 4: Write the cue**

`lib/features/study/presentation/states/study_speech_cue_state.dart`:

```dart
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/states/session_ending_state.dart';
import 'package:memox/features/study/presentation/states/study_turn_state.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';

/// What the session reads now (BR-STUDY-078).
final class SpeechCue {
  const SpeechCue({required this.key, required this.text});

  /// One reading per turn of a card in a mode: `card#mode#round#turn`. A
  /// card that comes back (self_assess Again, a later round) is a new turn
  /// and is read again.
  final String key;

  /// The card's term.
  final String text;
}

/// The reading due for [view] under [turn], or null (study speech spec §5):
/// a learning session serving a card in a mode that reads the term, no
/// write running and no turn held (the next card is read when it is drawn,
/// not when the stream moves under a hold), the session open, and a turn
/// not read yet ([lastKey]). The switch off (BR-STUDY-079) or a screen
/// reader on (D13: TalkBack reads the card itself) reads nothing; the
/// speaker button is the way then.
SpeechCue? speechCueOf(
  StudySessionView view,
  StudyTurnState turn, {
  required String? lastKey,
  required bool isAutoPlay,
  required bool isAccessibleNavigation,
}) {
  if (!isAutoPlay || isAccessibleNavigation) return null;
  if (view.kind != SessionKind.learning) return null;
  if (turn.isBusy || turn.held != null) return null;
  if (sessionEndingOf(view) != null) return null;
  final item = view.currentItem;
  if (item == null) return null;
  if (!view.currentMode.handler.readsTermAloud) return null;
  final key =
      '${item.cardId}#${view.currentMode.code}#${item.round}#${item.answersInSession}';
  if (key == lastKey) return null;
  return SpeechCue(key: key, text: item.front);
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `cd /home/user/memox-v8 && flutter test test/features/study_mode/reads_term_aloud_test.dart test/features/study/presentation/study_speech_cue_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/study_mode lib/features/study/presentation/states/study_speech_cue_state.dart test/features/study_mode/reads_term_aloud_test.dart test/features/study/presentation/study_speech_cue_test.dart
git commit -m "feat(study): readsTermAloud per mode and the pure speech cue

The handler says whether its prompt is the term (fill and match say no);
speechCueOf decides from the view and the turn what the session reads."
```

---

### Task 5: The session reads the term, and the speaker button

**Files:**
- Create: `lib/features/study/domain/usecases/watch_speech_settings_use_case.dart`, `lib/features/study/presentation/providers/watch_speech_settings_use_case_provider.dart`, `lib/features/study/presentation/providers/speech_settings_provider.dart`, `lib/features/study/presentation/widgets/support/study_speak_button_widget.dart`
- Modify: `lib/features/study/presentation/screens/study_session_screen.dart`, `lib/features/study/presentation/widgets/sections/study_browse_widget.dart`, `study_self_assess_widget.dart`, `study_guess_widget.dart`, `study_recall_widget.dart`, `lib/core/theme/foundations/app_icons.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/study/presentation/study_speech_test.dart`; the existing mode tests keep passing (`study_browse_test.dart`, `study_self_assess_test.dart`, `study_guess_test.dart`, `study_recall_test.dart`, `study_session_screen_test.dart`)

**Interfaces:**
- Consumes: `SpeechSettings`, `SettingsRepository.watchSpeechSettings`, `settingsRepositoryProvider`, `speechSynthesizerProvider`, `speechCueOf`, `FakeSpeechSynthesizer`.
- Produces: `WatchSpeechSettingsUseCase.call({required String deckId})` → `Stream<SpeechSettings?>`; `speechSettingsProvider(deckId)` → `AsyncValue<SpeechSettings?>`; `StudySpeakButtonWidget({required String text, required SpeechLanguage? language})`; the four mode widgets take `required SpeechLanguage? speechLanguage`; `AppIcons.speak`; ARB `studySpeakTerm`.

- [ ] **Step 1: Write the failing screen tests**

`test/features/study/presentation/study_speech_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/speech/di/speech_providers.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_browse_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_speak_button_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_speech_synthesizer.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';
import '../../../support/study_fixtures.dart';

// BR-STUDY-078…082, BR-SETTINGS-009; study speech spec §5.

final _en = lookupAppLocalizations(const Locale('en'));

/// A learning session of [count] cards on Korean › Lesson, whose root reads
/// in [language] when given.
Future<({String sessionId, String rootId})> _learning(
  LibraryEnv env, {
  int count = 3,
  SpeechLanguage? language,
}) async {
  final root = await env.decks.root('Korean');
  final leaf = await env.decks.sub(root.id, 'Lesson');
  for (var i = 1; i <= count; i++) {
    await insertCard(env.db, id: 'c$i', deckId: leaf.id, front: 'front $i', back: 'back $i');
  }
  if (language != null) {
    await SettingsRepositoryImpl(env.db).saveRootStudyOptions(
      rootDeckId: root.id,
      options: StudyOptions(
        cardLimit: 20,
        newCardOrder: NewCardOrder.created,
        speechLanguage: language,
      ),
    );
  }
  final opened = await studyEntryRepository(env.db, env.clock.now)
      .openLearningSession(deckId: leaf.id);
  return (sessionId: (opened as Ok<String, StudyRejection>).value, rootId: root.id);
}

StudySessionScreen _screen(String id, {ValueChanged<String>? onDone}) =>
    StudySessionScreen(
      sessionId: id,
      onDone: onDone ?? (_) {},
      onStudyDeck: (_) {},
      onLeave: (_) {},
    );

Future<void> _swipeLeft(WidgetTester tester) async {
  await tester.drag(find.byType(StudyBrowseWidget), const Offset(-300, 0));
  await tester.pumpAndSettle();
}

void main() {
  libraryTest('the first card of a learning session is read once, in the '
      "root's language (BR-STUDY-078, BR-SETTINGS-009)", (tester, env) async {
    final speech = FakeSpeechSynthesizer();
    final session = await _learning(env, language: SpeechLanguage.koKr);
    await pumpLibraryScreen(
      tester,
      env,
      _screen(session.sessionId),
      overrides: [speechSynthesizerProvider.overrideWithValue(speech)],
    );
    await tester.pumpAndSettle();

    expect(speech.spoken, [('front 1', SpeechLanguage.koKr)]);
  });

  libraryTest('each new card is read, and only once', (tester, env) async {
    final speech = FakeSpeechSynthesizer();
    final session = await _learning(env);
    await pumpLibraryScreen(
      tester,
      env,
      _screen(session.sessionId),
      overrides: [speechSynthesizerProvider.overrideWithValue(speech)],
    );
    await tester.pumpAndSettle();
    await _swipeLeft(tester);
    await _swipeLeft(tester);

    expect(speech.spoken.map((s) => s.$1).toList(), ['front 1', 'front 2', 'front 3']);
  });

  libraryTest('with the switch off nothing is read, but the speaker button '
      'reads on tap (BR-STUDY-079)', (tester, env) async {
    final speech = FakeSpeechSynthesizer();
    await SettingsRepositoryImpl(env.db).setSpeechAutoPlay(isOn: false);
    final session = await _learning(env);
    await pumpLibraryScreen(
      tester,
      env,
      _screen(session.sessionId),
      overrides: [speechSynthesizerProvider.overrideWithValue(speech)],
    );
    await tester.pumpAndSettle();
    expect(speech.spoken, isEmpty);

    await tester.tap(find.byType(StudySpeakButtonWidget));
    await tester.pumpAndSettle();

    expect(speech.spoken, [('front 1', SpeechLanguage.enUs)]);
    expect(find.bySemanticsLabel(_en.studySpeakTerm), findsOneWidget);
  });

  libraryTest('a review session reads nothing (BR-STUDY-078)', (tester, env) async {
    final speech = FakeSpeechSynthesizer();
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    await pumpLibraryScreen(
      tester,
      env,
      _screen(id),
      overrides: [speechSynthesizerProvider.overrideWithValue(speech)],
    );
    await tester.pumpAndSettle();

    expect(speech.spoken, isEmpty);
    expect(find.byType(StudySpeakButtonWidget), findsOneWidget);
  });

  libraryTest('leaving the session stops the voice (BR-STUDY-082)', (tester, env) async {
    final speech = FakeSpeechSynthesizer();
    final session = await _learning(env, count: 1);
    await pumpLibraryScreen(
      tester,
      env,
      _screen(session.sessionId),
      overrides: [speechSynthesizerProvider.overrideWithValue(speech)],
    );
    await tester.pumpAndSettle();
    final stopsBefore = speech.stops;

    // The last card: the session completes and the summary shows.
    await _swipeLeft(tester);

    expect(speech.stops, greaterThan(stopsBefore));
    expect(find.byType(StudySpeakButtonWidget), findsNothing);
  });
}
```

Check `openSelfAssessReview` and `libraryToday` in `test/support/study_entry_fixtures.dart` and `library_harness.dart` (the self-assess test uses both); check `insertCard`'s parameter names in `card_fixtures.dart`.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd /home/user/memox-v8 && flutter test test/features/study/presentation/study_speech_test.dart`
Expected: FAIL (missing `study_speak_button_widget.dart`).

- [ ] **Step 3: The icon and the strings**

`app_icons.dart`, in the list: `static const IconData speak = Icons.volume_up_outlined; // volume-2`

`app_en.arb` (next to the `studyBrowse*` keys):

```json
  "studySpeakTerm": "Read aloud",
  "@studySpeakTerm": {
    "description": "Study session: the speaker button under the term; reads it through the device's TTS (BR-STUDY-079)."
  },
```

`app_vi.arb`: `"studySpeakTerm": "Đọc to",`

Run: `cd /home/user/memox-v8 && flutter gen-l10n`

- [ ] **Step 4: The use case and the providers**

`lib/features/study/domain/usecases/watch_speech_settings_use_case.dart`:

```dart
import 'package:memox/features/settings/domain/models/speech_settings_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// What the session of [deckId] reads with, again on every change
/// (BR-STUDY-079, BR-STUDY-080): the app-wide switch and the language of
/// the deck's root. Null once the deck is gone.
final class WatchSpeechSettingsUseCase {
  const WatchSpeechSettingsUseCase(this._settings);

  final SettingsRepository _settings;

  Stream<SpeechSettings?> call({required String deckId}) =>
      _settings.watchSpeechSettings(deckId: deckId);
}
```

`lib/features/study/presentation/providers/watch_speech_settings_use_case_provider.dart`:

```dart
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/study/domain/usecases/watch_speech_settings_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_speech_settings_use_case_provider.g.dart';

@riverpod
WatchSpeechSettingsUseCase watchSpeechSettingsUseCase(Ref ref) =>
    WatchSpeechSettingsUseCase(ref.watch(settingsRepositoryProvider));
```

`lib/features/study/presentation/providers/speech_settings_provider.dart`:

```dart
import 'package:memox/features/settings/domain/models/speech_settings_model.dart';
import 'package:memox/features/study/presentation/providers/watch_speech_settings_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'speech_settings_provider.g.dart';

/// The switch and the language the session of [deckId] reads with, live
/// (BR-STUDY-080).
@riverpod
Stream<SpeechSettings?> speechSettings(Ref ref, String deckId) =>
    ref.watch(watchSpeechSettingsUseCaseProvider)(deckId: deckId);
```

- [ ] **Step 5: The speaker button**

`lib/features/study/presentation/widgets/support/study_speak_button_widget.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/speech/di/speech_providers.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// The speaker under the term (study speech spec §5): reads [text] in
/// [language] on tap, whatever the auto-play switch says (BR-STUDY-079).
/// Disabled until the session knows its language.
class StudySpeakButtonWidget extends ConsumerWidget {
  const StudySpeakButtonWidget({
    super.key,
    required this.text,
    required this.language,
  });

  final String text;
  final SpeechLanguage? language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = this.language;
    return MxIconButton(
      icon: AppIcons.speak,
      semanticLabel: context.l10n.studySpeakTerm,
      onPressed: language == null
          ? null
          : () => unawaited(
              ref.read(speechSynthesizerProvider).speak(text, language: language),
            ),
    );
  }
}
```

- [ ] **Step 6: The button in the four mode widgets**

Each of the four gets a new constructor parameter `required this.speechLanguage` (`final SpeechLanguage? speechLanguage;`, doc: "The language the term is read in; null until known.") and `import 'package:memox/core/speech/speech_language.dart';` plus the button import.

`study_browse_widget.dart`: `_Card` and `_Half` take the button. In `_Card`, the term half becomes:

```dart
                child: _Half(
                  label: l10n.studyBrowseTerm,
                  main: Text(
                    face.front,
                    textAlign: TextAlign.center,
                    style: styles.studyTerm,
                  ),
                  detail: face.pronunciation,
                  trailing: StudySpeakButtonWidget(
                    text: face.front,
                    language: speechLanguage,
                  ),
                ),
```

`_Card` gains `required this.speechLanguage`; `_Half` gains `this.trailing` (`final Widget? trailing;`) drawn under the detail line, centred, inside the half's `Column` (after the detail `Text`, `if (trailing != null) trailing!`). The look-back face reads the older card: the button carries `face.front`, so it reads what is shown (D11 says only auto-play ignores the look-back).

`study_self_assess_widget.dart`: `_TermFace` gains `required this.speechLanguage` and, after the pronunciation `Text`:

```dart
          StudySpeakButtonWidget(text: item.front, language: speechLanguage),
```

Pass `speechLanguage: widget.speechLanguage` where `_TermFace` is built. The button sits inside `StudyAppearingWidget`, so a meaning-first review shows it only once the term is revealed.

`study_guess_widget.dart` (line ~145) and `study_recall_widget.dart` (line ~200): wrap the `StudyWholeWordTextWidget` of the term in a `Column(mainAxisSize: MainAxisSize.min, spacing: AppSpacing.control, children: [ <the existing text>, StudySpeakButtonWidget(text: widget.item.front, language: widget.speechLanguage) ])`.

- [ ] **Step 7: The screen**

In `study_session_screen.dart`:

Imports:
```dart
import 'package:memox/core/speech/di/speech_providers.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/core/speech/speech_synthesizer.dart';
import 'package:memox/features/settings/domain/models/speech_settings_model.dart';
import 'package:memox/features/study/presentation/providers/speech_settings_provider.dart';
import 'package:memox/features/study/presentation/states/study_speech_cue_state.dart';
```

State fields and lifecycle:

```dart
  /// Read once, as the controller is: `dispose` stops the voice when no
  /// ancestor can be looked up (BR-STUDY-082).
  late final SpeechSynthesizer _speech;

  /// The last turn read aloud (BR-STUDY-078).
  String? _lastSpokenKey;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(
      studySessionControllerProvider(widget.sessionId).notifier,
    );
    _speech = ref.read(speechSynthesizerProvider);
    // The view may already be there when the screen opens (a resume).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cueSpeech();
    });
  }

  @override
  void dispose() {
    unawaited(_speech.stop());
    super.dispose();
  }

  /// The settings the session reads with; null while they load.
  SpeechSettings? _speechSettingsOf(StudySessionView view) =>
      ref.read(speechSettingsProvider(view.deckId)).value;

  /// Reads the card now drawn when it is a new turn (BR-STUDY-078). Called
  /// on every change of the view, the turn and the settings, so the first
  /// card waits for its language and a released hold reads the card the
  /// stream moved to meanwhile (spec §5).
  void _cueSpeech() {
    final current = ref.read(studySessionProvider(widget.sessionId));
    if (current case AsyncData(value: Ok(:final value))) {
      final settings = _speechSettingsOf(value);
      if (settings == null) return;
      final cue = speechCueOf(
        value,
        ref.read(studySessionControllerProvider(widget.sessionId)),
        lastKey: _lastSpokenKey,
        isAutoPlay: settings.isAutoPlay,
        isAccessibleNavigation: MediaQuery.accessibleNavigationOf(context),
      );
      if (cue == null) return;
      _lastSpokenKey = cue.key;
      unawaited(_speech.speak(cue.text, language: settings.language));
    }
  }
```

In `_onView`, before the `switch`:

```dart
    // An ended session is silent (BR-STUDY-082).
    if (next case AsyncData(value: Ok(:final value))
        when sessionEndingOf(value) != null) {
      unawaited(_speech.stop());
    }
```
and as the last line of `_onView` and of `_onTurn`: `_cueSpeech();`.

In `build`, after the two `ref.listen` calls, listen to the settings once the view is there (a `WidgetRef.listen` in `build` may be conditional: listeners not re-registered on a build are dropped):

```dart
    final viewAsync = ref.watch(studySessionProvider(widget.sessionId));
    if (viewAsync case AsyncData(value: Ok(:final value))) {
      ref.listen(speechSettingsProvider(value.deckId), (_, _) => _cueSpeech());
    }
```
and use `viewAsync` in the `switch` instead of watching again.

In `_sessionPage`, read the language for the buttons:

```dart
    final speechLanguage = ref
        .watch(speechSettingsProvider(view.deckId))
        .value
        ?.language;
```
and pass `speechLanguage: speechLanguage` to `StudyBrowseWidget`, `StudySelfAssessWidget`, `StudyGuessWidget` and `StudyRecallWidget` in `_modeBody` (add a `SpeechLanguage? speechLanguage` parameter to `_modeBody`).

- [ ] **Step 8: Generate, run the tests**

```bash
cd /home/user/memox-v8 && dart run build_runner build --delete-conflicting-outputs
bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/study/presentation
```
Expected: `study_speech_test.dart` PASS; every existing study presentation test PASS (the browse test's `_Host` builds `StudyBrowseWidget` directly: give it `speechLanguage: SpeechLanguage.enUs`; the same for any other direct construction the analyzer reports). Golden tests are tagged and skipped here; Task 8 updates them.

- [ ] **Step 9: Analyze and commit**

Run: `cd /home/user/memox-v8 && dart analyze && dart format --set-exit-if-changed lib test`
Expected: clean.

```bash
git add lib/core/theme/foundations/app_icons.dart lib/l10n lib/features/study test/features/study
git commit -m "feat(study): read a new card's term aloud, with a speaker button

The session screen cues the engine on each new turn of a learning
session in browse, self_assess, guess and recall, waits for the root's
language, stops on an ended session and on dispose; a speaker under the
term reads it on tap."
```

---

### Task 6: Screen 23 — the read-aloud switch and the default language

**Files:**
- Modify: `lib/features/settings/presentation/states/settings_state.dart`, `lib/features/settings/presentation/controllers/settings_controller.dart`, `lib/features/settings/presentation/widgets/sections/settings_study_defaults_section_widget.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Create: `lib/features/settings/presentation/widgets/support/speech_labels_widget.dart`, `lib/features/settings/presentation/widgets/overlays/speech_language_sheet_widget.dart`
- Test: `test/features/settings/presentation/settings_controller_test.dart`, `test/features/settings/presentation/settings_screen_test.dart`, `test/features/settings/presentation/speech_language_sheet_test.dart`

**Interfaces:**
- Consumes: `SetSpeechAutoPlayUseCase`/provider, `SaveStudyDefaultsUseCase(speechLanguage)`, `AppSettingsEntity.isSpeechAutoPlay`, `speechSynthesizerProvider`, `FakeSpeechSynthesizer`.
- Produces: `SettingsSubmit.speechLanguage`, `SettingsSubmit.speechAutoPlay`; `SettingsController.chooseSpeechLanguage(SpeechLanguage)`, `SettingsController.setSpeechAutoPlay({required bool isOn})`; `String speechLanguageName(AppLocalizations l10n, SpeechLanguage language)`; `Future<SpeechLanguage?> showSpeechLanguageSheet(BuildContext context, {required SpeechLanguage selected})`; ARB keys `settingsSpeechAutoPlay`, `settingsSpeechAutoPlayHint`, `settingsSpeechLanguage`, `settingsSpeechLanguageHint`, `settingsSpeechLanguageMissing`, `speechLanguageEnUs` … `speechLanguageEsEs`, and the reset copy.

- [ ] **Step 1: Write the failing tests**

In `settings_controller_test.dart` (its helpers: `_settingsTest(description, (rig) async {...})`, `_controller(rig)`, `_state(rig)`, `_stored(rig)` → `AppSettingsEntity`, `_settled()`; `rig.store` is the `FlakySettingsRepository`):

```dart
  _settingsTest('chooseSpeechLanguage writes the language alone '
      '(BR-SETTINGS-007, BR-SETTINGS-009)', (rig) async {
    _controller(rig).chooseSpeechLanguage(SpeechLanguage.jaJp);
    await _settled();

    final stored = await _stored(rig);
    expect(stored.studyDefaults.speechLanguage, SpeechLanguage.jaJp);
    expect(stored.studyDefaults.cardLimit, 20);
    expect(
      _state(rig).notice,
      isA<SettingsSaved>().having((n) => n.kind, 'kind', SettingsSubmit.speechLanguage),
    );
  });

  _settingsTest('the same language again writes nothing', (rig) async {
    _controller(rig).chooseSpeechLanguage(SpeechLanguage.enUs);
    await _settled();

    expect(rig.store.writes, 0);
  });

  _settingsTest('setSpeechAutoPlay writes the switch (BR-SETTINGS-010)', (rig) async {
    _controller(rig).setSpeechAutoPlay(isOn: false);
    await _settled();

    expect((await _stored(rig)).isSpeechAutoPlay, isFalse);
  });

  _settingsTest('a failed speech write leaves a Retry that writes it (E2)', (rig) async {
    rig.store.isFailing = true;
    _controller(rig).setSpeechAutoPlay(isOn: false);
    await _settled();
    expect(_state(rig).notice, isA<SettingsSaveFailed>());

    rig.store.isFailing = false;
    await _controller(rig).retry(SettingsSubmit.speechAutoPlay);
    await _settled();

    expect((await _stored(rig)).isSpeechAutoPlay, isFalse);
  });
```

Add `import 'package:memox/core/speech/speech_language.dart';` to the file.

In `settings_screen_test.dart`:

```dart
  libraryTest('Study defaults show the read-aloud switch and the default '
      'language', (tester, env) async {
    await pumpLibraryScreen(tester, env, _screen());

    expect(find.text(_en.settingsSpeechAutoPlay), findsOneWidget);
    expect(find.text(_en.settingsSpeechLanguage), findsOneWidget);
    expect(find.text(_en.speechLanguageEnUs), findsOneWidget);
  });

  libraryTest('the speech language row opens the sheet; a pick saves and '
      'shows its name (BR-SETTINGS-009)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: [
        speechSynthesizerProvider.overrideWithValue(
          FakeSpeechSynthesizer(available: {'en-US', 'vi-VN'}),
        ),
      ],
    );

    await tester.tap(find.text(_en.settingsSpeechLanguage));
    await tester.pumpAndSettle();
    expect(find.byType(MxBottomSheet), findsOneWidget);
    // A language the device lacks says so and stays selectable (D5).
    expect(find.text(_en.settingsSpeechLanguageMissing), findsNWidgets(8));

    await tester.tap(find.text(_en.speechLanguageViVn));
    await tester.pumpAndSettle();

    expect(find.byType(MxBottomSheet), findsNothing);
    expect(find.text(_en.speechLanguageViVn), findsOneWidget);
    final stored = await SettingsRepositoryImpl(env.db).watchAppSettings().first;
    expect(stored.studyDefaults.speechLanguage, SpeechLanguage.viVn);
  });

  libraryTest('the read-aloud toggle saves on change (BR-SETTINGS-010)', (tester, env) async {
    await pumpLibraryScreen(tester, env, _screen());

    await tester.tap(find.bySemanticsLabel(_en.settingsSpeechAutoPlay));
    await tester.pumpAndSettle();

    final stored = await SettingsRepositoryImpl(env.db).watchAppSettings().first;
    expect(stored.isSpeechAutoPlay, isFalse);
  });
```

Add the imports (`speech_providers.dart`, `speech_language.dart`, `mx_bottom_sheet.dart`, `fake_speech_synthesizer.dart`). If the sheet's option rows sit in a scrolling list and the Vietnamese row is off screen at 360×800, use `tester.scrollUntilVisible(find.text(_en.speechLanguageViVn), 100)` before the tap.

`test/features/settings/presentation/speech_language_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/speech/di/speech_providers.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/features/settings/presentation/widgets/overlays/speech_language_sheet_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

import '../../../support/fake_speech_synthesizer.dart';
import '../../../support/widget_harness.dart';

// Study speech spec §6, D5, D12.

final _en = lookupAppLocalizations(const Locale('en'));

Future<SpeechLanguage?> _open(
  WidgetTester tester, {
  required Set<String> available,
  SpeechLanguage selected = SpeechLanguage.enUs,
}) async {
  SpeechLanguage? picked;
  var opened = false;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        speechSynthesizerProvider.overrideWithValue(
          FakeSpeechSynthesizer(available: available),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                opened = true;
                picked = await showSpeechLanguageSheet(context, selected: selected);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(opened, isTrue);
  return picked;
}

void main() {
  testWidgets('every language is a row, the selected one marked, the ones '
      'the device lacks described (D5)', (tester) async {
    await _open(tester, available: {'en-US', 'ko-KR'});

    expect(find.byType(MxOptionRow), findsNWidgets(SpeechLanguage.values.length));
    final selected = tester.widget<MxOptionRow>(
      find.widgetWithText(MxOptionRow, _en.speechLanguageEnUs),
    );
    expect(selected.isSelected, isTrue);
    expect(find.text(_en.settingsSpeechLanguageMissing), findsNWidgets(8));
    final korean = tester.widget<MxOptionRow>(
      find.widgetWithText(MxOptionRow, _en.speechLanguageKoKr),
    );
    expect(korean.description, isNull);
  });

  testWidgets('a tap returns the language and closes the sheet', (tester) async {
    final future = _open(tester, available: const {});
    await tester.tap(find.text(_en.speechLanguageJaJp));
    await tester.pumpAndSettle();

    expect(await future, SpeechLanguage.jaJp);
  });

  testWidgets('an engine that reports no languages marks nothing', (tester) async {
    await _open(tester, available: const {});

    expect(find.text(_en.settingsSpeechLanguageMissing), findsNothing);
  });
}
```

(`_open` awaits the sheet's result; for the first and third tests the sheet stays open, which is fine since the test ends; if `pumpAndSettle` hangs on an open sheet, return the future without awaiting it, as the second test does, and `await` only after a pick.) Use `widget_harness.dart`'s `pumpMx` instead of a bare `MaterialApp` if a `ProviderScope` can be passed in; otherwise the inline `MaterialApp` with the theme from `buildLightTheme()` (`package:memox/core/theme/app_theme.dart`).

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd /home/user/memox-v8 && flutter test test/features/settings/presentation/settings_controller_test.dart test/features/settings/presentation/speech_language_sheet_test.dart`
Expected: FAIL (no `chooseSpeechLanguage`, no sheet).

- [ ] **Step 3: The strings**

`app_en.arb`, after `settingsOrderRandom`:

```json
  "settingsSpeechAutoPlay": "Read the term aloud",
  "@settingsSpeechAutoPlay": {
    "description": "Settings › Study defaults: the read-aloud switch (BR-SETTINGS-010)."
  },
  "settingsSpeechAutoPlayHint": "When a new card comes up while learning",
  "@settingsSpeechAutoPlayHint": {
    "description": "Subtitle of the read-aloud switch."
  },
  "settingsSpeechLanguage": "Speech language",
  "@settingsSpeechLanguage": {
    "description": "Settings › Study defaults and Study options: the row that opens the language sheet (BR-SETTINGS-009)."
  },
  "settingsSpeechLanguageHint": "Used by decks that follow the defaults",
  "@settingsSpeechLanguageHint": {
    "description": "Subtitle of the speech language row on Settings."
  },
  "settingsSpeechLanguageMissing": "Not installed on this device",
  "@settingsSpeechLanguageMissing": {
    "description": "Speech language sheet: the device's engine does not report this language; it stays selectable (spec D5)."
  },
  "studyOptionsSpeechLanguageHint": "The language the term is read in",
  "@studyOptionsSpeechLanguageHint": {
    "description": "Study options (screen 15): subtitle of the speech language row."
  },
  "speechLanguageEnUs": "English (US)",
  "@speechLanguageEnUs": { "description": "SpeechLanguage.enUs" },
  "speechLanguageEnGb": "English (UK)",
  "@speechLanguageEnGb": { "description": "SpeechLanguage.enGb" },
  "speechLanguageViVn": "Vietnamese",
  "@speechLanguageViVn": { "description": "SpeechLanguage.viVn" },
  "speechLanguageKoKr": "Korean",
  "@speechLanguageKoKr": { "description": "SpeechLanguage.koKr" },
  "speechLanguageJaJp": "Japanese",
  "@speechLanguageJaJp": { "description": "SpeechLanguage.jaJp" },
  "speechLanguageZhCn": "Chinese (Simplified)",
  "@speechLanguageZhCn": { "description": "SpeechLanguage.zhCn" },
  "speechLanguageZhTw": "Chinese (Traditional)",
  "@speechLanguageZhTw": { "description": "SpeechLanguage.zhTw" },
  "speechLanguageFrFr": "French",
  "@speechLanguageFrFr": { "description": "SpeechLanguage.frFr" },
  "speechLanguageDeDe": "German",
  "@speechLanguageDeDe": { "description": "SpeechLanguage.deDe" },
  "speechLanguageEsEs": "Spanish",
  "@speechLanguageEsEs": { "description": "SpeechLanguage.esEs" },
```

Change the reset copy:
- `settingsResetRowHint`: `"Theme, language, study defaults, read-aloud, reminder"`
- `settingsResetBody`: `"Theme, language, cards per session, new-card order, read-aloud settings and the daily reminder (off, 20:00) go back to their defaults."`

`app_vi.arb` (same keys, after `settingsOrderRandom`): `"Tự động đọc thuật ngữ"`, `"Khi thẻ mới xuất hiện lúc học"`, `"Ngôn ngữ phát âm"`, `"Dùng cho deck theo mặc định"`, `"Chưa có trên máy này"`, `"Ngôn ngữ đọc thuật ngữ"`, then `"Tiếng Anh (Mỹ)"`, `"Tiếng Anh (Anh)"`, `"Tiếng Việt"`, `"Tiếng Hàn"`, `"Tiếng Nhật"`, `"Tiếng Trung (giản thể)"`, `"Tiếng Trung (phồn thể)"`, `"Tiếng Pháp"`, `"Tiếng Đức"`, `"Tiếng Tây Ban Nha"`. Reset: `settingsResetRowHint` → `"Giao diện, ngôn ngữ, mặc định học, đọc to, nhắc học"`; in `settingsResetBody`, insert ", cài đặt đọc to" after the new-card-order phrase of the existing Vietnamese sentence.

Run: `cd /home/user/memox-v8 && flutter gen-l10n`

- [ ] **Step 4: State and controller**

`settings_state.dart`:

```dart
/// The submits of screen 23; each is a write of its own (BR-SETTINGS-007).
enum SettingsSubmit {
  cardLimit,
  newCardOrder,
  speechLanguage,
  speechAutoPlay,
  theme,
  language,
  reset,
}
```

`isStudyDefaultsBusy` stays the pair (limit and order share `_written`); the speech language writes its own column.

`settings_controller.dart`: imports for `SpeechLanguage` and `set_speech_auto_play_use_case_provider.dart`; after `chooseNewCardOrder`:

```dart
  /// The default speech language, written alone (BR-SETTINGS-007,
  /// BR-SETTINGS-009).
  void chooseSpeechLanguage(SpeechLanguage language) {
    if (language == _studyDefaults?.speechLanguage) return;
    unawaited(
      _submit(
        SettingsSubmit.speechLanguage,
        () => ref.read(saveStudyDefaultsUseCaseProvider)(
          speechLanguage: language,
        ),
        retry: () async => chooseSpeechLanguage(language),
      ),
    );
  }

  /// The read-aloud switch, saved on the toggle (BR-SETTINGS-010).
  void setSpeechAutoPlay({required bool isOn}) {
    if (isOn == _persisted?.isSpeechAutoPlay) return;
    unawaited(
      _submit(
        SettingsSubmit.speechAutoPlay,
        () => ref.read(setSpeechAutoPlayUseCaseProvider)(isOn: isOn),
        retry: () async => setSpeechAutoPlay(isOn: isOn),
      ),
    );
  }
```

In `chooseNewCardOrder` and `_saveCardLimit`, the `StudyOptions(...)` built for `_written` passes `speechLanguage: persisted.speechLanguage` so the remembered defaults keep the language.

- [ ] **Step 5: The labels and the sheet**

`lib/features/settings/presentation/widgets/support/speech_labels_widget.dart`:

```dart
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// [language] as the person reads it (study speech spec §4).
String speechLanguageName(AppLocalizations l10n, SpeechLanguage language) =>
    switch (language) {
      SpeechLanguage.enUs => l10n.speechLanguageEnUs,
      SpeechLanguage.enGb => l10n.speechLanguageEnGb,
      SpeechLanguage.viVn => l10n.speechLanguageViVn,
      SpeechLanguage.koKr => l10n.speechLanguageKoKr,
      SpeechLanguage.jaJp => l10n.speechLanguageJaJp,
      SpeechLanguage.zhCn => l10n.speechLanguageZhCn,
      SpeechLanguage.zhTw => l10n.speechLanguageZhTw,
      SpeechLanguage.frFr => l10n.speechLanguageFrFr,
      SpeechLanguage.deDe => l10n.speechLanguageDeDe,
      SpeechLanguage.esEs => l10n.speechLanguageEsEs,
    };
```

`lib/features/settings/presentation/widgets/overlays/speech_language_sheet_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/speech/di/speech_providers.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/settings/presentation/widgets/support/speech_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

/// The speech language picker of screens 15 and 23 (study speech spec D12):
/// one row per language, the current one selected. Returns the pick, or
/// null when dismissed.
Future<SpeechLanguage?> showSpeechLanguageSheet(
  BuildContext context, {
  required SpeechLanguage selected,
}) => showMxBottomSheet<SpeechLanguage>(
  context,
  builder: (_) => SpeechLanguageSheetWidget(selected: selected),
);

class SpeechLanguageSheetWidget extends ConsumerStatefulWidget {
  const SpeechLanguageSheetWidget({super.key, required this.selected});

  final SpeechLanguage selected;

  @override
  ConsumerState<SpeechLanguageSheetWidget> createState() =>
      _SpeechLanguageSheetWidgetState();
}

class _SpeechLanguageSheetWidgetState
    extends ConsumerState<SpeechLanguageSheetWidget> {
  /// What the device engine reports it can read; empty until it answers,
  /// and when it cannot say, so nothing is marked then (spec §6).
  Set<String> _available = const {};

  @override
  void initState() {
    super.initState();
    _loadAvailable();
  }

  Future<void> _loadAvailable() async {
    final tags = await ref.read(speechSynthesizerProvider).availableLanguageTags();
    if (mounted) setState(() => _available = tags);
  }

  bool _isMissing(SpeechLanguage language) =>
      _available.isNotEmpty && !_available.contains(language.tag);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxBottomSheet(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.grouped,
          AppSpacing.gutter,
          AppSpacing.grouped,
        ),
        child: Text(l10n.settingsSpeechLanguage, style: context.textStyles.sheetTitle),
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final (index, language) in SpeechLanguage.values.indexed)
            MxOptionRow(
              title: speechLanguageName(l10n, language),
              description: _isMissing(language)
                  ? l10n.settingsSpeechLanguageMissing
                  : null,
              isSelected: language == widget.selected,
              isDimmed: false,
              hasDivider: index < SpeechLanguage.values.length - 1,
              onSelected: () => Navigator.of(context).pop(language),
            ),
        ],
      ),
    );
  }
}
```

`sheetTitle` stands for the title style the existing pickers give their header: open `lib/shared/widgets/mx_deck_picker_sheet.dart` (or `grep -rn "header:" -A 8 lib/features/*/presentation/widgets/overlays/*.dart`) and copy its header `Padding` and text style exactly.

- [ ] **Step 6: The two rows on screen 23**

In `settings_study_defaults_section_widget.dart`, imports for `SpeechLanguage`, the labels, the sheet, `MxToggle`, and `stored` is `StudyOptions`; the switch needs the entity, so the widget takes a second value:

```dart
  const SettingsStudyDefaultsSectionWidget({
    super.key,
    required this.stored,
    required this.isSpeechAutoPlay,
  });

  /// The persisted defaults (BR-SETTINGS-001).
  final StudyOptions stored;

  /// The persisted read-aloud switch (BR-SETTINGS-010).
  final bool isSpeechAutoPlay;
```

(Update the one call site in `settings_screen.dart`: `isSpeechAutoPlay: settings.isSpeechAutoPlay`.)

After the "New-card order" row:

```dart
        MxSettingsRow(
          label: l10n.settingsSpeechAutoPlay,
          subtitle: l10n.settingsSpeechAutoPlayHint,
          icon: AppIcons.speak,
          trailing: MxToggle(
            isOn: isSpeechAutoPlay,
            semanticLabel: l10n.settingsSpeechAutoPlay,
            onChanged: (isOn) => _controller(ref).setSpeechAutoPlay(isOn: isOn),
          ),
        ),
        MxSettingsRow(
          label: l10n.settingsSpeechLanguage,
          subtitle: l10n.settingsSpeechLanguageHint,
          icon: AppIcons.speak,
          trailing: Text(
            speechLanguageName(l10n, stored.speechLanguage),
            style: context.textStyles.settingsLabel,
          ),
          onTap: () async {
            final picked = await showSpeechLanguageSheet(
              context,
              selected: stored.speechLanguage,
            );
            if (picked != null && context.mounted) {
              _controller(ref).chooseSpeechLanguage(picked);
            }
          },
        ),
```

`MxSettingsRow` takes `onTap` (and `isAction` for a row that opens a dialog); the Theme and Language rows in `settings_app_section_widget.dart` are the pattern of a row that opens something, copy their shape.

- [ ] **Step 7: Run the tests**

```bash
cd /home/user/memox-v8 && dart run build_runner build --delete-conflicting-outputs
bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/settings/presentation
```
Expected: PASS (goldens are tagged and skipped; Task 8).

- [ ] **Step 8: Analyze, format, commit**

Run: `cd /home/user/memox-v8 && dart analyze && dart format --set-exit-if-changed lib test`

```bash
git add lib/features/settings lib/l10n test/features/settings
git commit -m "feat(settings): read-aloud switch and default speech language on Settings

Two rows in Study defaults, a language sheet that marks what the device
lacks, SettingsController.chooseSpeechLanguage and setSpeechAutoPlay,
and the reset copy naming them."
```

---

### Task 7: Screen 15 — the root deck's speech language

**Files:**
- Modify: `lib/features/settings/presentation/states/study_options_state.dart`, `lib/features/settings/presentation/controllers/study_options_controller.dart`, `lib/features/settings/presentation/widgets/sections/study_options_form_widget.dart`
- Test: `test/features/settings/presentation/study_options_controller_test.dart`, `test/features/settings/presentation/study_options_screen_test.dart`

**Interfaces:**
- Consumes: `StudyOptionsForm`, `showSpeechLanguageSheet`, `speechLanguageName`.
- Produces: `StudyOptionsState.speechLanguage`, `edited(speechLanguage:)`; `StudyOptionsController.chooseSpeechLanguage(SpeechLanguage)`.

- [ ] **Step 1: Write the failing tests**

In `study_options_controller_test.dart` (its rig is `_rig`, `_controller`, `_state`, `_form`, `_stored`):

```dart
  libraryTest('chooseSpeechLanguage changes the draft; Save writes it in the '
      'override (BR-SETTINGS-009)', (tester, env) async {
    final rig = await _rig(env, rootConfig: '{"card_limit":30,"new_card_order":"random"}');
    _controller(rig).chooseSpeechLanguage(SpeechLanguage.koKr);
    expect((await _form(rig)).isChanged, isTrue);
    expect((await _form(rig)).options.speechLanguage, SpeechLanguage.koKr);

    await _controller(rig).save();

    final stored = await _stored(rig);
    expect(stored.options.speechLanguage, SpeechLanguage.koKr);
    expect(stored.options.cardLimit, 30);
  });

  libraryTest('an override from before speech shows the default language '
      'and is unchanged until edited (D6)', (tester, env) async {
    final rig = await _rig(env, rootConfig: '{"card_limit":30,"new_card_order":"random"}');

    final form = await _form(rig);
    expect(form.options.speechLanguage, SpeechLanguage.enUs);
    expect(form.isChanged, isFalse);
  });
```

(Use `libraryTest` or the file's own async `test` shape, whichever it uses.)

In `study_options_screen_test.dart`:

```dart
  libraryTest('following the defaults, the speech language is plain text; '
      'own options open the sheet and Save writes the pick', (tester, env) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _screen(ids.subId));

    expect(find.text(_en.settingsSpeechLanguage), findsOneWidget);
    expect(find.text(_en.speechLanguageEnUs), findsOneWidget);
    await tester.tap(find.text(_en.settingsSpeechLanguage));
    await tester.pumpAndSettle();
    expect(find.byType(MxBottomSheet), findsNothing);

    await tester.tap(find.bySemanticsLabel(_en.studyOptionsUseAppDefaults));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.settingsSpeechLanguage));
    await tester.pumpAndSettle();
    expect(find.byType(MxBottomSheet), findsOneWidget);
    await tester.tap(find.text(_en.speechLanguageJaJp));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.commonSave));
    await tester.pumpAndSettle();

    final stored = await _stored(env, ids.subId);
    expect(stored.options.speechLanguage, SpeechLanguage.jaJp);
  });
```

(`_seed`, `_screen` and `_stored` are the file's own helpers.) The Save label key is whatever the footer uses (`grep -n "label:" lib/features/settings/presentation/widgets/sections/study_options_footer_widget.dart`); add the imports for `SpeechLanguage` and `MxBottomSheet`.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd /home/user/memox-v8 && flutter test test/features/settings/presentation/study_options_controller_test.dart`
Expected: FAIL ("The method 'chooseSpeechLanguage' isn't defined").

- [ ] **Step 3: State and form**

`study_options_state.dart`: add `this.speechLanguage` (`final SpeechLanguage? speechLanguage;`) to the constructor, `edited(...)` (`SpeechLanguage? speechLanguage` → `speechLanguage ?? this.speechLanguage`) and `withSave`. In `StudyOptionsForm.of`:

```dart
        : StudyOptions(
            cardLimit: draft.cardLimit ?? stored.options.cardLimit,
            newCardOrder: draft.newCardOrder ?? stored.options.newCardOrder,
            speechLanguage:
                draft.speechLanguage ?? stored.options.speechLanguage,
          );
    final isChanged =
        isUsingAppDefaults != wasUsingAppDefaults ||
        stored.source == StudyOptionsSource.unreadableRootOverride ||
        (!isUsingAppDefaults &&
            (options.cardLimit != stored.options.cardLimit ||
                options.newCardOrder != stored.options.newCardOrder ||
                options.speechLanguage != stored.options.speechLanguage));
```

`study_options_controller.dart`, after `chooseNewCardOrder`:

```dart
  void chooseSpeechLanguage(SpeechLanguage language) {
    if (state.isSaving) return;
    state = state.edited(speechLanguage: language);
  }
```

- [ ] **Step 4: The row on screen 15**

In `study_options_form_widget.dart`, after the "New-card order" row, in the same `MxSection`:

```dart
            MxSettingsRow(
              label: l10n.settingsSpeechLanguage,
              subtitle: l10n.studyOptionsSpeechLanguageHint,
              icon: AppIcons.speak,
              trailing: Text(
                speechLanguageName(l10n, options.speechLanguage),
                style: styles.settingsLabel,
              ),
              onTap: !isEditable
                  ? null
                  : () async {
                      final picked = await showSpeechLanguageSheet(
                        context,
                        selected: options.speechLanguage,
                      );
                      if (picked != null && context.mounted) {
                        _controller(ref).chooseSpeechLanguage(picked);
                      }
                    },
            ),
```

The failed-save banner's sentence keeps naming the limit and the order (spec §6).

- [ ] **Step 5: Run the tests, analyze, commit**

```bash
cd /home/user/memox-v8 && dart run build_runner build --delete-conflicting-outputs
bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/settings/presentation
dart analyze && dart format --set-exit-if-changed lib test
git add lib/features/settings test/features/settings
git commit -m "feat(settings): a root deck's speech language on Study options

The row follows the read-only / editable pattern of the order row; the
draft, isChanged and Save carry the language into study_config."
```

---

### Task 8: Goldens, documentation, the gate

**Files:**
- Goldens: `test/features/settings/presentation/goldens/study_options_*.png`, `settings_loaded_*.png` (and the other `settings_*` states whose page grew), `test/features/study/presentation/goldens/study_browse_*.png`, `study_self_assess_*.png`, `study_guess_*.png`, `study_recall_*.png`
- Create: `docs/features/study/rules/BR-STUDY-078-doc-term-khi-the-moi.md` … `BR-STUDY-082-mot-giong.md`, `docs/features/settings/rules/BR-SETTINGS-009-ngon-ngu-phat-am-la-study-option.md`, `BR-SETTINGS-010-tu-dong-doc-toan-app.md`
- Modify: `docs/features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md` (`rules:` list), `docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md` (`rules:` list and step 2), `docs/features/settings/rules/BR-SETTINGS-008-reset-to-defaults.md` (eight values), `docs/shared/ui/screen-handoff/{15,16,16a,18,19,23}-*.md`, `docs/shared/ui/screen-handoff/00-index.md`, `docs/README.md` (out-of-MVP table), `docs/_generated/*` (regenerated)

- [ ] **Step 1: Update the goldens and build the review page**

```bash
cd /home/user/memox-v8 && bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update
git status --short test/**/goldens
```
Expected: the files above changed; nothing else. Open each changed PNG once (Read) and check the button sits under the term, centred, and the new rows read like the others. Then build the owner's page with the `golden-compare` skill (before · after · diff) and keep its link for the PR.

- [ ] **Step 2: Write the business rules**

Each file follows the shape of `BR-STUDY-073-*.md` (frontmatter `id`, `title`, `status: active`, `summary`, `superseded_by:`; sections `## Rule`, `## Lý do`, `## Ví dụ`, `## Edge case`; Vietnamese). The rules, from the spec §5:

- `BR-STUDY-078-doc-term-khi-the-moi.md` — "Đọc term khi thẻ mới xuất hiện": trong phiên `learning`, khi thẻ phục vụ đổi (cardId khác, hoặc cùng thẻ ở mode/round/lượt khác), app MUST đọc `front` một lần bằng ngôn ngữ phát âm của root deck khi mode là `browse`, `self_assess`, `guess`, `recall`; MUST NOT đọc ở `fill`, `match`, phiên `reviewing`. Enforced by: UI. Liên quan: BR-MODE-002, BR-STUDY-056, BR-SETTINGS-009. Edge case: nhìn lại thẻ cũ trong Browse không đọc (D11); TalkBack bật thì không tự đọc, nút loa vẫn đọc (D13).
- `BR-STUDY-079-cong-tac-tu-dong-doc.md` — tự động đọc chỉ khi `tts_auto_play` bật; nút loa MUST đọc khi chạm bất kể công tắc.
- `BR-STUDY-080-tuy-chon-doc-theo-thoi-gian-thuc.md` — ngôn ngữ và công tắc đọc tại thời điểm đọc; đổi áp dụng cho thẻ kế tiếp, không cần phiên mới (khác BR-SETTINGS-004).
- `BR-STUDY-081-doc-la-best-effort.md` — lỗi engine MUST được log (`speech.*`, category `ui`), MUST NOT hiện banner, retry hay đổi lượt; MUST NOT log nội dung thẻ.
- `BR-STUDY-082-mot-giong.md` — lần đọc mới MUST dừng lần trước; rời body phiên (summary, abandon, leave, dispose) MUST dừng.
- `BR-SETTINGS-009-ngon-ngu-phat-am-la-study-option.md` — theo BR-STUDY-056/BR-SETTINGS-003: override của root (`study_config.tts_language`) khi có, mặc định app (`app_settings.tts_language`) khi không; màn 15 sửa override, màn 23 sửa mặc định; thiếu key đọc là mặc định (D6).
- `BR-SETTINGS-010-tu-dong-doc-toan-app.md` — `tts_auto_play` toàn app, mặc định bật, chỉ của máy (không sync), Reset to defaults đưa về bật.

Add `BR-STUDY-078`…`082` to the `rules:` list of UC-STUDY-001 and `BR-SETTINGS-009`, `BR-SETTINGS-010` to UC-SETTINGS-001's, with one sentence in UC-SETTINGS-001 step 2 naming the two new values. In `BR-SETTINGS-008`, "sáu giá trị … `reminder_minute_of_day`" becomes "tám giá trị … `reminder_minute_of_day`, `tts_language`, `tts_auto_play`".

- [ ] **Step 3: Update the screen records**

- `15-study-options.md`: Options row adds "Speech language" / "The language the term is read in", plain text while the toggle is on, a row opening the language sheet when off; States table unchanged in count; copy list adds the three strings. Add a "Speech language sheet" line: `MxBottomSheet` + `MxOptionRow` × 10, "Not installed on this device" on the ones the engine lacks.
- `16-study-browse.md`: Card row: "…pronunciation, and a speaker (`MxIconButton`, volume-2) that reads the term (BR-STUDY-079)"; a "Speech" bullet under Shared by the session screens: BR-STUDY-078…082 in two sentences.
- `16a-study-self-assess.md`, `18-study-guess.md`, `19-study-recall.md`: the term/prompt row names the speaker.
- `23-settings.md`: Study defaults row: `MxSettingsRow` × 4; the two new rows and their copy; the Reset rows' copy as changed in Task 6.
- `00-index.md`: the States count of 15 and 23 if a state was added (none was), the FE item column of 15, 16, 16a, 18, 19, 23 gains "study speech" is not needed; leave the rows unless the detail file's state count changed.

- [ ] **Step 4: `docs/README.md` and the generated docs**

In the out-of-MVP table, the "Audio / hình ảnh trong card" row's Notes: append " — riêng việc **đọc term bằng TTS của máy** đã làm ([spec](superpowers/specs/2026-10-07-study-speech-design.md)); audio lưu trong card vẫn ngoài phạm vi".

```bash
cd /home/user/memox-v8 && python3 -I tools/docs/generate.py && python3 -I tools/docs/check.py
```
Expected: `PASS — 0 error(s)`; the new BRs are used by a UC, so no new warning.

- [ ] **Step 5: The gate**

```bash
cd /home/user/memox-v8 && bash .claude/skills/flutter-workflow/scripts/dod_check.sh
bash .claude/skills/flutter-workflow/scripts/run_goldens.sh
```
Expected: both PASS. Fix anything red before the commit; never `--update-goldens` here (Step 1 already did, deliberately).

- [ ] **Step 6: Commit**

```bash
git add test/features/settings/presentation/goldens test/features/study/presentation/goldens docs
git commit -m "docs(study): speech rules, screen records and goldens for read-aloud

BR-STUDY-078…082, BR-SETTINGS-009/010 and their UCs; handoff 15, 16,
16a, 18, 19, 23; the scope note; goldens of the six screens."
```

Then push the branch (`git push -u origin claude/flashcard-audio-on-card-switch-1sxrkh`) and open the PR with the golden review link, per `finishing-a-development-branch`. The Linear epic could not be created (workspace issue limit): say so in the PR body and to the owner.
