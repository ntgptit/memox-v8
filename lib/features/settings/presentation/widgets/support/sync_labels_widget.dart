import 'package:intl/intl.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// An absolute time (sync status spec R6), by the local calendar day of
/// [now].
String syncTimeLabel(AppLocalizations l10n, DateTime at, DateTime now) {
  final local = at.toLocal();
  // 24-hour HH:mm in every language, as screen 24 shows times (FE-B5 D9).
  final time = DateFormat('HH:mm', l10n.localeName).format(local);
  final day = DateTime(local.year, local.month, local.day);
  if (day == DateTime(now.year, now.month, now.day)) {
    return l10n.syncTimeToday(time);
  }
  if (day == DateTime(now.year, now.month, now.day - 1)) {
    return l10n.syncTimeYesterday(time);
  }
  return l10n.syncTimeOnDay(
    DateFormat.MMMd(l10n.localeName).format(local),
    time,
  );
}

/// Screen 23's Sync row subtitle (spec §5.1): the first rule that applies.
String syncStatusLine(AppLocalizations l10n, SyncStatus status, DateTime now) {
  if (status.rejectedCount > 0) {
    return l10n.syncStatusRejected(status.rejectedCount);
  }
  if (status.lastFailure case final failure?) {
    return switch (failure.kind) {
      SyncFailureKind.network => l10n.syncStatusFailedNetwork,
      SyncFailureKind.signIn => l10n.syncStatusFailedSignIn,
      SyncFailureKind.server => l10n.syncStatusFailedServer,
      SyncFailureKind.unknown => l10n.syncStatusFailedUnknown,
    };
  }
  if (status.lastSuccessAt case final success?) {
    return l10n.syncStatusSynced(syncTimeLabel(l10n, success, now));
  }
  return l10n.syncStatusNever;
}

/// Screen 27's failure banner (spec §5.4): local-first, no code or message.
String syncFailureSentence(AppLocalizations l10n, SyncFailureKind kind) =>
    switch (kind) {
      SyncFailureKind.network => l10n.syncFailedNetwork,
      SyncFailureKind.signIn => l10n.syncFailedSignIn,
      SyncFailureKind.server => l10n.syncFailedServer,
      SyncFailureKind.unknown => l10n.syncFailedUnknown,
    };
