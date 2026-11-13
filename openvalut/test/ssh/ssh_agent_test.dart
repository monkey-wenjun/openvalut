import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:openvalut/ssh/openssh_key.dart';
import 'package:openvalut/ssh/ssh_agent.dart';

Future<Uint8List> _string(List<int> value) async =>
    Uint8List.fromList([...(ByteData(4)..setUint32(0, value.length)).buffer.asUint8List(), ...value]);

void main() {
  test('agent lists identities and signs with the vault key', () async {
    final sshKeygen = await Process.run('which', ['ssh-keygen']);
    if (sshKeygen.exitCode != 0) {
      markTestSkipped('ssh-keygen not available');
      return;
    }
    final dir = await Directory.systemTemp.createTemp('agent_test_');
    try {
      final gen = await Process.run('ssh-keygen', [
        '-t',
        'ed25519',
        '-N',
        '',
        '-C',
        'test@openvalut',
        '-f',
        '${dir.path}/key',
      ]);
      expect(gen.exitCode, 0, reason: '${gen.stderr}');
      final parsed = parseOpensshPrivateKey(
        File('${dir.path}/key').readAsStringSync(),
      );

      final server = SshAgentServer();
      await server.start(() => [
        SshAgentIdentity(
          publicKeyBlob: parsed.publicKey,
          comment: 'test@openvalut',
          key: parsed,
        ),
      ]);
      addTearDown(server.stop);

      final socket = await Socket.connect('127.0.0.1', server.port!);
      addTearDown(socket.destroy);
      final frames = <Completer<Uint8List>>[];
      var buffer = Uint8List(0);
      socket.listen((chunk) {
        buffer = Uint8List.fromList([...buffer, ...chunk]);
        while (frames.isNotEmpty && buffer.length >= 4) {
          final length = ByteData.sublistView(buffer).getUint32(0);
          if (buffer.length < 4 + length) {
            break;
          }
          frames
              .removeAt(0)
              .complete(Uint8List.fromList(buffer.sublist(4, 4 + length)));
          buffer = buffer.sublist(4 + length);
        }
      });
      Future<Uint8List> readFrame() {
        final completer = Completer<Uint8List>();
        frames.add(completer);
        return completer.future;
      }

      Future<void> send(Uint8List message) async {
        final length = ByteData(4)..setUint32(0, message.length);
        socket.add(length.buffer.asUint8List());
        socket.add(message);
      }

      // Request identities.
      await send(Uint8List.fromList([11]));
      final identities = await readFrame();
      expect(identities[0], 12); // SSH2_AGENT_IDENTITIES_ANSWER
      expect(ByteData.sublistView(identities).getUint32(1), 1);

      // Request a signature.
      final data = utf8.encode('hello agent');
      final request = BytesBuilder()
        ..addByte(13) // SSH2_AGENTC_SIGN_REQUEST
        ..add(await _string(parsed.publicKey))
        ..add(await _string(data))
        ..add((ByteData(4)..setUint32(0, 0)).buffer.asUint8List());
      await send(request.toBytes());
      final response = await readFrame();
      expect(response[0], 14); // SSH2_AGENT_SIGN_RESPONSE
      final blobLength = ByteData.sublistView(response, 1).getUint32(0);
      final blob = response.sublist(5, 5 + blobLength);
      final algorithmLength = ByteData.sublistView(blob).getUint32(0);
      expect(
        utf8.decode(blob.sublist(4, 4 + algorithmLength)),
        'ssh-ed25519',
      );
      final signatureLength = ByteData.sublistView(blob, 4 + algorithmLength)
          .getUint32(0);
      expect(signatureLength, 64);
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
