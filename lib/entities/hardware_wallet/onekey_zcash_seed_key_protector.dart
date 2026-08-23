import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/entities/hardware_wallet/onekey_cipher_key_value.dart';
import 'package:cw_core/hardware/hardware_seed_key_protector.dart';

class OneKeyZcashSeedKeyProtector implements HardwareSeedKeyProtector {
  OneKeyZcashSeedKeyProtector(this._cipherService, this._secureStorage);

  static const _version = 1;
  static const _zcashPath = <int>[
    0x8000002c, // 44'
    0x80000085, // Zcash coin type 133'
    0x80000000, // account 0'
  ];

  final OneKeyCipherKeyValueClient _cipherService;
  final SecureStorage _secureStorage;

  @override
  Future<void> protect({
    required String domain,
    required int network,
    required int accountId,
    required Uint8List key,
  }) async {
    if (key.length != 32) {
      throw ArgumentError.value(key.length, 'key.length', 'must be exactly 32 bytes');
    }
    final random = Random.secure();
    final iv = Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256), growable: false),
    );
    final cipherKey = _cipherKey(domain: domain, network: network, accountId: accountId);
    final wrappedKey = await _cipherService.cipher(
      OneKeyCipherKeyValueRequest(
        addressPath: _zcashPath,
        key: cipherKey,
        value: key,
        iv: iv,
        encrypt: true,
        askOnEncrypt: true,
        askOnDecrypt: true,
      ),
    );
    if (wrappedKey.length != 32) {
      throw StateError('OneKey returned an invalid wrapped ZEC vault key');
    }

    await _secureStorage.write(
      key: _storageKey(domain: domain, network: network, accountId: accountId),
      value: jsonEncode({
        'version': _version,
        'iv': base64Encode(iv),
        'wrappedKey': base64Encode(wrappedKey),
      }),
    );
  }

  @override
  Future<Uint8List> unlock({
    required String domain,
    required int network,
    required int accountId,
  }) async {
    final encoded = await _secureStorage.read(
      key: _storageKey(domain: domain, network: network, accountId: accountId),
    );
    if (encoded == null) {
      throw StateError('OneKey protection record is missing for this ZEC wallet');
    }
    final record = jsonDecode(encoded);
    if (record is! Map<String, dynamic> || record['version'] != _version) {
      throw const FormatException('Unsupported OneKey ZEC protection record');
    }
    final iv = _decodeField(record, 'iv', 16);
    final wrappedKey = _decodeField(record, 'wrappedKey', 32);
    final vaultKey = await _cipherService.cipher(
      OneKeyCipherKeyValueRequest(
        addressPath: _zcashPath,
        key: _cipherKey(domain: domain, network: network, accountId: accountId),
        value: wrappedKey,
        iv: iv,
        encrypt: false,
        askOnEncrypt: true,
        askOnDecrypt: true,
      ),
    );
    if (vaultKey.length != 32) {
      throw StateError('OneKey returned an invalid ZEC vault key');
    }
    return vaultKey;
  }

  @override
  Future<void> remove({
    required String domain,
    required int network,
    required int accountId,
  }) =>
      _secureStorage.delete(
        key: _storageKey(domain: domain, network: network, accountId: accountId),
      );

  static Uint8List _decodeField(Map<String, dynamic> record, String name, int expectedLength) {
    final value = record[name];
    if (value is! String) {
      throw FormatException('OneKey ZEC protection record has no $name');
    }
    final decoded = base64Decode(value);
    if (decoded.length != expectedLength) {
      throw FormatException('OneKey ZEC protection record has invalid $name');
    }
    return decoded;
  }

  static String _cipherKey({
    required String domain,
    required int network,
    required int accountId,
  }) =>
      'PWallet/$domain/v$_version/$network/$accountId';

  static String _storageKey({
    required String domain,
    required int network,
    required int accountId,
  }) =>
      'com.yeats33.privacywallet/onekey-vault/$domain/$network/$accountId';
}
