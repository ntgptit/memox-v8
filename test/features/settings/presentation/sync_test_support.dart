import 'dart:async';

import 'package:flutter_riverpod/misc.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/core/sync/sync_commands.dart';
import 'package:memox/core/sync/sync_status.dart';

/// Screen 27's commands, counted; [hold] keeps Sync now running.
class FakeSyncCommands implements SyncCommands {
  var syncs = 0;
  var retries = 0;
  var keeps = 0;
  bool result = true;
  Completer<bool>? hold;

  @override
  Future<bool> syncNow() async {
    syncs++;
    return hold?.future ?? result;
  }

  @override
  Future<bool> retryRejected() async {
    retries++;
    return result;
  }

  @override
  Future<void> keepRejectedOnDevice() async => keeps++;
}

/// Sync as a build with Supabase would show it: [status], and [commands].
List<Override> syncOverrides(SyncStatus status, [FakeSyncCommands? commands]) =>
    [
      syncStatusProvider.overrideWith((ref) => Stream.value(status)),
      syncCommandsProvider.overrideWithValue(commands ?? FakeSyncCommands()),
    ];
