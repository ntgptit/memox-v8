import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/app/app_bootstrap.dart';
import 'package:memox/app/app_root.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = buildAppContainer();
  final result = await startApp(container);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: AppRoot(initial: result),
    ),
  );
}
