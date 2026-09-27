import 'package:json_annotation/json_annotation.dart';

part 'sync_models.g.dart';

/// The sync wire format (API-A2 spec §4).
/// One push operation (API-A2 spec §4.1): a command, or a patch of one
/// field group. Null fields are left out.
@JsonSerializable(includeIfNull: false)
class SyncOperationModel {
  const SyncOperationModel({
    required this.opId,
    required this.kind,
    this.type,
    this.entityType,
    this.entityId,
    this.group,
    this.payload,
    this.fields,
    this.affected = const [],
  });

  factory SyncOperationModel.fromJson(Map<String, Object?> json) =>
      _$SyncOperationModelFromJson(json);

  final String opId;
  final String kind;
  final String? type;
  final String? entityType;
  final String? entityId;
  final String? group;
  final Map<String, Object?>? payload;
  final Map<String, Object?>? fields;
  final List<Map<String, Object?>> affected;

  Map<String, Object?> toJson() => _$SyncOperationModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PushRequestModel {
  const PushRequestModel({required this.deviceId, required this.operations});

  factory PushRequestModel.fromJson(Map<String, Object?> json) =>
      _$PushRequestModelFromJson(json);

  final String deviceId;
  final List<SyncOperationModel> operations;

  Map<String, Object?> toJson() => _$PushRequestModelToJson(this);
}

@JsonSerializable()
class SyncChangeModel {
  const SyncChangeModel({
    required this.entityType,
    required this.entityId,
    required this.serverVersion,
    required this.isDeleted,
    required this.row,
  });

  factory SyncChangeModel.fromJson(Map<String, Object?> json) =>
      _$SyncChangeModelFromJson(json);

  final String entityType;
  final String entityId;
  final int serverVersion;
  @JsonKey(name: 'deleted')
  final bool isDeleted;
  final Map<String, Object?>? row;

  /// An id the server never stored (API-A2 `SyncChange.absent`).
  bool get isAbsent => serverVersion == 0 && row == null;

  Map<String, Object?> toJson() => _$SyncChangeModelToJson(this);
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

  factory OperationResultModel.fromJson(Map<String, Object?> json) =>
      _$OperationResultModelFromJson(json);

  static const applied = 'applied';

  final String opId;
  final String status;
  final int? serverVersion;
  final String? code;
  final List<SyncChangeModel>? current;

  bool get isApplied => status == applied;

  Map<String, Object?> toJson() => _$OperationResultModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PushResponseModel {
  const PushResponseModel({required this.results});

  factory PushResponseModel.fromJson(Map<String, Object?> json) =>
      _$PushResponseModelFromJson(json);

  final List<OperationResultModel> results;

  Map<String, Object?> toJson() => _$PushResponseModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ChangesResponseModel {
  const ChangesResponseModel({
    required this.changes,
    required this.nextSince,
    required this.hasMore,
  });

  factory ChangesResponseModel.fromJson(Map<String, Object?> json) =>
      _$ChangesResponseModelFromJson(json);

  final List<SyncChangeModel> changes;
  final int nextSince;
  final bool hasMore;

  Map<String, Object?> toJson() => _$ChangesResponseModelToJson(this);
}
