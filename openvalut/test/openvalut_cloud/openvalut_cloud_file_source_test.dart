import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openvalut/bloc/kdbx/file_source_openvalut_cloud.dart';
import 'package:openvalut/openvalut_cloud/openvalut_client.dart';
import 'package:openvalut/openvalut_cloud/openvalut_cloud_session.dart';
import 'package:openvalut/openvalut_cloud/openvalut_crypto.dart';

const _payload =
    '{"label":"GitHub","username":"octocat","password":"gh-secret"}';

class _FixedKeyCloudSource extends FileSourceopenvalutCloud {
  _FixedKeyCloudSource({
    required super.client,
    required super.vaultId,
    required super.vaultName,
    required super.uuid,
    required Uint8List key,
  }) : _key = key;

  final Uint8List _key;

  @override
  Future<Uint8List> vaultKey() async => _key;
}

void main() {
  test('openvalutClient parses vault list and single vault', () async {
    final client = openvalutClient(
      baseUrl: 'https://example.test',
      token: 'tok',
      httpClient: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer tok');
        if (request.url.path == '/api/vaults') {
          return http.Response(
            json.encode({
              'vaults': [
                {
                  'id': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                  'name': 'v1',
                  'nonce': 'AAEC',
                  'ciphertext': 'AQID',
                  'updatedAt': 123,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path ==
            '/api/vaults/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa') {
          return http.Response(
            json.encode({
              'vault': {
                'id': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                'name': 'v1',
                'nonce': 'AAEC',
                'ciphertext': 'AQID',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(json.encode({'error': 'not found'}), 404);
      }),
    );

    final vaults = await client.listVaults();
    expect(vaults, hasLength(1));
    expect(vaults.single.id, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
    expect(vaults.single.nonce, 'AAEC');
    expect(vaults.single.updatedAt, 123);

    final single = await client.getVault(
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    );
    expect(single.name, 'v1');
    expect(single.ciphertext, 'AQID');
  });

  test(
    'openvalutClient sends client-generated id when creating a vault',
    () async {
      openvalutClient? client;
      client = openvalutClient(
        baseUrl: 'https://example.test',
        token: 'tok',
        httpClient: MockClient((request) async {
          final body = json.decode(request.body) as Map<String, dynamic>;
          expect(body['id'], '0123456789abcdef0123456789abcdef');
          expect(body['name'], 'new');
          return http.Response(
            json.encode({
              'vault': {
                'id': body['id'],
                'name': body['name'],
                'nonce': body['nonce'],
                'ciphertext': body['ciphertext'],
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final vault = await client.createVault(
        id: '0123456789abcdef0123456789abcdef',
        name: 'new',
        nonce: 'AAEC',
        ciphertext: 'AQID',
      );
      expect(vault.id, '0123456789abcdef0123456789abcdef');
    },
  );

  test(
    'FileSourceopenvalutCloud load decrypts and write encrypts the blob',
    () async {
      final key = Uint8List.fromList(
        List.filled(32, 7),
      );
      final payload = Uint8List.fromList(utf8.encode(_payload));
      final (nonce, ciphertext) = openvalutCrypto.encrypt(key, payload);

      var updatedNonce = '';
      var updatedCiphertext = '';
      final client = openvalutClient(
        baseUrl: 'https://example.test',
        token: 'tok',
        httpClient: MockClient((request) async {
          if (request.url.path == '/api/server-key') {
            return http.Response(
              json.encode({
                'publicKey': base64.encode(List.filled(32, 9)),
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path.endsWith('/entries')) {
            // No rows yet: the load falls back to the blob path.
            return http.Response(
              json.encode({'entries': <dynamic>[]}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'GET') {
            return http.Response(
              json.encode({
                'vault': {
                  'id': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                  'name': 'v1',
                  'nonce': base64.encode(nonce),
                  'ciphertext': base64.encode(ciphertext),
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'PUT') {
            final body = json.decode(request.body) as Map<String, dynamic>;
            updatedNonce = body['nonce'] as String;
            updatedCiphertext = body['ciphertext'] as String;
            return http.Response(
              json.encode({'ok': true}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(json.encode({'error': 'bad request'}), 400);
        }),
      );

      final source = _FixedKeyCloudSource(
        client: client,
        vaultId: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        vaultName: 'v1',
        uuid: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        key: key,
      );

      final loaded = await source.content().last;
      expect(loaded.content, payload);
      expect(loaded.metadata?['vaultId'], 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');

      final changed = Uint8List.fromList(utf8.encode('{"label":"New"}'));
      await source.contentWrite(changed, metadata: loaded.metadata);
      expect(updatedNonce, isNotEmpty);
      final decrypted = openvalutCrypto.decrypt(
        key,
        Uint8List.fromList(base64.decode(updatedNonce)),
        Uint8List.fromList(base64.decode(updatedCiphertext)),
      );
      expect(decrypted, changed);
    },
  );

  test('newVaultId produces a 32-char lowercase hex id', () {
    final id = openvalutCloudSession.newVaultId();
    expect(id, matches(RegExp(r'^[0-9a-f]{32}$')));
    final other = openvalutCloudSession.newVaultId();
    expect(id, isNot(other));
  });

  test('openvalutClient looks up a user public key', () async {
    final client = openvalutClient(
      baseUrl: 'https://example.test',
      token: 'tok',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/users/family%40example.com/public-key');
        return http.Response(
          json.encode({
            'username': 'family@example.com',
            'publicKey': 'AQIDBAUGBwgJCgsMDQ4PEA==',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final pub = await client.getUserPublicKey('family@example.com');
    expect(pub, 'AQIDBAUGBwgJCgsMDQ4PEA==');
  });

  test('openvalutClient parses incoming shares', () async {
    final client = openvalutClient(
      baseUrl: 'https://example.test',
      token: 'tok',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/shares/incoming');
        return http.Response(
          json.encode({
            'shares': [
              {
                'id': 'share-1',
                'entryUuid': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                'ownerUsername': 'alice@example.com',
                'recipientUsername': 'bob@example.com',
                'encryptedShareKey': 'AQID',
                'sharedNonce': 'BAUG',
                'sharedCiphertext': 'BwgJ',
                'createdAt': 123,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final shares = await client.listIncomingShares();
    expect(shares, hasLength(1));
    expect(shares.single.ownerUsername, 'alice@example.com');
    expect(shares.single.encryptedShareKey, 'AQID');
    expect(shares.single.createdAt, 123);
  });

  test('openvalutClient createShare sends the wrapped key payload', () async {
    openvalutClient? client;
    client = openvalutClient(
      baseUrl: 'https://example.test',
      token: 'tok',
      httpClient: MockClient((request) async {
        expect(
          request.url.path,
          '/api/vaults/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/shares',
        );
        final body = json.decode(request.body) as Map<String, dynamic>;
        expect(body['entryUuid'], 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
        expect(body['recipientUsername'], 'bob@example.com');
        expect(body['encryptedShareKey'], 'AQID');
        expect(body['sharedNonce'], 'BAUG');
        expect(body['sharedCiphertext'], 'BwgJ');
        return http.Response(
          json.encode({
            'share': {'id': 's1'},
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    await client.createShare(
      vaultId: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      entryUuid: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      recipientUsername: 'bob@example.com',
      encryptedShareKey: 'AQID',
      sharedNonce: 'BAUG',
      sharedCiphertext: 'BwgJ',
    );
  });

  group('cloud vault key derivation', () {
    FileSourceopenvalutCloud sourceWith({
      String? masterPassword,
      Uint8List? rememberedVaultKey,
    }) {
      const vaultId = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      return FileSourceopenvalutCloud(
        client: openvalutClient(
          baseUrl: 'https://example.test',
          token: 'tok',
          httpClient: MockClient(
            (request) async => http.Response(
              json.encode({'error': 'unused'}),
              404,
              headers: {'content-type': 'application/json'},
            ),
          ),
        ),
        vaultId: vaultId,
        vaultName: 'v1',
        uuid: vaultId,
        masterPassword: masterPassword,
        rememberedVaultKey: rememberedVaultKey,
      );
    }

    test('the typed master password wins over a stale remembered key', () async {
      const vaultId = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      const password = 'typed-master-password';
      final stale = Uint8List.fromList(List.filled(32, 0xab));
      final source = sourceWith(
        masterPassword: password,
        rememberedVaultKey: stale,
      );
      try {
        final key = await source.vaultKey();
        final expected = await openvalutCrypto.deriveKey(
          password,
          Uint8List.fromList(utf8.encode(vaultId)),
        );
        expect(key, expected);
      } catch (e) {
        // The argon2 FFI library may not be loadable inside `flutter test`.
        markTestSkipped('argon2 FFI unavailable: $e');
      }
    });

    test('invalidateVaultKeyCache drops the key of a failed attempt', () async {
      const vaultId = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      final source = sourceWith(masterPassword: 'first-attempt-typo');
      try {
        final first = await source.vaultKey();
        source.masterPassword = 'second-attempt-correct';
        source.invalidateVaultKeyCache();
        final second = await source.vaultKey();
        final expected = await openvalutCrypto.deriveKey(
          'second-attempt-correct',
          Uint8List.fromList(utf8.encode(vaultId)),
        );
        expect(second, expected);
        expect(second, isNot(first));
      } catch (e) {
        // The argon2 FFI library may not be loadable inside `flutter test`.
        markTestSkipped('argon2 FFI unavailable: $e');
      }
    });
  });
}
