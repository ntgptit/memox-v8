import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// The local stack's mailbox (spec 2026-10-05 §4): the code of the newest
/// MemoX mail to an address, read from the subject the templates set.
class Mailpit {
  Mailpit(this._base, {http.Client? client})
    : _client = client ?? http.Client();

  final Uri _base;
  final http.Client _client;

  static final _subject = RegExp(r'^(\d{6}) is your MemoX code$');
  static const _poll = Duration(milliseconds: 250);

  /// Waits for a message to [to] received after [after] and returns its
  /// six digits; an older message never answers.
  Future<String> codeFor(
    String to, {
    required DateTime after,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final code = await _newestCode(to, after);
      if (code != null) return code;
      await Future<void>.delayed(_poll);
    }
    throw TimeoutException('No MemoX code reached $to', timeout);
  }

  Future<String?> _newestCode(String to, DateTime after) async {
    final uri = _base.replace(
      path: '/api/v1/search',
      queryParameters: {'query': 'to:"$to"'},
    );
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw StateError('Mailpit answered ${response.statusCode} at $uri');
    }
    final messages =
        (jsonDecode(response.body) as Map<String, Object?>)['messages']
            as List<Object?>? ??
        const [];
    final fresh =
        messages
            .cast<Map<String, Object?>>()
            .where(
              (m) => DateTime.parse(m['Created']! as String).isAfter(after),
            )
            .toList()
          ..sort(
            (a, b) =>
                DateTime.parse(b['Created']! as String)
                    .compareTo(DateTime.parse(a['Created']! as String)),
          );
    if (fresh.isEmpty) return null;
    return _subject.firstMatch(fresh.first['Subject']! as String)?.group(1);
  }
}
