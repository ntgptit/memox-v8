import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

/// What every test of one level and section must look like: its question
/// count, its real numbering and the points a question may carry
/// (BR-TOPIK-001, BR-TOPIK-002), and how often a group's audio plays in the
/// real exam (BR-TOPIK-004).
final class TopikExamLayout {
  const TopikExamLayout._({
    required this.questionCount,
    required this.firstQuestionNo,
    required this.allowedPoints,
  });

  /// The points of one section always add up to this (BR-TOPIK-002).
  static const int sectionTotal = 100;

  /// TOPIK II listening questions up to this number play once; later ones
  /// play twice (BR-TOPIK-004).
  static const int _topik2SinglePlayLastNo = 20;
  static const int _singlePlay = 1;
  static const int _doublePlay = 2;

  static const _topik1Listening = TopikExamLayout._(
    questionCount: 30,
    firstQuestionNo: 1,
    allowedPoints: {3, 4},
  );
  static const _topik1Reading = TopikExamLayout._(
    questionCount: 40,
    firstQuestionNo: 31,
    allowedPoints: {2, 3},
  );
  static const _topik2 = TopikExamLayout._(
    questionCount: 50,
    firstQuestionNo: 1,
    allowedPoints: {2},
  );

  final int questionCount;
  final int firstQuestionNo;
  final Set<int> allowedPoints;

  int get lastQuestionNo => firstQuestionNo + questionCount - 1;

  static TopikExamLayout of(TopikLevel level, TopikSection section) =>
      switch ((level, section)) {
        (TopikLevel.topik1, TopikSection.listening) => _topik1Listening,
        (TopikLevel.topik1, TopikSection.reading) => _topik1Reading,
        (TopikLevel.topik2, _) => _topik2,
      };

  /// How often the group holding [questionNo] plays in the real exam, or
  /// null for reading. Only Exam mode (Phase B) uses it.
  static int? playCountFor(
    TopikLevel level,
    TopikSection section,
    int questionNo,
  ) {
    if (section != TopikSection.listening) return null;
    if (level == TopikLevel.topik1) return _doublePlay;
    if (questionNo <= _topik2SinglePlayLastNo) return _singlePlay;
    return _doublePlay;
  }
}
