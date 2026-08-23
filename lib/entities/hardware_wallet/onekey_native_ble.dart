import "dart:async";
import "dart:collection";
import "dart:math";
import "dart:typed_data";

import "package:trezor_flutter/src/api/api.dart";
import "package:trezor_flutter/src/exceptions/trezor_exception.dart";
import "package:trezor_flutter/src/models/connection_type.dart";
import "package:trezor_flutter/src/operations/trezor_operations.dart";
import "package:trezor_flutter/src/utils/buffer.dart";
import "package:trezor_flutter/trezor_flutter.dart";
import "package:universal_ble/universal_ble.dart";

const oneKeyBleServiceUuid = "00000001-0000-1000-8000-00805f9b34fb";
const oneKeyBleWriteUuid = "00000002-0000-1000-8000-00805f9b34fb";
const oneKeyBleNotifyUuid = "00000003-0000-1000-8000-00805f9b34fb";

const _oneKeyBlePacketSize = 64;
const _oneKeyBleRequestedMtu = 247;
const _oneKeyBleWriteTimeout = Duration(seconds: 10);
const _oneKeyBleConnectTimeout = Duration(seconds: 30);

class OneKeyNativeBleInterface {
  OneKeyNativeBleInterface({
    required PermissionRequestCallback onPermissionRequest,
    required BluetoothOptions options,
  }) : _manager = OneKeyNativeBleManager(
          onPermissionRequest: onPermissionRequest,
          options: options,
        );

  final OneKeyNativeBleManager _manager;

  Stream<TrezorDevice> scan() => _manager.scan();

  Future<TrezorConnection> connect(TrezorDevice device) async {
    await stopScanning();
    await _manager.connect(device);
    return TrezorConnection(_manager, device);
  }

  Future<void> stopScanning() => _manager.stopScanning();
}

class OneKeyNativeBleManager extends ConnectionManager {
  OneKeyNativeBleManager({
    required this.onPermissionRequest,
    required this.options,
  }) {
    UniversalBle.onConnectionChange = (deviceId, isConnected, error) {
      _connectionChanges.add(
        isConnected ? BleConnectionState.connected : BleConnectionState.disconnected,
      );
    };
  }

  final PermissionRequestCallback onPermissionRequest;
  final BluetoothOptions options;
  final Map<String, ({OneKeyV1GattGateway gateway, TrezorDevice device})> _connected = {};
  final StreamController<BleConnectionState> _connectionChanges =
      StreamController<BleConnectionState>.broadcast();
  final StreamController<AvailabilityState> _availabilityChanges =
      StreamController<AvailabilityState>.broadcast();

  StreamController<TrezorDevice>? _scanController;
  bool _isScanning = false;
  bool _disposed = false;

  @override
  final ConnectionType connectionType = ConnectionType.ble;

  Stream<TrezorDevice> scan() async* {
    _ensureActive();
    if (!await _requestPermission()) {
      throw PermissionException(connectionType: ConnectionType.ble);
    }
    if (_isScanning && _scanController != null) {
      yield* _scanController!.stream;
      return;
    }

    _isScanning = true;
    final controller = StreamController<TrezorDevice>.broadcast();
    _scanController = controller;
    final scannedIds = <String>{};

    UniversalBle.onScanResult = (result) {
      if (!isOneKeyBleAdvertisement(result.services, name: result.name) ||
          scannedIds.contains(result.deviceId)) {
        return;
      }

      final device = TrezorDevice.ble(
        id: result.deviceId,
        name: result.name ?? "OneKey Pro",
        rssi: result.rssi ?? 0,
        // Native OneKey Pro speaks the V1 Monero wire protocol over BLE.
        deviceInfo: TrezorDeviceType.safe5,
      );
      scannedIds.add(device.id);
      if (!controller.isClosed) controller.add(device);
    };

    unawaited(_performScan());
    yield* controller.stream;
  }

  Future<void> _performScan() async {
    try {
      await UniversalBle.startScan(
        scanFilter: ScanFilter(withServices: [oneKeyBleServiceUuid]),
      );
      await Future<void>.delayed(options.maxScanDuration);
    } finally {
      await stopScanning();
    }
  }

  Future<void> stopScanning() async {
    if (!_isScanning) return;
    _isScanning = false;
    try {
      await UniversalBle.stopScan();
    } finally {
      UniversalBle.onScanResult = null;
      await _scanController?.close();
      _scanController = null;
    }
  }

  @override
  Future<void> connect(TrezorDevice device) async {
    _ensureActive();
    if (!await _requestPermission()) {
      throw PermissionException(connectionType: ConnectionType.ble);
    }

    try {
      final state = await UniversalBle.getConnectionState(device.id);
      if (state != BleConnectionState.connected) {
        await UniversalBle.connect(device.id).timeout(_oneKeyBleConnectTimeout);
      }

      final services =
          await UniversalBle.discoverServices(device.id).timeout(_oneKeyBleConnectTimeout);
      final gateway = OneKeyV1GattGateway(device: device, services: services);
      await gateway.start().timeout(_oneKeyBleConnectTimeout);
      _connected[device.id] = (gateway: gateway, device: device);
    } catch (error) {
      await disconnect(device.id).catchError((_) {});
      throw EstablishConnectionException(
        connectionType: ConnectionType.ble,
        nestedError: error,
      );
    }
  }

