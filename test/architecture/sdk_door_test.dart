import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The SDKs that only their door files may import (auth spec §5, plan
/// rulings 18–19). Paths are prefixes.
const _doors = <String, List<String>>{
  'package:supabase_flutter/': [
    'lib/core/auth/supabase_',
    'lib/core/network/',
    'lib/core/sync/supabase_sync_api.dart',
  ],
  'package:gotrue/': ['lib/core/auth/supabase_'],
  'package:google_sign_in/': ['lib/core/auth/google_'],
  'package:flutter_secure_storage/': ['lib/core/auth/secure_'],
};

final _import = RegExp(r"^\s*import\s+'([^']+)'", multiLine: true);

/// Each file of [sources] (path → text) that imports an SDK outside its
/// doors.
List<String> doorViolations(Map<String, String> sources) => [
  for (final MapEntry(key: path, value: text) in sources.entries)
    for (final match in _import.allMatches(text))
      for (final MapEntry(key: package, value: doors) in _doors.entries)
        if (match.group(1)!.startsWith(package) && !doors.any(path.startsWith))
          '$path imports ${match.group(1)}',
];

void main() {
  test('an SDK imported outside its door is found', () {
    final found = doorViolations({
      'lib/features/x/data/x.dart':
          "import 'package:supabase_flutter/supabase_flutter.dart';",
      'lib/core/auth/account_coordinator.dart':
          "import 'package:google_sign_in/google_sign_in.dart';",
      'lib/core/auth/supabase_auth_gateway.dart':
          "import 'package:supabase_flutter/supabase_flutter.dart';",
      'lib/core/auth/secure_secret_store.dart': "import 'package:flutter_secure_storage/flutter_secure_storage.dart';",
    });

    expect(found, hasLength(2));
  });

  test('lib/ reaches the SDKs only through their doors', () {
    final sources = {
      for (final file in Directory(
        'lib',
      ).listSync(recursive: true).whereType<File>())
        if (file.path.endsWith('.dart') && !file.path.endsWith('.g.dart'))
          file.path.replaceAll(r'\', '/'): file.readAsStringSync(),
    };

    expect(doorViolations(sources), isEmpty);
  });
}
