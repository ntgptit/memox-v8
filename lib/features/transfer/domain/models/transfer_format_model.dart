/// The file formats a transfer reads and writes (UC-TRANSFER-001,
/// UC-TRANSFER-002). XLSX comes with package 9b (transfer spec D3).
enum TransferFormat {
  csv(fileExtension: 'csv', mimeType: 'text/csv'),
  tsv(fileExtension: 'tsv', mimeType: 'text/tab-separated-values');

  const TransferFormat({required this.fileExtension, required this.mimeType});

  final String fileExtension;
  final String mimeType;

  /// The format the extension of [fileName] names, in any case; null for
  /// any other extension, or none.
  static TransferFormat? ofFileName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0) return null;
    final extension = fileName.substring(dot + 1).toLowerCase();
    for (final format in values) {
      if (format.fileExtension == extension) return format;
    }
    return null;
  }
}
