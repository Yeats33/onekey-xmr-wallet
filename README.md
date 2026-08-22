# XMR Wallet

Android-only, Monero-only wallet with first-class OneKey Pro and Trezor hardware-wallet support.

This project is based on [Cake Wallet](https://github.com/cake-tech/cake_wallet) v6.4.1 and retains its MIT license. It is an independent project and is not affiliated with OneKey, Trezor, or Cake Labs.

## OneKey support

OneKey is a separate hardware-wallet manufacturer in the application, not a renamed Trezor entry.

- Native OneKey Pro USB identity: `0x1209:0x4f4b`
- Native OneKey BLE service: `00000001-0000-1000-8000-00805f9b34fb`
- Dedicated USB/BLE transports and `MoneroOneKeyNativeService`
- Trezor compatibility mode must be disabled
- Native Android USB and Bluetooth connections
- Hardware passphrase sessions, Monero transaction signing, and key-image synchronization
- Private spend keys remain on the hardware wallet

The Monero wire-message schema remains shared with the implementation in OneKey firmware. Replacing that schema would require corresponding firmware changes.

## Android identity

- Application name: `XMR Wallet`
- Application ID: `com.yeats33.xmrwallet`
- Deep-link scheme: `xmrwallet`
- Current version: `1.2.0`

It can be installed alongside Cake Wallet and Monero.com because it uses a separate Android application ID.

## Configure and build

```bash
./configure_onekey_xmr.sh
./scripts/android/build_onekey_xmr.sh
```

Cake's shared Android plugins and native libraries must be prepared first. See [the Android build and device-testing guide](docs/ONEKEY_XMR_ANDROID.md).

Build outputs are written to `dist/android/` and deliberately excluded from Git history.

## Testing

The repository includes tests for:

- stable OneKey hardware-wallet persistence;
- rejection of the Trezor-compatibility USB PID by the native OneKey transport;
- native OneKey BLE UUIDs and V1 64-byte packet framing;
- Android OneKey USB/BLE connection availability.

Before using significant funds, test wallet restoration, receiving, sending, and key-image synchronization over both USB and BLE with a small amount of XMR.

Never enter a OneKey recovery phrase into this or any other software wallet.

## Upstream and license

Cake Wallet source and copyright notices remain under the MIT license in [LICENSE.md](LICENSE.md). Upstream security and Monero engine changes should be periodically merged from `cake-tech/cake_wallet`.
