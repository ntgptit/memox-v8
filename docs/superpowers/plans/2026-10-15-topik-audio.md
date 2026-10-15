# TOPIK audio player and the shared MxSlider Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Play a listening group's clip `[startMs, endMs)` of its section file with play, pause, seek, replay and four speeds, never failing the attempt when the file does not play (BR-TOPIK-017), and add the shared seek bar `MxSlider` the player needs (spec §13.8; Phase 2 plan 5 of §13.9, epic DEV-394).

**Architecture:** As the reminders feature reaches its plugins: a domain contract `TopikAudioRepository`, a data source interface `TopikAudioPlayerDataSource` with one door `PluginTopikAudioPlayerDataSource` (the only file that imports `just_audio`, guard `topik_audio_plugin_has_one_door`), and `TopikAudioRepositoryImpl` holding the rules (same clip keeps playing, replay from the start, clamped seek, the four speeds, a failure becomes a state and a log line). `MxSlider` is Material 3's `Slider` under a new `sliderTheme` in `lib/core/theme`, built through the `material3-shared-widgets` BUILD workflow.

**Tech Stack:** Flutter 3.47.5, `just_audio ^0.10.6` (owner approval 2026-10-15), Riverpod 3 codegen, `flutter_test`, golden harness.

**Spec:** `docs/superpowers/specs/2026-10-15-topik-practice-design.md` §5.5, §13.8. Rules: `BR-TOPIK-004`, `BR-TOPIK-017`. M3: `docs/shared/design/m3-adoption-ledger.md` DSD-23, spec `m3-shared-widget-spec-v2.6.1.md` §3 Slider rows.

## Global Constraints

- Only `lib/features/topik/data/datasources/plugin_topik_audio_player_data_source.dart` imports `package:just_audio/`; `rxdart` is not a direct dependency, so the door combines streams by hand.
- `AudioPlayer.play()` completes only when playback stops: the door never awaits it (`unawaited`).
- No autoplay: `load` never plays (BR-TOPIK-017).
- Speeds are exactly `0.75, 1.0, 1.25, 1.5`; anything else is an `ArgumentError`.
- A playback failure is a `failed` state and one `topik.audio_failed` warning naming the asset path only; the attempt is never touched (BR-TOPIK-017).
- `MxSlider` takes no colours or sizes: the `sliderTheme` slot is the one source; inactive track `surfaceContainerHighest`, active track and handle `primary` (owner 2026-10-15); the `year2023` flag is not set (the SDK default), and the colours are pinned explicitly so either appearance draws the approved roles (DSD-23).
- Goldens run only through `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh` in this Linux container; a changed golden gets the `golden-compare` page for the owner before the merge.
- Commits name DEV-394 (the Linear issue cap is reached; progress is recorded on the epic) and end with the session's attribution lines.

## Review Focus

1. **Moving between two questions of one group** while it plays: `load` of the same clip changes nothing, the audio keeps playing (Task 3).
2. **The file fails to load or to play**: state `failed`, a warning, no exception to the caller; `load` again (Retry) recovers (Task 3).
3. **Seek past the end or before the start**: clamped to `[0, length]` (Task 3).
4. **Play after the clip completed**: replays from the start (Task 3).
5. **A slider with `max` 0** (a clip not loaded yet): disabled, never an assertion (Task 1).

---

### Task 1: The shared MxSlider

**Files:**
- Modify: `lib/core/theme/app_component_themes.dart` (`sliderTheme`)
- Modify: `lib/core/theme/app_theme.dart` (`sliderTheme: sliderTheme(tokens)`)
- Create: `lib/shared/widgets/mx_slider.dart`
- Modify: `lib/app/gallery/gallery_inputs_section.dart` (one slider), `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (`gallerySeekBar`)
- Modify: `test/shared/widgets/input_widgets_golden_test.dart` (`mx_slider` goldens)
- Modify: `docs/shared/design/m3-adoption-ledger.md` (DSD-23 choice, SliderTheme row, MxSlider row)
- Test: `test/shared/widgets/mx_slider_test.dart`

**Interfaces:**
- Produces: `SliderThemeData sliderTheme(ThemeTokens t)`; `class MxSlider extends StatelessWidget { const MxSlider({required double value, required double max, required ValueChanged<double>? onChanged, ValueChanged<double>? onChangeEnd, required String semanticLabel, SemanticFormatterCallback? semanticFormatter}) }`.

- [ ] **Step 1: Write the failing test**

`test/shared/widgets/mx_slider_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';
import 'package:memox/shared/widgets/mx_slider.dart';

import '../../support/widget_harness.dart';

