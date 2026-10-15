import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_test_list_choice_provider.g.dart';

/// Screen 35's section and sort.
typedef TopikTestListChoice = ({TopikSection section, TopikTestOrder order});

/// Per level, reset when the screen closes (detail file 35, rulings).
@riverpod
class TopikTestListChoiceNotifier extends _$TopikTestListChoiceNotifier {
  @override
  TopikTestListChoice build(TopikLevel level) =>
      (section: TopikSection.reading, order: TopikTestOrder.roundDescending);

  void pickSection(TopikSection section) =>
      state = (section: section, order: state.order);

  void pickOrder(TopikTestOrder order) =>
      state = (section: state.section, order: order);
}
