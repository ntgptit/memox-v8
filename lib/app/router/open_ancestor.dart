import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/app_routes.dart';

/// Ruling P2-L5: a breadcrumb tap, or Open in Library on screen 14 (spec
/// D7), pops the branch's stack back to [deckId], or to the root for null. A deck that is not on the stack (it was opened
/// from search) is pushed over the root instead, as its [levelOf] location:
/// a Library level, or a Progress level (FE-A9 D5). [leaving] is popped
/// without being matched: a route of [deckId]'s own, such as its entry.
void openAncestor(
  BuildContext context,
  String? deckId, {
  String Function(String deckId) levelOf = AppRoutes.deck,
  Route<Object?>? leaving,
}) {
  final router = GoRouter.of(context);
  var isOnStack = false;
  Navigator.of(context).popUntil((route) {
    if (route == leaving) return false;
    final arguments = route.settings.arguments;
    isOnStack =
        deckId != null &&
        arguments is Map &&
        arguments[AppRoutes.deckIdParam] == deckId;
    return isOnStack || route.isFirst;
  });
  if (deckId == null || isOnStack) return;
  unawaited(router.push(levelOf(deckId)));
}
