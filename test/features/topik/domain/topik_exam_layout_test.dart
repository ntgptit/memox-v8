import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_exam_layout_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

// BR-TOPIK-001, BR-TOPIK-002, BR-TOPIK-004, BR-TOPIK-005.

void main() {
  group('TopikExamLayout (BR-TOPIK-001, BR-TOPIK-002)', () {
    test('TOPIK I listening is 30 questions 1–30 worth 3 or 4', () {
      final layout = TopikExamLayout.of(
        TopikLevel.topik1,
        TopikSection.listening,
      );
      expect(layout.questionCount, 30);
      expect(layout.firstQuestionNo, 1);
      expect(layout.lastQuestionNo, 30);
      expect(layout.allowedPoints, {3, 4});
    });

    test('TOPIK I reading is 40 questions numbered 31–70 worth 2 or 3', () {
      final layout = TopikExamLayout.of(
        TopikLevel.topik1,
        TopikSection.reading,
      );
      expect(layout.questionCount, 40);
      expect(layout.firstQuestionNo, 31);
      expect(layout.lastQuestionNo, 70);
      expect(layout.allowedPoints, {2, 3});
    });

    test('TOPIK II listening and reading are 50 questions 1–50 worth 2', () {
      for (final section in TopikSection.values) {
        final layout = TopikExamLayout.of(TopikLevel.topik2, section);
        expect(layout.questionCount, 50);
        expect(layout.firstQuestionNo, 1);
        expect(layout.lastQuestionNo, 50);
        expect(layout.allowedPoints, {2});
      }
      expect(TopikExamLayout.sectionTotal, 100);
    });
  });

  group('play count (BR-TOPIK-004)', () {
    test('TOPIK I listening plays every group twice', () {
      for (final no in [1, 15, 30]) {
        expect(
          TopikExamLayout.playCountFor(
            TopikLevel.topik1,
            TopikSection.listening,
            no,
          ),
          2,
        );
      }
    });

    test('TOPIK II listening plays 1–20 once and 21–50 twice', () {
      int? count(int no) => TopikExamLayout.playCountFor(
        TopikLevel.topik2,
        TopikSection.listening,
        no,
      );
      expect(count(1), 1);
      expect(count(20), 1);
      expect(count(21), 2);
      expect(count(50), 2);
    });

    test('reading has no play count', () {
      expect(
        TopikExamLayout.playCountFor(
          TopikLevel.topik2,
          TopikSection.reading,
          1,
        ),
        isNull,
      );
    });
  });

  group('question types (BR-TOPIK-005)', () {
    test('each level and section has the brief §2.5 number of types', () {
      int countOf(TopikLevel level, TopikSection section) => TopikQuestionType
          .values
          .where((type) => type.level == level && type.section == section)
          .length;
      expect(countOf(TopikLevel.topik1, TopikSection.listening), 8);
      expect(countOf(TopikLevel.topik1, TopikSection.reading), 8);
      expect(countOf(TopikLevel.topik2, TopikSection.listening), 7);
      expect(countOf(TopikLevel.topik2, TopikSection.reading), 13);
    });

    test(
      'every question number of every layout has exactly one default type',
      () {
        for (final level in TopikLevel.values) {
          for (final section in TopikSection.values) {
            final layout = TopikExamLayout.of(level, section);
            for (
              var no = layout.firstQuestionNo;
              no <= layout.lastQuestionNo;
              no++
            ) {
              final matches = TopikQuestionType.values.where(
                (type) =>
                    type.level == level &&
                    type.section == section &&
                    no >= type.defaultFirstNo &&
                    no <= type.defaultLastNo,
              );
              expect(
                matches,
                hasLength(1),
                reason: '${level.code} ${section.code} $no',
              );
              expect(
                TopikQuestionType.defaultFor(level, section, no),
                matches.single,
              );
            }
          }
        }
      },
    );

    test('codes are unique and read back', () {
      final codes = TopikQuestionType.values.map((type) => type.code).toSet();
      expect(codes, hasLength(TopikQuestionType.values.length));
      expect(
        TopikQuestionType.ofCode('R2_ordering'),
        TopikQuestionType.r2Ordering,
      );
      expect(TopikQuestionType.ofCode('nope'), isNull);
      expect(TopikLevel.ofCode('topik2'), TopikLevel.topik2);
      expect(TopikSection.ofCode('reading'), TopikSection.reading);
      expect(TopikSection.ofCode('writing'), isNull);
    });
  });
}
