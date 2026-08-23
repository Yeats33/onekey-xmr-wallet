# XMR Wallet 1.3.0

XMR Wallet 1.3.0 makes OneKey a first-class hardware-wallet option with native
OneKey Pro USB and Bluetooth transports. Trezor compatibility mode must be
disabled. Monero spend keys and transaction signatures remain on the OneKey.

## Highlights

- Native OneKey Pro USB identity, BLE discovery, V1 framing, and connection
  management.
- Dedicated OneKey wallet type and Monero service routing.
- Reliable OneKey recognition during resynchronization.
- Signed Android APKs for arm64-v8a, armeabi-v7a, and x86_64.
- Unsigned iOS IPA for later Apple signing.
- Platform-specific SHA-256 checksum assets.
- XMR donation screen and `monero:` payment URI.

## Install and verify

Android users should normally choose the `arm64-v8a` APK. Verify it against the
Android SHA-256 checksum asset before installation. The IPA is unsigned and must
be signed with a valid Apple certificate and matching provisioning profile.

This is an independent project based on Cake Wallet and is not affiliated with
OneKey, Trezor, or Cake Labs. Test restoration, receiving, sending, and
key-image synchronization with a small amount before using significant funds.
