import 'package:memox/features/topik/domain/models/topik_content_issue_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_group_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_text_model.dart';

/// What reading one content file gave: the test, or null when [issues] holds
/// an error.
typedef TopikTestRead = ({TopikTest? test, List<TopikContentIssue> issues});

/// The test a decoded content file describes (spec 2026-10-15 §4.1). Shape
/// problems — a missing field, a wrong type, an unknown code, a translation
/// without both languages (BR-TOPIK-006) — are collected with their path, all
/// of them, instead of thrown. The cross-field rules are `checkTopikTest`'s.
/// [origin] names the file in issues found before a test id is read.
TopikTestRead topikTestOf(Object? json, {String origin = '?'}) {
  final reader = _Reader(origin);
  if (json is! Map<String, Object?>) {
    reader.fail(TopikContentRule.shape, r'$', 'is not an object');
    return (test: null, issues: reader.issues);
  }
  final test = reader.test(json);
  final hasError = reader.issues.any((issue) => issue.isError);
  return (test: hasError ? null : test, issues: reader.issues);
}

final class _Reader {
  _Reader(this._origin) : _testId = _origin;

  final String _origin;
  final List<TopikContentIssue> issues = [];
  String _testId;

  void fail(TopikContentRule rule, String path, String what) =>
      issues.add(TopikContentIssue.error(rule, _testId, '$path: $what'));

  TopikTest? test(Map<String, Object?> json) {
    _testId = _textOrNull(json['testId']) ?? _origin;
    final schemaVersion = integer(json, 'schemaVersion', r'$');
    final contentVersion = integer(json, 'contentVersion', r'$');
    final testId = text(json, 'testId', r'$');
    final level = TopikLevel.ofCode(json['level']);
    if (level == null) {
      fail(TopikContentRule.shape, r'$.level', 'unknown level');
    }
    final round = integer(json, 'round', r'$');
    final section = TopikSection.ofCode(json['section']);
    if (section == null) {
      fail(TopikContentRule.shape, r'$.section', 'unknown section');
    }
    final format = text(json, 'format', r'$');
    final form = text(json, 'form', r'$');
    final titleKo = text(json, 'titleKo', r'$');
    final timeLimit = integer(json, 'officialTimeLimitSec', r'$');
    final source = _source(json['source']);
    final audioAsset = _audioAsset(json['assets']);
    final groups = _list(json['groups'], r'$.groups', _group);
    final questions = _list(json['questions'], r'$.questions', _question);
    if (schemaVersion == null || contentVersion == null || testId == null) {
      return null;
    }
    if (level == null || round == null || section == null) return null;
    if (format == null || form == null || titleKo == null) return null;
    if (timeLimit == null || source == null) return null;
    if (groups == null || questions == null) return null;
    return TopikTest(
      schemaVersion: schemaVersion,
      contentVersion: contentVersion,
      testId: testId,
      level: level,
      round: round,
      section: section,
      format: format,
      form: form,
      titleKo: titleKo,
      officialTimeLimitSec: timeLimit,
      source: source,
      audioAsset: audioAsset,
      groups: groups,
      questions: questions..sort((a, b) => a.no.compareTo(b.no)),
    );
  }

  TopikSource? _source(Object? json) {
    const path = r'$.source';
    if (json is! Map<String, Object?>) {
      fail(TopikContentRule.shape, path, 'missing or not an object');
      return null;
    }
    final publishedBy = text(json, 'publishedBy', path);
    final url = text(json, 'url', path);
    final publishedAt = optionalText(json, 'publishedAt', path);
    if (publishedBy == null || url == null) return null;
    return TopikSource(
      publishedBy: publishedBy,
      url: url,
      publishedAt: publishedAt,
    );
  }

  String? _audioAsset(Object? json) {
    if (json == null) return null;
    if (json is! Map<String, Object?>) {
      fail(TopikContentRule.shape, r'$.assets', 'not an object');
      return null;
    }
    return optionalText(json, 'audio', r'$.assets');
  }

  TopikQuestionGroup? _group(Object? json, String path) {
    if (json is! Map<String, Object?>) {
      fail(TopikContentRule.shape, path, 'not an object');
      return null;
    }
    final groupId = text(json, 'groupId', path);
    final where = groupId == null
        ? path
        : r'$.groups['
              '$groupId]';
    final instructionKo = text(json, 'instructionKo', where);
    final questionNos = _list(
      json['questionNos'],
      '$where.questionNos',
      _number,
    );
    final passage = _passage(json['passage'], '$where.passage');
    final audio = _groupAudio(json['audio'], '$where.audio');
    final script = optionalText(json, 'script', where);
    final scriptTranslation = localized(
      json['scriptTranslation'],
      '$where.scriptTranslation',
    );
    if (groupId == null || instructionKo == null || questionNos == null) {
      return null;
    }
    return TopikQuestionGroup(
      groupId: groupId,
      instructionKo: instructionKo,
      questionNos: questionNos,
      passage: passage,
      audio: audio,
      script: script,
      scriptTranslation: scriptTranslation,
    );
  }

  TopikPassage? _passage(Object? json, String path) {
    if (json == null) return null;
    if (json is! Map<String, Object?>) {
      fail(TopikContentRule.shape, path, 'not an object');
      return null;
    }
    return TopikPassage(
      textKo: optionalText(json, 'textKo', path),
      image: optionalText(json, 'image', path),
    );
  }

