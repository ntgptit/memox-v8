# TOPIK content layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Read a TOPIK content pack (JSON) into immutable domain models and check it against BR-TOPIK-001…009 with one checker that both the future app loader and the gate's lint use (deliverable 3 of the TOPIK module, epic DEV-394).

**Architecture:** Pure-Dart domain models and rules in `lib/features/topik/domain/models/`; a hand-written JSON mapper in `lib/features/topik/data/mappers/` that reports shape problems as issues instead of throwing (the starter-decks pattern, but with the reasons kept); a `dart:io` lint in `tools/topik/` that walks a pack directory with the same mapper and checker, run by a gate test over `assets/topik/` and by `dart run` for the content repository. No Flutter, Riverpod or Drift import anywhere in this plan's `lib/` code, so the lint runs under plain `dart run`.

**Tech Stack:** Dart 3.13 (Flutter 3.47.5 SDK), `flutter_test`, `dart:convert`, `dart:io` (tools and tests only).

**Spec:** `docs/superpowers/specs/2026-10-15-topik-practice-design.md` (§4 Content). Rules: `docs/features/topik/rules/BR-TOPIK-001` … `BR-TOPIK-009`.

## Global Constraints

- Domain files end in `_model.dart` (guard `memox.naming.domain_file_role_suffix`); data files end in `_mapper.dart`.
- `lib/features/topik/domain/` imports nothing but `dart:core` and its own feature's domain (ADR-011; `test/architecture/boundary_rules.dart`).
- `topik` imports no other feature: its entry in `allowedFeatureImports` is `'topik': {}`, added in the commit that creates `lib/features/topik/`.
- Package imports only (`always_use_package_imports`); `strict-casts`, `strict-inference`, `strict-raw-types` are on — every JSON read is type-tested, never cast.
- No `print` (`avoid_print`): tools write with `stdout.writeln`.
- Messages printed by `tools/` are in English (CLAUDE.md, Language).
- A file stays under 500 logical lines (guard).
- Totals and limits come from BR-TOPIK-001/002/004: T1 listening 30 questions 1–30, points 3 or 4; T1 reading 40 questions 31–70, points 2 or 3; T2 listening and reading 50 questions 1–50, points 2; every section totals 100; play count T1 2, T2 questions 1–20 1, 21–50 2.
- `schemaVersion` is 1; `format` is `pbt`; `source.publishedBy` is `NIIED` (BR-TOPIK-007).
- Every multilingual object has non-empty `vi` **and** `en` (BR-TOPIK-006).
- A question-type mismatch with the default number map is a **warning**; every other broken rule is an **error** (BR-TOPIK-005, BR-TOPIK-008).
- Run `dart format <touched files>` before every commit; the gate fails on unformatted code.
- Commits name the epic: `feat(topik): DEV-394 …`, with the session's attribution lines.

## Review Focus

1. **Numbers written as decimals** (`"points": 2.0`) — `jsonDecode` yields a `double`; a reasonable author expects either acceptance or a clear message. The mapper reports a `shape` error naming the path (Task 2).
2. **Whitespace-only translations** (`"en": "  "`) — must fail BR-TOPIK-006 exactly like a missing `en` (Task 2).
3. **Questions listed out of order in the file** — a valid pack in any order; the model holds them sorted by number so later screens never re-sort (Task 2).
4. **A group naming a question that does not exist** (`questionNos: [21, 22]` with no 22) — a `groups` error, not a crash (Task 3).
5. **A manifest entry whose file is missing or is not JSON** — that entry fails with its path, and the lint still checks every other pack (Task 4).

---

### Task 1: Vocabulary — levels, sections, question types, exam layout, issues

**Files:**
- Create: `lib/features/topik/domain/models/topik_level_model.dart`
- Create: `lib/features/topik/domain/models/topik_section_model.dart`
- Create: `lib/features/topik/domain/models/topik_question_type_model.dart`
- Create: `lib/features/topik/domain/models/topik_exam_layout_model.dart`
- Create: `lib/features/topik/domain/models/topik_content_issue_model.dart`
- Modify: `test/architecture/boundary_rules.dart` (add `'topik': {},` after `'account': {},` in `allowedFeatureImports`)
- Test: `test/features/topik/domain/topik_exam_layout_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `enum TopikLevel { topik1, topik2 }` with `String code` and `static TopikLevel? ofCode(Object? code)`.
  - `enum TopikSection { listening, reading }` with `String code` and `static TopikSection? ofCode(Object? code)`.
  - `enum TopikQuestionType` (36 values) with `String code`, `TopikLevel level`, `TopikSection section`, `int defaultFirstNo`, `int defaultLastNo`, `static TopikQuestionType? ofCode(Object? code)`, `static TopikQuestionType? defaultFor(TopikLevel level, TopikSection section, int questionNo)`.
  - `final class TopikExamLayout` with `int questionCount`, `int firstQuestionNo`, `int lastQuestionNo`, `Set<int> allowedPoints`, `static const int sectionTotal = 100`, `static TopikExamLayout of(TopikLevel, TopikSection)`, `static int? playCountFor(TopikLevel, TopikSection, int questionNo)`.
  - `enum TopikContentRule { shape, identity, metadata, numbering, points, options, groups, audio, questionType, languages, assets, duplicate }`, `enum TopikIssueSeverity { error, warning }`, `final class TopikContentIssue` with `rule`, `severity`, `testId`, `detail`, `bool get isError`, named constructors `.error(...)` and `.warning(...)`.

- [ ] **Step 1: Write the failing test**

`test/features/topik/domain/topik_exam_layout_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_exam_layout_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

// BR-TOPIK-001, BR-TOPIK-002, BR-TOPIK-004, BR-TOPIK-005.

