import 'package:flutter/foundation.dart';

/// Whether the tracer logs every statement as `debug db.query` (SQL log
/// switch spec §4.1). It starts on, the column's default, so the statements
/// that run before the account's row is read are logged as before; the
/// feeder in `logging_providers.dart` then keeps it equal to the row.
final class SqlLogSwitch extends ValueNotifier<bool> {
  SqlLogSwitch() : super(true);
}
