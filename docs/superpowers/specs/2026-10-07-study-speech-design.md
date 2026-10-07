# Study speech: the term read aloud in a learning session — design

Status: approved 2026-10-07 ·
Path: architectural · Owner rulings 2026-10-07 (§3): D1–D5

## 1. Intent

A learning session shows a card and the person reads it; nothing is heard. This spec
adds **text-to-speech of the term** to the session: when a new card comes up in a
learning session, the app reads its term aloud through the device's TTS engine, and a
speaker button on the term lets the person hear it again. The language the term is read
in belongs to the root deck, with an app-wide default, like the other study options.

Success means:

- in a learning session, a new card in `browse`, `self_assess`, `guess` or `recall` is
  read once, in the root deck's speech language, and never in `fill`, `match` or a review
  session (§5);
- the person can turn the automatic reading off, pick the default language on screen 23
  and a root deck's own language on screen 15 (§6);
- every TTS call goes through one door in `lib/core/speech/`, so a failing engine is
  logged and never blocks a turn (§3 D1, §7);
- the change leaves Supabase untouched (§4).

What is not in this spec: audio files on cards (still "Sau MVP" in `docs/README.md`),
reading the meaning or the example, a speaker button in `fill` after the check, speech in
a review session, and a speech rate or voice choice.

## 2. Context (2026-10-07)

- **Cards** have `front`, `back`, `example`, `hint` and `pronunciation` (text, IPA); no
  audio and no language. **Decks** have no language either.
- **Study options** (BR-STUDY-056): `StudyOptions(cardLimit, newCardOrder)`, the
  app-wide defaults in `app_settings` and a root deck's override in `deck.study_config`
  (JSON, `study_config_mapper.dart`). `EffectiveStudyOptions` resolves a deck to its
  root's options. Screen 15 edits a root's override; screen 23 edits the defaults.
- **Sync:** `AccountSettingsSyncDao` syncs four named columns of `app_settings`
  (`cardLimit`, `newCardOrder`, `themeMode`, `language`); every other column is
  device-only, as `welcome_seen` is. `deck.study_config` travels with the deck row; the
  server casts it to `jsonb` and checks no key
  (`supabase/migrations/20260928000000_deck_sync.sql`).
- **The session screen** (`StudySessionScreen`) watches `studySessionProvider` and
  dispatches one body per `StudyMode`; `StudySessionView.currentItem` is the card served,
  `view.kind` tells `learning` from `reviewing`. A learning session's `self_assess` asks
  the term first (`item.direction` is null); only an sm2 review has a direction.
- **Plugins with one door:** `plugin_reminder_plugins_data_source.dart` is the only file
  that imports the reminder plugins, held by the guard rule
  `memox_v8.architecture.reminder_plugins_have_one_door`
  (`code-verification-guard-v2/registries/projects/memox-v8/rules/memox-architecture-rules.yaml`).
- **Imports:** `study → settings` exists (`test/architecture/boundary_rules.dart`), so
  `settings` may not import `study`. `core/` is importable from every feature.
- **Schema:** `schemaVersion` is 14; a migration adds columns with `m.addColumn`
  (`from11To12` added `welcome_seen`). `test/database/schema_test.dart` and
  `schema_constants_parity_test.dart` cover versions and CHECK lists.
- **Widgets on hand:** `MxIconButton` (20 glyph, 36 box, 48 hit area), `MxToggle`,
  `MxSettingsRow`, `MxSection`, `MxBottomSheet`, `MxOptionRow`, `MxSegmentedTray`.
- **Platform:** Android only (ADR-009). `flutter_tts` 4.2.5 wraps
  `android.speech.tts.TextToSpeech`.

## 3. Decisions

