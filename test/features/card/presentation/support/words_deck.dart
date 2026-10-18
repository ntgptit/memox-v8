import '../../../../support/deck_fixtures.dart';
import '../../../../support/library_harness.dart';

/// Korean › Words, the leaf deck the card screens put their cards in; its
/// id.
Future<String> seedWordsDeck(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  return (await env.decks.sub(korean.id, 'Words')).id;
}
