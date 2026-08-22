import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:cw_core/hardware/device_connection_type.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("OneKey has a stable persisted enum value", () {
    expect(HardwareWalletType.values[6], HardwareWalletType.trezor);
    expect(HardwareWalletType.values[7], HardwareWalletType.onekey);
  });

  test("OneKey and Trezor share the Monero hardware protocol", () {
    expect(HardwareWalletType.onekey.usesTrezorMoneroProtocol, isTrue);
    expect(HardwareWalletType.trezor.usesTrezorMoneroProtocol, isTrue);
    expect(HardwareWalletType.ledger.usesTrezorMoneroProtocol, isFalse);
  });

  test("OneKey native support includes Android BLE and USB", () {
    expect(
      DeviceConnectionType.supportedConnectionTypes(
        WalletType.monero,
        HardwareWalletType.onekey,
      ),
      [DeviceConnectionType.ble, DeviceConnectionType.usb],
    );
    expect(
      DeviceConnectionType.supportedConnectionTypes(
        WalletType.monero,
        HardwareWalletType.onekey,
        true,
      ),
      isEmpty,
    );
  });
}