| # | Decision | Why |
|---|---|---|
| D1 | TTS lives in `lib/core/speech/`: `SpeechSynthesizer` (interface), `PluginSpeechSynthesizer` (the one file that imports `flutter_tts`), its provider, and a new guard rule `memox_v8.architecture.tts_plugin_has_one_door` | Owner 2026-10-07. Both `study` (speak) and `settings` (which languages the device has) use it, and `study → settings` already exists, so a home in `study` would need `settings → study`. The one-door shape is the reminders' |
| D2 | `flutter_tts: ^4.2.5` is added to `pubspec.yaml` | Owner 2026-10-07. The device engine, no server, no asset; a `MethodChannel` of our own would be Kotlin to maintain for the same calls |
| D3 | The speech language is a **study option of the root deck** with an **app-wide default**: `StudyOptions.speechLanguage`, key `tts_language` in `deck.study_config`, column `tts_language` in `app_settings` | Owner 2026-10-07. A person learns more than one language; the root deck already carries the other study options (BR-STUDY-056) |
| D4 | Automatic reading is on by default, with an app-wide device-only switch `tts_auto_play` on screen 23, and a speaker button on the term in every mode that shows it as the prompt | Owner 2026-10-07. Hearing the word is the point; a public place needs a way off; the button serves whoever turned it off |
| D5 | The languages offered are a fixed list, `SpeechLanguage` (§4), not what the engine reports | Owner 2026-10-07. The engine's list is long, its tags vary by vendor, and Flutter has no display names for them; a fixed list has translated names and a CHECK. A language the device lacks is still offered, marked, so a choice survives a change of device |
| D6 | A `study_config` without `tts_language` reads as the default language; a key of the wrong type or an unknown tag makes the override unreadable, as today | Every root with an override today lacks the key; none of them may turn "unreadable" (IT-STUDY-013) on update |
| D7 | The two new columns are device-only: not in `AccountSettingsSyncDao`, not on the server. The root override syncs with the deck row as it does today | Keeps Supabase and its migrations out of this change; a root's language reaches the other device through the deck |
| D8 | The session reads the language and the switch **live**, from `studyOptionsProvider(view.deckId)` and `appSettingsProvider` | Unlike the card limit and the order, nothing of the session is written from them; a change applies to the next card without a restart (BR-STUDY-080) |
| D9 | Speech is best-effort: an engine failure is logged (`LogCategory.ui`) and swallowed; nothing waits on it, nothing is retried | A turn never depends on sound (BR-STUDY-081) |
| D10 | Speaking stops before every new `speak` and when the session body leaves (summary, abandon, leave, dispose) | Two cards read over each other, or a word read on the summary, are defects |
| D11 | Looking back in Browse does not read the older card; the live card's speaker button is the way to hear a card again | "A new card" is the live one; the look-back is a glance (BR-STUDY-048) |
| D12 | The language picker on screens 15 and 23 is an `MxBottomSheet` of `MxOptionRow`s, one per `SpeechLanguage`, with the device's missing ones marked in the description | No new component, no new route; ten rows fit a sheet. Screen 26's full-screen pattern is for a setting that re-renders the whole app |

## 4. Data

### `SpeechLanguage` (`lib/core/speech/speech_language.dart`)

A fixed enum, each with its BCP-47 tag, the code stored everywhere:

| Name | Tag |
|---|---|
| `enUs` | `en-US` (default) |
| `enGb` | `en-GB` |
| `viVn` | `vi-VN` |
| `koKr` | `ko-KR` |
| `jaJp` | `ja-JP` |
| `zhCn` | `zh-CN` |
| `zhTw` | `zh-TW` |
| `frFr` | `fr-FR` |
| `deDe` | `de-DE` |
| `esEs` | `es-ES` |

`SpeechLanguage.fromTag(String)` returns null for an unknown tag; the display name is an
ARB entry per value (`speechLanguageEnUs`, …). Adding a language is a code change, a
schema migration (the CHECK) and two ARB lines.

### `StudyOptions`

Gains `speechLanguage` (`SpeechLanguage`, default `enUs`). `defaults` carries it.
`check()` is unchanged: an enum needs no range check.

### `deck.study_config`

Gains the key `tts_language` with the tag. `studyConfigOf` writes it; `studyOptionsOf`
reads it per D6: absent → `SpeechLanguage.enUs`; present but not a string, or a string
`fromTag` does not know → null (unreadable).

### `app_settings` (schema 14 → 15)

```sql
tts_language TEXT NOT NULL DEFAULT 'en-US'
  CHECK (tts_language IN ('en-US','en-GB','vi-VN','ko-KR','ja-JP','zh-CN','zh-TW','fr-FR','de-DE','es-ES')),
tts_auto_play INTEGER NOT NULL DEFAULT 1 CHECK (tts_auto_play IN (0, 1)),
```

`from14To15` adds the two columns; no row changes. `schema_constants_parity_test` checks
the CHECK list against `SpeechLanguage.values`. `AppSettingsEntity` gains
`isSpeechAutoPlay` (bool); `studyDefaults.speechLanguage` carries the language.
`appSettingsOf` maps both; an unknown tag throws, as the other codes do.
`Reset to defaults` (BR-SETTINGS-008) returns both to their defaults. `LocalDataReset`
is unchanged: the settings row is reset by the settings feature as today.

