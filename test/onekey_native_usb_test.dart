import "package:cake_wallet/entities/hardware_wallet/onekey_native_usb.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("OneKey native USB accepts only the native Pro identity", () {
    expect(
      OneKeyNativeUsbManager.isSupportedIdentity(vendorId: 0x1209, productId: 0x4f4b),
      isTrue,
    );
    expect(
      OneKeyNativeUsbManager.isSupportedIdentity(vendorId: 0x1209, productId: 0x53c1),
      isFalse,
      reason: "Trezor compatibility mode must not be accepted as native OneKey",
    );
    expect(
      OneKeyNativeUsbManager.isSupportedIdentity(vendorId: 0x534c, productId: 0x0001),
      isFalse,
    );
  });
}
