import 'package:flutter/foundation.dart';

/// Entity type names of the sync protocol (API-A2 spec §4).
abstract final class SyncEntityType {
  static const deck = 'deck';
  static const card = 'card';
  static const deleteBatch = 'delete_batch';
}

/// A synced entity as the protocol names it: `{entityType, entityId}`.
@immutable
final class SyncEntityRef {
  const SyncEntityRef(this.entityType, this.entityId);

  const SyncEntityRef.deck(this.entityId) : entityType = SyncEntityType.deck;
  const SyncEntityRef.card(this.entityId) : entityType = SyncEntityType.card;
  const SyncEntityRef.deleteBatch(this.entityId)
    : entityType = SyncEntityType.deleteBatch;

  factory SyncEntityRef.fromJson(Map<String, Object?> json) =>
      SyncEntityRef(json['entityType']! as String, json['entityId']! as String);

  final String entityType;
  final String entityId;

  Map<String, Object?> toJson() => {
    'entityType': entityType,
    'entityId': entityId,
  };

  @override
  bool operator ==(Object other) =>
      other is SyncEntityRef &&
      other.entityType == entityType &&
      other.entityId == entityId;

  @override
  int get hashCode => Object.hash(entityType, entityId);

  @override
  String toString() => '$entityType/$entityId';
}
