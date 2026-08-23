import "package:cake_wallet/product_flavor.dart";
import "package:cake_wallet/wallet_types.g.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("compiled product contains only its declared currencies", () {
    final expected = switch (currentProductFlavor) {
      ProductFlavor.xmrWallet => [WalletType.monero],
      ProductFlavor.zecWallet => [WalletType.zcash],
      ProductFlavor.pWallet => [WalletType.monero, WalletType.zcash],
      ProductFlavor.moneroCom => [WalletType.monero],
      ProductFlavor.cakeWallet => availableWalletTypes,
    };

    expect(availableWalletTypes, expected);
  });
}
