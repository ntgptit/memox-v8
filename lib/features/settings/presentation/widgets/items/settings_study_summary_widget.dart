import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The hub's Study defaults row in one line (settings hub spec D8):
/// "20 cards · In order · Read aloud on".
String studyDefaultsSummary(
  AppLocalizations l10n,
  StudyOptions options, {
  required bool isAutoPlay,
}) => l10n.settingsStudyDefaultsSummary(
  options.cardLimit,
  switch (options.newCardOrder) {
    NewCardOrder.created => l10n.settingsOrderCreated,
    NewCardOrder.random => l10n.settingsOrderRandom,
  },
  isAutoPlay.toString(),
);