// Spec §13.8, DSD-23: Material 3's Slider under the theme's sliderTheme,
// inactive track surfaceContainerHighest (owner 2026-10-15).
void main() {
  final scheme = lightColorScheme;
  const dimens = AppDimens();
  Finder slider() => find.byType(Slider);

  testWidgets('is a Material slider read from the theme', (tester) async {
    await pumpMx(
      tester,
      MxSlider(
        value: 3000,
        max: 10000,
        onChanged: (_) {},
        semanticLabel: 'Audio position',
      ),
    );
    final widget = tester.widget<Slider>(slider());
    expect(widget.value, 3000);
    expect(widget.max, 10000);
    expect(widget.activeColor, isNull);
    expect(widget.inactiveColor, isNull);
    expect(widget.thumbColor, isNull);
    final theme = SliderTheme.of(tester.element(slider()));
    expect(theme.activeTrackColor, scheme.primary);
    expect(theme.inactiveTrackColor, scheme.surfaceContainerHighest);
    expect(theme.thumbColor, scheme.primary);
  });

  testWidgets('drags report the new value and its end', (tester) async {
    double? changed;
    double? ended;
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxSlider(
          value: 0,
          max: 10000,
          onChanged: (value) => changed = value,
          onChangeEnd: (value) => ended = value,
          semanticLabel: 'Audio position',
        ),
      ),
    );
    await tester.drag(slider(), const Offset(150, 0));
    await tester.pumpAndSettle();
    expect(changed, greaterThan(0));
    expect(ended, changed);
  });

  testWidgets('a value past max is drawn at max', (tester) async {
    await pumpMx(
      tester,
      MxSlider(
        value: 12000,
        max: 10000,
        onChanged: (_) {},
        semanticLabel: 'Audio position',
      ),
    );
    expect(tester.widget<Slider>(slider()).value, 10000);
  });

  testWidgets('max 0 is a disabled slider, never an assertion', (tester) async {
    await pumpMx(
      tester,
      MxSlider(
        value: 0,
        max: 0,
        onChanged: (_) {},
        semanticLabel: 'Audio position',
      ),
    );
    final widget = tester.widget<Slider>(slider());
    expect(widget.onChanged, isNull);
    final theme = SliderTheme.of(tester.element(slider()));
    expect(
      theme.disabledActiveTrackColor,
      scheme.onSurface.withValues(alpha: dimens.opacityDisabledContent),
    );
  });

  testWidgets('announced with its label and value', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      MxSlider(
        value: 5000,
        max: 10000,
        onChanged: (_) {},
        semanticLabel: 'Audio position',
        semanticFormatter: (value) => '${(value / 1000).round()}s',
      ),
    );
    expect(
      tester.getSemantics(find.byType(MxSlider)),
      matchesSemantics(
        label: 'Audio position',
        value: '5s',
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
        increasedValue: anything,
        decreasedValue: anything,
        isSlider: true,
      ),
    );
    handle.dispose();
  });
}
```

(If `matchesSemantics` rejects `increasedValue: anything` on this SDK, assert `label`, `value`, `isSlider` and the two actions through `tester.getSemantics(...).getSemanticsData()` instead; record the change as a ruling. `find.bySemanticsLabel('Audio position')` must find exactly one node.)

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_slider_test.dart`
Expected: FAIL — `mx_slider.dart` does not exist.

- [ ] **Step 3: Implement the theme slot**

In `lib/core/theme/app_component_themes.dart`, after `switchTheme`:

```dart
/// The seek bar's colours (spec §13.8, DSD-23): Material 3's year2023
/// roles pinned explicitly, so the appearance flag never changes a colour.
/// Inactive track `surfaceContainerHighest` (owner 2026-10-15).
SliderThemeData sliderTheme(ThemeTokens t) {
  final scheme = t.scheme;
  final dimens = t.dimens;
  return SliderThemeData(
    activeTrackColor: scheme.primary,
    inactiveTrackColor: scheme.surfaceContainerHighest,
    thumbColor: scheme.primary,
    disabledActiveTrackColor: t.onSurfaceAt(dimens.opacityDisabledContent),
    disabledInactiveTrackColor: t.onSurfaceAt(dimens.opacityDisabledContainer),
    disabledThumbColor: Color.alphaBlend(
      t.onSurfaceAt(dimens.opacityDisabledContent),
      scheme.surface,
    ),
    overlayColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.dragged) ||
          states.contains(WidgetState.focused)) {
        return scheme.primary.withValues(alpha: dimens.opacityPressed);
      }
      if (states.contains(WidgetState.hovered)) {
        return scheme.primary.withValues(alpha: dimens.opacityHover);
      }
      return Colors.transparent;
    }),
  );
}
```

In `app_theme.dart` `_build`, after `switchTheme: switchTheme(tokens),` add `sliderTheme: sliderTheme(tokens),`.

(Check `t.onSurfaceAt` returns `scheme.onSurface.withValues(alpha: …)`, `app_component_themes.dart:44`; the test compares against that form.)

- [ ] **Step 4: Implement the widget**

`lib/shared/widgets/mx_slider.dart`:

```dart
import 'package:flutter/material.dart';

/// A seek bar (the TOPIK audio player, spec §13.8): Material 3's `Slider`,
/// styled by the theme's `sliderTheme`. [value] and [max] share one unit
/// (milliseconds for audio); a value past [max] is drawn at [max]. A [max]
/// of 0 (nothing loaded yet) is a disabled slider.
class MxSlider extends StatelessWidget {
  const MxSlider({
    super.key,
    required this.value,
    required this.max,
    required this.onChanged,
    this.onChangeEnd,
    required this.semanticLabel,
    this.semanticFormatter,
  });

  final double value;
  final double max;

  /// Null disables the slider.
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final String semanticLabel;

  /// How TalkBack reads the value, for example as a time.
  final SemanticFormatterCallback? semanticFormatter;

  @override
  Widget build(BuildContext context) {
    final hasRange = max > 0;
    // One node for TalkBack: the label merged with the slider's value and
    // actions, as MxToggle does.
    return MergeSemantics(
      child: Semantics(
        label: semanticLabel,
        child: Slider(
          value: hasRange ? value.clamp(0, max).toDouble() : 0,
          max: hasRange ? max : 1,
          onChanged: hasRange ? onChanged : null,
          onChangeEnd: hasRange ? onChangeEnd : null,
          semanticFormatterCallback: semanticFormatter,
        ),
      ),
    );
  }
}
```

Add one slider to the gallery's inputs section, after the toggle row:

