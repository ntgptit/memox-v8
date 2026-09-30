import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Final review I4: the app signs in with codes and native Google only, so no
// link may carry a session into the SDK (a crafted memox://app link would
// otherwise swap the account under a running app).
void main() {
  test('the client never takes a session from a deep link', () {
    final source = File('lib/core/network/supabase_client.dart')
        .readAsStringSync();

    expect(source, contains('detectSessionInUri: false'));
  });
}
