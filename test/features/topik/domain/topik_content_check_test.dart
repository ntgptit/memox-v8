import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/data/mappers/topik_test_mapper.dart';
import 'package:memox/features/topik/domain/models/topik_content_check_model.dart';
import 'package:memox/features/topik/domain/models/topik_content_issue_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';

import '../../../support/topik_content_fixtures.dart';

// BR-TOPIK-001…005, BR-TOPIK-007, BR-TOPIK-008; spec 2026-10-15 §4.2.

bool _everyAsset(String path) => true;

TopikTest _read(Map<String, Object?> json) {
  final read = topikTestOf(json);
  expect(read.issues, isEmpty, reason: 'the broken rule must be a check rule');
  return read.test!;
}

List<TopikContentIssue> _check(
  Map<String, Object?> json, {
  bool Function(String) assetExists = _everyAsset,
}) => checkTopikTest(_read(json), assetExists: assetExists);

List<TopikContentRule> _errorRules(List<TopikContentIssue> issues) => [
  for (final issue in issues)
    if (issue.isError) issue.rule,
];

void main() {
  test('every synthetic level and section passes', () {
    for (final level in TopikLevel.values) {
      for (final section in TopikSection.values) {
        expect(
          _check(topikTestJson(level: level, section: section)),
          isEmpty,
          reason: '${level.code} ${section.code}',
        );
      }
    }
  });

  group('identity and metadata (BR-TOPIK-007)', () {
    test('a test id that does not match level, round and section', () {
      final json = topikTestJson()..['testId'] = 'topik2-91-reading';
      expect(_errorRules(_check(json)), [TopikContentRule.identity]);
    });

    test('a publisher other than NIIED, a wrong format, a schema version', () {
      final json = topikTestJson()
        ..['format'] = 'ibt'
        ..['schemaVersion'] = 2
        ..['contentVersion'] = 0;
      (json['source']! as Map<String, Object?>)['publishedBy'] = 'Someone';
      expect(
        _errorRules(_check(json)),
        List.filled(4, TopikContentRule.metadata),
      );
    });
  });

  group('numbering (BR-TOPIK-001)', () {
    test('a missing question', () {
      final json = topikTestJson();
      (json['questions']! as List<Object?>).removeWhere(
        (question) => (question! as Map<String, Object?>)['no'] == 25,
      );
      groupJson(json, 'g25')['questionNos'] = <int>[];
      final rules = _errorRules(_check(json));
      expect(rules, contains(TopikContentRule.numbering));
    });

    test('TOPIK I reading numbered from 1 instead of 31', () {
      final json = topikTestJson(level: TopikLevel.topik1);
      for (final question in json['questions']! as List<Object?>) {
        final map = question! as Map<String, Object?>;
        map['no'] = (map['no']! as int) - 30;
      }
      expect(_errorRules(_check(json)), contains(TopikContentRule.numbering));
    });
  });

  group('points (BR-TOPIK-002)', () {
    test('a total of 98', () {
      final json = topikTestJson(
        level: TopikLevel.topik1,
        section: TopikSection.listening,
      );
      questionJson(json, 30)['points'] = 1;
      final rules = _errorRules(_check(json));
      expect(rules, [TopikContentRule.points, TopikContentRule.points]);
    });

    test('a TOPIK II question worth 3 keeps the total only by luck', () {
      final json = topikTestJson();
      questionJson(json, 1)['points'] = 3;
      questionJson(json, 2)['points'] = 1;
      expect(_errorRules(_check(json)), [
        TopikContentRule.points,
        TopikContentRule.points,
      ]);
    });
  });

  group('options (BR-TOPIK-003)', () {
    test('three options, a repeated idx, an empty option, an answer of 5', () {
      final json = topikTestJson();
      (questionJson(json, 1)['options']! as List<Object?>).removeLast();
      final options = questionJson(json, 2)['options']! as List<Object?>;
      (options[1]! as Map<String, Object?>)['idx'] = 1;
      (options[2]! as Map<String, Object?>).remove('textKo');
      questionJson(json, 3)['answerIdx'] = 5;
      expect(
        _errorRules(_check(json)),
        List.filled(4, TopikContentRule.options),
      );
    });
  });

  group('groups (BR-TOPIK-004)', () {
    test('a group naming a question that does not exist', () {
      final json = topikTestJson();
      groupJson(json, 'g1')['questionNos'] = [1, 51];
      expect(_errorRules(_check(json)), [TopikContentRule.groups]);
    });

    test('a group listing one question twice and missing its partner', () {
      final json = topikTestJson();
      groupJson(json, 'g49-50')['questionNos'] = [49, 49];
      expect(_errorRules(_check(json)), [TopikContentRule.groups]);
    });

    test('a question whose group does not exist', () {
      final json = topikTestJson();
      questionJson(json, 4)['groupId'] = 'nope';
      expect(_errorRules(_check(json)), contains(TopikContentRule.groups));
    });

    test('a repeated group id', () {
      final json = topikTestJson();
      groupJson(json, 'g2')['groupId'] = 'g1';
      expect(_errorRules(_check(json)), contains(TopikContentRule.groups));
    });
  });

  group('listening audio (BR-TOPIK-004)', () {
    test('a group without audio, a reversed range, a wrong play count', () {
      final json = topikTestJson(section: TopikSection.listening);
      groupJson(json, 'g1').remove('audio');
      groupJson(json, 'g2')['audio'] = {
        'startMs': 5000,
        'endMs': 5000,
        'playCount': 1,
      };
      groupJson(json, 'g21')['audio'] = {
        'startMs': 0,
        'endMs': 1000,
        'playCount': 1,
      };
      expect(_errorRules(_check(json)), List.filled(3, TopikContentRule.audio));
    });

    test('a listening test without its audio file', () {
      final json = topikTestJson(section: TopikSection.listening)
        ..remove('assets');
      expect(_errorRules(_check(json)), [TopikContentRule.audio]);
    });

    test('a group spanning questions that play once and twice', () {
      final json = topikTestJson(section: TopikSection.listening);
      questionJson(json, 21)['groupId'] = 'g20';
      groupJson(json, 'g20')['questionNos'] = [20, 21];
      groupJson(json, 'g21')['questionNos'] = <int>[];
      final rules = _errorRules(_check(json));
      expect(rules, contains(TopikContentRule.audio));
    });

    test('a reading group carrying audio', () {
      final json = topikTestJson();
      groupJson(json, 'g1')['audio'] = {
        'startMs': 0,
        'endMs': 1000,
        'playCount': 1,
      };
      expect(_errorRules(_check(json)), [TopikContentRule.audio]);
    });
  });

  group('question types (BR-TOPIK-005)', () {
    test('a type of another level or section is an error', () {
      final json = topikTestJson();
      questionJson(json, 1)['questionType'] = 'L1_place';
      expect(_errorRules(_check(json)), [TopikContentRule.questionType]);
    });

    test('a type off the default number map is only a warning', () {
      final json = topikTestJson();
      questionJson(json, 13)['questionType'] = 'R2_paragraph_blank';
      final issues = _check(json);
      expect(_errorRules(issues), isEmpty);
      expect(issues.single.rule, TopikContentRule.questionType);
      expect(issues.single.severity, TopikIssueSeverity.warning);
    });
  });

  group('assets (BR-TOPIK-008)', () {
    test('a missing audio file or image is an error naming the path', () {
      final json = topikTestJson(section: TopikSection.listening);
      (questionJson(json, 1)['options']! as List<Object?>)[0] = {
        'idx': 1,
        'image': 'assets/topik/fixture/q1.png',
      };
      final issues = _check(json, assetExists: (path) => false);
      expect(_errorRules(issues), [
        TopikContentRule.assets,
        TopikContentRule.assets,
      ]);
      expect(
        issues.map((issue) => issue.detail).join(),
        contains(topikFixtureAudioAsset),
      );
    });
  });

  test('a second test with the same id is a duplicate', () {
    final first = _read(topikTestJson());
    final second = _read(topikTestJson());
    final other = _read(topikTestJson(section: TopikSection.listening));
    final issues = checkTopikCatalog([first, other, second]);
    expect(issues.single.rule, TopikContentRule.duplicate);
    expect(issues.single.testId, 'topik2-96-reading');
  });
}
