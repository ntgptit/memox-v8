import 'package:memox/features/deck/domain/entities/deck_entity.dart';

import '../../../../support/deck_fixtures.dart';
import '../../../../support/library_harness.dart';

/// The deck `Words` under the root `Korean`, which the transfer screens
/// import into and export from.
Future<DeckEntity> seedWordsDeck(LibraryEnv env) async {
  final root = await env.decks.root('Korean');
  return env.decks.sub(root.id, 'Words');
}
