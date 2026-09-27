import 'package:flutter/foundation.dart';

/// The submits of screen 23; each is a write of its own (BR-SETTINGS-007).
enum SettingsSubmit { cardLimit, newCardOrder, theme, language, reset }

/// What screen 23 says once a submit ends. Each is a new object, so a
/// listener sees two of the same kind in a row (spec §5.2).
sealed class SettingsNotice {
  SettingsNotice(this.kind);

  final SettingsSubmit kind;
}

/// The write landed.
final class SettingsSaved extends SettingsNotice {
  SettingsSaved(super.kind);
}

/// The write failed; the persisted value stands and Retry resubmits (E2).
final class SettingsSaveFailed extends SettingsNotice {
  SettingsSaveFailed(super.kind);
}

/// Screen 23's own state. The persisted values live in the `app_settings`
/// stream; this holds only the card limit being changed, the submits in
/// flight and the last notice (BR-SETTINGS-001).
@immutable
final class SettingsState {
  const SettingsState({
    this.cardLimitDraft,
    this.isCardLimitInvalid = false,
    this.inFlight = const {},
    this.notice,
  });

  /// The card limit shown instead of the persisted one while it is changed;
  /// null once the store holds it.
  final int? cardLimitDraft;

  /// A typed limit outside 1–200: shown in the error ring, never written
  /// (E1).
  final bool isCardLimitInvalid;
  final Set<SettingsSubmit> inFlight;
  final SettingsNotice? notice;

  bool isBusy(SettingsSubmit kind) => inFlight.contains(kind);

  /// Card limit and new-card order write the same pair (BR-SETTINGS-002):
  /// one at a time, so neither overwrites the other.
  bool get isStudyDefaultsBusy =>
      isBusy(SettingsSubmit.cardLimit) || isBusy(SettingsSubmit.newCardOrder);

  SettingsState withDraft(int? draft, {bool isInvalid = false}) =>
      SettingsState(
        cardLimitDraft: draft,
        isCardLimitInvalid: isInvalid,
        inFlight: inFlight,
        notice: notice,
      );

  SettingsState withBusy(SettingsSubmit kind, {required bool isBusy}) =>
      SettingsState(
        cardLimitDraft: cardLimitDraft,
        isCardLimitInvalid: isCardLimitInvalid,
        inFlight: isBusy ? {...inFlight, kind} : ({...inFlight}..remove(kind)),
        notice: notice,
      );

  SettingsState withNotice(SettingsNotice notice) => SettingsState(
    cardLimitDraft: cardLimitDraft,
    isCardLimitInvalid: isCardLimitInvalid,
    inFlight: inFlight,
    notice: notice,
  );
}
