import 'package:memox/features/topik/domain/models/topik_content_issue_model.dart';
import 'package:memox/features/topik/domain/models/topik_exam_layout_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_group_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';

/// The one content checker (BR-TOPIK-008): the app's loader and the gate's
/// lint both run it, so what the gate stops is what the app refuses.
const int _schemaVersion = 1;
const String _format = 'pbt';
const String _publisher = 'NIIED';
const Set<int> _optionIdxs = {1, 2, 3, 4};

/// Every cross-field problem of [test] (spec 2026-10-15 §4.2). Shape and
/// language problems were already reported by the mapper. [assetExists]
/// answers whether a bundle path is present.
List<TopikContentIssue> checkTopikTest(
  TopikTest test, {
  required bool Function(String assetPath) assetExists,
}) {
  final issues = <TopikContentIssue>[];
  void error(TopikContentRule rule, String detail) =>
      issues.add(TopikContentIssue.error(rule, test.testId, detail));
  void warning(TopikContentRule rule, String detail) =>
      issues.add(TopikContentIssue.warning(rule, test.testId, detail));

  _checkIdentity(test, error);
  _checkNumbering(test, error);
  _checkPoints(test, error);
  for (final question in test.questions) {
    _checkOptions(question, error);
    _checkQuestionType(test, question, error, warning);
  }
  _checkGroups(test, error);
  _checkAudio(test, error);
  _checkAssets(test, assetExists, error);
  return issues;
}

/// A duplicate error for each test whose id an earlier one already has.
List<TopikContentIssue> checkTopikCatalog(Iterable<TopikTest> tests) {
  final seen = <String>{};
  return [
    for (final test in tests)
      if (!seen.add(test.testId))
        TopikContentIssue.error(
          TopikContentRule.duplicate,
          test.testId,
          'another pack already has this test id',
        ),
  ];
}

typedef _Report = void Function(TopikContentRule rule, String detail);

void _checkIdentity(TopikTest test, _Report error) {
  final expectedId = '${test.level.code}-${test.round}-${test.section.code}';
  if (test.testId != expectedId) {
    error(TopikContentRule.identity, 'testId should be $expectedId');
  }
  if (test.schemaVersion != _schemaVersion) {
    error(TopikContentRule.metadata, 'schemaVersion must be $_schemaVersion');
  }
  if (test.contentVersion < 1) {
    error(TopikContentRule.metadata, 'contentVersion must be at least 1');
  }
  if (test.format != _format) {
    error(TopikContentRule.metadata, 'format must be $_format');
  }
  if (test.source.publishedBy != _publisher) {
    error(TopikContentRule.metadata, 'source.publishedBy must be $_publisher');
  }
}

void _checkNumbering(TopikTest test, _Report error) {
  final layout = TopikExamLayout.of(test.level, test.section);
  final numbers = [for (final question in test.questions) question.no];
  final expected = [
    for (var no = layout.firstQuestionNo; no <= layout.lastQuestionNo; no++) no,
  ];
  if (numbers.length != expected.length ||
      numbers.toSet().length != numbers.length) {
    error(
      TopikContentRule.numbering,
      '${numbers.length} questions; ${layout.questionCount} distinct ones expected',
    );
    return;
  }
  for (final (index, no) in numbers.indexed) {
    if (no == expected[index]) continue;
    error(
      TopikContentRule.numbering,
      'questions must run ${layout.firstQuestionNo}–${layout.lastQuestionNo}',
    );
    return;
  }
}

void _checkPoints(TopikTest test, _Report error) {
  final layout = TopikExamLayout.of(test.level, test.section);
  var total = 0;
  for (final question in test.questions) {
    total += question.points;
    if (!layout.allowedPoints.contains(question.points)) {
      error(
        TopikContentRule.points,
        'question ${question.no} is worth ${question.points}; '
        'allowed ${layout.allowedPoints.join(' or ')}',
      );
    }
  }
  if (total != TopikExamLayout.sectionTotal) {
    error(
      TopikContentRule.points,
      'points total $total; must be ${TopikExamLayout.sectionTotal}',
    );
  }
}

