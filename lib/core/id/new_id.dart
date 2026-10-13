import 'dart:math';

import 'package:uuid/data.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
final _random = Random.secure();

/// The 12 `rand_a` bits of a v7 id: a counter inside one millisecond.
const _counterBits = 12;
const _counterMax = (1 << _counterBits) - 1;

// The clock and counter of the last id, so ids made inside one millisecond
// still sort in the order they were made (RFC 9562 §6.2, method 1).
var _lastMillis = 0;
var _counter = 0;

/// A client-generated UUID v7, per ADR-007: ids sort by the time they were
/// made, and ids made back to back sort in that order even inside one
/// millisecond, so a batch write keeps its source order under `id ASC`.
String newId() {
  _advance(DateTime.now().millisecondsSinceEpoch);
  final bytes = List<int>.generate(10, (_) => _random.nextInt(256));
  bytes[0] = _counter >> 8;
  bytes[1] = _counter & 0xff;
  return _uuid.v7(config: V7Options(_lastMillis, bytes));
}

/// Moves the clock to [millis] with a fresh counter, or steps the counter
/// when the millisecond has not changed (or the clock went backwards). A
/// counter that overflows borrows the next millisecond.
void _advance(int millis) {
  if (millis > _lastMillis) {
    _lastMillis = millis;
    // Start low so a burst has room before the counter overflows.
    _counter = _random.nextInt(_counterMax ~/ 2);
    return;
  }
  if (_counter < _counterMax) {
    _counter++;
    return;
  }
  _lastMillis++;
  _counter = 0;
}
