/// How many ids one statement binds. SQLite binds at most 32 766 variables
/// (`SQLITE_MAX_VARIABLE_NUMBER`); the rest of a statement's variables fit
/// in what is left (BE-C2).
const int sqliteIdChunk = 30000;

/// [ids] in chunks of at most [size], in their order. A DAO runs its
/// statement once per chunk, in the caller's transaction, and combines the
/// results as the statement means them. An empty set is no chunk.
List<List<T>> idChunks<T>(Iterable<T> ids, {int size = sqliteIdChunk}) {
  final all = ids.toList();
  return [
    for (var start = 0; start < all.length; start += size)
      all.sublist(start, start + size > all.length ? all.length : start + size),
  ];
}
