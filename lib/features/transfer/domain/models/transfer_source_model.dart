import 'dart:typed_data';

import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';

/// What the user hands to an import: a file, or text pasted in the app
/// (UC-TRANSFER-001 step 2, A1). The file's name is never kept: only its
/// format (BR-TRANSFER-006).
sealed class TransferSource {
  const TransferSource();
}

final class FileSource extends TransferSource {
  const FileSource({required this.bytes, required this.format});

  final Uint8List bytes;
  final TransferFormat format;
}

final class PastedSource extends TransferSource {
  const PastedSource(this.text);

  final String text;
}