  @override
  Future<T> sendRawOperation<T>(
    TrezorDevice device,
    TrezorOperation<T> operation,
    TrezorTransformer? transformer,
  ) {
    _ensureActive();
    final connected = _connected[device.id];
    if (connected == null) {
      throw DeviceNotConnectedException(
        requestedOperation: "OneKey native BLE sendOperation",
        connectionType: ConnectionType.ble,
      );
    }
    return connected.gateway.sendOperation(operation, transformer: transformer);
  }

  @override
  Future<void> disconnect(String deviceId) async {
    final gateway = _connected.remove(deviceId)?.gateway;
    if (gateway != null) {
      await gateway.disconnect();
    } else {
      await UniversalBle.disconnect(deviceId);
    }
  }

  @override
  Future<List<TrezorDevice>> get devices async =>
      _connected.values.map((entry) => entry.device).toList(growable: false);

  @override
  Future<AvailabilityState> get status => UniversalBle.getBluetoothAvailabilityState();

  @override
  Stream<AvailabilityState> get statusStateChanges {
    UniversalBle.onAvailabilityChange = _availabilityChanges.add;
    return _availabilityChanges.stream;
  }

  @override
  Stream<BleConnectionState> get deviceStateChanges => _connectionChanges.stream;

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    await stopScanning();
    for (final deviceId in List<String>.from(_connected.keys)) {
      await disconnect(deviceId).catchError((_) {});
    }
    _disposed = true;
    UniversalBle.onConnectionChange = null;
    UniversalBle.onAvailabilityChange = null;
    await _connectionChanges.close();
    await _availabilityChanges.close();
  }

  Future<bool> _requestPermission() async {
    final state = await UniversalBle.getBluetoothAvailabilityState();
    return onPermissionRequest(state);
  }

  void _ensureActive() {
    if (_disposed) throw TrezorManagerDisposedException(ConnectionType.ble);
  }
}

/// Identifies a native OneKey BLE advertisement.
///
/// Android can return an empty service list even when the platform scan filter
/// matched the OneKey service, especially for an already bonded device.  In
/// that case the advertised name is used only to keep the device in the
/// candidate list; [OneKeyV1GattGateway.start] still validates the native
/// service and both required characteristics before any protocol traffic.
bool isOneKeyBleAdvertisement(List<String> services, {String? name}) {
  final normalizedServices = services.map(_normalizeUuid);
  final hasNativeService = normalizedServices.any(
    (service) =>
        service == _normalizeUuid(oneKeyBleServiceUuid) ||
        service == "0001" ||
        service == "00000001",
  );
  if (hasNativeService) return true;

  return (name ?? "").trim().toLowerCase().contains("onekey");
}

class OneKeyV1GattGateway {
  OneKeyV1GattGateway({required this.device, required this.services});

  final TrezorDevice device;
  final List<BleService> services;
  final Queue<_OneKeyBleRequest<dynamic>> _pending = Queue();

  BleCharacteristic? _writeCharacteristic;
  BleCharacteristic? _notifyCharacteristic;
  bool _disposed = false;
  int? _expectedPayloadLength;
  final List<int> _responseBuffer = [];

  Future<void> start() async {
    final service = services.cast<BleService?>().firstWhere(
          (item) => _normalizeUuid(item?.uuid) == _normalizeUuid(oneKeyBleServiceUuid),
          orElse: () => null,
        );
    if (service == null) {
      throw StateError("OneKey BLE communication service not found");
    }

    _writeCharacteristic = _findCharacteristic(service, oneKeyBleWriteUuid);
    _notifyCharacteristic = _findCharacteristic(service, oneKeyBleNotifyUuid);
    if (_writeCharacteristic == null || _notifyCharacteristic == null) {
      throw StateError("OneKey BLE write/notify characteristics not found");
    }

    await UniversalBle.requestMtu(device.id, _oneKeyBleRequestedMtu).catchError((_) => 23);
    await _pairIfNeeded();
    await UniversalBle.subscribeNotifications(
      device.id,
      oneKeyBleServiceUuid,
      oneKeyBleNotifyUuid,
    );
    UniversalBle.onValueChange = _onValueChange;
  }

