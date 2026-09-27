import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/data/datasources/template_asset_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the bundled fixtures load, each whole, as spec D5 describes them',
    () async {
      final templates = await TemplateAssetDataSource(rootBundle).load();

      expect(
        [
          for (final t in templates)
            (
              t.templateId,
              t.title,
              t.cardCount,
              t.subDeckCount,
              t.suggestedScheduler,
              t.contentSource,
            ),
        ],
        [
          (
            'fixture.everyday-en-vi',
            'English → Vietnamese · Everyday',
            40,
            4,
            SchedulerType.eightBox,
            'Development fixture',
          ),
          (
            'fixture.hangul-basics',
            'Korean → Romanisation · Hangul basics',
            24,
            2,
            SchedulerType.sm2,
            'Development fixture',
          ),
        ],
      );
      expect(
        [for (final deck in templates.last.decks) deck.name],
        ['Consonants', 'Vowels'],
      );
      expect(templates.last.decks.first.cards.first.hint, '기역 (giyeok)');
    },
  );
}
