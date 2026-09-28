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
}
