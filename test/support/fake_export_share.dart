import 'dart:async';

import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/export_artifact_model.dart';
import 'package:memox/features/transfer/domain/repositories/export_share_repository.dart';

/// The system share sheet as a test drives it: it keeps every file handed
/// to it and answers [answer] (UC-TRANSFER-002 steps 6–7, A3, E1, E2).
final class FakeExportShare implements ExportShareRepository {
  final List<ExportArtifact> shared = [];
  Outcome<ExportShareResult, TransferRejection> answer = const Ok(
    ExportShareResult.shared,
  );

  @override
  Future<Outcome<ExportShareResult, TransferRejection>> share(
    ExportArtifact artifact,
  ) async {
    shared.add(artifact);
    return answer;
  }
}
