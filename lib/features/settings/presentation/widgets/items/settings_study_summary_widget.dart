import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/meta_line.dart';

/// The hub's Study options row in one line (settings hub spec D8):
/// "20 cards · In order · Read aloud on", short terms that break only between
/// them (The Wrap Rule).
String studyDefaultsSummary(
  AppLocalizations l10n,
  StudyOptions options, {
  required bool isAutoPlay,
}) => metaLine(
  l10n.settingsStudyDefaultsSummary(
    options.cardLimit,
    switch (options.newCardOrder) {
      NewCardOrder.created => l10n.settingsOrderCreated,
      NewCardOrder.random => l10n.settingsOrderRandom,
    },
    isAutoPlay ? 'on' : 'off',
  ),
);
