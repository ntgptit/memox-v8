import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';

enum _Reason { tooDeep }

void main() {
  test('Ok carries a value, Rejected carries a typed reason', () {
    const Outcome<int, _Reason> ok = Ok(1);
    const Outcome<int, _Reason> rejected = Rejected(_Reason.tooDeep);
    expect(switch (ok) {
      Ok(:final value) => value,
      Rejected() => -1,
    }, 1);
    expect(switch (rejected) {
      Ok() => null,
      Rejected(:final reason) => reason,
    }, _Reason.tooDeep);
  });
}
