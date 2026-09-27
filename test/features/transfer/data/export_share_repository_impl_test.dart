import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/data/repositories/export_share_repository_impl.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/export_artifact_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:share_plus/share_plus.dart';

final _artifact = ExportArtifact(
  bytes: Uint8List.fromList([1, 2, 3]),
  fileName: 'Nhà-hàng-2026-09-26.csv',
  format: TransferFormat.csv,
);

Future<Outcome<ExportShareResult, TransferRejection>> _shared(
  Future<ShareResult> Function(ShareParams params) share,
) => ExportShareRepositoryImpl(share: share).share(_artifact);

void main() {
  test('the file goes to the share sheet under its name and type', () async {
    late ShareParams sent;
    await _shared((params) async {
      sent = params;
      return const ShareResult('app', ShareResultStatus.success);
    });

    expect(sent.fileNameOverrides, ['Nhà-hàng-2026-09-26.csv']);
    expect(sent.files!.single.mimeType, 'text/csv');
    expect(await sent.files!.single.readAsBytes(), [1, 2, 3]);
  });

  test('success and an undetermined result are shared; a dismissal is a cancel (BR-TRANSFER-014)', () async {
    Future<Object?> result(ShareResultStatus status) async =>
        switch (await _shared((_) async => ShareResult('', status))) {
          Ok(:final value) => value,
          Rejected(:final reason) => reason,
        };

    expect(await result(ShareResultStatus.success), ExportShareResult.shared);
    expect(
      await result(ShareResultStatus.unavailable),
      ExportShareResult.shared,
    );
    expect(
      await result(ShareResultStatus.dismissed),
      ExportShareResult.dismissed,
    );
  });

  test(
    'no share sheet, and a platform failure, are typed reasons (E1, E2)',
    () async {
      TransferRejection reason(
        Outcome<ExportShareResult, TransferRejection> r,
      ) => (r as Rejected<ExportShareResult, TransferRejection>).reason;

      expect(
        reason(await _shared((_) => throw MissingPluginException())),
        TransferRejection.shareUnavailable,
      );
      expect(
        reason(
          await _shared(
            (_) => throw PlatformException(
              code: 'x',
              message: '/data/user/0/secret',
            ),
          ),
        ),
        TransferRejection.shareFailed,
      );
    },
  );
}
