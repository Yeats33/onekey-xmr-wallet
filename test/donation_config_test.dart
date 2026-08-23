import 'package:cake_wallet/entities/donation_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('donation address has a valid XMR address shape', () {
    expect(xmrWalletDonationAddress, hasLength(95));
    expect(RegExp(r'^[48][0-9A-Za-z]{94}$').hasMatch(xmrWalletDonationAddress), isTrue);
  });

  test('donation URI contains the same XMR address', () {
    final uri = Uri.parse(xmrWalletDonationUri);

    expect(uri.scheme, 'monero');
    expect(uri.path, xmrWalletDonationAddress);
    expect(uri.queryParameters, isEmpty);
  });
}
