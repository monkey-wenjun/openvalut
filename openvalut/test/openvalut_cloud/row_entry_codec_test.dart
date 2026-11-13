import 'package:flutter_test/flutter_test.dart';
import 'package:kdbx/kdbx.dart';
import 'package:openvalut/openvalut_cloud/row_entry_codec.dart';

KdbxFile newFile() {
  final format = KdbxFormat();
  return format.create(
    Credentials(ProtectedValue.fromString('test-pass')),
    'test',
  );
}

KdbxEntry addEntry(KdbxFile file, KdbxGroup group) {
  final entry = KdbxEntry.create(file, group);
  group.addEntry(entry);
  return entry;
}

void main() {
  test('entry row round-trips standard, protected and custom fields', () {
    final file = newFile();
    final source = addEntry(file, file.body.rootGroup);
    source.setString(KdbxKeyCommon.TITLE, PlainValue('GitHub'));
    source.setString(KdbxKeyCommon.USER_NAME, PlainValue('alice'));
    source.setString(
      KdbxKeyCommon.PASSWORD,
      ProtectedValue.fromString('s3cret'),
    );
    source.setString(KdbxKey('KPEX_PASSKEY_CREDENTIAL_ID'),
        ProtectedValue.fromString('cred-id-b64url'));
    source.setString(KdbxKey('notes-custom'), PlainValue('hello'));
    source.icon.set(KdbxIcon.Key);

    final row = encodeEntryRow(source);

    final targetFile = newFile();
    final target = addEntry(targetFile, targetFile.body.rootGroup);
    applyEntryRow(target, row);

    expect(target.getString(KdbxKeyCommon.TITLE)?.getText(), 'GitHub');
    expect(target.getString(KdbxKeyCommon.USER_NAME)?.getText(), 'alice');
    expect(target.getString(KdbxKeyCommon.PASSWORD)?.getText(), 's3cret');
    expect(target.getString(KdbxKeyCommon.PASSWORD), isA<ProtectedValue>());
    expect(
      target.getString(KdbxKey('KPEX_PASSKEY_CREDENTIAL_ID'))?.getText(),
      'cred-id-b64url',
    );
    expect(
      target.getString(KdbxKey('KPEX_PASSKEY_CREDENTIAL_ID')),
      isA<ProtectedValue>(),
    );
    expect(target.getString(KdbxKey('notes-custom'))?.getText(), 'hello');
    expect(target.getString(KdbxKey('notes-custom')), isA<PlainValue>());
    expect(target.icon.get(), KdbxIcon.Key);
  });

  test('icon and empty fields are handled', () {
    final file = newFile();
    final source = addEntry(file, file.body.rootGroup);
    source.setString(KdbxKeyCommon.TITLE, PlainValue('OnlyTitle'));

    final row = encodeEntryRow(source);

    final targetFile = newFile();
    final target = addEntry(targetFile, targetFile.body.rootGroup);
    applyEntryRow(target, row);

    expect(target.getString(KdbxKeyCommon.TITLE)?.getText(), 'OnlyTitle');
    expect(target.getString(KdbxKeyCommon.PASSWORD)?.getText(), isNull);
  });
}