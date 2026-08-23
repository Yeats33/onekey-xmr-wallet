import "dart:async";

import "package:flutter/services.dart";
import "package:trezor_flutter/src/api/api.dart";
import "package:trezor_flutter/src/exceptions/trezor_exception.dart";
import "package:trezor_flutter/src/operations/trezor/thp_ack_operation.dart";
import "package:trezor_flutter/src/operations/trezor/v1_operation.dart";
import "package:trezor_flutter/src/operations/trezor_operations.dart";
import "package:trezor_flutter/src/trezor/protobuf/messages-management.pb.dart";
import "package:trezor_flutter/src/trezor/protobuf/utils.dart";
import "package:trezor_flutter/src/trezor/protocol/constants/constants_v2.dart";
import "package:trezor_flutter/src/trezor/protocol/decoder.dart";
import "package:trezor_flutter/src/trezor/transformer/v1_transformer.dart";
import "package:trezor_flutter/src/utils/buffer.dart";
import "package:trezor_flutter/src/utils/exception_utils.dart";
import "package:trezor_flutter/trezor_flutter.dart";
import "package:trezor_usb_transport/trezor_usb_transport.dart";
import "package:trezor_usb_transport/usb_device.dart";

/// Native USB transport for OneKey Pro.
///
/// This intentionally accepts only OneKey's native firmware identity. The
/// Trezor-compatibility PID (0x53c1) is rejected, so users do not need to enable
/// compatibility mode on the device.
class OneKeyNativeUsbInterface {
  OneKeyNativeUsbInterface() : _manager = OneKeyNativeUsbManager();

  final OneKeyNativeUsbManager _manager;

  Future<List<TrezorDevice>> get devices => _manager.devices;

  Future<TrezorConnection> connect(TrezorDevice device) async {
    await _manager.connect(device);
    return TrezorConnection(_manager, device);
  }

  Future<void> stopScanning() async {}

  Future<void> dispose() => _manager.dispose();
}

class OneKeyNativeUsbManager extends ConnectionManager {
  static const vendorId = 0x1209;
  static const proNativeProductId = 0x4f4b;
  static const expectedVendor = "onekey.so";

  static bool isSupportedIdentity({required int vendorId, required int productId}) =>
      vendorId == OneKeyNativeUsbManager.vendorId && productId == proNativeProductId;

  final TrezorUsbTransport _usbTransport = TrezorUsbTransport();
  final Map<String, TrezorDevice> _devices = {};
  bool _disposed = false;

  @override
  final ConnectionType connectionType = ConnectionType.usb;

  @override
  Future<void> connect(TrezorDevice device) async {
    if (_disposed) throw TrezorManagerDisposedException(connectionType);

    try {
      final usbDevice = UsbDevice.fromIdentifier(device.id);
      await _usbTransport.requestPermission(usbDevice);
      await _usbTransport.open(usbDevice);
    } on PlatformException catch (exception) {
      throw TrezorExceptionUtils.fromPlatformException(exception, connectionType);
    }
  }

  @override
  Future<void> disconnect(String deviceId) async {
    if (_disposed) throw TrezorManagerDisposedException(connectionType);

    try {
      await _usbTransport.close();
    } on PlatformException catch (exception) {
      throw TrezorExceptionUtils.fromPlatformException(exception, connectionType);
    }
  }

  @override
  Future<T> sendRawOperation<T>(
    TrezorDevice device,
    TrezorOperation<T> operation,
    TrezorTransformer? transformer,
  ) async {
    if (_disposed) throw TrezorManagerDisposedException(connectionType);

    try {
      final writer = ByteDataWriter();
      final payload = await operation.write(writer);
      await _usbTransport.transferOut(payload);

      final reader = ByteDataReader();
      if (operation is TrezorThpAckOperation) return operation.read(reader);

      var response = await _readResponse();
      if (response case TrezorPackageV2 responseV2) {
        if (responseV2.headers.controlByte == THPControlByte.ackMessage) {
          response = await _readResponse();
        }
      }

      if (transformer != null) {
        reader.add(await transformer.onTransform([response.asUint8List()]));
      } else {
        reader.add(response.asUint8List());
      }

      return operation.read(reader);
    } on PlatformException catch (exception) {
      throw TrezorExceptionUtils.fromPlatformException(exception, connectionType);
    }
  }

  @override
  Future<List<TrezorDevice>> get devices async {
    if (_disposed) throw TrezorManagerDisposedException(connectionType);

    try {
      final usbDevices = await _usbTransport.listDevices();
      final attachedIds =
          usbDevices.where(_isNativeOneKeyPro).map((device) => device.identifier).toSet();
      _devices.removeWhere((deviceId, _) => !attachedIds.contains(deviceId));

      for (final usbDevice in usbDevices.where(_isNativeOneKeyPro)) {
        final candidate = TrezorDevice.usb(usbDevice);
        if (_devices.containsKey(candidate.id)) continue;

        await connect(candidate);
        try {
          final initialize = await sendRawOperation(
            candidate,
            TrezorV1Operation(
              data: Initialize().writeToBuffer(),
              messageType: TrezorMessageType.initialize.raw,
            ),
            const V1Transformer(),
          );
          final features = Features.fromBuffer(initialize.payload);
          if (features.vendor.toLowerCase() != expectedVendor) continue;

          _devices[candidate.id] = TrezorDevice.usb(
            usbDevice,
            TrezorDeviceType.fromInternalModel(features.internalModel),
          );
        } finally {
          await disconnect(candidate.id);
        }
      }

      return _devices.values.toList(growable: false);
    } on PlatformException catch (exception) {
      throw TrezorExceptionUtils.fromPlatformException(exception, connectionType);
    }
  }

  bool _isNativeOneKeyPro(UsbDevice device) =>
      isSupportedIdentity(vendorId: device.vendorId, productId: device.productId);

  @override
  Future<AvailabilityState> get status async => AvailabilityState.poweredOn;

  @override
  Stream<AvailabilityState> get statusStateChanges => const Stream.empty();

  @override
  Stream<BleConnectionState> get deviceStateChanges => const Stream.empty();

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _devices.clear();
    try {
      await _usbTransport.close();
    } on PlatformException catch (exception) {
      throw TrezorExceptionUtils.fromPlatformException(exception, connectionType);
    } finally {
      _disposed = true;
    }
  }

  Future<TrezorPackage> _readResponse() async {
    final firstPacket = await _usbTransport.transferIn();
    if (firstPacket == null) {
      throw StateError("OneKey returned an empty USB response");
    }

    var package = TrezorDecoder.decodePackage(firstPacket);
    while (package.needsContinuationPacket) {
      final packet = await _usbTransport.transferIn();
      if (packet == null) {
        throw StateError("OneKey USB response ended before completion");
      }
      final continuation = TrezorDecoder.decodePackage(packet);
      package = package is TrezorPackageV1
          ? TrezorDecoder.reconstructV1Payload([package, continuation])
          : TrezorDecoder.reconstructV2Payload([package, continuation]);
    }
    return package;
  }
}
