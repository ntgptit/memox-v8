import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/data/datasources/account_device_dao.dart';
import 'package:memox/features/account/domain/models/local_library_model.dart';
import 'package:memox/features/account/domain/repositories/account_device_repository.dart';

/// The welcome flag is a device-only column, like the reminder's delivery
/// time: its write opens no business transaction, so the account's gate
/// (auth spec R3) never refuses it.
final class AccountDeviceRepositoryImpl implements AccountDeviceRepository {
  AccountDeviceRepositoryImpl(AppDatabase db) : _dao = AccountDeviceDao(db);

  final AccountDeviceDao _dao;

  @override
  Future<bool> isWelcomeSeen() => guardDatabase(_dao.welcomeSeen);

  @override
  Future<void> markWelcomeSeen() => guardDatabase(_dao.setWelcomeSeen);

  @override
  Future<LocalLibrary> countLibrary() => guardDatabase(() async {
    final (decks, cards) = await _dao.liveCounts();
    return LocalLibrary(decks: decks, cards: cards);
  });
}
