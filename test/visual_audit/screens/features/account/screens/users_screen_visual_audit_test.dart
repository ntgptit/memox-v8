import 'package:memox/core/auth/account_user.dart';
import 'package:memox/features/account/di/user_role_repository_provider.dart';
import 'package:memox/features/account/presentation/screens/users_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/users_fakes.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 33', (tester, env) async {
    final roles = FakeUserRoleRepository([
      managedUser('ann@example.com', role: AccountRole.admin),
      managedUser('bob@example.com'),
    ]);
    await auditProductionScreen(
      tester,
      screen: UsersScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        const UsersScreen(),
        brightness: brightness,
        textScale: scale,
        overrides: [userRoleRepositoryProvider.overrideWithValue(roles)],
      ),
    );
  });
}