### Sync

`AccountSettingsSyncDao.readRow` and `upsertFromServer` do not name the new columns
(D7). No Supabase change. `deck.study_config` with the new key passes the server's
`jsonb` cast as any JSON does.

## 5. Behaviour in the session

New business rules, numbered after BR-STUDY-077:

- **BR-STUDY-078 — What is read.** In a learning session, when the card the session
  serves changes (a different `cardId`, or the same card in a different mode), the app
  reads the card's `front` once, in the root deck's speech language, when the mode is
  `browse`, `self_assess`, `guess` or `recall`. It never reads in `fill` (the term is the
  answer), `match` (no single card is served) or a review session.
- **BR-STUDY-079 — The switch.** Automatic reading runs only while `tts_auto_play` is on.
  The speaker button reads the term on tap whatever the switch says.
- **BR-STUDY-080 — Live options.** The language and the switch are read as they are at
  the moment of reading; a change applies to the next card, with no new session.
- **BR-STUDY-081 — Best-effort.** A failure to speak (no engine, language not installed,
  plugin error) is logged and changes nothing in the session: no banner, no retry, no
  effect on the turn.
- **BR-STUDY-082 — One voice.** A new reading stops the one in progress; leaving the
  session body (summary, abandon, leave, dispose) stops it too.

Settings rules, numbered after BR-SETTINGS-008:

- **BR-SETTINGS-009 — Speech language is a study option.** It follows BR-STUDY-056 and
  BR-SETTINGS-003: the root deck's override when it has one, the app default otherwise;
  screen 15 edits the override, screen 23 the default.
- **BR-SETTINGS-010 — Automatic reading is app-wide and device-only.** On by default;
  never synced; reset to on by Reset to defaults.

### Where the reading fires

One place: `StudySessionScreen`. It already listens to `studySessionProvider`
(`_onView`). A new feature-local helper, `StudySpeechCue` (pure, in
`lib/features/study/presentation/states/study_speech_cue.dart`), decides from
`(previousView, nextView, turn)` whether a reading is due and of what:

```dart
/// What the session should read now, if anything (BR-STUDY-078).
SpeechCue? speechCueOf(StudySessionView? previous, StudySessionView next, StudyTurnState turn);
```

It returns a cue when `next.kind == learning`, `next.currentItem != null`,
`sessionEndingOf(next) == null`, `!turn.isBusy && turn.held == null`,
`next.currentMode.handler.readsTermAloud` (below), and `(cardId, mode)` differs from the
previous view's. The screen then reads the switch and the language and calls
`SpeechSynthesizer.speak`. Keeping the decision pure keeps it unit-tested without a
widget.

`StudyModeHandler` gains `bool get readsTermAloud` (default `true`), overridden to
`false` in `fill` and `match`: the one place a mode is told apart (guard
`single_study_mode_dispatch`).

The frozen view (`_lastOpenView`, spec D5 of the study UI) is what the screen draws while
a turn is held; the cue uses the drawn view, so the next card is read when it appears,
not when the stream moves ahead under a hold.

### The speaker button

`StudySpeakButtonWidget` (`lib/features/study/presentation/widgets/support/`): an
`MxIconButton` with `AppIcons.speak` (new, `Icons.volume_up_rounded`) and the semantic
label "Read aloud" / "Đọc to"; `onPressed` reads `item.front` in the session's language.
Placed under the term, after the pronunciation, in: Browse's term half, Self-assess's
`_TermFace` (shown with the face), Guess's prompt, Recall's prompt. Not in Fill or Match.

## 6. Settings UI

### Screen 23 · Settings → Study defaults

Two rows after "New-card order", in `SettingsStudyDefaultsSectionWidget`:

| Row | Widget | Copy (en / vi) |
|---|---|---|
| Read aloud | `MxSettingsRow` + `MxToggle` (`AppIcons.speak`) | "Read the term aloud" / "Tự động đọc thuật ngữ"; subtitle "When a new card comes up while learning" / "Khi thẻ mới xuất hiện lúc học" |
| Speech language | `MxSettingsRow`, trailing the language name, tap opens the sheet | "Speech language" / "Ngôn ngữ phát âm"; subtitle "Used by decks that follow the defaults" / "Dùng cho deck theo mặc định" |

