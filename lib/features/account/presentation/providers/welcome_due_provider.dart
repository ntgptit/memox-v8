import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/features/account/presentation/providers/mark_welcome_seen_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'welcome_due_provider.g.dart';

/// Whether the router sends the app to Welcome (account UI spec U1, §4).
/// False until `main` finds `welcome_seen` unset on a build that can sign
/// in (plan ruling 3), and false again the moment Welcome is answered.
@Riverpod(keepAlive: true)
class WelcomeDue extends _$WelcomeDue {
  @override
  bool build() => false;

  /// Before the first frame: Welcome was never answered on this device.
  void show() => state = true;

  /// Every exit of Welcome (spec §5.1). The router lets go at once, then the
  /// answer is stored; a failed write only shows Welcome again next launch.
  Future<void> dismiss() async {
    state = false;
    try {
      await ref.read(markWelcomeSeenUseCaseProvider)();
    } on Failure catch (error, stackTrace) {
      appLogger.warning(
        'account.welcome_not_saved',
        category: LogCategory.state,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
