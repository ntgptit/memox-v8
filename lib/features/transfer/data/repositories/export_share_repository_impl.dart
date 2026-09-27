import 'package:flutter/services.dart' show MissingPluginException;
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/export_artifact_model.dart';
import 'package:memox/features/transfer/domain/repositories/export_share_repository.dart';
import 'package:share_plus/share_plus.dart';

/// `share_plus` writes the bytes to its own folder in the app's cache, which
/// it clears before each share, and hands that file to the system: no shared
/// directory, no storage permission (BR-TRANSFER-014).
final class ExportShareRepositoryImpl implements ExportShareRepository {
  ExportShareRepositoryImpl({
    Future<ShareResult> Function(ShareParams params)? share,
  }) : _share = share ?? SharePlus.instance.share;

  final Future<ShareResult> Function(ShareParams params) _share;

  @override
  Future<Outcome<ExportShareResult, TransferRejection>> share(
    ExportArtifact artifact,
  ) async {
    final ShareResult result;
    try {
      result = await _share(
        ShareParams(
          files: [
            XFile.fromData(artifact.bytes, mimeType: artifact.format.mimeType),
          ],
          fileNameOverrides: [artifact.fileName],
        ),
      );
    } on MissingPluginException {
      return const Rejected(TransferRejection.shareUnavailable);
    } on UnimplementedError {
      return const Rejected(TransferRejection.shareUnavailable);
    } on Object {
      // The platform's message may carry a path: the user sees only the
      // typed reason (UC-TRANSFER-002 E2).
      return const Rejected(TransferRejection.shareFailed);
    }
    return switch (result.status) {
      ShareResultStatus.dismissed => const Ok(ExportShareResult.dismissed),
      // `unavailable`: the system took the file but cannot say what the user
      // did with it. It was handed over, which is all the app may claim.
      ShareResultStatus.success ||
      ShareResultStatus.unavailable => const Ok(ExportShareResult.shared),
    };
  }
}