  Future<T> sendOperation<T>(
    TrezorOperation<T> operation, {
    TrezorTransformer? transformer,
  }) async {
    if (_disposed) throw StateError("OneKey BLE gateway is closed");

    final completer = Completer<T>();
    final request = _OneKeyBleRequest<T>(operation, transformer, completer);
    _pending.addLast(request);

    try {
      final writer = ByteDataWriter();
      final message = await operation.write(writer);
      final packets = OneKeyV1BlePacker.pack(message);
      final writeWithoutResponse =
          _writeCharacteristic!.properties.contains(CharacteristicProperty.writeWithoutResponse);

      for (final packet in packets) {
        await UniversalBle.write(
          device.id,
          oneKeyBleServiceUuid,
          oneKeyBleWriteUuid,
          packet,
          withoutResponse: writeWithoutResponse,
          timeout: _oneKeyBleWriteTimeout,
        );
      }
      return completer.future;
    } catch (error, stackTrace) {
      _pending.remove(request);
      if (!completer.isCompleted) completer.completeError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_disposed) return;
    _disposed = true;
    UniversalBle.onValueChange = null;
    await UniversalBle.unsubscribe(device.id, oneKeyBleServiceUuid, oneKeyBleNotifyUuid)
        .catchError((_) {});
    await UniversalBle.disconnect(device.id).catchError((_) {});
    while (_pending.isNotEmpty) {
      final request = _pending.removeFirst();
      if (!request.completer.isCompleted) {
        request.completer.completeError(StateError("OneKey BLE disconnected"));
      }
    }
  }

  Future<void> _pairIfNeeded() async {
    final paired = await UniversalBle.isPaired(
      device.id,
      pairingCommand: BleCommand(
        service: oneKeyBleServiceUuid,
        characteristic: oneKeyBleWriteUuid,
      ),
    );
    if (paired == true) return;

    final completer = Completer<void>();
    UniversalBle.onPairingStateChange = (deviceId, isPaired) {
      if (deviceId != device.id || completer.isCompleted) return;
      isPaired
          ? completer.complete()
          : completer.completeError(StateError("OneKey BLE pairing failed"));
    };
    try {
      await UniversalBle.pair(device.id);
      await completer.future.timeout(_oneKeyBleConnectTimeout);
    } finally {
      UniversalBle.onPairingStateChange = (deviceId, isPaired) {};
    }
  }

  void _onValueChange(
    String deviceId,
    String characteristicId,
    Uint8List rawData,
    int? timestamp,
  ) {
    if (_disposed || deviceId != device.id || _pending.isEmpty || rawData.isEmpty) return;

    try {
      if (_isHeaderChunk(rawData)) {
        if (rawData.length < 9) throw StateError("Invalid OneKey BLE response header");
        _expectedPayloadLength = ByteData.sublistView(rawData, 5, 9).getUint32(0);
        _responseBuffer
          ..clear()
          ..addAll(rawData.sublist(3));
      } else {
        if (_expectedPayloadLength == null) return;
        _responseBuffer.addAll(rawData);
      }

      final expectedMessageLength = 6 + (_expectedPayloadLength ?? 0);
      if (_responseBuffer.length < expectedMessageLength) return;

      final response = Uint8List.fromList([
        0x3f,
        0x23,
        0x23,
        ..._responseBuffer.take(expectedMessageLength),
      ]);
      _responseBuffer.clear();
      _expectedPayloadLength = null;
      unawaited(_completeRequest(response));
    } catch (error, stackTrace) {
      final request = _pending.removeFirst();
      if (!request.completer.isCompleted) request.completer.completeError(error, stackTrace);
    }
  }

  Future<void> _completeRequest(Uint8List response) async {
    if (_pending.isEmpty) return;
    final request = _pending.removeFirst();
    try {
      final reader = ByteDataReader();
      final transformer = request.transformer;
      reader.add(transformer == null ? response : await transformer.onTransform([response]));
      final result = await request.operation.read(reader);
      if (!request.completer.isCompleted) request.completer.complete(result);
    } catch (error, stackTrace) {
      if (!request.completer.isCompleted) request.completer.completeError(error, stackTrace);
    }
  }

  static BleCharacteristic? _findCharacteristic(BleService service, String uuid) {
    final expected = _normalizeUuid(uuid);
    for (final characteristic in service.characteristics) {
      if (_normalizeUuid(characteristic.uuid) == expected) return characteristic;
    }
    return null;
  }

  static bool _isHeaderChunk(Uint8List bytes) =>
      bytes.length >= 9 && bytes[0] == 0x3f && bytes[1] == 0x23 && bytes[2] == 0x23;
}

class OneKeyV1BlePacker {
  static List<Uint8List> pack(Uint8List message) {
    if (message.isEmpty || message.first != 0x3f) {
      throw ArgumentError("OneKey BLE V1 message must start with 0x3f");
    }

    final packets = <Uint8List>[];
    packets.add(_pad(message.sublist(0, min(message.length, _oneKeyBlePacketSize))));

    var offset = _oneKeyBlePacketSize;
    while (offset < message.length) {
      final end = min(offset + _oneKeyBlePacketSize - 1, message.length);
      packets.add(_pad(Uint8List.fromList([0x3f, ...message.sublist(offset, end)])));
      offset = end;
    }
    return packets;
  }

  static Uint8List _pad(List<int> bytes) => Uint8List.fromList([
        ...bytes,
        ...List<int>.filled(_oneKeyBlePacketSize - bytes.length, 0),
      ]);
}

class _OneKeyBleRequest<T> {
  _OneKeyBleRequest(this.operation, this.transformer, this.completer);

  final TrezorOperation<T> operation;
  final TrezorTransformer? transformer;
  final Completer<T> completer;
}

String _normalizeUuid(String? uuid) => (uuid ?? "").replaceAll("-", "").toLowerCase();
