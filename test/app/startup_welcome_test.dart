import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/startup_welcome.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/data/repositories/account_device_repository_impl.dart';
import 'package:memox/features/account/domain/models/local_library_model.dart';
import 'package:memox/features/account/domain/repositories/account_device_repository.dart';
import 'package:memox/features/account/domain/usecases/is_welcome_seen_use_case.dart';
import 'package:memox/features/account/presentation/providers/is_welcome_seen_use_case_provider.dart';
import 'package:memox/features/account/presentation/providers/welcome_due_provider.dart';

import '../support/auth_fakes.dart';
import '../support/test_database.dart';

final class _FailingDevice implements AccountDeviceRepository {
  @override
  Future<bool> isWelcomeSeen() async =>
      throw const UnknownDatabaseFailure(cause: 'disk');

  @override
  Future<void> markWelcomeSeen() async =>
      throw const UnknownDatabaseFailure(cause: 'disk');

  @override
  Future<LocalLibrary> countLibrary() async =>
      throw const UnknownDatabaseFailure(cause: 'disk');
}

void main() {
  late AppDatabase db;
  late AuthWorld world;

  // Two in-memory databases by design: the app's and the account world's.
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    db = openTestDatabase();
    world = AuthWorld()..boot();
  });
  tearDown(() async {
    await world.close();
    await db.close();
  });

  ProviderContainer containerWith(List<Override> overrides) {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db), ...overrides],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('a build that can sign in shows Welcome until it is answered', () async {
    final container = containerWith([
      accountCoordinatorProvider.overrideWithValue(world.coordinator),
    ]);

    await showWelcomeIfDue(container);
    expect(container.read(welcomeDueProvider), isTrue);

    await AccountDeviceRepositoryImpl(db).markWelcomeSeen();
    final next = containerWith([
      accountCoordinatorProvider.overrideWithValue(world.coordinator),
    ]);
    await showWelcomeIfDue(next);
    expect(next.read(welcomeDueProvider), isFalse);
  });

  test('a build with no Supabase project never shows Welcome', () async {
    final container = containerWith([
      accountCoordinatorProvider.overrideWithValue(null),
    ]);

    await showWelcomeIfDue(container);

    expect(container.read(welcomeDueProvider), isFalse);
  });

  test('a failed read shows nothing', () async {
    final container = containerWith([
      accountCoordinatorProvider.overrideWithValue(world.coordinator),
      isWelcomeSeenUseCaseProvider.overrideWithValue(
        IsWelcomeSeenUseCase(_FailingDevice()),
      ),
    ]);

    await showWelcomeIfDue(container);

    expect(container.read(welcomeDueProvider), isFalse);
  });

  test('dismiss lets go at once, then stores the answer', () async {
    final container = containerWith([
      accountCoordinatorProvider.overrideWithValue(world.coordinator),
    ]);
    final due = container.read(welcomeDueProvider.notifier)..show();

    final saving = due.dismiss();
    expect(container.read(welcomeDueProvider), isFalse);
    await saving;

    expect(await AccountDeviceRepositoryImpl(db).isWelcomeSeen(), isTrue);
  });
}
