import "dart:typed_data";

import "package:cake_wallet/entities/hardware_wallet/onekey_cipher_key_value.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("CipherKeyValue encodes the stock OneKey protobuf fields", () {
    final request = OneKeyCipherKeyValueRequest(
      addressPath: [1],
      key: "k",
      value: Uint8List(16),
      encrypt: true,
      askOnDecrypt: true,
    );

    expect(
      OneKeyCipherKeyValueCodec.encodeRequest(request),
      [
        0x08,
        0x01,
        0x12,
        0x01,
        0x6b,
        0x1a,
        0x10,
        ...List<int>.filled(16, 0),
        0x20,
        0x01,
        0x28,
        0x00,
        0x30,
        0x01,
      ],
    );
  });

  test("CipheredKeyValue decoder accepts unknown fields", () {
    final decoded = OneKeyCipherKeyValueCodec.decodeResponse(
      Uint8List.fromList([0x10, 0x01, 0x0a, 0x03, 1, 2, 3]),
    );
    expect(decoded, [1, 2, 3]);
  });

  test("CipherKeyValue rejects unsafe value and IV sizes", () {
    expect(
      () => OneKeyCipherKeyValueRequest(
        addressPath: [1],
        key: "zec-vault",
        value: Uint8List(31),
        encrypt: true,
      ),
      throwsArgumentError,
    );
    expect(
      () => OneKeyCipherKeyValueRequest(
        addressPath: [1],
        key: "zec-vault",
        value: Uint8List(32),
        encrypt: true,
        iv: Uint8List(15),
      ),
      throwsArgumentError,
    );
  });
}
