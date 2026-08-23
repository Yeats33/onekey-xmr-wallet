import "package:cake_wallet/product_flavor.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("privacy product identifiers remain stable", () {
    expect(ProductFlavor.xmrWallet.id, "onekey-xmr");
    expect(ProductFlavor.zecWallet.id, "onekey-zec");
    expect(ProductFlavor.pWallet.id, "pwallet");
  });

  test("unknown flavor falls back to the released XMR product", () {
    expect(ProductFlavor.fromId("unknown"), ProductFlavor.xmrWallet);
  });

  test("only the three fork products use privacy branding", () {
    expect(ProductFlavor.xmrWallet.isPrivacyProduct, isTrue);
    expect(ProductFlavor.zecWallet.isPrivacyProduct, isTrue);
    expect(ProductFlavor.pWallet.isPrivacyProduct, isTrue);
    expect(ProductFlavor.cakeWallet.isPrivacyProduct, isFalse);
  });
}