```dart
      MxSlider(
        value: _seekPosition,
        max: _seekLength,
        onChanged: (value) => setState(() => _seekPosition = value),
        semanticLabel: context.l10n.gallerySeekBar,
      ),
```

with `static const double _seekLength = 100;` and `var _seekPosition = 40.0;` in `_GalleryInputsSectionState` (it is a `StatefulWidget`). Add the ARB key in both locales, `description` last (guard `memox.i18n.arb_entry_needs_description`):

- `app_en.arb`: `"gallerySeekBar": "Seek bar"`, `"@gallerySeekBar": {"description": "Debug gallery: sample copy in the component showcase."}`
- `app_vi.arb`: `"gallerySeekBar": "Thanh tua"`, same description.

Then `flutter gen-l10n`.

- [ ] **Step 5: Goldens**

In `test/shared/widgets/input_widgets_golden_test.dart`, add:

```dart
  testWidgets('MxSlider: at a value, at the start, disabled', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_slider',
      SizedBox(
        width: 320,
        child: Column(
          spacing: 8,
          children: [
            MxSlider(
              value: 40,
              max: 100,
              onChanged: (_) {},
              semanticLabel: 'Audio position',
            ),
            MxSlider(
              value: 0,
              max: 100,
              onChanged: (_) {},
              semanticLabel: 'Audio position',
            ),
            const MxSlider(
              value: 40,
              max: 100,
              onChanged: null,
              semanticLabel: 'Audio position',
            ),
          ],
        ),
      ),
    );
  });
```

Run `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update test/shared/widgets/input_widgets_golden_test.dart`, look at both new PNGs, then run it again without `--update` (PASS). Only `mx_slider_light.png` and `mx_slider_dark.png` may be new; any other changed golden is a finding to explain before going on.

- [ ] **Step 6: Ledger and lint**

In `docs/shared/design/m3-adoption-ledger.md`:
- DSD-23: replace "`lib/` uses no Slider … so no `year2023` value needs choosing now" with "`MxSlider` (`mx_slider.dart`) keeps the SDK default appearance (`year2023` not set) and pins every colour in `sliderTheme` (`ACT`), so the inactive track is `surfaceContainerHighest` in either appearance (owner 2026-10-15)".
- In the theme inventory, move Slider out of the "absent" row and add `| SliderTheme | ACT sliderTheme | selection | continuous | rest, hover, focus, dragged, disabled | ACT | MxSlider | §3 Slider rows, DSD-23 | PASS | | T:mx_slider_test.dart; G:mx_slider_light.png, mx_slider_dark.png | none |`.
- In the component inventory, add an `MxSlider` row: `mx_slider.dart`, Selection, continuous, rest/hover/focus/dragged/disabled, `sliderTheme`, consumers "none yet (TOPIK audio player, plan 6)", PASS with the tests above.
- Remove "Slider" from the "`lib/` has no … Slider …" sentence of the inventory header.

Run `dart run tools/m3_lint/m3_lint.dart` (exit 0) and `python3 tools/docs/check.py` (PASS).

- [ ] **Step 7: Run and commit**

```bash
bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets test/core/theme test/app/gallery_test.dart
git add lib/core/theme lib/shared/widgets/mx_slider.dart lib/app/gallery lib/l10n/app_en.arb lib/l10n/app_vi.arb test/shared/widgets docs/shared/design/m3-adoption-ledger.md
git commit -m "feat(ui): DEV-394 the shared MxSlider and its sliderTheme"
```

---

### Task 2: The audio contract and its state

**Files:**
- Create: `lib/features/topik/domain/models/topik_audio_model.dart`
- Create: `lib/features/topik/domain/repositories/topik_audio_repository.dart`
- Test: `test/features/topik/domain/topik_audio_model_test.dart`

**Interfaces:**
- Produces:
  - `const List<double> topikAudioSpeeds = [0.75, 1.0, 1.25, 1.5];`
  - `enum TopikAudioStatus { idle, loading, ready, playing, completed, failed }`
  - `final class TopikAudioClip { const TopikAudioClip({required String asset, required int startMs, required int endMs}); int get lengthMs; bool operator ==; int get hashCode; }`
  - `final class TopikAudioState { status, clip, positionMs, speed; static const TopikAudioState initial; TopikAudioState copyWith({...}); bool get isPlaying; }`
  - `abstract interface class TopikAudioRepository { Stream<TopikAudioState> watchState(); TopikAudioState get state; Future<void> load(TopikAudioClip clip); Future<void> play(); Future<void> pause(); Future<void> seek(int positionMs); Future<void> setSpeed(double speed); Future<void> stop(); Future<void> dispose(); }`

- [ ] **Step 1: Write the failing test**

`test/features/topik/domain/topik_audio_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';

// BR-TOPIK-017, spec §5.5.
void main() {
  test('the four practice speeds', () {
    expect(topikAudioSpeeds, [0.75, 1.0, 1.25, 1.5]);
  });

  test('a clip is a range of a section file; equal clips are the same group', () {
    const a = TopikAudioClip(asset: 'x.mp3', startMs: 1000, endMs: 4000);
    const b = TopikAudioClip(asset: 'x.mp3', startMs: 1000, endMs: 4000);
    expect(a.lengthMs, 3000);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(
      a == const TopikAudioClip(asset: 'x.mp3', startMs: 4000, endMs: 7000),
      isFalse,
    );
  });

  test('the initial state is idle at normal speed', () {
    expect(TopikAudioState.initial.status, TopikAudioStatus.idle);
    expect(TopikAudioState.initial.speed, 1.0);
    expect(TopikAudioState.initial.isPlaying, isFalse);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/domain/topik_audio_model_test.dart`
