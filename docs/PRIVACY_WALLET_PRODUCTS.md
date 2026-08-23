# Privacy wallet product matrix

This repository produces three privacy-focused applications from one source
tree. Product identity is selected at build time with `PRODUCT_FLAVOR`; coin
dependencies are selected by Cake's configure generator.

| Product | App type | Currencies | Android/iOS identifier | Release tag |
| --- | --- | --- | --- | --- |
| XMR Wallet | `onekey-xmr` | XMR | `com.yeats33.xmrwallet` | `xmr-v*` |
| ZEC Wallet | `onekey-zec` | ZEC | `com.yeats33.zecwallet` | `zec-v*` |
| PWallet | `pwallet` | XMR and ZEC | `com.yeats33.pwallet` | `pwallet-v*` |

The package identifiers are intentionally independent, so all three products
can be installed on the same device. XMR Wallet retains its existing production
signing identity. ZEC Wallet and PWallet remain pre-release until the signing
boundaries below are implemented and audited.

## Signing boundaries

- XMR on OneKey: native hardware signing. The private spend key remains on the
  OneKey device.
- Transparent ZEC on OneKey: planned native ZIP-244 hardware signing. The
  transparent private key must remain on the OneKey device.
- Shielded ZEC: OneKey-protected software signing is implemented. Stock OneKey
  `CipherKeyValue` protects a random vault key; the wallet database stores only
  an authenticated XChaCha20-Poly1305 seed envelope and UFVK material. Sapling,
  Orchard, and Ironwood signing occurs inside Rust. Plaintext seed buffers and
  BIP-39 material are cleared on drop; upstream derived-key types are
  short-lived but do not yet guarantee explicit memory wiping.
- The UI must call the Shielded mode **OneKey-protected**, never
  **hardware-signed**. OneKey cannot verify a Shielded recipient or transaction
  under the stock firmware.
- Losing the app's protected-key record leaves the database watch-only. The
  wallet must be restored again from its ZEC seed; OneKey protection is not a
  substitute for an offline seed backup.
- The implementation is included in Android release builds and has automated
  crypto, binding, tamper, ABI, package-signature, and 16 KiB alignment checks.
  A physical OneKey transaction test and external security review remain
  required before a production ZEC/PWallet tag.

OneKey Pro firmware already contains a transparent ZIP-244 signer for Zcash v5,
but that implementation explicitly rejects non-v5 transactions. Current
NU6.3/Ironwood zkool transactions use the newer transaction path, while the
current OneKey/Zcash proposal calls for PCZT-aware transparent and Orchard
firmware support. Until that device-side path is released and testable, this
project will not mislabel a software signature as transparent hardware signing.
See the official [v5 signer](https://github.com/OneKeyHQ/firmware-pro/blob/main/core/src/apps/zcash/signer.py)
and [OneKey Zcash hardware proposal](https://github.com/ZcashCommunityGrants/zcashcommunitygrants/issues/228).

## Build commands

Android configuration:

```bash
./configure_wallet.sh onekey-xmr
./configure_wallet.sh onekey-zec
./configure_wallet.sh pwallet
```

Android release builds:

```bash
./scripts/android/build_wallet.sh onekey-xmr
./scripts/android/build_wallet.sh onekey-zec
./scripts/android/build_wallet.sh pwallet
```

iOS configuration and IPA builds require macOS and Xcode:

```bash
./configure_wallet_ios.sh onekey-xmr
./scripts/ios/build_wallet.sh onekey-xmr
```

Replace the app type with `onekey-zec` or `pwallet` for the other products.
Signed IPA export additionally requires an Apple signing certificate and a
provisioning profile for each bundle identifier.

The iOS CI workflow produces `*-unsigned.ipa` archives for build verification
and later sideload signing. They are not App Store/TestFlight artifacts and are
not directly installable until signed with a valid Apple certificate and
matching provisioning profile.

## Release policy

Pushes and pull requests build all Android products. A product-specific tag
builds and publishes only the matching product. APK and IPA checksums contain
portable relative filenames. No ZEC or PWallet production tag should be pushed
until physical-device tests and an external security review are complete.
