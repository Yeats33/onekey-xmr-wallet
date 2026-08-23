# Privacy Wallet Suite

[![Privacy Wallets Android](https://github.com/Yeats33/onekey-xmr-wallet/actions/workflows/xmr-wallet-android.yml/badge.svg)](https://github.com/Yeats33/onekey-xmr-wallet/actions/workflows/xmr-wallet-android.yml)

Privacy-focused Flutter wallets with first-class OneKey integration:

- **XMR Wallet** — Monero-only, with native OneKey Pro and Trezor hardware signing.
- **ZEC Wallet** — Zcash-only; OneKey-protected Shielded signing is implemented, while transparent OneKey hardware signing remains under development.
- **PWallet** — XMR and ZEC in one privacy-only application.

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

## Product identities

| Application | Identifier | Deep-link scheme | Version |
| --- | --- | --- | --- |
| XMR Wallet | `com.yeats33.xmrwallet` | `xmrwallet` | `1.2.1` |
| ZEC Wallet | `com.yeats33.zecwallet` | `zecwallet` | `0.1.0` |
| PWallet | `com.yeats33.pwallet` | `pwallet` | `0.1.0` |

All products can be installed together and alongside Cake Wallet or Monero.com.
See [the complete product and signing matrix](docs/PRIVACY_WALLET_PRODUCTS.md).

## Configure and build

```bash
./configure_wallet.sh onekey-xmr
./scripts/android/build_wallet.sh onekey-xmr
```

Use `onekey-zec` or `pwallet` to configure and build the other products.

Cake's shared Android plugins and native libraries must be prepared first. See [the Android build and device-testing guide](docs/ONEKEY_XMR_ANDROID.md).

Build outputs are written below `dist/android/<product>/` and deliberately excluded from Git history.

The `Privacy Wallets Android` workflow builds all three product matrices on pushes and pull requests. Product tags such as `xmr-v1.2.1`, `zec-v0.1.0`, or `pwallet-v0.1.0` publish only the matching signed APKs and `SHA256SUMS`.

The `Privacy Wallets iOS` workflow builds clearly named unsigned IPA archives.
They verify the iOS build and can be re-signed for sideloading, but they are not
directly installable App Store/TestFlight artifacts without Apple signing.

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
