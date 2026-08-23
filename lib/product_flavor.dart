enum ProductFlavor {
  moneroCom("monero.com", "Monero.com"),
  cakeWallet("cakewallet", "Cake Wallet"),
  xmrWallet("onekey-xmr", "XMR Wallet"),
  zecWallet("onekey-zec", "ZEC Wallet"),
  pWallet("pwallet", "PWallet");

  const ProductFlavor(this.id, this.displayName);

  final String id;
  final String displayName;

  String get urlScheme => switch (this) {
        ProductFlavor.moneroCom => "monero.com",
        ProductFlavor.cakeWallet => "cakewallet",
        ProductFlavor.xmrWallet => "xmrwallet",
        ProductFlavor.zecWallet => "zecwallet",
        ProductFlavor.pWallet => "pwallet",
      };

  static ProductFlavor fromId(String id) => values.firstWhere(
        (flavor) => flavor.id == id,
        orElse: () => ProductFlavor.xmrWallet,
      );

  bool get isPrivacyProduct => switch (this) {
        ProductFlavor.xmrWallet || ProductFlavor.zecWallet || ProductFlavor.pWallet => true,
        ProductFlavor.moneroCom || ProductFlavor.cakeWallet => false,
      };
}

const productFlavorId = String.fromEnvironment(
  "PRODUCT_FLAVOR",
  defaultValue: "onekey-xmr",
);

final currentProductFlavor = ProductFlavor.fromId(productFlavorId);
