import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/features/settings/presentation/states/sync_screen_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_controller.g.dart';

/// Screen 27's commands (sync status spec §5.2): one at a time; each ends
/// in a notice.
@riverpod
class SyncController extends _$SyncController {
  @override
  SyncScreenState build() => const SyncScreenState();

  Future<void> run(SyncTask task) async {
    final commands = ref.read(syncCommandsProvider);
    if (commands == null || state.task != null) return;
    state = SyncScreenState(task: task);
    final SyncNotice notice;
    try {
      notice = switch (task) {
        SyncTask.syncNow => _ranOf(await commands.syncNow()),
        SyncTask.retry => _ranOf(await commands.retryRejected()),
        SyncTask.keep => await _keep(commands.keepRejectedOnDevice),
      };
    } on Object {
      if (!ref.mounted) return;
      state = SyncScreenState(notice: SyncChangeFailed(task));
      return;
    }
    if (!ref.mounted) return;
    state = SyncScreenState(notice: notice);
  }

  static SyncNotice _ranOf(bool succeeded) =>
      succeeded ? SyncSucceeded() : SyncNotSucceeded();

  static Future<SyncNotice> _keep(Future<void> Function() keep) async {
    await keep();
    return SyncKeptOnDevice();
  }
}
