/// The three file formats Card Transfer reads and writes (UC-TRANSFER-001,
/// UC-TRANSFER-002).
enum TransferFormat {
  csv('csv', 'text/csv'),
  tsv('tsv', 'text/tab-separated-values'),
  xlsx(
    'xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );

  const TransferFormat(this.extension, this.mimeType);

  /// Without the dot, lower case.
  final String extension;
  final String mimeType;

  /// The format a file name ends with, ignoring case; null for any other
  /// extension (UC-TRANSFER-001 E1).
  static TransferFormat? ofFileName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0) return null;
    final extension = fileName.substring(dot + 1).toLowerCase();
    for (final format in values) {
      if (format.extension == extension) return format;
    }
    return null;
  }
}