Each saves on change, as the section's other rows do (`SettingsController`:
`toggleSpeechAutoPlay`, `chooseSpeechLanguage`, through `SaveStudyDefaultsUseCase` and a
new `SetSpeechAutoPlayUseCase`). The reset copy on screen 23 names the two values.

### Screen 15 · Study options

One row after "New-card order", in `StudyOptionsFormWidget`: "Speech language" with the
same read-only / editable pattern as the order row (plain text while "Use app defaults"
is on, a tappable row opening the sheet when off). `StudyOptionsState` gains
`speechLanguage`; `StudyOptionsForm.of` folds it; `isChanged` counts it. Save writes it in
the same JSON (BR-SETTINGS-009). The toggle's "Following Settings · …" subtitle and the
failed-save banner stay as they are: the language is in the rows below.

### The language sheet (`SpeechLanguageSheetWidget`, `settings/presentation/widgets/overlays/`)

`showMxBottomSheet` with the title "Speech language", one `MxOptionRow` per
`SpeechLanguage` in the order of §4, the current one selected. The sheet asks
`SpeechSynthesizer.availableLanguageTags()` once when it opens; a language not in the
set gets the description "Not installed on this device" / "Chưa có trên máy này" and
stays selectable (D5). A failed query marks nothing.

## 7. `lib/core/speech/`

```
lib/core/speech/
  speech_language.dart              # the enum of §4
  speech_synthesizer.dart           # the interface
  plugin_speech_synthesizer.dart    # the one door to flutter_tts
  di/speech_providers.dart          # speechSynthesizerProvider (keep-alive)
```

```dart
abstract interface class SpeechSynthesizer {
  /// Reads [text] in [language]; stops what is being read first. Never throws:
  /// a failure is logged (BR-STUDY-081).
  Future<void> speak(String text, {required SpeechLanguage language});
  Future<void> stop();
  /// The BCP-47 tags the device engine reports; empty when it cannot say.
  Future<Set<String>> availableLanguageTags();
}
```

`PluginSpeechSynthesizer` holds one `FlutterTts`, sets the language before each `speak`
(`setLanguage`, then `speak`), awaits nothing beyond the plugin's own future, and
catches `Object` around every plugin call to log it. It is the only file that imports
`package:flutter_tts`; the guard rule `tts_plugin_has_one_door` and its test in
`code-verification-guard-v2/tests/test_memox_v8_architecture_guard_rules.py` hold that.
Tests use `FakeSpeechSynthesizer` (`test/support/`), which records calls.

## 8. Testing

- **Unit:** `studyOptionsOf` with and without `tts_language`, with a wrong type and an
  unknown tag (D6); `studyConfigOf` round-trip; `appSettingsOf` on both columns;
  `speechCueOf` for every branch of BR-STUDY-078 (mode, kind, busy, held, same card,
  ending); `readsTermAloud` per mode; schema 14 → 15 in `schema_test.dart`; the parity
  test on the CHECK list; the guard rule test.
- **Controllers:** `SettingsController` toggles and chooses; `StudyOptionsController`
  draft, `isChanged` and save with the language.
- **Widgets:** the session screen reads on a new card in Browse and Self-assess, not in
  Fill, not in a review, not with the switch off, and stops on leave (fake synthesizer);
  the speaker button speaks on tap; screen 23's two rows; screen 15's row in both
  states; the sheet marks a missing language.
- **Goldens:** screens 15 (`override`, `defaults`), 16, 16a, 18, 19, 23 change; a
  golden-compare page goes to the owner before merge.
- The gate (`dod_check.sh`) and `run_goldens.sh` in the container.

## 9. Documentation

- Handoff files 15, 16, 16a, 18, 19 and 23: the new row or button, with this spec's
  rules; their rows in `00-index.md`.
- `docs/README.md`, the out-of-MVP table: a note on the "Audio / hình ảnh trong card"
  row that reading the term by TTS is in (this spec), stored audio is not.
- `DESIGN.md`: unchanged (no new component or token; `AppIcons.speak` is an icon
  entry).
- `.claude/skills/flutter-architecture` or the architecture docs that list `lib/core/`
  folders: `speech/` added where the list is.
- Linear: epic "Phát âm thẻ bằng TTS khi học" in milestone `Sau V8.0`; the plan's tasks
  as its sub-issues.

## 10. Rollback

Remove the dependency, `lib/core/speech/`, the cue, the button and the two settings
rows. The two columns and the JSON key may stay: a column with a default and an ignored
key harm nothing.
