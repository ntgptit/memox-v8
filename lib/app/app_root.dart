import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/app_bootstrap.dart';
import 'package:memox/app/startup_failure_app.dart';
import 'package:memox/core/logging/di/logging_providers.dart';

/// What `main` runs: the app once the start is ready, else the recovery
/// screen (DEV-195), whose Retry runs the start again from the database on
/// and whose Send report ships the log buffer, where the open's error went.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key, required this.initial});

  final StartupResult initial;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late StartupResult _result = widget.initial;
  var _isRetrying = false;
  var _isReportQueued = false;

  ProviderContainer get _container =>
      ProviderScope.containerOf(context, listen: false);

  Future<void> _retry() async {
    setState(() => _isRetrying = true);
    final result = await retryStartApp(_container);
    if (!mounted) return;
    setState(() {
      _result = result;
      _isRetrying = false;
    });
  }

  Future<void> _sendReport() async {
    setState(() => _isReportQueued = true);
    await _container.read(logSchedulerProvider)?.syncNow();
  }

  @override
  Widget build(BuildContext context) => switch (_result) {
    StartupReady(:final settings) => MemoxApp(initialSettings: settings),
    final StartupDatabaseUnavailable failure => StartupFailureApp(
      failure: failure,
      isRetrying: _isRetrying,
      isReportQueued: _isReportQueued,
      onRetry: _retry,
      onSendReport: _sendReport,
    ),
  };
}
