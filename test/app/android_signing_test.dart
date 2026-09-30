import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// SB-A4 known limit: CI APKs are signed by the release key from
// `android/key.properties` (written by the Build APK workflow from its
// secrets), so native Google sign-in can match a registered SHA-1. Without
// the file the release build keeps the debug key, so `flutter run --release`
// works on any machine.
void main() {
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();

  test('the release build reads android/key.properties', () {
    expect(gradle, contains('rootProject.file("key.properties")'));
    expect(gradle, contains('create("release")'));
    for (final key in [
      'storeFile',
      'storePassword',
      'keyAlias',
      'keyPassword',
    ]) {
      expect(gradle, contains('"$key"'), reason: key);
    }
  });

  test('without key.properties the release build keeps the debug key', () {
    expect(
      gradle,
      matches(
        RegExp(
          r'signingConfig\s*=\s*if\s*\(\s*hasReleaseKey\s*\)\s*'
          r'signingConfigs\.getByName\("release"\)\s*'
          r'else\s*signingConfigs\.getByName\("debug"\)',
        ),
      ),
    );
  });

  test('no keystore or key.properties is committed', () {
    final tracked =
        Process.runSync('git', ['ls-files', 'android']).stdout as String;
    final secrets = tracked
        .split('\n')
        .where(
          (path) =>
              path.endsWith('key.properties') ||
              path.endsWith('.jks') ||
              path.endsWith('.keystore'),
        );

    expect(secrets, isEmpty);
  });

  test('Build APK writes key.properties outside the checkout and prints '
      'the signer', () {
    final workflow = File('.github/workflows/build-apk.yml').readAsStringSync();

    expect(workflow, contains('ANDROID_KEYSTORE_BASE64'));
    expect(workflow, contains(r'$RUNNER_TEMP/memox-release.jks'));
    expect(workflow, contains('android/key.properties'));
    expect(workflow, contains('apksigner'));
  });
}
