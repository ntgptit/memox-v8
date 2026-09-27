/// Keys of the `sync_state` table (app deck-sync spec §3).
library;

/// While this key exists, the sync triggers do not queue writes: the write
/// is data from the server, not a local change.
const syncApplyingRemoteKey = 'applying_remote';

/// This installation's id, sent with every push.
const syncDeviceIdKey = 'device_id';

/// The `serverVersion` cursor of the last applied pull page.
const syncSinceKey = 'since';
