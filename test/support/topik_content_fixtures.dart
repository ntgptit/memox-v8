import 'dart:convert';

import 'package:memox/features/topik/domain/models/topik_exam_layout_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

/// Synthetic TOPIK content (spec 2026-10-15 §4.5): structurally complete and
/// valid for any level and section, with made-up text. It is test data, never
/// shipped and never presented as a real paper.

/// The audio path every synthetic listening test names.
const String topikFixtureAudioAsset = 'assets/topik/fixture/listening.mp3';

const _optionCount = 4;
const _groupLengthMs = 30000;

/// A valid test as decoded JSON, with the runtime types `jsonDecode` gives
/// (`List<dynamic>`, `Map<String, dynamic>`), so tests can break it in place.
/// The last two questions share one group;
/// every other question has its own. Question 1 (or 31) carries an
/// explanation and a word; listening groups carry a script.
Map<String, Object?> topikTestJson({
  TopikLevel level = TopikLevel.topik2,
  TopikSection section = TopikSection.reading,
  int round = 96,
}) {
  final layout = TopikExamLayout.of(level, section);
  final numbers = [
    for (var i = 0; i < layout.questionCount; i++) layout.firstQuestionNo + i,
  ];
  final pairStart = numbers[numbers.length - 2];
  String groupIdOf(int no) =>
      no >= pairStart ? 'g$pairStart-${numbers.last}' : 'g$no';
  final groupIds = <String>[];
  for (final no in numbers) {
    final id = groupIdOf(no);
    if (!groupIds.contains(id)) groupIds.add(id);
  }
  final isListening = section == TopikSection.listening;
  return _decoded({
    'schemaVersion': 1,
    'contentVersion': 1,
    'testId': '${level.code}-$round-${section.code}',
    'level': level.code,
    'round': round,
    'section': section.code,
    'format': 'pbt',
    'form': 'B-홀수형',
    'titleKo': '제$round회 한국어능력시험',
    'officialTimeLimitSec': 3600,
    'source': {
      'publishedBy': 'NIIED',
      'url': 'https://www.topik.go.kr/fixture',
      'publishedAt': '2025-01-01',
    },
    if (isListening) 'assets': {'audio': topikFixtureAudioAsset},
    'groups': [
      for (final (index, id) in groupIds.indexed)
        {
          'groupId': id,
          'instructionKo': '※ 다음을 읽고 물음에 답하십시오.',
          'questionNos': [
            for (final no in numbers)
              if (groupIdOf(no) == id) no,
          ],
          'passage': isListening ? null : {'textKo': '지문 $id'},
          if (isListening)
            'audio': {
              'startMs': index * _groupLengthMs,
              'endMs': (index + 1) * _groupLengthMs,
              'playCount': TopikExamLayout.playCountFor(
                level,
                section,
                numbers.firstWhere((no) => groupIdOf(no) == id),
              )!,
            },
          if (isListening) 'script': '남자: 안녕하세요. 여자: 네.',
          if (isListening)
            'scriptTranslation': {'vi': 'Xin chào.', 'en': 'Hello.'},
        },
    ],
    'questions': [
      for (final no in numbers)
        {
          'no': no,
          'groupId': groupIdOf(no),
          'questionType': TopikQuestionType.defaultFor(
            level,
            section,
            no,
          )!.code,
          'points': _pointsOf(level, section, no, layout),
          'stemKo': '알맞은 것을 고르십시오. ($no)',
          'options': [
            for (var idx = 1; idx <= _optionCount; idx++)
              {'idx': idx, 'textKo': '보기 $idx'},
          ],
          'answerIdx': (no - 1) % _optionCount + 1,
          if (no == layout.firstQuestionNo) ...{
            'explanation': {'vi': 'Giải thích.', 'en': 'Explanation.'},
            'words': [
              {'ko': '기획', 'vi': 'kế hoạch', 'en': 'planning', 'pos': 'n'},
            ],
          },
        },
    ],
  });
}

Map<String, Object?> _decoded(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, Object?>;

/// TOPIK I listening: the first ten questions 4, the rest 3 (40 + 60).
/// TOPIK I reading: the first twenty 3, the rest 2 (60 + 40). TOPIK II: 2.
int _pointsOf(
  TopikLevel level,
  TopikSection section,
  int no,
  TopikExamLayout layout,
) {
  final rank = no - layout.firstQuestionNo;
  return switch ((level, section)) {
    (TopikLevel.topik1, TopikSection.listening) => rank < 10 ? 4 : 3,
    (TopikLevel.topik1, TopikSection.reading) => rank < 20 ? 3 : 2,
    (TopikLevel.topik2, _) => 2,
  };
}

/// The question [no] of [test], for a test to break it in place.
Map<String, Object?> questionJson(Map<String, Object?> test, int no) =>
    (test['questions']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .firstWhere((question) => question['no'] == no);

/// The group [groupId] of [test], for a test to break it in place.
Map<String, Object?> groupJson(Map<String, Object?> test, String groupId) =>
    (test['groups']! as List<Object?>).cast<Map<String, Object?>>().firstWhere(
      (group) => group['groupId'] == groupId,
    );
