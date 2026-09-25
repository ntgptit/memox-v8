/// What a turn tells the screen (graded modes spec §8.1): whether the answer
/// was right, for the feedback of a graded mode. Null for `browse` and
/// `self_assess`, whose result the person chose.
final class TurnResult {
  const TurnResult({this.isCorrect});

  final bool? isCorrect;
}
