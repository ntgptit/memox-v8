import 'package:json_annotation/json_annotation.dart';

part 'sync_models.g.dart';

/// The sync wire format (server-sync spec §4). `row` stays a map: each
/// EntitySyncAdapter converts its own table.
@JsonSerializable()
class SyncOperationModel {
  const SyncOperationModel({
    required this.opId,
    required this.entityType,
    required this.entityId,
    required this.op,
    required this.row,
  });

  factory SyncOperationModel.fromJson(Map<String, dynamic> json) =>
      _$SyncOperationModelFromJson(json);

  final String opId;
  final String entityType;
  final String entityId;
  final String op;
  final Map<String, dynamic>? row;

  Map<String, dynamic> toJson() => _$SyncOperationModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PushRequestModel {
  const PushRequestModel({required this.deviceId, required this.operations});

  factory PushRequestModel.fromJson(Map<String, dynamic> json) =>
      _$PushRequestModelFromJson(json);

  final String deviceId;
  final List<SyncOperationModel> operations;

  Map<String, dynamic> toJson() => _$PushRequestModelToJson(this);
}

@JsonSerializable()
class SyncChangeModel {
  const SyncChangeModel({
    required this.entityType,
    required this.entityId,
    required this.serverVersion,
    required this.deleted,
    required this.row,
  });

  factory SyncChangeModel.fromJson(Map<String, dynamic> json) =>
      _$SyncChangeModelFromJson(json);

  final String entityType;
  final String entityId;
  final int serverVersion;
  final bool deleted;
  final Map<String, dynamic>? row;

  Map<String, dynamic> toJson() => _$SyncChangeModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OperationResultModel {
  const OperationResultModel({
    required this.opId,
    required this.status,
    required this.serverVersion,
    required this.code,
    required this.current,
  });

  factory OperationResultModel.fromJson(Map<String, dynamic> json) =>
      _$OperationResultModelFromJson(json);

  static const applied = 'applied';

  final String opId;
  final String status;
  final int? serverVersion;
  final String? code;
  final SyncChangeModel? current;

  bool get isApplied => status == applied;

  Map<String, dynamic> toJson() => _$OperationResultModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PushResponseModel {
  const PushResponseModel({required this.results});

  factory PushResponseModel.fromJson(Map<String, dynamic> json) =>
      _$PushResponseModelFromJson(json);

  final List<OperationResultModel> results;

  Map<String, dynamic> toJson() => _$PushResponseModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ChangesResponseModel {
  const ChangesResponseModel({
    required this.changes,
    required this.nextSince,
    required this.hasMore,
  });

  factory ChangesResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ChangesResponseModelFromJson(json);

  final List<SyncChangeModel> changes;
  final int nextSince;
  final bool hasMore;

  Map<String, dynamic> toJson() => _$ChangesResponseModelToJson(this);
}
