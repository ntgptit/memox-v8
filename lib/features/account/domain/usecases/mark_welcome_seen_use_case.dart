import 'package:memox/features/account/domain/repositories/account_device_repository.dart';

/// Account UI spec §5.1: every exit of Welcome answers it for good.
final class MarkWelcomeSeenUseCase {
  const MarkWelcomeSeenUseCase(this._device);

  final AccountDeviceRepository _device;

  Future<void> call() => _device.markWelcomeSeen();
}
