# XMR Wallet for Android

This fork builds an Android-only, Monero-only wallet from Cake Wallet v6.4.1.
OneKey is represented as a first-class hardware-wallet manufacturer next to
Trezor. OneKey uses its native USB identity and a dedicated transport/service;
the shared Monero message schema is retained because it is what OneKey firmware
implements for hardware XMR signing.

## Product identity

- App name: `XMR Wallet`
- Android application ID: `com.yeats33.xmrwallet`
- Deep-link scheme: `xmrwallet`
- Version: `1.3.0`
- App type: `onekey-xmr`

The application ID is independent of Cake Wallet (`com.cakewallet.cake_wallet`)
and Monero.com (`com.monero.app`), so all three applications can be installed on
the same Android device.

## OneKey behavior

- OneKey and Trezor are separate choices on the hardware-manufacturer screen.
- Selecting OneKey labels compatible devices as `OneKey Pro` and uses a
  dedicated device icon.
- OneKey wallets are persisted as `HardwareWalletType.onekey`; they are not
  stored as Trezor wallets.
- OneKey uses dedicated native USB and Bluetooth transports plus
  `MoneroOneKeyNativeService`; it is not stored or presented as a Trezor
  connection.
- Native mode accepts only USB ID `0x1209:0x4f4b` and verifies that firmware
  reports vendor `onekey.so`. The Trezor-compatibility PID is rejected.
- Address/watch-key export, passphrase sessions, transaction signing, and key
  image synchronization use the Monero wire messages implemented by OneKey
  firmware.
- The private spend key remains on the hardware wallet.

OneKey Pro must have **Trezor compatibility mode disabled**. Native OneKey USB
and BLE are supported on Android. Bluetooth uses OneKey's native GATT service
and Android system bonding. This project is independent and is not affiliated
with OneKey.

## Configure

```bash
./configure_onekey_xmr.sh
```

The upstream Cake build still resolves several shared Android plugins even in
single-coin builds. Before packaging, prepare its BitBox AAR, Reown native
bindings, and Monero native libraries using Cake's documented Android builder
environment.

## Sign and build

Create a release keystore once and keep it permanently. Android will reject
future upgrades signed with a different key. Then generate `android/key.properties`
with Cake's helper and run:

```bash
./scripts/android/build_onekey_xmr.sh
```

Artifacts are written to `dist/android/xmr-wallet/v1.3.0/` for ARM64, 32-bit ARM, and
x86_64. Modern phones should use the `arm64-v8a` APK.

## Continuous integration and releases

`.github/workflows/xmr-wallet-android.yml` runs on pushes, pull requests,
manual dispatches, and `v*` tags. Native build inputs are restored from pinned
Cake Android dependency images with immutable SHA-256 digests. Normal CI builds
use an ephemeral signing key; tagged releases require the repository's
`ANDROID_RELEASE_*` secrets and publish the three APKs plus `SHA256SUMS`.

The production signing certificate SHA-256 is
`1A:4B:25:DE:7B:4A:F3:D8:FB:72:97:9E:6F:9F:E7:1B:D9:66:B4:FC:D4:75:54:59:C6:EF:FC:89:DB:CB:1B:43`.
The corresponding private key is not stored in Git and must be backed up
separately for all future Android updates.

## Device acceptance test

Do not use significant funds until all of these pass on a physical Android
device:

1. Keep the official Cake Wallet installed and install this APK alongside it.
2. Disable Trezor compatibility mode on OneKey Pro and reconnect its USB cable.
3. Choose **Restore from hardware wallet > OneKey**.
4. Test both USB and Bluetooth connections and verify the address shown by the
   app and device.
5. Receive a small amount of XMR and let the wallet fully synchronize.
6. Send a small amount; verify destination and amount on OneKey Pro before
   approving.
7. Run **Resync device** to synchronize key images.
8. Recreate the wallet from the same device/passphrase and confirm the balance
   and transaction history.

Never enter the OneKey recovery phrase into this or any other software wallet.
