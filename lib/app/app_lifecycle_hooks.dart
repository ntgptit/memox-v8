import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/reminders/presentation/providers/reconcile_reminder_provider.dart';
import 'package:memox/features/study/presentation/providers/abandon_stale_sessions_use_case_provider.dart';
import 'package:memox/features/trash/presentation/providers/purge_expired_trash_use_case_provider.dart';

/// The features' side effects of the app's lifecycle, in one place
/// (DEV-176): the start, every resume, and the router's Reset app options
/// call these, so each rule runs through one path. Every hook swallows its
/// [Failure]: a refusal changes nothing the person sees, and the next start
/// or resume tries again.
final class AppLifecycleHooks {
  const AppLifecycleHooks(this._container);

  final ProviderContainer _container;

  /// At start. Unawaited: no frame waits for any of them.
  void onStart() {
    // A session left open on an earlier day closes as interrupted before
    // anything could offer it (BR-STUDY-072); the entry already offers no
    // earlier day's session, so nothing waits for it.
    unawaited(_closeStaleSessions());
    unawaited(purgeExpiredTrash());
    unawaited(reconcileReminder());
  }

  /// On every resume: the Trash's purge (UC-TRASH-001 A4), and the reminder,
  /// since the local offset may have changed while the app slept
  /// (BR-REMINDER-009).
  void onResume() {
    unawaited(purgeExpiredTrash());
    unawaited(reconcileReminder());
  }

  /// UC-REMINDER-001 step 6: the pending alarm follows the stored reminder
  /// again, through the gate.
  Future<void> reconcileReminder() async {
    try {
      await _container.read(reconcileReminderProvider)();
    } on Failure {
      // The stored reminder could not be read; the next start retries.
    }
  }

  /// BR-TRASH-009: what is past 30 days leaves for good. A failed purge
  /// keeps it for the next start, resume or visit to the Trash.
  Future<void> purgeExpiredTrash() async {
    try {
      await _container.read(purgeExpiredTrashUseCaseProvider)();
    } on Failure {
      // Nothing to say: the entries stay in the Trash until the next try.
    }
  }

  Future<void> _closeStaleSessions() async {
    try {
      await _container.read(abandonStaleSessionsUseCaseProvider)();
    } on Failure {
      // A failed sweep leaves the sessions open; the next start retries.
    }
  }
}
