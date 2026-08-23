# Changelog

All notable changes to XMR Wallet, ZEC Wallet, and PWallet are documented in
this file. Product-specific GitHub release notes live under `docs/releases/`.

## [1.3.0] - 2026-08-23

### Products and packaging

- Added three independently installable Flutter products:
  - XMR Wallet: `com.yeats33.xmrwallet` (`xmrwallet` URL scheme).
  - ZEC Wallet: `com.yeats33.zecwallet` (`zecwallet` URL scheme).
  - PWallet: `com.yeats33.pwallet` (`pwallet` URL scheme), containing XMR and
    ZEC only.
- Unified all three user-facing versions at 1.3.0. XMR Wallet uses build 5;
  ZEC Wallet and PWallet use build 2 on Android and iOS.
- Added product-specific `xmr-v*`, `zec-v*`, and `pwallet-v*` release tags.
- Added signed Android APK output for arm64-v8a, armeabi-v7a, and x86_64.
- Added unsigned iOS IPA output for later signing with an Apple certificate and
  matching provisioning profile.
- Added distinct Android and iOS checksum assets so one platform cannot
  overwrite the other platform's `SHA256SUMS` file in a GitHub release.

### OneKey and Monero

- Promoted OneKey to a first-class hardware-wallet manufacturer and persisted
  wallet type instead of displaying it as a renamed Trezor entry.
- Added native OneKey Pro USB identity and BLE advertisement detection,
  connection management, V1 framing, and transport tests.
- Added native OneKey Monero service routing over USB and Bluetooth. Trezor
  compatibility mode must be disabled; the Monero wire-message schema remains
  shared with OneKey firmware.
- Kept Monero spend keys and transaction signing on OneKey hardware.
- Fixed OneKey recognition during hardware-wallet resynchronization.

### OneKey-protected Zcash

- Added a ZEC-only wallet and the ZEC side of PWallet.
- Added OneKey `CipherKeyValue` support over the native device connection.
- Added OneKey-protected Shielded ZEC account creation and restoration.
- The wallet database stores viewing material plus an authenticated
  XChaCha20-Poly1305 seed envelope. The random vault key is wrapped and
  unwrapped by OneKey; plaintext seed handling and signing stay inside Rust.
- Added protected transaction signing, tamper/wrong-key/account-binding tests,
  and disabled unattended auto-shield/migration for protected accounts.
- Added an explicit in-app warning that OneKey unlocks the Shielded signer but
  cannot verify the Shielded recipient, amount, or fee.

### CI, release, and verification

- Added Android and iOS matrices covering XMR Wallet, ZEC Wallet, and PWallet.
- Added package/bundle/version checks, APK signature checks, 16 KiB zipalign
  checks, SHA-256 verification, product-matrix tests, and GitHub artifacts.
- Pinned and verified the native dependency bundles used by iOS CI, including
  Monero and LibTorch frameworks.
- Added reusable product release notes. ZEC Wallet and PWallet are published as
  GitHub pre-releases until physical-device testing and an external security
  review are complete.

### Donation

- Added the configured XMR donation address and an in-app Monero payment URI:
  `89stMPmzZBFLumXZnBBrux92HtCiJwhnUXFg1RrKBfkfKGVbEnZdWAtPu7E6ZN8ZCrCuu6Qx1rypa1CqkY3UYmhAQWSL4bC`.

### Security boundaries and known limitations

- Shielded ZEC is **OneKey-protected software signing**, not hardware signing.
  OneKey controls access to the encrypted vault key, while Sapling, Orchard,
  and Ironwood signatures are produced on the phone inside Rust.
- Transparent ZEC hardware signing is not enabled. The stock OneKey signer is
  limited to Zcash v5/ZIP-244 transactions, while the current wallet path uses
  the newer NU6.3/Ironwood transaction format.
- The iOS artifacts are unsigned build-verification archives and are not
  directly installable App Store or TestFlight packages.
- OneKey physical-device transaction testing and an independent security review
  remain required before ZEC Wallet or PWallet can be promoted from pre-release
  to a stable production release. Do not use significant funds before those
  gates are complete.

## [1.2.1] - 2026-08-23

- Added the XMR donation flow and validation tests.
- Published signed Android XMR Wallet APKs with portable checksums.

## [1.2.0] - 2026-08-23

- Fixed reliable OneKey recognition during resynchronization.
- Added native OneKey USB/BLE transport and release verification for XMR Wallet.
