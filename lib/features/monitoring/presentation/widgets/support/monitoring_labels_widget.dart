import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/log_window_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

/// The level's name (monitoring spec §3.2).
String monitoringLevelLabel(AppLocalizations l10n, LogLevel level) =>
    switch (level) {
      LogLevel.debug => l10n.monitoringLevelDebug,
      LogLevel.info => l10n.monitoringLevelInfo,
      LogLevel.warning => l10n.monitoringLevelWarning,
      LogLevel.error => l10n.monitoringLevelError,
    };

/// One glyph per level, so colour is never the only cue.
IconData monitoringLevelIcon(LogLevel level) => switch (level) {
  LogLevel.debug => AppIcons.levelDebug,
  LogLevel.info => AppIcons.info,
  LogLevel.warning => AppIcons.levelWarning,
  LogLevel.error => AppIcons.alert,
};

/// The level's tile: the existing status tints, warning as the caution tint
/// and error as the danger tint.
MxIconTileTone monitoringLevelTone(LogLevel level) => switch (level) {
  LogLevel.debug || LogLevel.info => MxIconTileTone.tinted,
  LogLevel.warning => MxIconTileTone.caution,
  LogLevel.error => MxIconTileTone.danger,
};

String monitoringStatusLabel(AppLocalizations l10n, LogStatus status) =>
    switch (status) {
      LogStatus.open => l10n.monitoringStatusOpen,
      LogStatus.fixed => l10n.monitoringStatusFixed,
    };

/// An open problem is a warning-toned pill, a fixed one the green: the label
/// says it too, so the tone is never the only cue.
MxBadgeTone monitoringStatusTone(LogStatus status) => switch (status) {
  LogStatus.open => MxBadgeTone.warning,
  LogStatus.fixed => MxBadgeTone.mastery,
};

String monitoringWindowLabel(AppLocalizations l10n, LogWindow window) =>
    switch (window) {
      LogWindow.hour => l10n.monitoringWindowHour,
      LogWindow.day => l10n.monitoringWindowDay,
      LogWindow.week => l10n.monitoringWindowWeek,
      LogWindow.month => l10n.monitoringWindowMonth,
      LogWindow.all => l10n.monitoringWindowAll,
    };

/// A filter chip: its name alone, with the choices' names when one or two
/// are made, with how many from three (monitoring spec §3.2; critique
/// 2026-09-30 part 3b: "Level · 2" said no level). A chip whose choices are
/// ids, not names, counts a pair instead ([isPairNamed] false).
String monitoringChipLabel(
  AppLocalizations l10n,
  String label,
  List<String> chosen, {
  bool isPairNamed = true,
}) => switch (chosen.length) {
  0 => label,
  1 => l10n.monitoringChipValue(label, chosen.single),
  2 when isPairNamed => l10n.monitoringChipValue(label, chosen.join(', ')),
  final count => l10n.monitoringChipValue(label, '$count'),
};

/// An id as shown: a break is allowed after each hyphen, so a 36-character
/// UUID that does not fit wraps between its groups instead of mid-group
/// (Impeccable 2026-09-29 F3). Copying uses the id itself.
String monitoringIdText(String id) => id.replaceAll('-', '-\u200B');

/// What a screen reader hears for a chip: every choice by name, where the
/// chip shows only how many (Impeccable 2026-09-29 F8).
String monitoringChipSemantics(
  AppLocalizations l10n,
  String label,
  List<String> chosen,
) =>
    chosen.isEmpty ? label : l10n.monitoringChipValue(label, chosen.join(', '));

/// A row's time (monitoring spec §3.2): 24-hour `HH:mm` for today, else the
/// short month and day, in local time.
String monitoringRowTime(AppLocalizations l10n, DateTime at, DateTime now) {
  final local = at.toLocal();
  final day = DateTime(local.year, local.month, local.day);
  if (day == DateTime(now.year, now.month, now.day)) {
    return DateFormat('HH:mm', l10n.localeName).format(local);
  }
  return DateFormat.MMMd(l10n.localeName).format(local);
}

/// The detail's time: the full date and `HH:mm:ss`, in local time.
String monitoringFullTime(AppLocalizations l10n, DateTime at) =>
    DateFormat.yMMMd(l10n.localeName).add_Hms().format(at.toLocal());
