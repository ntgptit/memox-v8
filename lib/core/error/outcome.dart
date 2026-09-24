/// The result of an operation that can be legitimately refused. Not an
/// exception: a `Rejected` is an expected outcome the caller must handle.
///
/// [R] is the refusing feature's own reason enum (ADR-011 D6), so `core/`
/// names no business reason and a switch over [R] stays exhaustive.
sealed class Outcome<T, R extends Enum> {
  const Outcome();
}

final class Ok<T, R extends Enum> extends Outcome<T, R> {
  const Ok(this.value);
  final T value;
}

final class Rejected<T, R extends Enum> extends Outcome<T, R> {
  const Rejected(this.reason);
  final R reason;
}
