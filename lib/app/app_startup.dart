import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/features/study/presentation/providers/abandon_stale_sessions_use_case_provider.dart';

/// Work that must finish before the first frame (spec D9): sessions left
/// open on an earlier day close as `interrupted` before any screen can offer
/// one to Continue (BR-STUDY-072).
Future<void> runStartupTasks(ProviderContainer container) =>
    container.read(abandonStaleSessionsUseCaseProvider)();
