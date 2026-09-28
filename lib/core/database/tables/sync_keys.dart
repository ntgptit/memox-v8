/// Keys of the `sync_state` table (app deck-sync spec §3).
library;

/// While this key exists, the sync triggers do not queue writes: the write
/// is data from the server, not a local change.
const syncApplyingRemoteKey = 'applying_remote';

/// This installation's id, sent with every push.
const syncDeviceIdKey = 'device_id';

/// The `serverVersion` cursor of the last applied pull page.
const syncSinceKey = 'since';

/// When the last run ended without an error: UTC epoch milliseconds (SB-U1).
const syncLastSuccessAtKey = 'last_success_at';

/// When the last run failed: UTC epoch milliseconds (SB-U1).
const syncLastFailureAtKey = 'last_failure_at';

/// The `SyncFailureKind` name of the last failed run (SB-U1).
const syncLastFailureKindKey = 'last_failure_kind';
