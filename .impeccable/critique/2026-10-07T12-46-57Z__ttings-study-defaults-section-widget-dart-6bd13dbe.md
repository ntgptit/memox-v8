---
target: study speech UI (settings 23, study options 15, study session modes)
total_score: 25
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 2
target_identity: "file:/home/user/memox-v8/lib/features/settings/presentation/widgets/sections/settings_study_defaults_section_widget.dart"
target_fingerprint: "sha256:5d272ae6d4d5824c6cd6491fa7818f33cb96d14ff8f44fc16f10741fd8019a48"
target_path: /home/user/memox-v8/lib/features/settings/presentation/widgets/sections/settings_study_defaults_section_widget.dart
timestamp: 2026-10-07T12-46-57Z
slug: ttings-study-defaults-section-widget-dart-6bd13dbe
---
# Critique: study speech (Settings 23, Study options 15, Study session 16/16a/18/19)

Method: dual-agent (A: design review · B: detector + native audit). Range e6f670b..0c36032. Detector: not applicable to Dart (0 findings, verified with an HTML probe); repo design-token guard: 0 findings on 40 changed lib files.

## Design Health Score

| # | Heuristic | Score | Key issue |
|---|-----------|-------|-----------|
| 1 | Visibility of system status | 2 | The session never shows which language a term is read in; a missing voice reads nothing with no sign. |
| 2 | Match system / real world | 3 | Vietnamese copy uses three verbs for one feature (Đọc to / Tự động đọc / phát âm). |
| 3 | User control and freedom | 3 | Off switch is two screens away; no per-session mute. |
| 4 | Consistency and standards | 2 | Speech language row: value in trailing text, no chevron (MxSettingsRow drops it when trailing != null); editable and read-only states identical on screen 15. |
| 5 | Error prevention | 2 | Default en-US + auto-play ON reads Korean/Vietnamese terms in an English voice; a missing language stays selectable and then reads nothing. |
| 6 | Recognition rather than recall | 3 | Sheet marks the current language; the language in force is not visible in the session. |
| 7 | Flexibility and efficiency | 3 | Default + per-root override is sound; no quick mute. |
| 8 | Aesthetic and minimalist design | 3 | Value set at label size; subtitle wraps to 2–3 lines beside it at 360dp. |
| 9 | Error recovery | 2 | Silent failure by design (BR-STUDY-081); "Couldn't save read-aloud." is awkward. |
| 10 | Help and documentation | 2 | "Not installed on this device" states no consequence; the Study defaults note ("Applies to sessions started from now on") is false for the two live speech rows (BR-STUDY-080). |
| **Total** | | **25/40** | **Needs work** |

## Design specificity
Authored for the product: reuses MxSettingsRow, MxToggle, MxBottomSheet, MxOptionRow, MxIconButton, AppIcons, AppSpacing; no new component or token; dark theme through tokens. Falls short in the language row (reads as a label) and the unverified sheet (no golden).

## Priority issues
1. [P1] Speech language row has no tap affordance; on screen 15 editable == read-only pixel for pixel (settings_study_defaults_section_widget.dart:116-132, study_options_form_widget.dart:208-226, MxSettingsRow.isNavigable). Fix: value in subtitle + chevron (Theme/Language pattern) or a chevron composed into trailing when editable; Flexible on the trailing text.
2. [P1] Silent wrong voice / no voice: default en-US + auto-play ON, language never shown in session, missing voice logs only. Fix: speaker label names the language (studySpeakTermIn); dimmed button + tooltip when the voice is missing; owner ruling on auto-play default and on a toast for an explicit silent tap.
3. [P2] Language sheet unverified (no golden), layout shifts when availability arrives, selected row not scrolled into view, "Not installed" compares tags exactly (es-ES vs es-US). Fix: goldens (available / partly missing / vi), availability through isLanguageAvailable, copy states the consequence.
4. [P2] Same glyph AppIcons.speak on two adjacent rows next to the app "Language" row; speak appended inside the nav-destination block of app_icons.dart. Fix: AppIcons.language (or translate) for the language row.
5. [P2] speak()/stop() not serialized: a stop between stop→setLanguage→speak can be overtaken (plugin_speech_synthesizer.dart:20-38); window widens on cold start. Fix: generation counter.
6. [P3] Copy: "deck" vs "bộ thẻ" in vi hint; verbs; "Couldn't save read-aloud."; the two "from now on" notes; sheet title not announced as header (systemic to MxBottomSheet); MediaQuery read inside listener callbacks (cache in didChangeDependencies).

## Persona red flags
- Self-learner: unexpected voice in public, off switch in Settings; uninstalled voice cannot be fixed offline and nothing says so.
- Exam crammer: auto-play on every card slows pace; Recall countdown keeps running while the term plays; no quick mute.
- TalkBack: D13 correct (no auto-play, button works); label does not name the language; language row has no "opens sheet" hint.

## Minor observations
- Speaker costs ~56dp of a card half; halves scroll at 360x640 where they did not before.
- study_self_assess_prompt is a review: button shown, auto-play silent by design.
- Study options footer "Saved to this device only." is misleading: the language travels with the deck through sync (D7).

## Questions
1. Should auto-play default to ON when the default language is wrong for half the decks?
2. Does the language belong to the root deck or to the card side?
3. If a missing voice makes a language useless, why is it selectable?
