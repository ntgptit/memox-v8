/// Keys of the `sync_state` table (app deck-sync spec §3).
library;

/// This installation's id, sent with every push.
const syncDeviceIdKey = 'device_id';

/// The `serverVersion` cursor of the last applied pull page.
const syncSinceKey = 'since';
