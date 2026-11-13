import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kdbx/kdbx.dart';
import 'package:openvalut/credential_server/credential_server.dart';

Future<Map<String, Object?>> _request({
  required int port,
  required String token,
  required String method,
  Map<String, Object?> params = const {},
}) async {
  final socket = await Socket.connect('127.0.0.1', port);
  try {
    socket.add(
      utf8.encode(
        '${json.encode({'id': 1, 'token': token, 'method': method, 'params': params})}\n',
      ),
    );
    final buffer = StringBuffer();
    await for (final chunk in socket) {
      buffer.write(utf8.decode(chunk));
      if (buffer.toString().contains('\n')) {
        break;
      }
    }
    return (json.decode(buffer.toString().trim()) as Map<Object?, Object?>)
        .cast<String, Object?>();
  } finally {
    socket.destroy();
  }
}

void main() {
  const token = 'test-token';
  late CredentialServer server;

  setUp(() async {
    server = CredentialServer(
      token: token,
      entries: () => [
        CredentialServerEntry(
          uuid: 'u1',
          label: 'GitHub',
          username: 'octocat',
          group: 'Root',
          file: 'Test',
        ),
        CredentialServerEntry(
          uuid: 'u2',
          label: 'Google',
          username: 'me@gmail.com',
          group: 'Root',
          file: 'Test',
        ),
      ],
      resolveReference: (reference) {
        if (reference == 'ov://Test/u1/password') {
          return 'gh-secret';
        }
        if (reference == 'ov://Test/u1/username') {
          return 'octocat';
        }
        if (reference == 'ov://Test/u1/totp') {
          return {'code': '123456', 'period': 30, 'remainingSeconds': 20};
        }
        if (reference == 'ov://Test/u2/username') {
          return 'me@gmail.com';
        }
        return null;
      },
      export: () => [
        {
          'file': 'Test',
          'group': 'Root',
          'title': 'GitHub',
          'username': 'octocat',
          'password': 'gh-secret',
          'url': 'https://github.com',
          'notes': '',
          'totp': 'otpauth://totp/GitHub?secret=ABC',
        },
      ],
      sudo: (code) => code == '654321'
          ? (username: 'octocat', password: 'sudo-secret')
          : null,
      pamSetup: (_) async => '/home/test/.openvalut/totp/abc.enc',
    );
    await server.start();
  });

  tearDown(() => server.stop());

  test('ping requires the token', () async {
    final denied = await _request(
      port: server.port!,
      token: 'wrong',
      method: 'ping',
    );
    expect(denied['ok'], isFalse);
    expect(denied['error'], 'unauthorized');

    final ok = await _request(port: server.port!, token: token, method: 'ping');
    expect(ok['ok'], isTrue);
    expect((ok['data'] as Map<String, Object?>)['pong'], isTrue);
  });

  test('non-ping requests require successful authentication', () async {
    await server.stop();
    var authenticationCount = 0;
    server = CredentialServer(
      token: token,
      entries: () => [],
      resolveReference: (_) => null,
      sudo: (_) => null,
      pamSetup: (_) async => null,
      authenticate: () async {
        authenticationCount++;
        return false;
      },
    );
    await server.start();

    final ping = await _request(
      port: server.port!,
      token: token,
      method: 'ping',
    );
    expect(ping['ok'], isTrue);
    expect(authenticationCount, 0);

    final list = await _request(
      port: server.port!,
      token: token,
      method: 'list',
    );
    expect(list['ok'], isFalse);
    expect(list['error'], 'biometric authentication failed');
    expect(authenticationCount, 1);
  });

  test('list returns searchable metadata', () async {
    final response = await _request(
      port: server.port!,
      token: token,
      method: 'list',
    );
    final entries =
        (response['data'] as Map<String, Object?>)['entries'] as List<Object?>;
    expect(entries, hasLength(2));
    final first = (entries.first as Map<Object?, Object?>)
        .cast<String, Object?>();
    expect(first['label'], 'GitHub');
    expect(first['password'], isNull); // never leaks secrets in list
  });

  test('get matches by label and returns metadata only', () async {
    final response = await _request(
      port: server.port!,
      token: token,
      method: 'get',
      params: {'query': 'github', 'field': 'label'},
    );
    expect(response['data'], 'GitHub');
  });

  test('get rejects sensitive fields', () async {
    final response = await _request(
      port: server.port!,
      token: token,
      method: 'get',
      params: {'query': 'github', 'field': 'password'},
    );
    expect(response['ok'], isFalse);
    expect(
      (response['error'] as String).toLowerCase(),
      contains('resolve'),
    );
  });

  test('resolve returns a secret by reference', () async {
    final response = await _request(
      port: server.port!,
      token: token,
      method: 'resolve',
      params: {'reference': 'ov://Test/u1/password'},
    );
    expect(response['data'], 'gh-secret');
  });

  test('resolve returns a totp by reference', () async {
    final response = await _request(
      port: server.port!,
      token: token,
      method: 'resolve',
      params: {'reference': 'ov://Test/u1/totp'},
    );
    final data = (response['data'] as Map<String, Object?>);
    expect(data['code'], '123456');
    expect(data['period'], 30);
  });

  test('totp method is no longer exposed directly', () async {
    final response = await _request(
      port: server.port!,
      token: token,
      method: 'totp',
      params: {'query': 'github'},
    );
    expect(response['ok'], isFalse);
    expect(
      (response['error'] as String).toLowerCase(),
      contains('resolve'),
    );
  });

  test('sudo returns the password when totp is valid', () async {
    final response = await _request(
      port: server.port!,
      token: token,
      method: 'sudo',
      params: {'totp': '654321'},
    );
    final data = (response['data'] as Map<String, Object?>);
    expect(data['username'], 'octocat');
    expect(data['password'], 'sudo-secret');
  });

  test('sudo rejects an invalid totp', () async {
    final response = await _request(
      port: server.port!,
      token: token,
      method: 'sudo',
      params: {'totp': '000000'},
    );
    expect(response['ok'], isFalse);
  });

  test('no matching entry is an error', () async {
    final response = await _request(
      port: server.port!,
      token: token,
      method: 'get',
      params: {'query': 'nothing'},
    );
    expect(response['ok'], isFalse);
  });

  test('generateTotpForEntry is deterministic within a time step', () {
    final format = KdbxFormat();
    final file = format.create(
      Credentials(ProtectedValue.fromString('p')),
      'T',
    );
    final entry = KdbxEntry.create(file, file.body.rootGroup);
    entry.setString(
      KdbxKeyCommon.OTP,
      PlainValue(
        'otpauth://totp/GitHub:octocat?secret=JBSWY3DPEHPK3PXP&digits=6&period=30',
      ),
    );

    var now = 1700000000000;
    final result = generateTotpForEntry(entry, nowMillis: () => now)!;
    expect(result.code.length, 6);
    expect(result.period, 30);
    expect(int.tryParse(result.code), isNotNull);
    expect(result.remaining, inInclusiveRange(0, 30));

    final again = generateTotpForEntry(entry, nowMillis: () => now)!;
    expect(again.code, result.code);

    now += 30000;
    final later = generateTotpForEntry(entry, nowMillis: () => now)!;
    expect(later.code, isNot(result.code));
  });

  test('export returns decrypted entries', () async {
    final response = await _request(
      port: server.port!,
      token: token,
      method: 'export',
    );
    expect(response['ok'], isTrue);
    final entries =
        (response['data'] as Map<Object?, Object?>)['entries'] as List<Object?>;
    expect(entries, hasLength(1));
    final first = entries.first as Map<Object?, Object?>;
    expect(first['title'], 'GitHub');
    expect(first['password'], 'gh-secret');
    expect(first['totp'], 'otpauth://totp/GitHub?secret=ABC');
  });
}
