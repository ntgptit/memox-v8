import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/data/mappers/topik_content_pack_mapper.dart';
import 'package:memox/features/topik/domain/models/topik_content_issue_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

import '../../../support/topik_content_fixtures.dart';

// BR-TOPIK-008: the one pipeline the app loader and the lint share.

bool _everyAsset(String path) => true;

List<String> _acceptedIds(TopikContentLoad load) => [
  for (final test in load.accepted) test.testId,
];

void main() {
  test('valid packs are accepted in file order', () {
    final load = topikContentOf([
      (
        origin: 'listening.json',
        json: topikTestJson(section: TopikSection.listening),
      ),
      (origin: 'reading.json', json: topikTestJson()),
    ], assetExists: _everyAsset);
    expect(_acceptedIds(load), ['topik2-96-listening', 'topik2-96-reading']);
    expect(load.issues, isEmpty);
    expect(load.readCount, 2);
    expect(load.hasErrors, isFalse);
  });

  test('a pack that fails a check is rejected, the others still load', () {
    final broken = topikTestJson(section: TopikSection.listening);
    questionJson(broken, 50)['points'] = 4;
    final load = topikContentOf([
      (origin: 'broken.json', json: broken),
      (origin: 'fine.json', json: topikTestJson()),
    ], assetExists: _everyAsset);
    expect(_acceptedIds(load), ['topik2-96-reading']);
    expect(load.readCount, 2);
    expect(load.hasErrors, isTrue);
    expect(load.issues.map((issue) => issue.rule).toSet(), {
      TopikContentRule.points,
    });
  });

  test('the second valid copy of an id is a duplicate naming its file', () {
    final load = topikContentOf([
      (origin: 'a.json', json: topikTestJson()),
      (origin: 'b.json', json: topikTestJson()),
    ], assetExists: _everyAsset);
    expect(_acceptedIds(load), ['topik2-96-reading']);
    expect(load.issues.single.rule, TopikContentRule.duplicate);
    expect(load.issues.single.detail, contains('b.json'));
  });

  test('an invalid first copy does not block a valid second copy', () {
    final invalid = topikTestJson();
    questionJson(invalid, 1)['points'] = 5;
    final load = topikContentOf([
      (origin: 'a.json', json: invalid),
      (origin: 'b.json', json: topikTestJson()),
    ], assetExists: _everyAsset);
    expect(_acceptedIds(load), ['topik2-96-reading']);
    expect(
      load.issues.map((issue) => issue.rule),
      isNot(contains(TopikContentRule.duplicate)),
    );
  });

  test('a warning does not reject the pack', () {
    final json = topikTestJson();
    questionJson(json, 13)['questionType'] = 'R2_paragraph_blank';
    final load = topikContentOf([
      (origin: 'a.json', json: json),
    ], assetExists: _everyAsset);
    expect(_acceptedIds(load), ['topik2-96-reading']);
    expect(load.issues.single.severity, TopikIssueSeverity.warning);
    expect(load.hasErrors, isFalse);
  });

  test('a pack whose JSON is unreadable is not read', () {
    final load = topikContentOf([
      (origin: 'bad.json', json: 'nope'),
    ], assetExists: _everyAsset);
    expect(load.accepted, isEmpty);
    expect(load.readCount, 0);
    expect(load.issues.single.testId, 'bad.json');
  });

  test('file issues found before decoding are carried', () {
    const missing = TopikContentIssue.error(
      TopikContentRule.shape,
      'gone.json',
      'file not found',
    );
    final load = topikContentOf(
      const [],
      assetExists: _everyAsset,
      fileIssues: const [missing],
    );
    expect(load.issues, [missing]);
    expect(load.hasErrors, isTrue);
  });
}
