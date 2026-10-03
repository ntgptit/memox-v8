import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// §9 row 62: Android 14+ previews system Back only when the app opts in.
void main() {
  test('the application opts in to predictive Back', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    final application = RegExp(r'<application\b[^>]*>')
        .firstMatch(manifest)!
        .group(0)!;

    expect(application, contains('android:enableOnBackInvokedCallback="true"'));
  });

  // ADR-015: sync calls Supabase; only debug and profile get INTERNET from Flutter.
  test('the release build may use the network', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    expect(
      manifest,
      contains('<uses-permission android:name="android.permission.INTERNET"/>'),
    );
  });

  // FE-D3 spec D4: memox://app/<route> opens the route from the OS.
  test('MainActivity takes memox://app deep links', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    final filter = RegExp(
      r'<intent-filter>(?:(?!</intent-filter>).)*android\.intent\.action\.VIEW'
      r'(?:(?!</intent-filter>).)*</intent-filter>',
      dotAll: true,
    ).firstMatch(manifest)?.group(0);

    expect(filter, isNotNull);
    expect(filter, contains('android.intent.category.DEFAULT'));
    expect(filter, contains('android.intent.category.BROWSABLE'));
    expect(filter, contains('android:scheme="memox"'));
    expect(filter, contains('android:host="app"'));
  });

  test('the launch window paints each theme surface (SP1 §5.2)', () {
    String read(String path) =>
        File('android/app/src/main/res/$path').readAsStringSync();
    expect(read('values/colors.xml'), contains('#F7F9FE'));
    expect(read('values-night/colors.xml'), contains('#0A0E27'));
    for (final path in [
      'drawable/launch_background.xml',
      'drawable-v21/launch_background.xml',
    ]) {
      expect(read(path), contains('@color/launch_surface'));
    }
    for (final path in [
      'values-v31/styles.xml',
      'values-night-v31/styles.xml',
    ]) {
      expect(read(path), contains('windowSplashScreenBackground'));
    }
  });
}
