import "dart:convert";
import "dart:typed_data";

import "package:trezor_flutter/src/operations/trezor/v1_operation.dart";
import "package:trezor_flutter/src/trezor/protobuf/messages-common.pb.dart";
import "package:trezor_flutter/src/trezor/transformer/v1_transformer.dart";
import "package:trezor_flutter/trezor_flutter.dart";

const oneKeyCipherKeyValueMessageType = 23;
const oneKeyCipheredKeyValueMessageType = 48;

class OneKeyCipherKeyValueRequest {
  OneKeyCipherKeyValueRequest({
    required List<int> addressPath,
    required this.key,
    required Uint8List value,
    required this.encrypt,
    this.askOnEncrypt = false,
    this.askOnDecrypt = true,
    Uint8List? iv,
  })  : addressPath = List<int>.unmodifiable(addressPath),
        value = Uint8List.fromList(value),
        iv = iv == null ? null : Uint8List.fromList(iv) {
    if (addressPath.isEmpty || addressPath.length > 8) {
      throw ArgumentError.value(addressPath, "addressPath", "must contain between 1 and 8 items");
    }
    if (utf8.encode(key).length > 256) {
      throw ArgumentError.value(key, "key", "UTF-8 representation exceeds 256 bytes");
    }
    if (value.isEmpty || value.length > 1024 || value.length % 16 != 0) {
      throw ArgumentError.value(
        value.length,
        "value.length",
        "must be a non-zero multiple of 16 and no larger than 1024",
      );
    }
    if (iv != null && iv.length != 16) {
      throw ArgumentError.value(iv.length, "iv.length", "must be 16 bytes");
    }
    for (final component in addressPath) {
      if (component < 0 || component > 0xffffffff) {
        throw ArgumentError.value(component, "addressPath", "contains a non-uint32 value");
      }
    }
  }

  final List<int> addressPath;
  final String key;
  final Uint8List value;
  final bool encrypt;
  final bool askOnEncrypt;
  final bool askOnDecrypt;
  final Uint8List? iv;
}

abstract final class OneKeyCipherKeyValueCodec {
  static Uint8List encodeRequest(OneKeyCipherKeyValueRequest request) {
    final output = BytesBuilder(copy: false);
    for (final component in request.addressPath) {
      _writeTag(output, 1, 0);
      _writeVarint(output, component);
    }
    _writeLengthDelimited(output, 2, Uint8List.fromList(utf8.encode(request.key)));
    _writeLengthDelimited(output, 3, request.value);
    _writeBool(output, 4, request.encrypt);
    _writeBool(output, 5, request.askOnEncrypt);
    _writeBool(output, 6, request.askOnDecrypt);
    if (request.iv != null) _writeLengthDelimited(output, 7, request.iv!);
    return output.takeBytes();
  }

  static Uint8List decodeResponse(Uint8List payload) {
    var offset = 0;
    Uint8List? value;

    while (offset < payload.length) {
      final tag = _readVarint(payload, offset);
      offset = tag.nextOffset;
      final field = tag.value >> 3;
      final wireType = tag.value & 0x07;

      if (field == 1 && wireType == 2) {
        final length = _readVarint(payload, offset);
        offset = length.nextOffset;
        final end = offset + length.value;
        if (end > payload.length) throw const FormatException("Truncated CipheredKeyValue value");
        value = Uint8List.fromList(payload.sublist(offset, end));
        offset = end;
      } else {
        offset = _skipField(payload, offset, wireType);
      }
    }

    if (value == null) throw const FormatException("CipheredKeyValue response has no value");
    return value;
  }

  static void _writeBool(BytesBuilder output, int field, bool value) {
    _writeTag(output, field, 0);
    output.addByte(value ? 1 : 0);
  }

  static void _writeLengthDelimited(BytesBuilder output, int field, Uint8List value) {
    _writeTag(output, field, 2);
    _writeVarint(output, value.length);
    output.add(value);
  }

  static void _writeTag(BytesBuilder output, int field, int wireType) =>
      _writeVarint(output, (field << 3) | wireType);

  static void _writeVarint(BytesBuilder output, int value) {
    var remaining = value;
    while (remaining >= 0x80) {
      output.addByte((remaining & 0x7f) | 0x80);
      remaining >>= 7;
    }
    output.addByte(remaining);
  }

  static ({int value, int nextOffset}) _readVarint(Uint8List bytes, int offset) {
    var result = 0;
    var shift = 0;
    var cursor = offset;
    while (cursor < bytes.length && shift <= 63) {
      final byte = bytes[cursor++];
      result |= (byte & 0x7f) << shift;
      if ((byte & 0x80) == 0) return (value: result, nextOffset: cursor);
      shift += 7;
    }
    throw const FormatException("Invalid protobuf varint");
  }

  static int _skipField(Uint8List bytes, int offset, int wireType) {
    switch (wireType) {
      case 0:
        return _readVarint(bytes, offset).nextOffset;
      case 1:
        final end = offset + 8;
        if (end > bytes.length) throw const FormatException("Truncated fixed64 field");
        return end;
      case 2:
        final length = _readVarint(bytes, offset);
        final end = length.nextOffset + length.value;
        if (end > bytes.length) throw const FormatException("Truncated length-delimited field");
        return end;
      case 5:
        final end = offset + 4;
        if (end > bytes.length) throw const FormatException("Truncated fixed32 field");
        return end;
      default:
        throw FormatException("Unsupported protobuf wire type $wireType");
    }
  }
}

abstract interface class OneKeyCipherKeyValueClient {
  Future<Uint8List> cipher(OneKeyCipherKeyValueRequest request);
}

class OneKeyCipherKeyValueService implements OneKeyCipherKeyValueClient {
  OneKeyCipherKeyValueService(this.client);

  final TrezorClient client;

  @override
  Future<Uint8List> cipher(OneKeyCipherKeyValueRequest request) async {
    var response = await _call(
      oneKeyCipherKeyValueMessageType,
      OneKeyCipherKeyValueCodec.encodeRequest(request),
    );

    for (var interaction = 0; interaction < 8; interaction++) {
      switch (response.messageTypeRaw) {
        case oneKeyCipheredKeyValueMessageType:
          return OneKeyCipherKeyValueCodec.decodeResponse(response.payload);
        case 26: // ButtonRequest
          response = await _call(27, ButtonAck().writeToBuffer());
          continue;
        case 3: // Failure
          final failure = Failure.fromBuffer(response.payload);
          throw StateError("OneKey CipherKeyValue failed: ${failure.message}");
        default:
          throw StateError(
            "Unexpected OneKey CipherKeyValue response ${response.messageTypeRaw}",
          );
      }
    }

    throw StateError("Too many OneKey CipherKeyValue interaction requests");
  }

  Future<TrezorResponse> _call(int messageType, Uint8List payload) =>
      client.connection.sendOperation(
        TrezorV1Operation(messageType: messageType, data: payload),
        transformer: const V1Transformer(),
      );
}
