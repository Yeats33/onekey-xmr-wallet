# PWallet 1.3.0 pre-release

PWallet combines XMR and ZEC in one privacy-focused application. It excludes
the non-privacy coin set from the full Cake Wallet build. This GitHub release is
intentionally marked as a **pre-release**.

## XMR

- First-class OneKey device identity with native USB and Bluetooth transports.
- Hardware Monero signing and key-image synchronization; spend keys remain on
  OneKey.
- Reliable OneKey recognition during resynchronization.

## ZEC

- OneKey-protected Shielded software signing using a random device-wrapped vault
  key and an authenticated XChaCha20-Poly1305 seed envelope.
- Seed decryption and Shielded signatures happen on the phone inside Rust.
- OneKey cannot verify the Shielded recipient, amount, or fee.
- Transparent ZEC hardware signing is not enabled on the current transaction
  path.

## Artifacts and warning

The release contains signed Android APKs for arm64-v8a, armeabi-v7a, and x86_64,
an unsigned iOS IPA, and separate checksum assets for both platforms. The IPA
requires Apple signing before installation. Physical OneKey transaction testing
and an independent security review remain required before PWallet can become a
stable release. Do not use significant funds with this pre-release.