Expected: FAIL — the model file does not exist.

- [ ] **Step 3: Implement**

`lib/features/topik/domain/models/topik_audio_model.dart`:

```dart
/// The speeds Practice mode offers (BR-TOPIK-017).
const List<double> topikAudioSpeeds = [0.75, 1.0, 1.25, 1.5];

/// Where the player is (BR-TOPIK-017). [failed] shows an error with Retry
/// inside the player; the attempt is untouched.
enum TopikAudioStatus { idle, loading, ready, playing, completed, failed }

/// A listening group's range `[startMs, endMs)` of its section file
/// (BR-TOPIK-004). Two equal clips are the same group.
final class TopikAudioClip {
  const TopikAudioClip({
    required this.asset,
    required this.startMs,
    required this.endMs,
  });

  final String asset;
  final int startMs;
  final int endMs;

  int get lengthMs => endMs - startMs;

  @override
  bool operator ==(Object other) =>
      other is TopikAudioClip &&
      other.asset == asset &&
      other.startMs == startMs &&
      other.endMs == endMs;

  @override
  int get hashCode => Object.hash(asset, startMs, endMs);
}

/// What the player shows: its status, the clip, the position inside the
/// clip in milliseconds, and the speed.
final class TopikAudioState {
  const TopikAudioState({
    required this.status,
    required this.clip,
    required this.positionMs,
    required this.speed,
  });

  static const TopikAudioState initial = TopikAudioState(
    status: TopikAudioStatus.idle,
    clip: null,
    positionMs: 0,
    speed: 1.0,
  );

  final TopikAudioStatus status;
  final TopikAudioClip? clip;
  final int positionMs;
  final double speed;

  bool get isPlaying => status == TopikAudioStatus.playing;

  TopikAudioState copyWith({
    TopikAudioStatus? status,
    TopikAudioClip? clip,
    int? positionMs,
    double? speed,
  }) => TopikAudioState(
    status: status ?? this.status,
    clip: clip ?? this.clip,
    positionMs: positionMs ?? this.positionMs,
    speed: speed ?? this.speed,
  );
}
```

`lib/features/topik/domain/repositories/topik_audio_repository.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';

/// The listening player (BR-TOPIK-017, spec §5.5). The one implementation
/// is `TopikAudioRepositoryImpl` over the `just_audio` door; tests use a
/// fake. Nothing here throws for a file that does not play: that is the
/// [TopikAudioStatus.failed] state.
abstract interface class TopikAudioRepository {
  /// The current state, then every change.
  Stream<TopikAudioState> watchState();

  TopikAudioState get state;

  /// Readies [clip] without playing it (no autoplay). The clip already
  /// loaded and not failed is left as it is, playing or not: moving between
  /// the questions of one group keeps the audio.
  Future<void> load(TopikAudioClip clip);

  /// Plays; after the clip completed, replays it from its start.
  Future<void> play();

  Future<void> pause();

  /// Moves inside the clip; clamped to `[0, lengthMs]`.
  Future<void> seek(int positionMs);

  /// One of [topikAudioSpeeds]; anything else is an `ArgumentError`.
  Future<void> setSpeed(double speed);

  /// Stops and returns to the start of the clip.
  Future<void> stop();

  Future<void> dispose();
}
```

- [ ] **Step 4: Run and commit**

```bash
bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/domain
git add lib/features/topik/domain test/features/topik/domain/topik_audio_model_test.dart
git commit -m "feat(topik): DEV-394 the audio contract and its state"
```

---

### Task 3: The player rules over a data source

**Files:**
- Create: `lib/features/topik/data/datasources/topik_audio_player_data_source.dart`
- Create: `lib/features/topik/data/repositories/topik_audio_repository_impl.dart`
- Create: `test/support/fake_topik_audio_player.dart`
- Test: `test/features/topik/data/topik_audio_repository_impl_test.dart`

**Interfaces:**
- Produces:
  - `enum TopikPlayerPhase { idle, loading, ready, completed }`
  - `typedef TopikPlayerSnapshot = ({bool playing, TopikPlayerPhase phase, int positionMs});`
  - `abstract interface class TopikAudioPlayerDataSource { Stream<TopikPlayerSnapshot> get snapshots; Future<void> setClip({required String asset, required int startMs, required int endMs}); Future<void> play(); Future<void> pause(); Future<void> seek(int positionMs); Future<void> setSpeed(double speed); Future<void> stop(); Future<void> dispose(); }` — every method may throw on a platform failure.
  - `final class TopikAudioRepositoryImpl implements TopikAudioRepository { TopikAudioRepositoryImpl(TopikAudioPlayerDataSource source); }`

- [ ] **Step 1: Write the fake and the failing test**

`test/support/fake_topik_audio_player.dart`:

```dart
import 'dart:async';

import 'package:memox/features/topik/data/datasources/topik_audio_player_data_source.dart';

/// The plugin with its calls recorded and its reports pushed by the test.
final class FakeTopikAudioPlayer implements TopikAudioPlayerDataSource {
  final calls = <String>[];
  final _snapshots = StreamController<TopikPlayerSnapshot>.broadcast();
  bool failSetClip = false;
  bool failPlay = false;

  void report({
    bool playing = false,
    TopikPlayerPhase phase = TopikPlayerPhase.ready,
    int positionMs = 0,
  }) => _snapshots.add((playing: playing, phase: phase, positionMs: positionMs));

  @override
  Stream<TopikPlayerSnapshot> get snapshots => _snapshots.stream;

  @override
  Future<void> setClip({
    required String asset,
    required int startMs,
    required int endMs,
  }) async {
    calls.add('setClip:$asset:$startMs-$endMs');
    if (failSetClip) throw StateError('no such asset');
  }

  @override
  Future<void> play() async {
    calls.add('play');
    if (failPlay) throw StateError('decoder');
  }

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> seek(int positionMs) async => calls.add('seek:$positionMs');

  @override
  Future<void> setSpeed(double speed) async => calls.add('speed:$speed');

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Future<void> dispose() async {
    calls.add('dispose');
    await _snapshots.close();
  }
}
```

