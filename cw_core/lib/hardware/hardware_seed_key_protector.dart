import 'dart:typed_data';

abstract interface class HardwareSeedKeyProtector {
  Future<void> protect({
    required String domain,
    required int network,
    required int accountId,
    required Uint8List key,
  });

  Future<Uint8List> unlock({
    required String domain,
    required int network,
    required int accountId,
  });

  Future<void> remove({
    required String domain,
    required int network,
    required int accountId,
  });
}