  TopikGroupAudio? _groupAudio(Object? json, String path) {
    if (json == null) return null;
    if (json is! Map<String, Object?>) {
      fail(TopikContentRule.shape, path, 'not an object');
      return null;
    }
    final startMs = integer(json, 'startMs', path);
    final endMs = integer(json, 'endMs', path);
    final playCount = integer(json, 'playCount', path);
    if (startMs == null || endMs == null || playCount == null) return null;
    return TopikGroupAudio(
      startMs: startMs,
      endMs: endMs,
      playCount: playCount,
    );
  }

  TopikQuestion? _question(Object? json, String path) {
    if (json is! Map<String, Object?>) {
      fail(TopikContentRule.shape, path, 'not an object');
      return null;
    }
    final no = integer(json, 'no', path);
    final where = no == null
        ? path
        : r'$.questions[no '
              '$no]';
    final groupId = text(json, 'groupId', where);
    final type = TopikQuestionType.ofCode(json['questionType']);
    if (type == null) {
      fail(TopikContentRule.shape, '$where.questionType', 'unknown type');
    }
    final points = integer(json, 'points', where);
    final stemKo = text(json, 'stemKo', where);
    final options = _list(json['options'], '$where.options', _option);
    final answerIdx = integer(json, 'answerIdx', where);
    final explanation = localized(json['explanation'], '$where.explanation');
    final translation = localized(json['translation'], '$where.translation');
    final words = _list(
      json['words'] ?? const <Object?>[],
      '$where.words',
      _word,
    );
    final grammars = _list(
      json['grammars'] ?? const <Object?>[],
      '$where.grammars',
      _grammar,
    );
    if (no == null || groupId == null || type == null || points == null) {
      return null;
    }
    if (stemKo == null || options == null || answerIdx == null) return null;
    if (words == null || grammars == null) return null;
    return TopikQuestion(
      no: no,
      groupId: groupId,
      questionType: type,
      points: points,
      stemKo: stemKo,
      options: options,
      answerIdx: answerIdx,
      explanation: explanation,
      translation: translation,
      words: words,
      grammars: grammars,
    );
  }

  TopikOption? _option(Object? json, String path) {
    if (json is! Map<String, Object?>) {
      fail(TopikContentRule.shape, path, 'not an object');
      return null;
    }
    final idx = integer(json, 'idx', path);
    if (idx == null) return null;
    return TopikOption(
      idx: idx,
      textKo: optionalText(json, 'textKo', path),
      image: optionalText(json, 'image', path),
    );
  }

  TopikWord? _word(Object? json, String path) {
    if (json is! Map<String, Object?>) {
      fail(TopikContentRule.shape, path, 'not an object');
      return null;
    }
    final ko = text(json, 'ko', path);
    final meaning = _meaning(json, path);
    if (ko == null || meaning == null) return null;
    return TopikWord(
      ko: ko,
      meaning: meaning,
      pos: optionalText(json, 'pos', path),
    );
  }

  TopikGrammar? _grammar(Object? json, String path) {
    if (json is! Map<String, Object?>) {
      fail(TopikContentRule.shape, path, 'not an object');
      return null;
    }
    final pattern = text(json, 'pattern', path);
    final meaning = _meaning(json, path);
    if (pattern == null || meaning == null) return null;
    return TopikGrammar(pattern: pattern, meaning: meaning);
  }

  /// A word's or grammar's `vi` and `en`, which sit on the object itself.
  TopikText? _meaning(Map<String, Object?> json, String path) =>
      localized({'vi': json['vi'], 'en': json['en']}, path);

  int? _number(Object? json, String path) {
    if (json is int) return json;
    fail(TopikContentRule.shape, path, 'not an integer');
    return null;
  }

  /// A multilingual object, or null when absent. Present, it needs both
  /// languages with something in them (BR-TOPIK-006).
  TopikText? localized(Object? json, String path) {
    if (json == null) return null;
    if (json is! Map<String, Object?>) {
      fail(TopikContentRule.shape, path, 'not an object');
      return null;
    }
    final vi = _textOrNull(json['vi']);
    final en = _textOrNull(json['en']);
    if (vi == null || en == null) {
      fail(TopikContentRule.languages, path, 'needs non-empty vi and en');
      return null;
    }
    return TopikText(vi: vi, en: en);
  }

  /// Every item of a list read by [item]; null when the list or any item is
  /// unreadable (each problem already reported).
  List<T>? _list<T>(
    Object? json,
    String path,
    T? Function(Object? item, String path) item,
  ) {
    if (json is! List<Object?>) {
      fail(TopikContentRule.shape, path, 'missing or not a list');
      return null;
    }
    final items = <T>[];
    var isComplete = true;
    for (final (index, value) in json.indexed) {
      final read = item(value, '$path[$index]');
      if (read == null) {
        isComplete = false;
      } else {
        items.add(read);
      }
    }
    return isComplete ? items : null;
  }

  String? text(Map<String, Object?> json, String key, String path) {
    final value = _textOrNull(json[key]);
    if (value == null) {
      fail(TopikContentRule.shape, '$path.$key', 'missing or empty text');
    }
    return value;
  }

  String? optionalText(Map<String, Object?> json, String key, String path) {
    final value = json[key];
    if (value == null) return null;
    final text = _textOrNull(value);
    if (text == null) {
      fail(TopikContentRule.shape, '$path.$key', 'empty or not text');
    }
    return text;
  }

  int? integer(Map<String, Object?> json, String key, String path) {
    final value = json[key];
    if (value is int) return value;
    fail(TopikContentRule.shape, '$path.$key', 'missing or not an integer');
    return null;
  }
}

/// [value] when it is text with something in it.
String? _textOrNull(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value;
}
