import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The foundation's one route: a placeholder with no product UI. The UI
/// sub-project replaces this shell (deck/card backend spec §12).
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('MemoX foundation'))),
    ),
  ],
);