`test/features/topik/data/topik_audio_repository_impl_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/data/datasources/topik_audio_player_data_source.dart';
import 'package:memox/features/topik/data/repositories/topik_audio_repository_impl.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';

import '../../../support/fake_topik_audio_player.dart';

const _clip = TopikAudioClip(asset: 'l.mp3', startMs: 10000, endMs: 40000);
const _next = TopikAudioClip(asset: 'l.mp3', startMs: 40000, endMs: 70000);

// BR-TOPIK-017, spec §5.5.
void main() {
  late FakeTopikAudioPlayer player;
  late TopikAudioRepositoryImpl audio;
  setUp(() {
    player = FakeTopikAudioPlayer();
    audio = TopikAudioRepositoryImpl(player);
  });

  test('load readies the clip without playing it (no autoplay)', () async {
    await audio.load(_clip);
    expect(player.calls, ['setClip:l.mp3:10000-40000']);
    expect(audio.state.status, TopikAudioStatus.ready);
    expect(audio.state.clip, _clip);
  });

  test('the same clip again changes nothing, playing or not', () async {
    await audio.load(_clip);
    await audio.play();
    player.report(playing: true, positionMs: 3000);
    await pumpEventQueue();
    await audio.load(_clip);
    expect(player.calls, ['setClip:l.mp3:10000-40000', 'play']);
    expect(audio.state.isPlaying, isTrue);
  });

  test('another group stops the previous one and loads its own', () async {
    await audio.load(_clip);
    await audio.play();
    await audio.load(_next);
    expect(player.calls.skip(2), ['stop', 'setClip:l.mp3:40000-70000']);
    expect(audio.state.clip, _next);
    expect(audio.state.status, TopikAudioStatus.ready);
  });

  test('reports map to the state; the position is clamped to the clip', () async {
    await audio.load(_clip);
    player.report(playing: true, positionMs: 5000);
    await pumpEventQueue();
    expect(audio.state.status, TopikAudioStatus.playing);
    expect(audio.state.positionMs, 5000);
    player.report(phase: TopikPlayerPhase.completed, positionMs: 30500);
    await pumpEventQueue();
    expect(audio.state.status, TopikAudioStatus.completed);
    expect(audio.state.positionMs, 30000);
  });

  test('play after completing replays from the start', () async {
    await audio.load(_clip);
    player.report(phase: TopikPlayerPhase.completed, positionMs: 30000);
    await pumpEventQueue();
    await audio.play();
    expect(player.calls.skip(1), ['seek:0', 'play']);
  });

  test('seek is clamped to the clip', () async {
    await audio.load(_clip);
    await audio.seek(-5);
    await audio.seek(99999);
    expect(player.calls.skip(1), ['seek:0', 'seek:30000']);
  });

  test('only the four speeds', () async {
    await audio.load(_clip);
    await audio.setSpeed(1.25);
    expect(audio.state.speed, 1.25);
    expect(() => audio.setSpeed(2.0), throwsArgumentError);
  });

  test('a file that does not load is failed, and Retry recovers', () async {
    player.failSetClip = true;
    await audio.load(_clip);
    expect(audio.state.status, TopikAudioStatus.failed);
    player.failSetClip = false;
    await audio.load(_clip);
    expect(audio.state.status, TopikAudioStatus.ready);
  });

  test('a failure to play is a state, never an exception', () async {
    await audio.load(_clip);
    player.failPlay = true;
    await audio.play();
    expect(audio.state.status, TopikAudioStatus.failed);
  });

  test('stop returns to the start; dispose releases the plugin', () async {
    await audio.load(_clip);
    await audio.stop();
    expect(audio.state.positionMs, 0);
    expect(audio.state.status, TopikAudioStatus.ready);
    await audio.dispose();
    expect(player.calls.last, 'dispose');
  });

  test('watchState starts with the current state', () async {
    await audio.load(_clip);
    expect((await audio.watchState().first).clip, _clip);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/data/topik_audio_repository_impl_test.dart`
Expected: FAIL — the files do not exist.

- [ ] **Step 3: Implement**

`lib/features/topik/data/datasources/topik_audio_player_data_source.dart`:

```dart
/// The audio plugin's processing phase, as plain values.
enum TopikPlayerPhase { idle, loading, ready, completed }

/// What the plugin reports: whether it plays, its phase, and the position in
/// the loaded clip in milliseconds.
typedef TopikPlayerSnapshot = ({
  bool playing,
  TopikPlayerPhase phase,
  int positionMs,
});

/// The audio plugin (spec §13.8). The one implementation is
/// `PluginTopikAudioPlayerDataSource`, the only file that imports
/// `just_audio` (guard `topik_audio_plugin_has_one_door`); every method may
/// throw on a platform failure, which the repository turns into a state.
abstract interface class TopikAudioPlayerDataSource {
  Stream<TopikPlayerSnapshot> get snapshots;

  /// Loads `[startMs, endMs)` of the bundled [asset].
  Future<void> setClip({
    required String asset,
    required int startMs,
    required int endMs,
  });

  /// Starts playing and returns at once.
  Future<void> play();

  Future<void> pause();

  Future<void> seek(int positionMs);

  Future<void> setSpeed(double speed);

  Future<void> stop();

  Future<void> dispose();
}
```

