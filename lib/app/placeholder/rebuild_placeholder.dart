import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/l10n/l10n_context.dart';

/// SP2 (spec 2026-10-04-sp2 §5.2): stands in for a screen until SP3 rebuilds
/// it. It names the screen and reads nothing; SP3b deletes this folder.
class RebuildPlaceholder extends StatelessWidget {
  const RebuildPlaceholder({super.key, required this.scrId});

  final String scrId;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Text(scrId), Text(context.l10n.placeholderBeingRebuilt)],
        ),
      ),
    ),
  );
}

/// A location no route matches: no exception text, one way to the Library.
class UnknownRoutePlaceholder extends StatelessWidget {
  const UnknownRoutePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.routeNotFoundTitle),
              Text(l10n.routeNotFoundBody),
              TextButton(
                onPressed: () => context.go(AppRoutes.decks),
                child: Text(l10n.deckBackToLibrary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
