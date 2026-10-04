import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'import_file_picker_provider.g.dart';

/// A file the user picked: its name, shown on the file chip and never
/// logged, and its bytes, read in memory (BR-TRANSFER-006).
typedef ImportPickedFile = ({String name, Uint8List bytes});

/// Opens the system file picker on CSV, TSV and XLSX; null when the user
/// cancels (UC-TRANSFER-001 A5). A provider so tests replace the platform.
@riverpod
Future<ImportPickedFile?> Function() importFilePicker(Ref ref) => () async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: [
      for (final format in TransferFormat.values) format.extension,
    ],
  );
  if (file == null) return null;
  return (name: file.name, bytes: await file.readAsBytes());
};
