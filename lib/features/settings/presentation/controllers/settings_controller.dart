import 'dart:async';

import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/providers/reset_app_settings_use_case_provider.dart';
import 'package:memox/features/settings/presentation/providers/save_study_defaults_use_case_provider.dart';
import 'package:memox/features/settings/presentation/providers/set_language_use_case_provider.dart';
import 'package:memox/features/settings/presentation/providers/set_theme_use_case_provider.dart';
import 'package:memox/features/settings/presentation/states/settings_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_controller.g.dart';

/// How long the card limit stays still before it is saved (spec §5.2): a
/// hold or a run of taps is one write.
const Duration cardLimitSettle = Duration(milliseconds: 600);

/// Screen 23's submits (UC-SETTINGS-001): each settled change is one write
/// (D1, D6), a second submit of a kind in flight is ignored (A4), and a
/// failure keeps the persisted value with a Retry (E2). Widgets only draw
/// its state and the `app_settings` stream.
@riverpod
class SettingsController extends _$SettingsController {
  Timer? _settle;

  /// The limit changed again while its write ran: write it once that ends.
  var _isCardLimitQueued = false;

  /// What Retry resubmits, per kind.
  final _retries = <SettingsSubmit, Future<void> Function()>{};

  /// The study defaults last written, until the stream brings them back: a
  /// write right after another builds on it, not on the older row.
  StudyOptions? _written;

  @override
  SettingsState build() {
    ref.onDispose(() => _settle?.cancel());
    ref.listen(appSettingsProvider, (_, next) {
      _written = null;
      _dropSavedDraft(next.value);
    });
    return const SettingsState();
  }

  AppSettingsEntity? get _persisted => ref.read(appSettingsProvider).value;

  StudyOptions? get _studyDefaults => _written ?? _persisted?.studyDefaults;

  /// −/+ or a hold: the draft moves by [delta] within 1–200, and is saved
  /// [cardLimitSettle] after the last step.
  void stepCardLimit(int delta) {
    final persisted = _persisted;
    if (persisted == null) return;
    final from = state.isCardLimitInvalid
        ? persisted.studyDefaults.cardLimit
        : state.cardLimitDraft ?? persisted.studyDefaults.cardLimit;
    final next = (from + delta).clamp(
      StudyOptions.minCardLimit,
      StudyOptions.maxCardLimit,
    );
    state = state.withDraft(next);
    _settle?.cancel();
    _settle = Timer(cardLimitSettle, () => unawaited(_saveCardLimit()));
  }

  /// A typed limit: saved at once when it is within 1–200; otherwise shown
  /// as invalid and not written (E1).
  void typeCardLimit(String text) {
    _settle?.cancel();
    final value = int.tryParse(text);
    final isValid =
        value != null &&
        value >= StudyOptions.minCardLimit &&
        value <= StudyOptions.maxCardLimit;
    state = state.withDraft(value, isInvalid: !isValid);
    if (isValid) unawaited(_saveCardLimit());
  }

  void chooseNewCardOrder(NewCardOrder order) {
    final persisted = _studyDefaults;
    if (persisted == null || order == persisted.newCardOrder) return;
    if (state.isStudyDefaultsBusy) return;
    final options = StudyOptions(
      cardLimit: persisted.cardLimit,
      newCardOrder: order,
    );
    unawaited(
      _submit(
        SettingsSubmit.newCardOrder,
        () => ref.read(saveStudyDefaultsUseCaseProvider)(options: options),
        retry: () async => chooseNewCardOrder(order),
      ).then((hasSaved) => _afterStudyDefaults(options, hasSaved: hasSaved)),
    );
  }

  void chooseTheme(ThemeChoice theme) {
    if (theme == _persisted?.theme) return;
    unawaited(
      _submit(
        SettingsSubmit.theme,
        () => ref.read(setThemeUseCaseProvider)(theme: theme),
        retry: () async => chooseTheme(theme),
      ),
    );
  }

