import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kdbx/kdbx.dart';
import 'package:openvalut/bloc/kdbx_bloc.dart';

void main() {
  final now = DateTime.utc(2026, 8, 25, 12);

  bool usable({
    required int savedMinutesAgo,
    required int rememberDays,
    Object? entryBootId,
    String? currentBootId,
  }) => isRememberedUnlockEntryUsable(
    savedAt: now.subtract(Duration(minutes: savedMinutesAgo)),
    now: now,
    maxAge: Duration(days: rememberDays),
    entryBootId: entryBootId,
    currentBootId: currentBootId,
  );

  test('fresh entry in the same boot is usable', () {
    expect(
      usable(
        savedMinutesAgo: 5,
        rememberDays: 30,
        entryBootId: 'boot-1',
        currentBootId: 'boot-1',
      ),
      isTrue,
    );
  });

  test('expired grace period is not usable', () {
    expect(
      usable(
        savedMinutesAgo: 60 * 24 * 31,
        rememberDays: 30,
        entryBootId: 'boot-1',
        currentBootId: 'boot-1',
      ),
      isFalse,
    );
  });

  test('entry from a previous boot session is not usable', () {
    expect(
      usable(
        savedMinutesAgo: 5,
        rememberDays: 30,
        entryBootId: 'boot-1',
        currentBootId: 'boot-2',
      ),
      isFalse,
    );
  });

  test('entry without a boot id is not usable when a boot id is known', () {
    expect(
      usable(
        savedMinutesAgo: 5,
        rememberDays: 30,
        entryBootId: null,
        currentBootId: 'boot-1',
      ),
      isFalse,
    );
  });

  test('boot is not checked when the platform exposes no boot id', () {
    expect(
      usable(
        savedMinutesAgo: 5,
        rememberDays: 30,
        entryBootId: 'boot-old',
        currentBootId: null,
      ),
      isTrue,
    );
    expect(
      usable(
        savedMinutesAgo: 5,
        rememberDays: 30,
        entryBootId: null,
        currentBootId: null,
      ),
      isTrue,
    );
  });

  test('remember disabled (0 days) never unlocks', () {
    expect(
      usable(
        savedMinutesAgo: 5,
        rememberDays: 0,
        entryBootId: 'boot-1',
        currentBootId: 'boot-1',
      ),
      isFalse,
    );
  });

  group('remembered unlock payload', () {
    final savedAt = DateTime.utc(2026, 8, 25, 12);

    test('transformed key round-trips without losing the fingerprint', () {
      final credentials = TransformedKeyCredentials(
        transformedKey: Uint8List.fromList(List.filled(32, 7)),
        kdfFingerprint: 'fp-123',
      );
      final payload = rememberedUnlockPayload(
        credentials,
        savedAt,
        'boot-1',
      );
      expect(payload['type'], 'transformed');
      expect(payload['bootId'], 'boot-1');

      final restored = rememberedCredentialsFromPayload(payload);
      expect(restored, isA<TransformedKeyCredentials>());
      final transformed = restored! as TransformedKeyCredentials;
      expect(transformed.kdfFingerprint, 'fp-123');
      expect(transformed.transformedKey, List.filled(32, 7));
    });

    test('composite hash round-trips as HashCredentials', () {
      final credentials = Credentials.fromHash(Uint8List.fromList([1, 2, 3]));
      final payload = rememberedUnlockPayload(credentials, savedAt, 'boot-1');
      expect(payload['type'], 'composite');
      final restored = rememberedCredentialsFromPayload(payload);
      expect(restored, isA<HashCredentials>());
      expect(restored!.getHash(), [1, 2, 3]);
    });

    test('cloud vault key round-trips through the payload', () {
      final credentials = Credentials.fromHash(Uint8List.fromList([1, 2, 3]));
      final vaultKey = Uint8List.fromList(List.filled(32, 7));
      final payload = rememberedUnlockPayload(
        credentials,
        savedAt,
        'boot-1',
        vaultKey: vaultKey,
      );
      expect(payload['vaultKey'], isA<String>());

      final restored = rememberedUnlockDataFromPayload(payload);
      expect(restored, isNotNull);
      expect(restored!.credentials.getHash(), [1, 2, 3]);
      expect(restored.vaultKey, vaultKey);

      // Local files carry no vault key.
      final local = rememberedUnlockDataFromPayload(
        rememberedUnlockPayload(credentials, savedAt, 'boot-1'),
      );
      expect(local, isNotNull);
      expect(local!.vaultKey, isNull);
    });

    test('cloud master password round-trips for writable reopen', () {
      final credentials = Credentials.fromHash(Uint8List.fromList([1, 2, 3]));
      final payload = rememberedUnlockPayload(
        credentials,
        savedAt,
        'boot-1',
        masterPassword: 'my-secret',
      );
      expect(payload['masterPassword'], isA<String>());
      final restored = rememberedUnlockDataFromPayload(payload);
      expect(restored, isNotNull);
      expect(restored!.masterPassword, 'my-secret');
    });

    test('legacy payload without a type is read as a composite hash', () {
      final restored = rememberedCredentialsFromPayload({
        'hash': base64Encode([9, 8, 7]),
        'savedAt': savedAt.millisecondsSinceEpoch,
      });
      expect(restored, isA<HashCredentials>());
      expect(restored!.getHash(), [9, 8, 7]);
    });

    test('corrupt payload returns null', () {
      expect(
        rememberedCredentialsFromPayload(const {'type': 'transformed'}),
        isNull,
      );
      expect(
        rememberedCredentialsFromPayload(const {'type': 'composite'}),
        isNull,
      );
    });
  });

  group('quick unlock boot binding', () {
    test('entry stored in this boot session is usable', () {
      expect(
        isQuickUnlockEntryUsable(
          entryBootId: 'boot-1',
          currentBootId: 'boot-1',
        ),
        isTrue,
      );
    });

    test('entry from an earlier boot session is rejected', () {
      expect(
        isQuickUnlockEntryUsable(
          entryBootId: 'boot-1',
          currentBootId: 'boot-2',
        ),
        isFalse,
      );
      // Entries written before boot ids were recorded are rejected too, so an
      // upgrade can never skip the master password after a reboot.
      expect(
        isQuickUnlockEntryUsable(
          entryBootId: null,
          currentBootId: 'boot-2',
        ),
        isFalse,
      );
    });

    test('boot is not checked when the platform exposes no boot id', () {
      expect(
        isQuickUnlockEntryUsable(entryBootId: null, currentBootId: null),
        isTrue,
      );
      expect(
        isQuickUnlockEntryUsable(
          entryBootId: 'boot-old',
          currentBootId: null,
        ),
        isTrue,
      );
    });

    test('payload carries the boot id and the hash', () {
      final credentials = Credentials.fromHash(Uint8List.fromList([1, 2, 3]));
      final payload = quickUnlockPayload(
        RememberedUnlockData(credentials: credentials),
        bootId: 'boot-1',
      );
      expect(payload['bootId'], 'boot-1');
      expect(payload['hash'], base64Encode([1, 2, 3]));
      expect(payload.containsKey('vaultKey'), isFalse);
      expect(payload.containsKey('masterPassword'), isFalse);

      final cloud = quickUnlockPayload(
        RememberedUnlockData(
          credentials: credentials,
          vaultKey: Uint8List.fromList(List.filled(32, 7)),
          masterPassword: 'my-secret',
        ),
        bootId: 'boot-1',
      );
      expect(cloud['vaultKey'], isA<String>());
      expect(
        utf8.decode(base64Decode(cloud['masterPassword'] as String)),
        'my-secret',
      );

      final withoutBootId = quickUnlockPayload(
        RememberedUnlockData(credentials: credentials),
        bootId: null,
      );
      expect(withoutBootId.containsKey('bootId'), isFalse);
    });
  });
}
