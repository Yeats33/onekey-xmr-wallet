import "dart:typed_data";

import "package:cake_wallet/entities/hardware_wallet/onekey_native_ble.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("OneKey BLE uses the native GATT service", () {
    expect(oneKeyBleServiceUuid, "00000001-0000-1000-8000-00805f9b34fb");
    expect(oneKeyBleWriteUuid, "00000002-0000-1000-8000-00805f9b34fb");
    expect(oneKeyBleNotifyUuid, "00000003-0000-1000-8000-00805f9b34fb");
  });

  test("OneKey BLE recognizes bonded Android advertisements without service data", () {
    expect(isOneKeyBleAdvertisement(const [], name: "OneKey Pro"), isTrue);
    expect(isOneKeyBleAdvertisement(const [], name: "Unknown wallet"), isFalse);
  });

  test("OneKey BLE recognizes full and shortened native service UUIDs", () {
    expect(isOneKeyBleAdvertisement([oneKeyBleServiceUuid]), isTrue);
    expect(isOneKeyBleAdvertisement(const ["0001"]), isTrue);
    expect(isOneKeyBleAdvertisement(const ["00000001"]), isTrue);
  });

  test("OneKey BLE V1 packer emits 64-byte transport reports", () {
    final message = Uint8List.fromList(List<int>.generate(150, (index) => index & 0xff));
    message[0] = 0x3f;

    final packets = OneKeyV1BlePacker.pack(message);
    expect(packets, hasLength(3));
    expect(packets.every((packet) => packet.length == 64), isTrue);
    expect(packets.first, message.sublist(0, 64));
    expect(packets[1].first, 0x3f);
    expect(packets[1].sublist(1), message.sublist(64, 127));
    expect(packets[2].first, 0x3f);
    expect(packets[2].sublist(1, 24), message.sublist(127));
    expect(packets[2].sublist(24).every((byte) => byte == 0), isTrue);
  });
}