  void chooseLanguage(LanguageChoice language) {
    if (language == _persisted?.language) return;
    unawaited(
      _submit(
        SettingsSubmit.language,
        () => ref.read(setLanguageUseCaseProvider)(language: language),
        retry: () async => chooseLanguage(language),
      ),
    );
  }

  /// A3: every app option back to its default in one write; completes true
  /// once it landed, so the dialog can close.
  Future<bool> reset() async {
    _settle?.cancel();
    final hasReset = await _submit(
      SettingsSubmit.reset,
      () => ref.read(resetAppSettingsUseCaseProvider)(),
      retry: () async => unawaited(reset()),
    );
    if (hasReset && ref.mounted) {
      _written = null;
      state = state.withDraft(null);
    }
    return hasReset;
  }

  /// Retry after [SettingsSaveFailed] of [kind].
  Future<void> retry(SettingsSubmit kind) async {
    final again = _retries.remove(kind);
    if (again != null) await again();
  }

  Future<void> _saveCardLimit() async {
    final draft = state.cardLimitDraft;
    final persisted = _studyDefaults;
    if (draft == null || persisted == null || state.isCardLimitInvalid) {
      return;
    }
    if (state.isStudyDefaultsBusy) {
      _isCardLimitQueued = true;
      return;
    }
    final options = StudyOptions(
      cardLimit: draft,
      newCardOrder: persisted.newCardOrder,
    );
    final hasSaved = await _submit(
      SettingsSubmit.cardLimit,
      () => ref.read(saveStudyDefaultsUseCaseProvider)(options: options),
      retry: () async {
        state = state.withDraft(draft);
        await _saveCardLimit();
      },
    );
    if (!ref.mounted) return;
    if (!hasSaved) {
      // The control shows the persisted value again (E2).
      state = state.withDraft(null);
      return;
    }
    _dropSavedDraft(_persisted);
    await _afterStudyDefaults(options, hasSaved: true);
  }

  /// After a study defaults write: remember what it wrote, then write the
  /// limit that changed meanwhile.
  Future<void> _afterStudyDefaults(
    StudyOptions options, {
    required bool hasSaved,
  }) async {
    if (!ref.mounted) return;
    if (hasSaved) _written = options;
    await _saveQueuedCardLimit();
  }

  /// The limit changed while its group wrote: write it now.
  Future<void> _saveQueuedCardLimit() async {
    if (!_isCardLimitQueued || !ref.mounted) return;
    _isCardLimitQueued = false;
    await _saveCardLimit();
  }

  /// One submit of [kind]; ignored while one of the same group runs (A4).
  /// Completes true once it wrote.
  Future<bool> _submit(
    SettingsSubmit kind,
    Future<Outcome<void, SettingsRejection>> Function() write, {
    required Future<void> Function() retry,
  }) async {
    if (state.isBusy(kind)) return false;
    state = state.withBusy(kind, isBusy: true);
    var hasWritten = false;
    try {
      hasWritten = await write() is Ok;
    } on Failure {
      hasWritten = false;
    }
    if (!ref.mounted) return hasWritten;
    state = state.withBusy(kind, isBusy: false);
    if (hasWritten) {
      _retries.remove(kind);
      state = state.withNotice(SettingsSaved(kind));
    } else {
      _retries[kind] = retry;
      state = state.withNotice(SettingsSaveFailed(kind));
    }
    return hasWritten;
  }

  /// The draft goes once the store holds it and no write of it runs.
  void _dropSavedDraft(AppSettingsEntity? persisted) {
    final draft = state.cardLimitDraft;
    if (draft == null || persisted == null) return;
    if (state.isBusy(SettingsSubmit.cardLimit) || state.isCardLimitInvalid) {
      return;
    }
    if (persisted.studyDefaults.cardLimit == draft) {
      state = state.withDraft(null);
    }
  }
}
