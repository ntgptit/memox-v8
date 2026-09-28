import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';

/// An unknown location, such as a deep link that leads nowhere (IT-NAV-005,
/// FE-D3 spec D5): no exception text, and one way back to the Library.
class RouteNotFoundScreen extends StatelessWidget {
  const RouteNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: MxEmptyState(
          icon: AppIcons.searchOff,
          title: l10n.routeNotFoundTitle,
          body: l10n.routeNotFoundBody,
          actionLabel: l10n.deckBackToLibrary,
          onAction: () => context.go(AppRoutes.decks),
        ),
      ),
    );
  }
}
