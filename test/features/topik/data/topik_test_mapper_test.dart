import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/data/mappers/topik_test_mapper.dart';
import 'package:memox/features/topik/domain/models/topik_content_issue_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';

import '../../../support/topik_content_fixtures.dart';

// Spec 2026-10-15 §4.1; BR-TOPIK-003, BR-TOPIK-006, BR-TOPIK-009.

List<TopikContentRule> _rulesOf(TopikTestRead read) => [
  for (final issue in read.issues) issue.rule,
];

void main() {
  test('every synthetic level and section reads without an issue', () {
    for (final level in TopikLevel.values) {
      for (final section in TopikSection.values) {
        final read = topikTestOf(topikTestJson(level: level, section: section));
        expect(read.issues, isEmpty, reason: '${level.code} ${section.code}');
        expect(read.test, isNotNull);
      }
    }
  });

  test('the model keeps every field of the file', () {
    final test = topikTestOf(
      topikTestJson(level: TopikLevel.topik1, section: TopikSection.listening),
    ).test!;
    expect(test.testId, 'topik1-96-listening');
    expect(test.level, TopikLevel.topik1);
    expect(test.section, TopikSection.listening);
    expect(test.round, 96);
    expect(test.form, 'B-홀수형');
    expect(test.source.publishedBy, 'NIIED');
    expect(test.audioAsset, topikFixtureAudioAsset);
    expect(test.questions.first.no, 1);
    expect(test.questions.first.points, 4);
    expect(
      test.questions.first.questionType,
      TopikQuestionType.l1AnswerQuestion,
    );
    expect(test.questions.first.options.map((option) => option.idx), [
      1,
      2,
      3,
      4,
    ]);
    expect(test.questions.first.explanation!.en, 'Explanation.');
    expect(test.questions.first.words.single.meaning.vi, 'kế hoạch');
    expect(test.groups.last.questionNos, [29, 30]);
    expect(test.groups.first.audio!.playCount, 2);
  });

  test('content tags are derived from the data (BR-TOPIK-009)', () {
    final reading = topikTestOf(topikTestJson()).test!;
    expect(reading.contentTags, {
      TopikContentTag.explanation,
      TopikContentTag.words,
    });
    final listening = topikTestOf(
      topikTestJson(section: TopikSection.listening),
    ).test!;
    expect(listening.contentTags, {
      TopikContentTag.explanation,
      TopikContentTag.words,
      TopikContentTag.script,
      TopikContentTag.translation,
    });
  });

  test('questions listed out of order are held in number order', () {
    final json = topikTestJson();
    (json['questions']! as List<Object?>).setAll(0, [
      ...(json['questions']! as List<Object?>).reversed,
    ]);
    final test = topikTestOf(json).test!;
    expect(test.questions.first.no, 1);
    expect(test.questions.last.no, 50);
  });

  group('shape problems are reported with their path, never thrown', () {
    test('a value that is not a map', () {
      final read = topikTestOf('nope');
      expect(read.test, isNull);
      expect(_rulesOf(read), [TopikContentRule.shape]);
    });

    test('a missing required field', () {
      final json = topikTestJson()..remove('form');
      final read = topikTestOf(json);
      expect(read.test, isNull);
      expect(read.issues.single.rule, TopikContentRule.shape);
      expect(read.issues.single.detail, contains('form'));
      expect(read.issues.single.testId, 'topik2-96-reading');
    });

    test('points written as a decimal', () {
      final json = topikTestJson();
      questionJson(json, 7)['points'] = 2.0;
      final read = topikTestOf(json);
      expect(read.test, isNull);
      expect(read.issues.single.detail, contains('questions[no 7].points'));
    });

    test('an unknown level, section or question type', () {
      final json = topikTestJson()..['section'] = 'writing';
      questionJson(json, 3)['questionType'] = 'R9_nope';
      final read = topikTestOf(json);
      expect(read.test, isNull);
      expect(_rulesOf(read), [TopikContentRule.shape, TopikContentRule.shape]);
    });

    test('every problem of one file is reported, not only the first', () {
      final json = topikTestJson()
        ..remove('form')
        ..remove('titleKo');
      expect(topikTestOf(json).issues, hasLength(2));
    });
  });

  group('multilingual text needs vi and en (BR-TOPIK-006)', () {
    test('a missing en', () {
      final json = topikTestJson();
      questionJson(json, 1)['explanation'] = {'vi': 'Giải thích.'};
      final read = topikTestOf(json);
      expect(read.test, isNull);
      expect(_rulesOf(read), [TopikContentRule.languages]);
    });

    test('a whitespace-only en', () {
      final json = topikTestJson();
      questionJson(json, 1)['words'] = [
        {'ko': '기획', 'vi': 'kế hoạch', 'en': '  '},
      ];
      expect(_rulesOf(topikTestOf(json)), [TopikContentRule.languages]);
    });

    test('a script translation without vi', () {
      final json = topikTestJson(section: TopikSection.listening);
      groupJson(json, 'g1')['scriptTranslation'] = {'en': 'Hello.'};
      expect(_rulesOf(topikTestOf(json)), [TopikContentRule.languages]);
    });
  });
}
