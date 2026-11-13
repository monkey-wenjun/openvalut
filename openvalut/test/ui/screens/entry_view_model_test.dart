import 'dart:typed_data';

import 'package:openvalut/bloc/app_data.dart';
import 'package:openvalut/bloc/kdbx/file_content.dart';
import 'package:openvalut/bloc/kdbx/file_source.dart';
import 'package:openvalut/bloc/kdbx_bloc.dart';
import 'package:openvalut/ui/screens/password_list.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kdbx/kdbx.dart';
import 'package:logging_appenders/logging_appenders.dart';
import 'package:mockito/mockito.dart';

import '../../util/test_util.dart';
import '../../util/test_util.mocks.dart';

void main() {
  PrintAppender.setupLogging();
  final testUtil = TestUtil();
  group('entry view model', () {
    late KdbxEntry entry;
    late MockKdbxBloc kdbxBloc;

    setUp(() {
      final file = testUtil.createFile();
      final rootGroup = file.body.rootGroup;
      entry = KdbxEntry.create(file, rootGroup);
      rootGroup.addEntry(entry);

      kdbxBloc = MockKdbxBloc();
      final fakeFile = OpenedFile(
        (b) => b
          ..lastOpenedAt = clock.now().toUtc()
          ..uuid = AppDataBloc.createUuid()
          ..sourceType = OpenedFilesSourceType.Url
          ..sourcePath = 'foo'
          ..name = 'bar',
      );
      final fakeKdbxOpenedFile = KdbxOpenedFile(
        fileSource: FileSourceUrl(
          Uri.parse('https://openvalut.app/'),
          uuid: AppDataBloc.createUuid(),
        ),
        openedFile: fakeFile,
        kdbxFile: file,
        kdbxFileContent: FileContent(Uint8List(0)),
      );
      when(kdbxBloc.fileForKdbxFile(any)).thenReturn(fakeKdbxOpenedFile);
    });
    String? website(String value) {
      entry.setString(EntryViewModel.websiteKey, PlainValue(value));
      final vm = EntryViewModel(entry, kdbxBloc);
      return vm.website;
    }

    test('url transforms', () {
      // bloc.fileForFileSource()

      expect(website('openvalut.app'), 'http://openvalut.app/');
      // TODO we should probably fix this somehow.
      expect(website('openvalut.app\nloremipsum'), 'http://openvalut.app/');
      expect(website('\n\nopenvalut.app\r\n'), 'http://openvalut.app/');
      expect(website('\n\nopenvalut.app//blubb\r\n'), 'http://openvalut.app/');
      expect(website('   \n'), isNull);
    });
  });
}
