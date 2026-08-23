import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/entities/donation_config.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => S.current = S());

  test('donation address is a valid XMR address', () {
    expect(xmrWalletDonationAddress, hasLength(95));
    expect(
      AddressValidator(type: CryptoCurrency.xmr).isValid(xmrWalletDonationAddress),
      isTrue,
    );
  });

  test('donation URI opens an XMR payment request', () {
    final request = PaymentRequest.fromUri(Uri.parse(xmrWalletDonationUri));

    expect(request.scheme, 'monero');
    expect(request.address, xmrWalletDonationAddress);
    expect(request.amount, isEmpty);
  });
}
