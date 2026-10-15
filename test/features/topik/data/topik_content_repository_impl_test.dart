import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/features/topik/data/mappers/topik_content_pack_mapper.dart';
import 'package:memox/features/topik/data/repositories/topik_content_repository_impl.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

import '../../../support/recording_log_sink.dart';
import '../../../support/topik_content_fixtures.dart';

// Spec §13.4: parsed once per app run; rejections logged once (BR-TOPIK-008).

TopikContentLoad _loadOf(List<TopikPackFile> files) =>
    topikContentOf(files, assetExists: (_) => true);

void main() {
  late RecordingLogSink log;
  late AppLogger previous;

  setUp(() {
    log = RecordingLogSink();
    previous = appLogger;
    AppLogger.install(AppLogger(sinks: [log]));
  });
  tearDown(() => AppLogger.install(previous));

  test('the catalog is the accepted tests, read once', () async {
    var reads = 0;
    final repository = TopikContentRepositoryImpl(
      load: () async {
        reads++;
        return _loadOf([(origin: 'r.json', json: topikTestJson())]);
      },
    );
    final first = await repository.catalog();
    final second = await repository.catalog();
    expect(first.map((test) => test.testId), ['topik2-96-reading']);
    expect(identical(first, second), isTrue);
    expect(reads, 1);
  });

  test(
    'each rejected pack is logged once, with its first error rule',
    () async {
      final broken = topikTestJson(section: TopikSection.listening);
      questionJson(broken, 50)['points'] = 4;
      final repository = TopikContentRepositoryImpl(
        load: () async => _loadOf([
          (origin: 'broken.json', json: broken),
          (origin: 'fine.json', json: topikTestJson()),
        ]),
      );
      await repository.catalog();
      await repository.catalog();
      final rejected = log.entries
          .where((entry) => entry.event == 'topik.content_rejected')
          .toList();
      expect(rejected, hasLength(1));
      expect(rejected.single.context['testId'], 'topik2-96-listening');
      expect(rejected.single.context['rule'], 'points');
    },
  );

  test('warnings are not logged as rejections', () async {
    final json = topikTestJson();
    questionJson(json, 13)['questionType'] = 'R2_paragraph_blank';
    await TopikContentRepositoryImpl(
      load: () async => _loadOf([(origin: 'r.json', json: json)]),
    ).catalog();
    expect(log.events, isNot(contains('topik.content_rejected')));
  });

  test('a failed read is not cached: the next call reads again', () async {
    var reads = 0;
    final repository = TopikContentRepositoryImpl(
      load: () async {
        reads++;
        if (reads == 1) throw StateError('asset manifest unreadable');
        return _loadOf([(origin: 'r.json', json: topikTestJson())]);
      },
    );
    await expectLater(repository.catalog(), throwsStateError);
    expect(await repository.catalog(), hasLength(1));
    expect(reads, 2);
  });
}
