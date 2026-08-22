import "package:cake_wallet/entities/hardware_wallet/onekey_native_usb.dart";
import "package:cake_wallet/entities/hardware_wallet/onekey_native_ble.dart";
import "package:trezor_flutter/trezor_flutter.dart" as sdk;

abstract interface class MoneroUsbInterface {
  Future<List<sdk.TrezorDevice>> get devices;

  Future<sdk.TrezorConnection> connect(sdk.TrezorDevice device);

  Future<void> stopScanning();
}

class TrezorMoneroUsbInterface implements MoneroUsbInterface {
  TrezorMoneroUsbInterface() : _delegate = sdk.TrezorInterface.usb();

  final sdk.TrezorInterface _delegate;

  @override
  Future<List<sdk.TrezorDevice>> get devices => _delegate.devices;

  @override
  Future<sdk.TrezorConnection> connect(sdk.TrezorDevice device) => _delegate.connect(device);

  @override
  Future<void> stopScanning() => _delegate.stopScanning();
}

class OneKeyMoneroUsbInterface implements MoneroUsbInterface {
  OneKeyMoneroUsbInterface() : _delegate = OneKeyNativeUsbInterface();

  final OneKeyNativeUsbInterface _delegate;

  @override
  Future<List<sdk.TrezorDevice>> get devices => _delegate.devices;

  @override
  Future<sdk.TrezorConnection> connect(sdk.TrezorDevice device) => _delegate.connect(device);

  @override
  Future<void> stopScanning() => _delegate.stopScanning();
}

abstract interface class MoneroBleInterface {
  Stream<sdk.TrezorDevice> scan();

  Future<sdk.TrezorConnection> connect(sdk.TrezorDevice device);

  Future<void> stopScanning();
}

class TrezorMoneroBleInterface implements MoneroBleInterface {
  TrezorMoneroBleInterface({
    required sdk.PermissionRequestCallback onPermissionRequest,
    required sdk.BluetoothOptions options,
  }) : _delegate = sdk.TrezorInterface.ble(
          onPermissionRequest: onPermissionRequest,
          bleOptions: options,
        );

  final sdk.TrezorInterface _delegate;

  @override
  Stream<sdk.TrezorDevice> scan() => _delegate.scan();

  @override
  Future<sdk.TrezorConnection> connect(sdk.TrezorDevice device) => _delegate.connect(device);

  @override
  Future<void> stopScanning() => _delegate.stopScanning();
}

class OneKeyMoneroBleInterface implements MoneroBleInterface {
  OneKeyMoneroBleInterface({
    required sdk.PermissionRequestCallback onPermissionRequest,
    required sdk.BluetoothOptions options,
  }) : _delegate = OneKeyNativeBleInterface(
          onPermissionRequest: onPermissionRequest,
          options: options,
        );

  final OneKeyNativeBleInterface _delegate;

  @override
  Stream<sdk.TrezorDevice> scan() => _delegate.scan();

  @override
  Future<sdk.TrezorConnection> connect(sdk.TrezorDevice device) => _delegate.connect(device);

  @override
  Future<void> stopScanning() => _delegate.stopScanning();
}
