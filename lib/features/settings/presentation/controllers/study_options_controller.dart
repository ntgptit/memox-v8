import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/providers/save_root_study_options_use_case_provider.dart';
import 'package:memox/features/settings/presentation/providers/study_options_provider.dart';
import 'package:memox/features/settings/presentation/providers/use_app_defaults_use_case_provider.dart';
import 'package:memox/features/settings/presentation/states/study_options_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_options_controller.g.dart';

/// Screen 15 (UC-SETTINGS-001 A1, E4): a draft of the options of [deckId]'s
/// root, saved in one write by Save. A second Save while one runs is
/// ignored (A4); a failure keeps the draft for Retry save.
@riverpod
class StudyOptionsController extends _$StudyOptionsController {
  @override
  StudyOptionsState build(String deckId) {
    // Kept alive while the screen is: the draft is read against them.
    ref
      ..listen(studyOptionsProvider(deckId), (_, _) {})
      ..listen(appSettingsProvider, (_, _) {});
    return const StudyOptionsState();
  }

  EffectiveStudyOptions? get _stored =>
      switch (ref.read(studyOptionsProvider(deckId)).value) {
        Ok(:final value) => value,
        _ => null,
      };

  StudyOptionsForm? get _form {
    final stored = _stored;
    final appDefaults = ref.read(appSettingsProvider).value?.studyDefaults;
    if (stored == null || appDefaults == null) return null;
    return StudyOptionsForm.of(stored, state, appDefaults: appDefaults);
  }

  void useAppDefaults({required bool isOn}) {
    if (state.isSaving) return;
    state = state.edited(isUsingAppDefaults: isOn);
  }

  /// −/+ or a hold, within 1–200; an invalid typed value steps from the
  /// shown one.
  void stepCardLimit(int delta) {
    final form = _form;
    if (form == null || state.isSaving || form.isUsingAppDefaults) return;
    final next = (form.options.cardLimit + delta).clamp(
      StudyOptions.minCardLimit,
      StudyOptions.maxCardLimit,
    );
    state = state.edited(cardLimit: next, isCardLimitInvalid: false);
  }

  /// A typed limit: kept and shown in either case, and marked invalid
  /// outside 1–200 (E1).
  void typeCardLimit(String text) {
    if (state.isSaving) return;
    final value = int.tryParse(text);
    final isValid = StudyOptions.isValidCardLimit(value);
    state = state.edited(cardLimit: value, isCardLimitInvalid: !isValid);
  }

  void chooseNewCardOrder(NewCardOrder order) {
    if (state.isSaving) return;
    state = state.edited(newCardOrder: order);
  }

  /// The root's speech language (BR-SETTINGS-009), saved with the rest.
  void chooseSpeechLanguage(SpeechLanguage language) {
    if (state.isSaving) return;
    state = state.edited(speechLanguage: language);
  }

  /// Save, or Retry save: Use app defaults clears the root's override;
  /// otherwise the root takes the options shown (spec §5.5).
  Future<void> save() async {
    final stored = _stored;
    final form = _form;
    if (stored == null || form == null || state.isSaving) return;
    if (!form.canSave) return;
    state = state.withSave(StudyOptionsSave.saving);
    final Outcome<void, SettingsRejection> outcome;
    try {
      outcome = form.isUsingAppDefaults
          ? await ref.read(useAppDefaultsUseCaseProvider)(
              rootDeckId: stored.rootDeckId,
            )
          : await ref.read(saveRootStudyOptionsUseCaseProvider)(
              rootDeckId: stored.rootDeckId,
              options: form.options,
            );
    } on Failure {
      if (ref.mounted) state = state.withSave(StudyOptionsSave.failed);
      return;
    }
    if (!ref.mounted) return;
    state = switch (outcome) {
      Ok() => StudyOptionsState(timesSaved: state.timesSaved + 1),
      // The deck went meanwhile: the stream shows it gone.
      Rejected(reason: SettingsRejection.deckNotFound) => state.withSave(
        StudyOptionsSave.idle,
      ),
      Rejected() => state.withSave(StudyOptionsSave.failed),
    };
  }
}
