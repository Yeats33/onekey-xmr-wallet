import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/hardware/hardware_seed_key_protector.dart';

class ZcashNewWalletCredentials extends WalletCredentials {
  ZcashNewWalletCredentials({
    required final String name,
    final String? password,
    required final String? passphrase,
    final String? mnemonic,
    final int? seedPhraseLength,
    this.network = 0,
    this.seedKeyProtector,
  }) : super(
         name: name,
         password: password,
         passphrase: passphrase,
         seedPhraseLength: seedPhraseLength,
       ) {
    this.mnemonic = mnemonic;
  }

  String? mnemonic;
  int network;
  final HardwareSeedKeyProtector? seedKeyProtector;
}

class ZcashFromSeedWalletCredentials extends WalletCredentials {
  ZcashFromSeedWalletCredentials({
    required final String name,
    final String? password,
    required final String? passphrase,
    required this.seed,
    required super.height,
    this.network = 0,
    this.seedKeyProtector,
  }) : super(name: name, password: password, passphrase: passphrase);
  String? seed;
  int network;
  final HardwareSeedKeyProtector? seedKeyProtector;
}

class ZcashFromKeysWalletCredentials extends WalletCredentials {
  ZcashFromKeysWalletCredentials({
    required final String name,
    final String? password,
    required final int? height,
    required this.privateKey,
    this.network = 0,
  }) : super(name: name, password: password, height: height);
  final String? privateKey;
  int network;
}
