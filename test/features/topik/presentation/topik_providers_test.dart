import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_test_list_choice_provider.dart';

// Screen 35: the section and the sort live in the screen's provider and
// reset when the screen closes.
void main() {
  test('reading and newest round first, per level, reset on close', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = topikTestListChoiceProvider(TopikLevel.topik1);
    final subscription = container.listen(provider, (_, _) {});

    expect(subscription.read().section, TopikSection.reading);
    expect(subscription.read().order, TopikTestOrder.roundDescending);
    container.read(provider.notifier)
      ..pickSection(TopikSection.listening)
      ..pickOrder(TopikTestOrder.latestActivity);
    expect(subscription.read().section, TopikSection.listening);
    expect(subscription.read().order, TopikTestOrder.latestActivity);
    expect(
      container.read(topikTestListChoiceProvider(TopikLevel.topik2)).section,
      TopikSection.reading,
    );

    subscription.close();
    await pumpEventQueue();
    expect(container.read(provider).section, TopikSection.reading);
  });
}