`lib/features/topik/data/repositories/topik_audio_repository_impl.dart`:

```dart
import 'dart:async';

import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/features/topik/data/datasources/topik_audio_player_data_source.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_audio_repository.dart';

/// The listening player's rules over the plugin (BR-TOPIK-017): no
/// autoplay, the same group keeps playing, replay from the start, a clamped
/// seek, four speeds, and a failure kept as a state with one warning.
final class TopikAudioRepositoryImpl implements TopikAudioRepository {
  TopikAudioRepositoryImpl(this._source) {
    _reports = _source.snapshots.listen(_onSnapshot);
  }

  final TopikAudioPlayerDataSource _source;
  late final StreamSubscription<TopikPlayerSnapshot> _reports;
  final _states = StreamController<TopikAudioState>.broadcast();
  TopikAudioState _state = TopikAudioState.initial;

  @override
  TopikAudioState get state => _state;

  @override
  Stream<TopikAudioState> watchState() async* {
    yield _state;
    yield* _states.stream;
  }

  @override
  Future<void> load(TopikAudioClip clip) async {
    if (_state.clip == clip && _state.status != TopikAudioStatus.failed) {
      return;
    }
    if (_state.clip != null) await _guard(_source.stop);
    _emit(
      _state.copyWith(
        status: TopikAudioStatus.loading,
        clip: clip,
        positionMs: 0,
      ),
    );
    final loaded = await _guard(
      () => _source.setClip(
        asset: clip.asset,
        startMs: clip.startMs,
        endMs: clip.endMs,
      ),
    );
    if (!loaded) return;
    await _guard(() => _source.setSpeed(_state.speed));
    _emit(_state.copyWith(status: TopikAudioStatus.ready));
  }

  @override
  Future<void> play() async {
    if (!_isLoaded) return;
    if (_state.status == TopikAudioStatus.completed) {
      if (!await _guard(() => _source.seek(0))) return;
    }
    await _guard(_source.play);
  }

  @override
  Future<void> pause() async {
    if (_isLoaded) await _guard(_source.pause);
  }

  @override
  Future<void> seek(int positionMs) async {
    final clip = _state.clip;
    if (clip == null || !_isLoaded) return;
    await _guard(() => _source.seek(positionMs.clamp(0, clip.lengthMs)));
  }

  @override
  Future<void> setSpeed(double speed) async {
    if (!topikAudioSpeeds.contains(speed)) {
      throw ArgumentError.value(speed, 'speed', 'is not a practice speed');
    }
    _emit(_state.copyWith(speed: speed));
    if (_isLoaded) await _guard(() => _source.setSpeed(speed));
  }

  @override
  Future<void> stop() async {
    if (!_isLoaded) return;
    if (await _guard(_source.stop)) {
      _emit(_state.copyWith(status: TopikAudioStatus.ready, positionMs: 0));
    }
  }

  @override
  Future<void> dispose() async {
    await _reports.cancel();
    await _states.close();
    await _source.dispose();
  }

  bool get _isLoaded => switch (_state.status) {
    TopikAudioStatus.ready ||
    TopikAudioStatus.playing ||
    TopikAudioStatus.completed => true,
    _ => false,
  };

  void _onSnapshot(TopikPlayerSnapshot snapshot) {
    final clip = _state.clip;
    if (clip == null || !_isLoaded) return;
    final status = switch (snapshot.phase) {
      TopikPlayerPhase.completed => TopikAudioStatus.completed,
      _ when snapshot.playing => TopikAudioStatus.playing,
      _ => TopikAudioStatus.ready,
    };
    _emit(
      _state.copyWith(
        status: status,
        positionMs: snapshot.positionMs.clamp(0, clip.lengthMs),
      ),
    );
  }

  /// Runs a plugin call; a failure becomes the failed state and one
  /// warning naming the asset (BR-TOPIK-017). Whether it succeeded.
  Future<bool> _guard(Future<void> Function() call) async {
    try {
      await call();
      return true;
    } catch (error) {
      appLogger.warning(
        'topik.audio_failed',
        category: LogCategory.state,
        context: {
          'asset': _state.clip?.asset,
          'error': error.runtimeType.toString(),
        },
      );
      _emit(_state.copyWith(status: TopikAudioStatus.failed));
      return false;
    }
  }

  void _emit(TopikAudioState next) {
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }
}
```

(Check the `appLogger.warning` signature against `lib/core/logging/app_logger.dart` and the one call in `topik_content_repository_impl.dart`; match it. Use the log category the content repository uses.)

- [ ] **Step 4: Run and commit**

```bash
bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik
git add lib/features/topik/data test/support/fake_topik_audio_player.dart test/features/topik/data/topik_audio_repository_impl_test.dart
git commit -m "feat(topik): DEV-394 the listening player's rules"
```

---

### Task 4: The just_audio door, its guard and the provider

**Files:**
- Modify: `pubspec.yaml`, `pubspec.lock` (`just_audio: ^0.10.6`)
- Create: `lib/features/topik/data/datasources/plugin_topik_audio_player_data_source.dart`
- Create: `lib/features/topik/di/topik_audio_repository_provider.dart`
- Modify: `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-architecture-rules.yaml` (`topik_audio_plugin_has_one_door`)
- Modify: `code-verification-guard-v2/tests/test_memox_v8_architecture_guard_rules.py`
- Test: `test/features/topik/data/plugin_topik_audio_player_data_source_test.dart`, `test/features/topik/di/topik_audio_repository_provider_test.dart`

