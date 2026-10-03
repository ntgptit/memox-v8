/// The largest source an import reads (SP2a 2.23): the commit is one
/// transaction on the UI isolate and the preview is built in memory, so a
/// source past these is split into files instead.
abstract final class TransferLimits {
  static const int maxMegabytes = 5;
  static const int maxBytes = maxMegabytes * 1024 * 1024;

  /// Rows of the parsed table, a header row included.
  static const int maxRows = 20000;
}
