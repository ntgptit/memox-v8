import 'package:memox/features/account/domain/repositories/account_device_repository.dart';

/// Account UI spec U1: whether Welcome still has to show on this device.
final class IsWelcomeSeenUseCase {
  const IsWelcomeSeenUseCase(this._device);

  final AccountDeviceRepository _device;

  Future<bool> call() => _device.isWelcomeSeen();
}