**Interfaces:**
- Consumes: `TopikAudioPlayerDataSource`, `TopikAudioRepositoryImpl` (Task 3).
- Produces: `PluginTopikAudioPlayerDataSource({AudioPlayer? player})`; `topikAudioRepositoryProvider` (`@riverpod`, auto-dispose, disposes the player).

- [ ] **Step 1: Add the dependency**

```bash
flutter pub add just_audio:^0.10.6
flutter pub get
```

Expected: `pubspec.yaml` lists `just_audio: ^0.10.6` in alphabetical place among `dependencies`; `pubspec.lock` changes.

- [ ] **Step 2: Write the failing tests**

`test/features/topik/data/plugin_topik_audio_player_data_source_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:memox/features/topik/data/datasources/plugin_topik_audio_player_data_source.dart';

/// The plugin with its calls recorded instead of sent. With the session
/// flags off the constructor reaches no platform channel (just_audio 0.10.6,
/// `just_audio.dart:239-380`).
class _FakePlayer extends AudioPlayer {
  _FakePlayer()
    : super(
        handleInterruptions: false,
        handleAudioSessionActivation: false,
        androidApplyAudioAttributes: false,
      );

  final calls = <String>[];
  AudioSource? source;

  @override
  Future<Duration?> setAudioSource(
    AudioSource source, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    this.source = source;
    calls.add('setAudioSource');
    return null;
  }

  @override
  Future<void> play() async => calls.add('play');

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> seek(Duration? position, {int? index}) async =>
      calls.add('seek:${position?.inMilliseconds}');

  @override
  Future<void> setSpeed(double speed) async => calls.add('speed:$speed');

  @override
  Future<void> stop() async => calls.add('stop');
}

// Spec §13.8: the one door to just_audio plays the clip natively.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a clip is a ClippingAudioSource over the bundled asset', () async {
    final player = _FakePlayer();
    final door = PluginTopikAudioPlayerDataSource(player: player);

    await door.setClip(asset: 'assets/topik/l.mp3', startMs: 1000, endMs: 4000);

    final source = player.source! as ClippingAudioSource;
    expect(source.start, const Duration(milliseconds: 1000));
    expect(source.end, const Duration(milliseconds: 4000));
    expect(source.child.uri.toString(), contains('assets/topik/l.mp3'));
  });

  test('controls go to the plugin; play does not wait for the end', () async {
    final player = _FakePlayer();
    final door = PluginTopikAudioPlayerDataSource(player: player);

    await door.play();
    await door.pause();
    await door.seek(2500);
    await door.setSpeed(0.75);
    await door.stop();

    expect(player.calls, ['play', 'pause', 'seek:2500', 'speed:0.75', 'stop']);
  });
}
```