void _checkOptions(TopikQuestion question, _Report error) {
  final idxs = [for (final option in question.options) option.idx];
  if (idxs.length != _optionIdxs.length ||
      !idxs.toSet().containsAll(_optionIdxs)) {
    error(
      TopikContentRule.options,
      'question ${question.no} needs options 1–4 once each',
    );
  }
  if (question.options.any(
    (option) => option.textKo == null && option.image == null,
  )) {
    error(
      TopikContentRule.options,
      'question ${question.no} has an option with no text or image',
    );
  }
  if (!_optionIdxs.contains(question.answerIdx)) {
    error(
      TopikContentRule.options,
      'question ${question.no} answerIdx must be 1–4',
    );
  }
}

void _checkQuestionType(
  TopikTest test,
  TopikQuestion question,
  _Report error,
  _Report warning,
) {
  final type = question.questionType;
  if (type.level != test.level || type.section != test.section) {
    error(
      TopikContentRule.questionType,
      'question ${question.no}: ${type.code} belongs to another level or section',
    );
    return;
  }
  final usual = TopikQuestionType.defaultFor(
    test.level,
    test.section,
    question.no,
  );
  if (usual != null && usual != type) {
    warning(
      TopikContentRule.questionType,
      'question ${question.no} is ${type.code}; papers 35–102 have ${usual.code}',
    );
  }
}

void _checkGroups(TopikTest test, _Report error) {
  final ids = <String>{};
  for (final group in test.groups) {
    if (!ids.add(group.groupId)) {
      error(TopikContentRule.groups, 'group id ${group.groupId} is repeated');
    }
  }
  for (final question in test.questions) {
    if (!ids.contains(question.groupId)) {
      error(
        TopikContentRule.groups,
        'question ${question.no} names missing group ${question.groupId}',
      );
    }
  }
  for (final group in test.groups) {
    final members = {
      for (final question in test.questions)
        if (question.groupId == group.groupId) question.no,
    };
    if (members.isEmpty && group.questionNos.isEmpty) continue;
    if (members.length != group.questionNos.length ||
        !members.containsAll(group.questionNos)) {
      error(
        TopikContentRule.groups,
        'group ${group.groupId} lists ${group.questionNos}; its questions are $members',
      );
    }
  }
}

void _checkAudio(TopikTest test, _Report error) {
  final isListening = test.section == TopikSection.listening;
  if (isListening && test.audioAsset == null) {
    error(TopikContentRule.audio, 'a listening test needs assets.audio');
  }
  for (final group in test.groups) {
    if (!isListening) {
      if (group.audio != null) {
        error(
          TopikContentRule.audio,
          'reading group ${group.groupId} carries audio',
        );
      }
      continue;
    }
    _checkGroupAudio(test, group, error);
  }
}

void _checkGroupAudio(TopikTest test, TopikQuestionGroup group, _Report error) {
  final audio = group.audio;
  if (group.questionNos.isEmpty) return;
  if (audio == null) {
    error(TopikContentRule.audio, 'group ${group.groupId} has no audio range');
    return;
  }
  if (audio.startMs < 0 || audio.startMs >= audio.endMs) {
    error(
      TopikContentRule.audio,
      'group ${group.groupId} audio range is empty or reversed',
    );
    return;
  }
  final counts = {
    for (final no in group.questionNos)
      TopikExamLayout.playCountFor(test.level, test.section, no),
  };
  if (counts.length != 1 || counts.single != audio.playCount) {
    error(
      TopikContentRule.audio,
      'group ${group.groupId} playCount ${audio.playCount}; expected $counts',
    );
  }
}

void _checkAssets(
  TopikTest test,
  bool Function(String assetPath) assetExists,
  _Report error,
) {
  final paths = <String>{
    ?test.audioAsset,
    for (final group in test.groups) ?group.passage?.image,
    for (final question in test.questions)
      for (final option in question.options) ?option.image,
  };
  for (final path in paths) {
    if (!assetExists(path))
      error(TopikContentRule.assets, 'missing file $path');
  }
}