void main() {
  group('TopikExamLayout (BR-TOPIK-001, BR-TOPIK-002)', () {
    test('TOPIK I listening is 30 questions 1–30 worth 3 or 4', () {
      final layout = TopikExamLayout.of(TopikLevel.topik1, TopikSection.listening);
      expect(layout.questionCount, 30);
      expect(layout.firstQuestionNo, 1);
      expect(layout.lastQuestionNo, 30);
      expect(layout.allowedPoints, {3, 4});
    });

    test('TOPIK I reading is 40 questions numbered 31–70 worth 2 or 3', () {
      final layout = TopikExamLayout.of(TopikLevel.topik1, TopikSection.reading);
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
          TopikExamLayout.playCountFor(TopikLevel.topik1, TopikSection.listening, no),
          2,
        );
      }
    });

    test('TOPIK II listening plays 1–20 once and 21–50 twice', () {
      int? count(int no) =>
          TopikExamLayout.playCountFor(TopikLevel.topik2, TopikSection.listening, no);
      expect(count(1), 1);
      expect(count(20), 1);
      expect(count(21), 2);
      expect(count(50), 2);
    });

    test('reading has no play count', () {
      expect(
        TopikExamLayout.playCountFor(TopikLevel.topik2, TopikSection.reading, 1),
        isNull,
      );
    });
  });

  group('question types (BR-TOPIK-005)', () {
    test('each level and section has the brief §2.5 number of types', () {
      int countOf(TopikLevel level, TopikSection section) => TopikQuestionType.values
          .where((type) => type.level == level && type.section == section)
          .length;
      expect(countOf(TopikLevel.topik1, TopikSection.listening), 8);
      expect(countOf(TopikLevel.topik1, TopikSection.reading), 8);
      expect(countOf(TopikLevel.topik2, TopikSection.listening), 7);
      expect(countOf(TopikLevel.topik2, TopikSection.reading), 13);
    });

    test('every question number of every layout has exactly one default type', () {
      for (final level in TopikLevel.values) {
        for (final section in TopikSection.values) {
          final layout = TopikExamLayout.of(level, section);
          for (var no = layout.firstQuestionNo; no <= layout.lastQuestionNo; no++) {
            final matches = TopikQuestionType.values.where(
              (type) =>
                  type.level == level &&
                  type.section == section &&
                  no >= type.defaultFirstNo &&
                  no <= type.defaultLastNo,
            );
            expect(matches, hasLength(1), reason: '${level.code} ${section.code} $no');
            expect(TopikQuestionType.defaultFor(level, section, no), matches.single);
          }
        }
      }
    });

    test('codes are unique and read back', () {
      final codes = TopikQuestionType.values.map((type) => type.code).toSet();
      expect(codes, hasLength(TopikQuestionType.values.length));
      expect(TopikQuestionType.ofCode('R2_ordering'), TopikQuestionType.r2Ordering);
      expect(TopikQuestionType.ofCode('nope'), isNull);
      expect(TopikLevel.ofCode('topik2'), TopikLevel.topik2);
      expect(TopikSection.ofCode('reading'), TopikSection.reading);
      expect(TopikSection.ofCode('writing'), isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/domain/topik_exam_layout_test.dart`
Expected: FAIL — compile errors, `topik_exam_layout_model.dart` does not exist.

- [ ] **Step 3: Write the implementation**

`lib/features/topik/domain/models/topik_level_model.dart`:

```dart
/// The two TOPIK exams: TOPIK I (grades 1–2) and TOPIK II (grades 3–6)
/// (spec 2026-10-15 §4.1).
enum TopikLevel {
  topik1('topik1'),
  topik2('topik2');

  const TopikLevel(this.code);

  /// The value stored in content files and in the database.
  final String code;

  static TopikLevel? ofCode(Object? code) {
    for (final level in values) {
      if (level.code == code) return level;
    }
    return null;
  }
}
```

`lib/features/topik/domain/models/topik_section_model.dart`:

```dart
/// A section of the paper exam. Writing (쓰기) is Phase C and has no value
/// yet, so a writing file reads as unknown (spec 2026-10-15 §4.2).
enum TopikSection {
  listening('listening'),
  reading('reading');

  const TopikSection(this.code);

  /// The value stored in content files and in the database.
  final String code;

  static TopikSection? ofCode(Object? code) {
    for (final section in values) {
      if (section.code == code) return section;
    }
    return null;
  }
}
```

`lib/features/topik/domain/models/topik_question_type_model.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

/// The kind of a question (BR-TOPIK-005), with the question numbers it
/// usually covers on the published PBT papers 35–102. The range is a default,
/// not a rule: a question outside it is a warning, never a rejection.
enum TopikQuestionType {
  l1AnswerQuestion('L1_answer_question', TopikLevel.topik1, TopikSection.listening, 1, 4),
  l1NextUtterance('L1_next_utterance', TopikLevel.topik1, TopikSection.listening, 5, 6),
  l1Place('L1_place', TopikLevel.topik1, TopikSection.listening, 7, 10),
  l1Topic('L1_topic', TopikLevel.topik1, TopikSection.listening, 11, 14),
  l1Picture('L1_picture', TopikLevel.topik1, TopikSection.listening, 15, 16),
  l1MatchContent('L1_match_content', TopikLevel.topik1, TopikSection.listening, 17, 21),
  l1MainIdea('L1_main_idea', TopikLevel.topik1, TopikSection.listening, 22, 24),
  l1Paired('L1_paired', TopikLevel.topik1, TopikSection.listening, 25, 30),
  r1Topic('R1_topic', TopikLevel.topik1, TopikSection.reading, 31, 33),
  r1FillBlank('R1_fill_blank', TopikLevel.topik1, TopikSection.reading, 34, 39),
  r1NotMatch('R1_not_match', TopikLevel.topik1, TopikSection.reading, 40, 42),
  r1MatchContent('R1_match_content', TopikLevel.topik1, TopikSection.reading, 43, 45),
  r1MainIdea('R1_main_idea', TopikLevel.topik1, TopikSection.reading, 46, 48),
  r1Paired('R1_paired', TopikLevel.topik1, TopikSection.reading, 49, 56),
  r1Ordering('R1_ordering', TopikLevel.topik1, TopikSection.reading, 57, 58),
  r1LongPaired('R1_long_paired', TopikLevel.topik1, TopikSection.reading, 59, 70),
  l2PictureGraph('L2_picture_graph', TopikLevel.topik2, TopikSection.listening, 1, 3),
  l2NextUtterance('L2_next_utterance', TopikLevel.topik2, TopikSection.listening, 4, 8),
  l2NextAction('L2_next_action', TopikLevel.topik2, TopikSection.listening, 9, 12),
  l2MatchContent('L2_match_content', TopikLevel.topik2, TopikSection.listening, 13, 16),
  l2MainIdea('L2_main_idea', TopikLevel.topik2, TopikSection.listening, 17, 20),
  l2Paired('L2_paired', TopikLevel.topik2, TopikSection.listening, 21, 36),
  l2PairedAdvanced('L2_paired_advanced', TopikLevel.topik2, TopikSection.listening, 37, 50),
  r2GrammarBlank('R2_grammar_blank', TopikLevel.topik2, TopikSection.reading, 1, 2),
  r2SimilarExpression('R2_similar_expression', TopikLevel.topik2, TopikSection.reading, 3, 4),
  r2AdTopic('R2_ad_topic', TopikLevel.topik2, TopikSection.reading, 5, 8),
  r2MatchContent('R2_match_content', TopikLevel.topik2, TopikSection.reading, 9, 12),
  r2Ordering('R2_ordering', TopikLevel.topik2, TopikSection.reading, 13, 15),
  r2ParagraphBlank('R2_paragraph_blank', TopikLevel.topik2, TopikSection.reading, 16, 18),
  r2Paired('R2_paired', TopikLevel.topik2, TopikSection.reading, 19, 24),
  r2Headline('R2_headline', TopikLevel.topik2, TopikSection.reading, 25, 27),
  r2ComplexBlank('R2_complex_blank', TopikLevel.topik2, TopikSection.reading, 28, 31),
  r2MatchContentMid('R2_match_content_mid', TopikLevel.topik2, TopikSection.reading, 32, 34),
  r2Theme('R2_theme', TopikLevel.topik2, TopikSection.reading, 35, 38),
  r2SentenceInsert('R2_sentence_insert', TopikLevel.topik2, TopikSection.reading, 39, 41),
  r2LongPaired('R2_long_paired', TopikLevel.topik2, TopikSection.reading, 42, 50);

  const TopikQuestionType(
    this.code,
    this.level,
    this.section,
    this.defaultFirstNo,
    this.defaultLastNo,
  );

  /// The value stored in content files and answer snapshots.
  final String code;
  final TopikLevel level;
  final TopikSection section;
  final int defaultFirstNo;
  final int defaultLastNo;

  static TopikQuestionType? ofCode(Object? code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }

  /// The type question [questionNo] usually has, or null outside the layout.
  static TopikQuestionType? defaultFor(
    TopikLevel level,
    TopikSection section,
    int questionNo,
  ) {
    for (final type in values) {
      if (type.level != level || type.section != section) continue;
      if (questionNo < type.defaultFirstNo) continue;
      if (questionNo > type.defaultLastNo) continue;
      return type;
    }
    return null;
  }
}
```

`lib/features/topik/domain/models/topik_exam_layout_model.dart`:

```dart
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
```

`lib/features/topik/domain/models/topik_content_issue_model.dart`:

```dart
/// The rule a content problem breaks, one per row of spec 2026-10-15 §4.2.
enum TopikContentRule {
  /// The JSON is not the shape the schema describes.
  shape,
  identity,
  metadata,
  numbering,
  points,
  options,
  groups,
  audio,
  questionType,
  languages,
  assets,

  /// Two packs share one test id.
  duplicate,
}

/// An error rejects the test (BR-TOPIK-008); a warning is reported only.
enum TopikIssueSeverity { error, warning }

/// One problem found in a content pack. [detail] is English and is read by
/// the content author and the log, never shown in the app (BR-CORE-005).
final class TopikContentIssue {
  const TopikContentIssue({
    required this.rule,
    required this.severity,
    required this.testId,
    required this.detail,
  });

  const TopikContentIssue.error(this.rule, this.testId, this.detail)
      : severity = TopikIssueSeverity.error;

  const TopikContentIssue.warning(this.rule, this.testId, this.detail)
      : severity = TopikIssueSeverity.warning;

  final TopikContentRule rule;
  final TopikIssueSeverity severity;

  /// The test the problem belongs to, or the file path when no id was read.
  final String testId;
  final String detail;

  bool get isError => severity == TopikIssueSeverity.error;

  @override
  String toString() => '${severity.name} $testId [${rule.name}] $detail';
}
```

In `test/architecture/boundary_rules.dart`, inside `allowedFeatureImports`, after `'account': {},` add:

```dart
  'topik': {},
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/domain/topik_exam_layout_test.dart test/architecture`
Expected: PASS (all tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/topik test/features/topik test/architecture/boundary_rules.dart
git commit -m "feat(topik): DEV-394 levels, sections, question types and exam layout"
```

---

### Task 2: Content models and the JSON mapper

**Files:**
- Create: `lib/features/topik/domain/models/topik_text_model.dart`
- Create: `lib/features/topik/domain/models/topik_question_model.dart`
- Create: `lib/features/topik/domain/models/topik_question_group_model.dart`
- Create: `lib/features/topik/domain/models/topik_test_model.dart`
- Create: `lib/features/topik/data/mappers/topik_test_mapper.dart`
- Create: `test/support/topik_content_fixtures.dart`
- Test: `test/features/topik/data/topik_test_mapper_test.dart`

**Interfaces:**
- Consumes (Task 1): `TopikLevel`, `TopikSection`, `TopikQuestionType`, `TopikExamLayout`, `TopikContentIssue`, `TopikContentRule`.
- Produces:
  - `final class TopikText { const TopikText({required String vi, required String en}); String vi; String en; }`
  - `final class TopikOption { int idx; String? textKo; String? image; }`, `final class TopikWord { String ko; TopikText meaning; String? pos; }`, `final class TopikGrammar { String pattern; TopikText meaning; }`, `final class TopikQuestion { int no; String groupId; TopikQuestionType questionType; int points; String stemKo; List<TopikOption> options; int answerIdx; TopikText? explanation; TopikText? translation; List<TopikWord> words; List<TopikGrammar> grammars; }`
  - `final class TopikPassage { String? textKo; String? image; }`, `final class TopikGroupAudio { int startMs; int endMs; int playCount; }`, `final class TopikQuestionGroup { String groupId; String instructionKo; List<int> questionNos; TopikPassage? passage; TopikGroupAudio? audio; String? script; TopikText? scriptTranslation; }`
  - `enum TopikContentTag { explanation, translation, words, grammars, script }`, `final class TopikSource { String publishedBy; String url; String? publishedAt; }`, `final class TopikTest { int schemaVersion; int contentVersion; String testId; TopikLevel level; int round; TopikSection section; String format; String form; String titleKo; int officialTimeLimitSec; TopikSource source; String? audioAsset; List<TopikQuestionGroup> groups; List<TopikQuestion> questions /* sorted by no */; Set<TopikContentTag> get contentTags; }`
  - `typedef TopikTestRead = ({TopikTest? test, List<TopikContentIssue> issues});` and `TopikTestRead topikTestOf(Object? json)` — `test` is null exactly when `issues` has an error.
  - Test support: `Map<String, Object?> topikTestJson({TopikLevel level = TopikLevel.topik2, TopikSection section = TopikSection.reading, int round = 96})`, `Map<String, Object?> questionJson(Map<String, Object?> test, int no)`, `Map<String, Object?> groupJson(Map<String, Object?> test, String groupId)`, `const String topikFixtureAudioAsset`.

- [ ] **Step 1: Write the fixture builder**

`test/support/topik_content_fixtures.dart`:

```dart
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

/// A valid test as decoded JSON. The last two questions share one group;
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
  String groupIdOf(int no) => no >= pairStart ? 'g$pairStart-${numbers.last}' : 'g$no';
  final groupIds = <String>[];
  for (final no in numbers) {
    final id = groupIdOf(no);
    if (!groupIds.contains(id)) groupIds.add(id);
  }
  final isListening = section == TopikSection.listening;
  return {
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
              'playCount': TopikExamLayout.playCountFor(level, section, numbers
                  .firstWhere((no) => groupIdOf(no) == id))!,
            },
          if (isListening) 'script': '남자: 안녕하세요. 여자: 네.',
          if (isListening) 'scriptTranslation': {'vi': 'Xin chào.', 'en': 'Hello.'},
        },
    ],
    'questions': [
      for (final no in numbers)
        {
          'no': no,
          'groupId': groupIdOf(no),
          'questionType': TopikQuestionType.defaultFor(level, section, no)!.code,
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
  };
}

/// TOPIK I listening: the first ten questions 4, the rest 3 (40 + 60).
/// TOPIK I reading: the first twenty 3, the rest 2 (60 + 40). TOPIK II: 2.
int _pointsOf(TopikLevel level, TopikSection section, int no, TopikExamLayout layout) {
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
    (test['groups']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .firstWhere((group) => group['groupId'] == groupId);
```

- [ ] **Step 2: Write the failing mapper test**

`test/features/topik/data/topik_test_mapper_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/data/mappers/topik_test_mapper.dart';
import 'package:memox/features/topik/domain/models/topik_content_issue_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';

import '../../../support/topik_content_fixtures.dart';

// Spec 2026-10-15 §4.1; BR-TOPIK-003, BR-TOPIK-006, BR-TOPIK-009.

List<TopikContentRule> _rulesOf(TopikTestRead read) =>
    [for (final issue in read.issues) issue.rule];

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
    expect(test.questions.first.questionType, TopikQuestionType.l1AnswerQuestion);
    expect(test.questions.first.options.map((option) => option.idx), [1, 2, 3, 4]);
    expect(test.questions.first.explanation!.en, 'Explanation.');
    expect(test.questions.first.words.single.meaning.vi, 'kế hoạch');
    expect(test.groups.last.questionNos, [29, 30]);
    expect(test.groups.first.audio!.playCount, 2);
  });

  test('content tags are derived from the data (BR-TOPIK-009)', () {
    final reading = topikTestOf(topikTestJson()).test!;
    expect(reading.contentTags, {TopikContentTag.explanation, TopikContentTag.words});
    final listening = topikTestOf(topikTestJson(section: TopikSection.listening)).test!;
    expect(
      listening.contentTags,
      {
        TopikContentTag.explanation,
        TopikContentTag.words,
        TopikContentTag.script,
        TopikContentTag.translation,
      },
    );
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
```

- [ ] **Step 3: Run test to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/data/topik_test_mapper_test.dart`
Expected: FAIL — compile errors, the models and the mapper do not exist.

- [ ] **Step 4: Write the models**

`lib/features/topik/domain/models/topik_text_model.dart`:

```dart
/// A text the content gives in Vietnamese and English; both are always
/// present and non-empty (BR-TOPIK-006).
final class TopikText {
  const TopikText({required this.vi, required this.en});

  final String vi;
  final String en;
}
```

`lib/features/topik/domain/models/topik_question_model.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/domain/models/topik_text_model.dart';

/// One of a question's four choices, numbered 1–4 like ①–④ (BR-TOPIK-003).
final class TopikOption {
  const TopikOption({required this.idx, this.textKo, this.image});

  final int idx;
  final String? textKo;

  /// An asset path, for picture questions.
  final String? image;
}

/// A word of the question with its meaning.
final class TopikWord {
  const TopikWord({required this.ko, required this.meaning, this.pos});

  final String ko;
  final TopikText meaning;

  /// Part of speech as the content writes it (`n`, `v`, …).
  final String? pos;
}

/// A grammar pattern of the question with its meaning.
final class TopikGrammar {
  const TopikGrammar({required this.pattern, required this.meaning});

  final String pattern;
  final TopikText meaning;
}

/// One question with its real number (BR-TOPIK-001) and official points
/// (BR-TOPIK-002).
final class TopikQuestion {
  const TopikQuestion({
    required this.no,
    required this.groupId,
    required this.questionType,
    required this.points,
    required this.stemKo,
    required this.options,
    required this.answerIdx,
    this.explanation,
    this.translation,
    this.words = const [],
    this.grammars = const [],
  });

  final int no;
  final String groupId;
  final TopikQuestionType questionType;
  final int points;
  final String stemKo;
  final List<TopikOption> options;
  final int answerIdx;
  final TopikText? explanation;
  final TopikText? translation;
  final List<TopikWord> words;
  final List<TopikGrammar> grammars;
}
```

`lib/features/topik/domain/models/topik_question_group_model.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_text_model.dart';

/// The text or picture a group's questions share.
final class TopikPassage {
  const TopikPassage({this.textKo, this.image});

  final String? textKo;

  /// An asset path.
  final String? image;
}

/// The stretch of the section's audio file a listening group plays
/// (BR-TOPIK-004): `[startMs, endMs)`.
final class TopikGroupAudio {
  const TopikGroupAudio({
    required this.startMs,
    required this.endMs,
    required this.playCount,
  });

  final int startMs;
  final int endMs;

  /// Plays in the real exam; only Exam mode (Phase B) uses it.
  final int playCount;
}

/// Questions that share one instruction, passage and audio, such as
/// `[21～22]` (BR-TOPIK-004).
final class TopikQuestionGroup {
  const TopikQuestionGroup({
    required this.groupId,
    required this.instructionKo,
    required this.questionNos,
    this.passage,
    this.audio,
    this.script,
    this.scriptTranslation,
  });

  final String groupId;
  final String instructionKo;
  final List<int> questionNos;
  final TopikPassage? passage;
  final TopikGroupAudio? audio;

  /// The listening script (듣기 대본).
  final String? script;
  final TopikText? scriptTranslation;
}
```

`lib/features/topik/domain/models/topik_test_model.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_group_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

/// The supporting content a test carries, derived from its data
/// (BR-TOPIK-009).
enum TopikContentTag { explanation, translation, words, grammars, script }

/// Where a test was published (BR-TOPIK-007).
final class TopikSource {
  const TopikSource({
    required this.publishedBy,
    required this.url,
    this.publishedAt,
  });

  final String publishedBy;
  final String url;
  final String? publishedAt;
}

/// One published paper: a level, a round and a section (BR-TOPIK-001).
final class TopikTest {
  const TopikTest({
    required this.schemaVersion,
    required this.contentVersion,
    required this.testId,
    required this.level,
    required this.round,
    required this.section,
    required this.format,
    required this.form,
    required this.titleKo,
    required this.officialTimeLimitSec,
    required this.source,
    required this.groups,
    required this.questions,
    this.audioAsset,
  });

  final int schemaVersion;

  /// Goes up with every correction of this test's content (BR-TOPIK-007).
  final int contentVersion;
  final String testId;
  final TopikLevel level;
  final int round;
  final TopikSection section;
  final String format;

  /// The paper's form, such as `B-홀수형`: the answers fit this form only
  /// (BR-TOPIK-003).
  final String form;
  final String titleKo;
  final int officialTimeLimitSec;
  final TopikSource source;

  /// The section's audio file, for listening.
  final String? audioAsset;
  final List<TopikQuestionGroup> groups;

  /// Sorted by question number.
  final List<TopikQuestion> questions;

  Set<TopikContentTag> get contentTags => {
    if (questions.any((q) => q.explanation != null)) TopikContentTag.explanation,
    if (questions.any((q) => q.translation != null) ||
        groups.any((g) => g.scriptTranslation != null))
      TopikContentTag.translation,
    if (questions.any((q) => q.words.isNotEmpty)) TopikContentTag.words,
    if (questions.any((q) => q.grammars.isNotEmpty)) TopikContentTag.grammars,
    if (groups.any((g) => g.script != null)) TopikContentTag.script,
  };
}
```

- [ ] **Step 5: Write the mapper**

`lib/features/topik/data/mappers/topik_test_mapper.dart`:

```dart
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
TopikTestRead topikTestOf(Object? json) {
  final reader = _Reader();
  if (json is! Map<String, Object?>) {
    reader.fail(TopikContentRule.shape, r'$', 'is not an object');
    return (test: null, issues: reader.issues);
  }
  final test = reader.test(json);
  final hasError = reader.issues.any((issue) => issue.isError);
  return (test: hasError ? null : test, issues: reader.issues);
}

final class _Reader {
  final List<TopikContentIssue> issues = [];
  String _testId = '?';

  void fail(TopikContentRule rule, String path, String what) =>
      issues.add(TopikContentIssue.error(rule, _testId, '$path: $what'));

  TopikTest? test(Map<String, Object?> json) {
    _testId = _textOrNull(json['testId']) ?? '?';
    final schemaVersion = integer(json, 'schemaVersion', r'$');
    final contentVersion = integer(json, 'contentVersion', r'$');
    final testId = text(json, 'testId', r'$');
    final level = TopikLevel.ofCode(json['level']);
    if (level == null) fail(TopikContentRule.shape, r'$.level', 'unknown level');
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
    return TopikSource(publishedBy: publishedBy, url: url, publishedAt: publishedAt);
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
    final where = groupId == null ? path : r'$.groups[' '$groupId]';
    final instructionKo = text(json, 'instructionKo', where);
    final questionNos = _list(json['questionNos'], '$where.questionNos', _number);
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
    return TopikGroupAudio(startMs: startMs, endMs: endMs, playCount: playCount);
  }

  TopikQuestion? _question(Object? json, String path) {
    if (json is! Map<String, Object?>) {
      fail(TopikContentRule.shape, path, 'not an object');
      return null;
    }
    final no = integer(json, 'no', path);
    final where = no == null ? path : r'$.questions[no ' '$no]';
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
    final words = _list(json['words'] ?? const <Object?>[], '$where.words', _word);
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
    return TopikWord(ko: ko, meaning: meaning, pos: optionalText(json, 'pos', path));
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
```

Note on the test `points written as a decimal`: the path printed for question 7 is `$.questions[no 7].points`, and the test checks `contains('questions[no 7].points')`.

- [ ] **Step 6: Run the test to verify it passes**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/data/topik_test_mapper_test.dart`
Expected: PASS. If `the model keeps every field` fails on `test.groups.first.audio!.playCount`, the fixture's play count for TOPIK I is wrong — fix the fixture, not the assertion (BR-TOPIK-004 says 2).

- [ ] **Step 7: Commit**

```bash
git add lib/features/topik test/features/topik test/support/topik_content_fixtures.dart
git commit -m "feat(topik): DEV-394 content models and the JSON mapper"
```

---

### Task 3: The content check (BR-TOPIK-001…005, 007, 008)

**Files:**
- Create: `lib/features/topik/domain/models/topik_content_check_model.dart`
- Test: `test/features/topik/domain/topik_content_check_test.dart`

**Interfaces:**
- Consumes: Task 1 (`TopikExamLayout`, `TopikQuestionType`, `TopikContentIssue`, `TopikContentRule`), Task 2 (`TopikTest` and its parts; in tests, `topikTestOf`, `topikTestJson`, `questionJson`, `groupJson`, `topikFixtureAudioAsset`).
- Produces:
  - `List<TopikContentIssue> checkTopikTest(TopikTest test, {required bool Function(String assetPath) assetExists})` — every cross-field problem of one test; errors and warnings.
  - `List<TopikContentIssue> checkTopikCatalog(Iterable<TopikTest> tests)` — a `duplicate` error for every test whose `testId` an earlier test already has.

- [ ] **Step 1: Write the failing test**

`test/features/topik/domain/topik_content_check_test.dart`:

```dart
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
      expect(_errorRules(_check(json)), List.filled(4, TopikContentRule.metadata));
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
      final json = topikTestJson(level: TopikLevel.topik1, section: TopikSection.listening);
      questionJson(json, 30)['points'] = 1;
      final rules = _errorRules(_check(json));
      expect(rules, [TopikContentRule.points, TopikContentRule.points]);
    });

    test('a TOPIK II question worth 3 keeps the total only by luck', () {
      final json = topikTestJson();
      questionJson(json, 1)['points'] = 3;
      questionJson(json, 2)['points'] = 1;
      expect(_errorRules(_check(json)), [TopikContentRule.points, TopikContentRule.points]);
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
      groupJson(json, 'g2')['audio'] = {'startMs': 5000, 'endMs': 5000, 'playCount': 1};
      groupJson(json, 'g21')['audio'] = {'startMs': 0, 'endMs': 1000, 'playCount': 1};
      expect(_errorRules(_check(json)), List.filled(3, TopikContentRule.audio));
    });

    test('a listening test without its audio file', () {
      final json = topikTestJson(section: TopikSection.listening)..remove('assets');
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
      groupJson(json, 'g1')['audio'] = {'startMs': 0, 'endMs': 1000, 'playCount': 1};
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
      expect(_errorRules(issues), [TopikContentRule.assets, TopikContentRule.assets]);
      expect(issues.map((issue) => issue.detail).join(), contains(topikFixtureAudioAsset));
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/domain/topik_content_check_test.dart`
Expected: FAIL — `topik_content_check_model.dart` does not exist.

- [ ] **Step 3: Write the check**

`lib/features/topik/domain/models/topik_content_check_model.dart`:

```dart
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
  if (numbers.length != expected.length || numbers.toSet().length != numbers.length) {
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
  if (idxs.length != _optionIdxs.length || !idxs.toSet().containsAll(_optionIdxs)) {
    error(TopikContentRule.options, 'question ${question.no} needs options 1–4 once each');
  }
  if (question.options.any((option) => option.textKo == null && option.image == null)) {
    error(TopikContentRule.options, 'question ${question.no} has an option with no text or image');
  }
  if (!_optionIdxs.contains(question.answerIdx)) {
    error(TopikContentRule.options, 'question ${question.no} answerIdx must be 1–4');
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
  final usual = TopikQuestionType.defaultFor(test.level, test.section, question.no);
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
        error(TopikContentRule.audio, 'reading group ${group.groupId} carries audio');
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
    error(TopikContentRule.audio, 'group ${group.groupId} audio range is empty or reversed');
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
    if (!assetExists(path)) error(TopikContentRule.assets, 'missing file $path');
  }
}
```

`?value` inside a collection literal is a null-aware element (the package's SDK is `^3.13.4`; `lib/shared/widgets/mx_action_pair.dart` already uses it).

The test `a group spanning questions that play once and twice` leaves group `g21` with an empty `questionNos`; an empty group is not reported by `_checkGroups` (both sides empty) and `_checkGroupAudio` returns early for it, so the only audio error is the mixed play count of `g20`.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/domain/topik_content_check_test.dart test/features/topik`
Expected: PASS. When a test fails on the **count** of issues, print `_check(json)` and fix the check so each broken rule is reported exactly once — never loosen the expectation.

- [ ] **Step 5: Commit**

```bash
git add lib/features/topik/domain/models/topik_content_check_model.dart test/features/topik/domain/topik_content_check_test.dart
git commit -m "feat(topik): DEV-394 the content check shared by app and lint"
```

---

### Task 4: The lint — CLI, gate test and the empty pack manifest

**Files:**
- Create: `tools/topik/topik_lint.dart`
- Create: `assets/topik/manifest.json`
- Test: `test/tools/topik_lint_test.dart`
- Test: `test/tools/topik_content_assets_test.dart`

**Interfaces:**
- Consumes: `topikTestOf` (Task 2), `checkTopikTest`, `checkTopikCatalog` (Task 3), `TopikContentIssue` (Task 1).
- Produces:
  - `final class TopikLintReport { final List<TopikContentIssue> issues; final int testCount; bool get passes; }`
  - `TopikLintReport lintTopikContent({required Directory contentRoot, required Directory bundleRoot})` — reads `contentRoot/manifest.json` (`{"tests": ["<path relative to contentRoot>", …]}`), maps and checks every listed file, resolves asset paths against `bundleRoot`.
  - `void main(List<String> args)` — `dart run tools/topik/topik_lint.dart [contentRoot] [bundleRoot]`, defaults `assets/topik` and `.`; exit code 1 on any error.

- [ ] **Step 1: Write the failing tests**

`test/tools/topik_lint_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_content_issue_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

import '../../tools/topik/topik_lint.dart';
import '../support/topik_content_fixtures.dart';

// BR-TOPIK-008: the gate's lint runs the app's mapper and check.

void main() {
  late Directory bundle;
  late Directory content;

  setUp(() {
    bundle = Directory.systemTemp.createTempSync('topik_lint');
    content = Directory('${bundle.path}/assets/topik')..createSync(recursive: true);
    File('${bundle.path}/$topikFixtureAudioAsset')
      ..createSync(recursive: true)
      ..writeAsBytesSync([0]);
  });

  tearDown(() => bundle.deleteSync(recursive: true));

  void writePack(String path, Object? json) => File('${content.path}/$path')
    ..createSync(recursive: true)
    ..writeAsStringSync(json is String ? json : jsonEncode(json));

  void writeManifest(List<String> tests) =>
      writePack('manifest.json', {'tests': tests});

  TopikLintReport lint() =>
      lintTopikContent(contentRoot: content, bundleRoot: bundle);

  test('valid packs pass', () {
    writePack('topik2/96/reading.json', topikTestJson());
    writePack(
      'topik2/96/listening.json',
      topikTestJson(section: TopikSection.listening),
    );
    writeManifest(['topik2/96/reading.json', 'topik2/96/listening.json']);
    final report = lint();
    expect(report.issues, isEmpty);
    expect(report.testCount, 2);
    expect(report.passes, isTrue);
  });

  test('a broken pack fails while the others are still checked', () {
    final broken = topikTestJson(section: TopikSection.listening);
    questionJson(broken, 50)['points'] = 4;
    writePack('broken.json', broken);
    writePack('fine.json', topikTestJson());
    writeManifest(['broken.json', 'fine.json']);
    final report = lint();
    expect(report.passes, isFalse);
    expect(report.testCount, 2);
    expect(
      report.issues.map((issue) => issue.rule).toSet(),
      {TopikContentRule.points},
    );
  });

  test('a missing audio file fails on assets', () {
    File('${bundle.path}/$topikFixtureAudioAsset').deleteSync();
    writePack('listening.json', topikTestJson(section: TopikSection.listening));
    writeManifest(['listening.json']);
    expect(lint().issues.single.rule, TopikContentRule.assets);
  });

  test('a listed file that is missing or not JSON fails with its path', () {
    writePack('bad.json', '{ not json');
    writePack('fine.json', topikTestJson());
    writeManifest(['bad.json', 'gone.json', 'fine.json']);
    final report = lint();
    expect(report.testCount, 1);
    expect(report.issues.map((issue) => issue.testId), ['bad.json', 'gone.json']);
  });

  test('two packs with one test id fail on duplicate', () {
    writePack('a.json', topikTestJson());
    writePack('b.json', topikTestJson());
    writeManifest(['a.json', 'b.json']);
    expect(lint().issues.single.rule, TopikContentRule.duplicate);
  });

  test('a missing manifest fails', () {
    final report = lint();
    expect(report.passes, isFalse);
    expect(report.issues.single.testId, 'manifest.json');
  });
}
```

`test/tools/topik_content_assets_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tools/topik/topik_lint.dart';

// BR-TOPIK-008: no content pack that breaks a rule can merge.

void main() {
  test('every bundled TOPIK pack passes the content check', () {
    final report = lintTopikContent(
      contentRoot: Directory('assets/topik'),
      bundleRoot: Directory.current,
    );
    expect(report.issues.where((issue) => issue.isError), isEmpty);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/tools`
Expected: FAIL — `tools/topik/topik_lint.dart` does not exist.

- [ ] **Step 3: Write the lint and the manifest**

`assets/topik/manifest.json` (no pack yet; round 96 arrives in its own PR, spec D5):

```json
{
  "tests": []
}
```

`tools/topik/topik_lint.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:memox/features/topik/data/mappers/topik_test_mapper.dart';
import 'package:memox/features/topik/domain/models/topik_content_check_model.dart';
import 'package:memox/features/topik/domain/models/topik_content_issue_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';

/// Checks TOPIK content packs the way the app does (BR-TOPIK-008).
///
///     dart run tools/topik/topik_lint.dart [contentRoot] [bundleRoot]
///
/// contentRoot holds manifest.json (default assets/topik); asset paths in the
/// packs resolve against bundleRoot (default the current directory). Prints
/// one line per issue; exits 1 when any is an error.

const String _manifestName = 'manifest.json';

final class TopikLintReport {
  const TopikLintReport({required this.issues, required this.testCount});

  final List<TopikContentIssue> issues;

  /// Tests that were read, whether or not they pass.
  final int testCount;

  bool get passes => !issues.any((issue) => issue.isError);
}

TopikLintReport lintTopikContent({
  required Directory contentRoot,
  required Directory bundleRoot,
}) {
  final issues = <TopikContentIssue>[];
  final entries = _manifestEntries(contentRoot, issues);
  final tests = <TopikTest>[];
  for (final entry in entries) {
    final json = _decode(File('${contentRoot.path}/$entry'), entry, issues);
    if (json == null) continue;
    final read = topikTestOf(json);
    issues.addAll(read.issues);
    final test = read.test;
    if (test == null) continue;
    tests.add(test);
    issues.addAll(
      checkTopikTest(
        test,
        assetExists: (path) => File('${bundleRoot.path}/$path').existsSync(),
      ),
    );
  }
  issues.addAll(checkTopikCatalog(tests));
  return TopikLintReport(issues: issues, testCount: tests.length);
}

List<String> _manifestEntries(Directory root, List<TopikContentIssue> issues) {
  final json = _decode(File('${root.path}/$_manifestName'), _manifestName, issues);
  if (json == null) return const [];
  final tests = json is Map<String, Object?> ? json['tests'] : null;
  if (tests is! List<Object?> || tests.any((entry) => entry is! String)) {
    issues.add(
      const TopikContentIssue.error(
        TopikContentRule.shape,
        _manifestName,
        'tests must be a list of paths',
      ),
    );
    return const [];
  }
  return tests.cast<String>();
}

Object? _decode(File file, String name, List<TopikContentIssue> issues) {
  if (!file.existsSync()) {
    issues.add(TopikContentIssue.error(TopikContentRule.shape, name, 'file not found'));
    return null;
  }
  try {
    return jsonDecode(file.readAsStringSync());
  } on FormatException catch (error) {
    issues.add(
      TopikContentIssue.error(TopikContentRule.shape, name, 'not JSON: ${error.message}'),
    );
    return null;
  }
}

void main(List<String> args) {
  final contentRoot = Directory(args.isNotEmpty ? args[0] : 'assets/topik');
  final bundleRoot = Directory(args.length > 1 ? args[1] : '.');
  final report = lintTopikContent(contentRoot: contentRoot, bundleRoot: bundleRoot);
  for (final issue in report.issues) {
    stdout.writeln(issue);
  }
  final verdict = report.passes ? 'PASS' : 'FAIL';
  stdout.writeln('$verdict: ${report.testCount} test(s), ${report.issues.length} issue(s)');
  exitCode = report.passes ? 0 : 1;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/tools`
Expected: PASS.

- [ ] **Step 5: Prove the CLI runs under plain Dart**

Run: `dart run tools/topik/topik_lint.dart`
Expected output: `PASS: 0 test(s), 0 issue(s)` and exit code 0. If `dart run` fails because something under `lib/features/topik` pulls in `dart:ui` or Flutter, that import breaks the Global Constraints: remove it.

- [ ] **Step 6: Commit**

```bash
git add tools/topik test/tools assets/topik/manifest.json
git commit -m "feat(topik): DEV-394 content lint for the gate and the content repository"
```

---

### Task 5: Docs and the gate

**Files:**
- Modify: `docs/superpowers/specs/2026-10-15-topik-practice-design.md` (§3.2, §4.3, §4.4)
- Modify: `docs/features/topik/rules/BR-TOPIK-008-de-khong-hop-le-bi-loai-khi-nap.md` (Rule section, first bullet list intro)
- Modify: `docs/features/topik/README.md` (frontmatter `code:`)
- Regenerate: `docs/_generated/` via `python3 tools/docs/generate.py`

**Interfaces:**
- Consumes: the file paths and names of Tasks 1–4.
- Produces: docs that name the code as built.

- [ ] **Step 1: Align the spec with the code**

In the spec:
- §3.2 replace `The validator (\`TopikContentValidator\`) is pure Dart in \`domain/\`.` with `The checker (\`checkTopikTest\`, \`domain/models/topik_content_check_model.dart\`) is pure Dart in \`domain/\`.`
- §4.3 replace `dart run tools/topik/lint.dart <dir>` with `dart run tools/topik/topik_lint.dart [contentRoot] [bundleRoot]`.
- §4.4 replace `\`R2_*\` (14)` with `\`R2_*\` (13)` — the brief's table lists 13 TOPIK II reading types.

- [ ] **Step 2: Align BR-TOPIK-008**

Replace `(\`TopikContentValidator\`, thuần Dart trong domain)` with `(\`checkTopikTest\` trong \`lib/features/topik/domain/models/topik_content_check_model.dart\`, thuần Dart)`, and replace `một test duyệt mọi gói dưới \`assets/topik/\` bằng cùng bộ kiểm tra` with `\`test/tools/topik_content_assets_test.dart\` duyệt mọi gói dưới \`assets/topik/\` bằng cùng bộ kiểm tra qua \`tools/topik/topik_lint.dart\``.

- [ ] **Step 3: Name the code in the feature README**

In `docs/features/topik/README.md` frontmatter replace `code: []` with:

```yaml
code: [lib/features/topik/domain, lib/features/topik/data, tools/topik]
```

- [ ] **Step 4: Regenerate and check the docs**

Run: `python3 tools/docs/generate.py && python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), 0 warning(s)`.

- [ ] **Step 5: Run the gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh --changed`
Expected: `✓ mechanical gates passed`. In a fresh container run `flutter pub get` and `dart run build_runner build --delete-conflicting-outputs` first: generated code is gitignored and its absence fails `analyze` with unrelated errors.

- [ ] **Step 6: Commit**

```bash
git add docs
git commit -m "docs(topik): DEV-394 name the content check and lint as built"
```

## Out of this plan

- The app-side loader (asset data source, `TopikContentRepository`, its provider, the `topik.content_rejected` log) and the `pubspec.yaml` asset entry: the first plan of Phase 2 (deliverable 7), after the engineering design (deliverable 4).
- The round-96 pack: its own PR once the owner supplies the files.
- Checking an audio range against the file's real duration: needs decoding; the player clamps to the file (spec §5.5).
