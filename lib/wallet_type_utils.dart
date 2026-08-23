import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/wallet_types.g.dart';
import 'package:cake_wallet/product_flavor.dart';

bool get isMoneroOnly {
  return availableWalletTypes.length == 1 && availableWalletTypes.first == WalletType.monero;
}

bool get isSingleCoin {
  return availableWalletTypes.length == 1;
}

bool get isZcashOnly {
  return availableWalletTypes.length == 1 && availableWalletTypes.first == WalletType.zcash;
}

bool get isPrivacyWallet {
  return availableWalletTypes.length == 2 &&
      availableWalletTypes.contains(WalletType.monero) &&
      availableWalletTypes.contains(WalletType.zcash);
}

bool get hasMonero {
  return availableWalletTypes.contains(WalletType.monero);
}

bool get hasZcash {
  return availableWalletTypes.contains(WalletType.zcash);
}

String get approximatedAppName => currentProductFlavor.displayName;
