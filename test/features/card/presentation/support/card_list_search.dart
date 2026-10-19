import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/states/card_search_open_state.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';

/// The app bar's search action (screen 07): here, straight on the state.
Future<void> openCardSearch(WidgetTester tester, String deckId) async {
  ProviderScope.containerOf(tester.element(find.byType(CardListSectionWidget)))
      .read(cardSearchOpenProvider(deckId).notifier)
      .open();
  await tester.pumpAndSettle();
}
