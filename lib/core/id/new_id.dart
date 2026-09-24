import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// A client-generated UUID v4, per ADR-007.
String newId() => _uuid.v4();
