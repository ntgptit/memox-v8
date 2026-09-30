import 'package:memox/features/account/domain/models/local_library_model.dart';
import 'package:memox/features/account/domain/repositories/account_device_repository.dart';

/// Account UI spec §5.3, R6: what a merge would bring, or that there is
/// nothing to ask about.
final class CountLocalLibraryUseCase {
  const CountLocalLibraryUseCase(this._device);

  final AccountDeviceRepository _device;

  Future<LocalLibrary> call() => _device.countLibrary();
}
