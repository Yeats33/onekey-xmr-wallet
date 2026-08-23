import "dart:convert";
import "dart:typed_data";

import "package:cake_wallet/core/secure_storage.dart";
import "package:cake_wallet/entities/hardware_wallet/onekey_cipher_key_value.dart";
import "package:cake_wallet/entities/hardware_wallet/onekey_zcash_seed_key_protector.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("OneKey ZEC protector wraps and unlocks a vault key", () async {
    final cipher = _FakeCipher();
    final storage = _MemorySecureStorage();
    final protector = OneKeyZcashSeedKeyProtector(cipher, storage);
    final vaultKey = Uint8List.fromList(List<int>.generate(32, (index) => index));

    await protector.protect(domain: "zcash", network: 0, accountId: 7, key: vaultKey);

    expect(storage.values, hasLength(1));
    expect(storage.values.values.single, isNot(contains(base64Encode(vaultKey))));
    final unlocked = await protector.unlock(domain: "zcash", network: 0, accountId: 7);
    expect(unlocked, vaultKey);
    expect(cipher.requests, hasLength(2));
    expect(cipher.requests.first.encrypt, isTrue);
    expect(cipher.requests.last.encrypt, isFalse);
    expect(cipher.requests.first.addressPath, [0x8000002c, 0x80000085, 0x80000000]);
    expect(cipher.requests.every((request) => request.askOnDecrypt), isTrue);
  });

  test("OneKey ZEC protector binds records to account context", () async {
    final protector = OneKeyZcashSeedKeyProtector(_FakeCipher(), _MemorySecureStorage());
    final vaultKey = Uint8List(32);

    await protector.protect(domain: "zcash", network: 0, accountId: 7, key: vaultKey);

    expect(
      () => protector.unlock(domain: "zcash", network: 0, accountId: 8),
      throwsA(isA<StateError>()),
    );
  });

  test("OneKey ZEC protector rejects invalid vault key sizes", () async {
    final protector = OneKeyZcashSeedKeyProtector(_FakeCipher(), _MemorySecureStorage());

    expect(
      () => protector.protect(
        domain: "zcash",
        network: 0,
        accountId: 7,
        key: Uint8List(16),
      ),
      throwsArgumentError,
    );
  });
}

class _FakeCipher implements OneKeyCipherKeyValueClient {
  final requests = <OneKeyCipherKeyValueRequest>[];

  @override
  Future<Uint8List> cipher(OneKeyCipherKeyValueRequest request) async {
    requests.add(request);
    final context = utf8.encode(request.key).fold<int>(0, (sum, byte) => (sum + byte) & 0xff);
    return Uint8List.fromList(
      List<int>.generate(
        request.value.length,
        (index) => request.value[index] ^ request.iv![index % request.iv!.length] ^ context,
        growable: false,
      ),
    );
  }
}

class _MemorySecureStorage implements SecureStorage {
  final values = <String, String>{};

  @override
  Future<void> delete({required String key}) async => values.remove(key);

  @override
  Future<void> deleteAll() async => values.clear();

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<Map<String, String>> readAll() async => Map<String, String>.from(values);

  @override
  Future<String?> readNoIOptions({required String key}) => read(key: key);

  @override
  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}
