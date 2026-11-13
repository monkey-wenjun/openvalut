import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';

import 'openssh_key.dart';

final _logger = Logger('ssh_agent');

/// One key the agent offers, derived from a vault entry.
class SshAgentIdentity {
  SshAgentIdentity({
    required this.publicKeyBlob,
    required this.comment,
    required this.key,
  });

  final Uint8List publicKeyBlob;
  final String comment;
  final ParsedSshPrivateKey key;
}

// SSH agent protocol constants (draft-ietf-secsh-agent / OpenSSH).
const _requestIdentities = 11;
const _identitiesAnswer = 12;
const _signRequest = 13;
const _signResponse = 14;
const _failure = 5;
const _rsaSha2_512 = 4;

/// Serves the SSH agent protocol over a loopback TCP socket.
///
/// The Unix socket ssh actually wants to talk to is provided by a small C
/// bridge (`openvalut-agent-bridge`) that forwards between
/// `~/.openvalut/agent.sock` and this port. Private keys stay in the process
/// memory of the unlocked app; only signatures leave.
class SshAgentServer {
  ServerSocket? _server;

  int? get port => _server?.port;

  /// Starts listening on an ephemeral loopback port. [identities] is called
  /// for every request so keys added/removed in the vault show up without a
  /// restart.
  Future<void> start(List<SshAgentIdentity> Function() identities) async {
    await stop();
    final server = await ServerSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    _server = server;
    _logger.info('SSH agent listening on 127.0.0.1:${server.port}');
    server.listen(
      (socket) => unawaited(_handleClient(socket, identities)),
      onError: (Object error, StackTrace stackTrace) {
        _logger.warning('SSH agent socket error.', error, stackTrace);
      },
    );
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    if (server != null) {
      await server.close();
    }
  }

  Future<void> _handleClient(
    Socket socket,
    List<SshAgentIdentity> Function() identities,
  ) async {
    _logger.fine('SSH agent client connected.');
    var buffer = Uint8List(0);
    try {
      await for (final chunk in socket) {
        buffer = Uint8List.fromList([...buffer, ...chunk]);
        final responses = <Uint8List>[];
        var offset = 0;
        while (buffer.length - offset >= 4) {
          final length = ByteData.sublistView(buffer, offset).getUint32(0);
          if (buffer.length - offset < 4 + length) {
            break; // incomplete message; wait for more data
          }
          final message = buffer.sublist(offset + 4, offset + 4 + length);
          final response = _handleMessage(
            Uint8List.fromList(message),
            identities,
          );
          if (response != null) {
            responses.add(_frame(response));
          }
          offset += 4 + length;
        }
        if (offset > 0) {
          buffer = buffer.sublist(offset);
        }
        for (final response in responses) {
          socket.add(response);
        }
      }
    } catch (e, stackTrace) {
      _logger.fine('SSH agent client error.', e, stackTrace);
    } finally {
      await socket.close();
    }
  }

  Uint8List? _handleMessage(
    Uint8List message,
    List<SshAgentIdentity> Function() identities,
  ) {
    if (message.isEmpty) {
      return Uint8List.fromList([_failure]);
    }
    switch (message[0]) {
      case _requestIdentities:
        return _listIdentities(identities());
      case _signRequest:
        return _sign(message, identities());
      default:
        // Everything else (add/remove/lock/extension) is not supported.
        return Uint8List.fromList([_failure]);
    }
  }

  Uint8List _listIdentities(List<SshAgentIdentity> identities) {
    final body = BytesBuilder();
      body.addByte(_identitiesAnswer);
      body.add(_uint32(identities.length));
      for (final identity in identities) {
        body.add(_string(identity.publicKeyBlob));
        body.add(_string(utf8.encode(identity.comment)));
      }
    return body.toBytes();
  }

  Uint8List _sign(
    Uint8List message,
    List<SshAgentIdentity> identities,
  ) {
    final reader = _AgentReader(message, 1);
    final keyBlob = reader.readString();
    final data = reader.readString();
    final flags = reader.readUint32();

    for (final identity in identities) {
      if (!_bytesEqual(identity.publicKeyBlob, keyBlob)) {
        continue;
      }
      try {
        final algorithm = identity.key.keyType == SshKeyType.rsa
            ? flags & _rsaSha2_512 != 0
                  ? SshSignatureAlgorithm.rsaSha2_512
                  : SshSignatureAlgorithm.rsaSha2_256
            : null;
        final signature = identity.key.sign(data, rsaAlgorithm: algorithm);
        final blob = sshSignatureBlob(identity.key, signature, rsaAlgorithm: algorithm);
        return Uint8List.fromList([
          _signResponse,
          ..._string(blob),
        ]);
      } catch (e, stackTrace) {
        _logger.warning('SSH agent signing failed.', e, stackTrace);
        return Uint8List.fromList([_failure]);
      }
    }
    return Uint8List.fromList([_failure]);
  }
}

Uint8List _uint32(int value) {
  final data = ByteData(4)..setUint32(0, value);
  return data.buffer.asUint8List();
}

Uint8List _string(List<int> value) {
  final data = ByteData(4 + value.length)
    ..setUint32(0, value.length);
  for (var i = 0; i < value.length; i++) {
    data.setUint8(4 + i, value[i]);
  }
  return data.buffer.asUint8List();
}

Uint8List _frame(Uint8List payload) {
  final data = ByteData(4 + payload.length)
    ..setUint32(0, payload.length);
  for (var i = 0; i < payload.length; i++) {
    data.setUint8(4 + i, payload[i]);
  }
  return data.buffer.asUint8List();
}

bool _bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

class _AgentReader {
  _AgentReader(this.bytes, this._pos);

  final Uint8List bytes;
  int _pos;

  Uint8List readString() {
    final length = ByteData.sublistView(bytes).getUint32(_pos);
    _pos += 4;
    final out = Uint8List.fromList(bytes.sublist(_pos, _pos + length));
    _pos += length;
    return out;
  }

  int readUint32() {
    final value = ByteData.sublistView(bytes).getUint32(_pos);
    _pos += 4;
    return value;
  }
}