(If the fake still reaches a platform channel when the test runs, keep the door's unit test to what runs without one, mark the rest `UNVERIFIED (device)` in the PR, and record it as a ruling.)

`test/features/topik/di/topik_audio_repository_provider_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/data/repositories/topik_audio_repository_impl.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';

import '../../../support/fake_topik_audio_player.dart';

void main() {
  test('builds the player over the door and releases it on dispose', () async {
    final player = FakeTopikAudioPlayer();
    final container = ProviderContainer(
      overrides: [topikAudioPlayerDataSourceProvider.overrideWithValue(player)],
    );
    final audio = container.read(topikAudioRepositoryProvider);
    expect(audio, isA<TopikAudioRepositoryImpl>());

    container.dispose();
    await pumpEventQueue();

    expect(player.calls.last, 'dispose');
  });
}
```

- [ ] **Step 3: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/data/plugin_topik_audio_player_data_source_test.dart test/features/topik/di/topik_audio_repository_provider_test.dart`
Expected: FAIL — the door and provider do not exist.

- [ ] **Step 4: Implement the door**

`lib/features/topik/data/datasources/plugin_topik_audio_player_data_source.dart`:

```dart
import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:memox/features/topik/data/datasources/topik_audio_player_data_source.dart';

/// The one door to `just_audio` (spec §13.8, guard
/// `topik_audio_plugin_has_one_door`): a group's range plays natively
/// through `ClippingAudioSource`. `AudioPlayer.play` completes only when
/// playback stops, so [play] does not wait for it.
final class PluginTopikAudioPlayerDataSource
    implements TopikAudioPlayerDataSource {
  PluginTopikAudioPlayerDataSource({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<TopikPlayerSnapshot> get snapshots {
    StreamSubscription<PlayerState>? states;
    StreamSubscription<Duration>? positions;
    late final StreamController<TopikPlayerSnapshot> controller;
    void report() => controller.add((
      playing: _player.playing,
      phase: _phaseOf(_player.processingState),
      positionMs: _player.position.inMilliseconds,
    ));
    controller = StreamController<TopikPlayerSnapshot>(
      onListen: () {
        states = _player.playerStateStream.listen((_) => report());
        positions = _player.positionStream.listen((_) => report());
      },
      onCancel: () async {
        await states?.cancel();
        await positions?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> setClip({
    required String asset,
    required int startMs,
    required int endMs,
  }) async {
    await _player.setAudioSource(
      ClippingAudioSource(
        child: AudioSource.asset(asset),
        start: Duration(milliseconds: startMs),
        end: Duration(milliseconds: endMs),
      ),
    );
  }

  @override
  Future<void> play() async => unawaited(_player.play());

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(int positionMs) =>
      _player.seek(Duration(milliseconds: positionMs));

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();

  static TopikPlayerPhase _phaseOf(ProcessingState state) => switch (state) {
    ProcessingState.idle => TopikPlayerPhase.idle,
    ProcessingState.loading ||
    ProcessingState.buffering => TopikPlayerPhase.loading,
    ProcessingState.ready => TopikPlayerPhase.ready,
    ProcessingState.completed => TopikPlayerPhase.completed,
  };
}
```

`ClippingAudioSource` is not deprecated in 0.10.6 (`just_audio.dart:3219`); `ConcatenatingAudioSource` is, and is not used.

- [ ] **Step 5: The provider and the guard**

`lib/features/topik/di/topik_audio_repository_provider.dart`:

```dart
import 'package:memox/features/topik/data/datasources/plugin_topik_audio_player_data_source.dart';
import 'package:memox/features/topik/data/datasources/topik_audio_player_data_source.dart';
import 'package:memox/features/topik/data/repositories/topik_audio_repository_impl.dart';
import 'package:memox/features/topik/domain/repositories/topik_audio_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_audio_repository_provider.g.dart';

/// The plugin door; tests override it with a fake.
@riverpod
TopikAudioPlayerDataSource topikAudioPlayerDataSource(Ref ref) =>
    PluginTopikAudioPlayerDataSource();

/// One player per attempt screen; released with it.
@riverpod
TopikAudioRepository topikAudioRepository(Ref ref) {
  final audio = TopikAudioRepositoryImpl(
    ref.watch(topikAudioPlayerDataSourceProvider),
  );
  ref.onDispose(audio.dispose);
  return audio;
}
```

Guard rule, after `tts_plugin_has_one_door` in `memox-architecture-rules.yaml`:

```yaml
  # TOPIK spec §13.8: the audio plugin is reached through one door, so a
  # failing file is a state in one place and tests fake one interface.
  - id: memox_v8.architecture.topik_audio_plugin_has_one_door
    type: regex
    severity: error
    enabled: true
    message: >-
      Import `just_audio` only in
      `lib/features/topik/data/datasources/plugin_topik_audio_player_data_source.dart`;
      go through `TopikAudioRepository` instead.
    scopes:
      - dart_lib
    exclude:
      - lib/features/topik/data/datasources/plugin_topik_audio_player_data_source.dart
    patterns:
      - "^\\s*import\\s+'package:just_audio/"
    tags:
      - memox-v8
      - architecture
```

Guard test, after `test_tts_plugin_is_imported_by_its_door_only`:

```python
AUDIO_PLUGIN = "memox_v8.architecture.topik_audio_plugin_has_one_door"
AUDIO_DOOR = "lib/features/topik/data/datasources/plugin_topik_audio_player_data_source.dart"


def test_audio_plugin_is_imported_by_its_door_only(tmp_path: Path) -> None:
    line = "import 'package:just_audio/just_audio.dart';\n"
    assert _violations_at(
        AUDIO_PLUGIN, tmp_path / "leak",
        {"lib/features/topik/presentation/screens/topik_attempt_screen.dart": line},
    )
    assert not _violations_at(AUDIO_PLUGIN, tmp_path / "door", {AUDIO_DOOR: line})
```

Run `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 6: Run and commit**

```bash
bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik test/architecture
python3 -m pytest -q code-verification-guard-v2/tests/test_memox_v8_architecture_guard_rules.py
git add pubspec.yaml pubspec.lock lib/features/topik test/features/topik code-verification-guard-v2
git commit -m "feat(topik): DEV-394 the just_audio door, its guard and provider"
```

---

### Task 5: Docs and the gates

- [ ] **Step 1:** In `docs/features/topik/README.md` nothing changes (the code paths are already listed). In spec §13.8, add after the dependency bullet: "Built: `TopikAudioRepository` (domain), `TopikAudioPlayerDataSource` with its door `PluginTopikAudioPlayerDataSource` (data), `topikAudioRepositoryProvider` (di); `MxSlider` with `sliderTheme`." Run `python3 tools/docs/check.py`.
- [ ] **Step 2:** Run `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` (PASS) and `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh` (PASS, only the two new `mx_slider` goldens added).
- [ ] **Step 3:** Build the golden review page with the `golden-compare` skill for `mx_slider_light.png` and `mx_slider_dark.png` (new images: "before" is empty) and publish it for the owner before the merge.
- [ ] **Step 4:** Commit `docs(topik): DEV-394 audio and MxSlider as built`.

## Plan-time rulings

| # | Ruling | Why |
|---|---|---|
| A1 | The reminders pattern: domain contract, data source interface, one plugin door, repository impl with the rules. | The rules (same group keeps playing, replay, clamp, speeds, failure as state) are testable only above the plugin; the door stays thin. |
| A2 | `load` of the clip already loaded is a no-op unless it failed. | BR-TOPIK-017: moving between the questions of a group keeps the audio; Retry after a failure loads again. |
| A3 | `MxSlider` keeps the SDK's default appearance and pins every colour in `sliderTheme`. | The `year2023` flag is deprecated (DSD-23); pinned colours make the approved roles independent of it. |
| A4 | Hover and focus use the slider's own state layer (SDK), not an extra ring. | Material 3's slider shows focus with its handle overlay; the toggle draws a ring only because `Switch` has none. Owner question Q-P5-1. |

## Out of this plan

The player widget and the attempt screen that use these (plan 6); Exam mode's play count (Phase B).
