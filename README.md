# XMR Wallet

[![XMR Wallet Android](https://github.com/Yeats33/onekey-xmr-wallet/actions/workflows/xmr-wallet-android.yml/badge.svg)](https://github.com/Yeats33/onekey-xmr-wallet/actions/workflows/xmr-wallet-android.yml)

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
- Current version: `1.2.1`

It can be installed alongside Cake Wallet and Monero.com because it uses a separate Android application ID.

## Configure and build

```bash
./configure_onekey_xmr.sh
./scripts/android/build_onekey_xmr.sh
```

Cake's shared Android plugins and native libraries must be prepared first. See [the Android build and device-testing guide](docs/ONEKEY_XMR_ANDROID.md).

Build outputs are written to `dist/android/` and deliberately excluded from Git history.

The `XMR Wallet Android` workflow runs the OneKey USB/BLE tests and builds signed APK artifacts on every push and pull request. Tags matching the configured application version, such as `v1.2.1`, publish the production-signed APKs and `SHA256SUMS` as a GitHub Release.

Production APK signing certificate SHA-256:

```text
1A:4B:25:DE:7B:4A:F3:D8:FB:72:97:9E:6F:9F:E7:1B:D9:66:B4:FC:D4:75:54:59:C6:EF:FC:89:DB:CB:1B:43
```

## Testing

The repository includes tests for:

- stable OneKey hardware-wallet persistence;
- rejection of the Trezor-compatibility USB PID by the native OneKey transport;
- native OneKey BLE UUIDs and V1 64-byte packet framing;
- Android OneKey USB/BLE connection availability;
- the XMR donation address and `monero:` payment URI.

Before using significant funds, test wallet restoration, receiving, sending, and key-image synchronization over both USB and BLE with a small amount of XMR.

Never enter a OneKey recovery phrase into this or any other software wallet.

## Donate

To support continued XMR Wallet development, donations can be sent to this Monero address:

```text
89stMPmzZBFLumXZnBBrux92HtCiJwhnUXFg1RrKBfkfKGVbEnZdWAtPu7E6ZN8ZCrCuu6Qx1rypa1CqkY3UYmhAQWSL4bC
```

The same address is available from **Settings → About → Donate XMR** in the Android app.

## Upstream and license

Cake Wallet source and copyright notices remain under the MIT license in [LICENSE.md](LICENSE.md). Upstream security and Monero engine changes should be periodically merged from `cake-tech/cake_wallet`.
