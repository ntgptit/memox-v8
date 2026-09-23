import 'package:flutter/material.dart';
import 'package:memox/app/router/app_router.dart';

/// The app shell. Provider overrides, such as the retry policy, are set on
/// the `ProviderScope` in `main.dart`, not here.
class MemoxApp extends StatelessWidget {
  const MemoxApp({super.key});

  @override
  Widget build(BuildContext context) =>
      MaterialApp.router(routerConfig: appRouter);
}
