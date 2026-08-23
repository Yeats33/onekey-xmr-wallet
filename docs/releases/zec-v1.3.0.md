# ZEC Wallet 1.3.0 pre-release

ZEC Wallet is a Zcash-only application with OneKey-protected Shielded software
signing. This GitHub release is intentionally marked as a **pre-release**.

## Protection model

- OneKey `CipherKeyValue` wraps a random vault key after device confirmation.
- The database stores viewing material plus an authenticated
  XChaCha20-Poly1305 seed envelope.
- Seed decryption and Sapling, Orchard, and Ironwood signing happen on the phone
  inside Rust.
- OneKey unlocks the signer but cannot verify a Shielded recipient, amount, or
  fee. This is not Shielded hardware signing.
- Unattended auto-shield and migration signing are disabled for protected
  accounts.

## Artifacts

- Signed Android APKs for arm64-v8a, armeabi-v7a, and x86_64.
- Unsigned iOS IPA for later Apple signing.
- Separate Android and iOS SHA-256 checksum assets.

## Important limitations

Transparent ZEC hardware signing is not enabled: stock OneKey firmware currently
supports the Zcash v5/ZIP-244 path, while this wallet uses the newer
NU6.3/Ironwood transaction path. The iOS IPA is not directly installable until
signed. Physical OneKey transaction testing and an independent security review
remain required before this product can be promoted to a stable release. Do not
use significant funds with this pre-release.
