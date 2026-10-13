import 'package:flutter/foundation.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';

/// Where screen 15's Save stands (spec §5.5).
enum StudyOptionsSave { idle, saving, failed }

/// Screen 15's draft: only what the person changed, over the options in
/// force; a null field shows the stored value (BR-SETTINGS-001).
@immutable
final class StudyOptionsState {
  const StudyOptionsState({
    this.isUsingAppDefaults,
    this.cardLimit,
    this.isCardLimitInvalid = false,
    this.newCardOrder,
    this.speechLanguage,
    this.save = StudyOptionsSave.idle,
    this.timesSaved = 0,
  });

  final bool? isUsingAppDefaults;
  final int? cardLimit;

  /// A typed limit outside 1–200: shown in the error ring, never saved (E1).
  final bool isCardLimitInvalid;
  final NewCardOrder? newCardOrder;

  /// The root's speech language the person picked (BR-SETTINGS-009).
  final SpeechLanguage? speechLanguage;
  final StudyOptionsSave save;

  /// Grows with each save that landed, so the screen says "Saved" once per
  /// save.
  final int timesSaved;

  bool get isSaving => save == StudyOptionsSave.saving;

  /// The draft after an edit. A failed save stays in view until a save
  /// lands: the banner states the deck's stored values, still true while
  /// the person edits (critique 2026-09-30 part 3d-2, E13).
  StudyOptionsState edited({
    bool? isUsingAppDefaults,
    int? cardLimit,
    bool? isCardLimitInvalid,
    NewCardOrder? newCardOrder,
    SpeechLanguage? speechLanguage,
  }) => StudyOptionsState(
    isUsingAppDefaults: isUsingAppDefaults ?? this.isUsingAppDefaults,
    cardLimit: cardLimit ?? this.cardLimit,
    isCardLimitInvalid: isCardLimitInvalid ?? this.isCardLimitInvalid,
    newCardOrder: newCardOrder ?? this.newCardOrder,
    speechLanguage: speechLanguage ?? this.speechLanguage,
    save: save == StudyOptionsSave.failed
        ? StudyOptionsSave.failed
        : StudyOptionsSave.idle,
    timesSaved: timesSaved,
  );

  StudyOptionsState withSave(StudyOptionsSave save) => StudyOptionsState(
    isUsingAppDefaults: isUsingAppDefaults,
    cardLimit: cardLimit,
    isCardLimitInvalid: isCardLimitInvalid,
    newCardOrder: newCardOrder,
    speechLanguage: speechLanguage,
    save: save,
    timesSaved: timesSaved,
  );
}

/// What screen 15 shows: the draft over the options in force.
@immutable
final class StudyOptionsForm {
  const StudyOptionsForm._({
    required this.isUsingAppDefaults,
    required this.options,
    required this.isCardLimitInvalid,
    required this.isChanged,
  });

  /// [appDefaults] are Settings' values, shown while the deck follows
  /// them: [stored] holds the override until Save clears it.
  factory StudyOptionsForm.of(
    EffectiveStudyOptions stored,
    StudyOptionsState draft, {
    required StudyOptions appDefaults,
  }) {
    final wasUsingAppDefaults = stored.source == StudyOptionsSource.appDefaults;
    final isUsingAppDefaults = draft.isUsingAppDefaults ?? wasUsingAppDefaults;
    // App defaults are shown as they are; own options start from the ones
    // in force (A1).
    final options = isUsingAppDefaults
        ? appDefaults
        : StudyOptions(
            cardLimit: draft.cardLimit ?? stored.options.cardLimit,
            newCardOrder: draft.newCardOrder ?? stored.options.newCardOrder,
            speechLanguage:
                draft.speechLanguage ?? stored.options.speechLanguage,
          );
    final isChanged =
        isUsingAppDefaults != wasUsingAppDefaults ||
        // An override that cannot be read is replaced by any save.
        stored.source == StudyOptionsSource.unreadableRootOverride ||
        (!isUsingAppDefaults &&
            (options.cardLimit != stored.options.cardLimit ||
                options.newCardOrder != stored.options.newCardOrder ||
                options.speechLanguage != stored.options.speechLanguage));
    return StudyOptionsForm._(
      isUsingAppDefaults: isUsingAppDefaults,
      options: options,
      isCardLimitInvalid: !isUsingAppDefaults && draft.isCardLimitInvalid,
      isChanged: isChanged,
    );
  }

  final bool isUsingAppDefaults;
  final StudyOptions options;
  final bool isCardLimitInvalid;
  final bool isChanged;

  /// D9: Save only for a valid change.
  bool get canSave => isChanged && !isCardLimitInvalid;
}
