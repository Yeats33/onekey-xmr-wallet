import 'dart:math';

import 'package:cake_wallet/entities/donation_config.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/copy_wrapper.dart';
import 'package:cake_wallet/new-ui/widgets/modal_page_wrapper.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart' as qr;
import 'package:url_launcher/url_launcher.dart';

// written by people who happened to read my slack message in 2025
// whoever works on this codebase in the future, feel free to add your own mark here
const List<String> aboutPageEasterEggs = [
  "Designed in (S)pain",
  "Proudly managing over 🤷‍♂️ XMR",
  "The cake is not a lie 🍰",
  "I don’t play soccer because I enjoy the sport. I’m just doing it for kicks.",
  "Markets in red? Big deal.\nWhat color is the grass outside?",
  "Conquered Web3, now working on Web6-7",
  "Proud owner of none of your funds\n(we are not impressed)",
  "*writing down my seedphrase*\ncake cake cake cake cake cake cake ca...",
  "Don't forget to actually use your crypto to pay for stuff in the real world 🙂",
  "A chain of blocks? That's preposterous!",
  "IOU a hug <3",
  "Warning: up to 4.8% programmed by cats",
  "We love collecting your data <3\nWe're just really incompetent at it"
];

class AboutPage extends StatefulWidget {
  const AboutPage({super.key, required this.appVersion});

  final String appVersion;

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  static const int easterEggTreshold = 5;
  String _bottomText = S.current.payment_made_easy;
  int _easterEggCounter = 0;

  void _easterEgg() {
    _easterEggCounter++;
    if (_easterEggCounter == easterEggTreshold) {
      setState(() {
        _bottomText = aboutPageEasterEggs.elementAt(Random().nextInt(aboutPageEasterEggs.length));
      });
    }
  }

  void _showDonationSheet(BuildContext pageContext) {
    showModalBottomSheet<void>(
      context: pageContext,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(pageContext).colorScheme.surface,
      builder: (sheetContext) => _DonationSheet(
        onSend: () {
          Navigator.of(sheetContext).pop();
          Navigator.of(pageContext).pushNamed(
            Routes.send,
            arguments: {
              'paymentRequest': PaymentRequest.fromUri(Uri.parse(xmrWalletDonationUri)),
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModalPageWrapper(
      topBar: ModalTopBar(
        title: S.of(context).about,
        leadingIcon: Icon(Icons.arrow_back_ios_new),
        leadingSemanticLabel: S.of(context).seed_alert_back,
        onLeadingPressed: Navigator.of(context).pop,
      ),
      content: Container(
          color: Theme.of(context).colorScheme.surface,
          child: Column(children: [
            Column(
              children: [
                Column(
                  spacing: 16,
                  children: [
                    SizedBox(),
                    GestureDetector(
                      onTap: _easterEgg,
                      child: CakeImageWidget(
                        imageUrl: "assets/new-ui/cake_squircle_icon.svg",
                        width: 128,
                        height: 128,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          "Cake Wallet",
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
                        ),
                        Text(widget.appVersion,
                            style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurfaceVariant))
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Wrap(
                        children: [
                          Text(
                            _bottomText,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32),
                NewListSections(sections: {
                  "": [
                    ListItemRegularRow(
                        keyValue: "official website",
                        label: "Official Website",
                        onTap: () => launchUrl(Uri.https("cakewallet.com")),
                        trailingIconPath: "assets/new-ui/link_arrow.svg",
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        trailingIconSize: 10),
                    ListItemRegularRow(
                        keyValue: "docs",
                        label: "Cake Docs",
                        onTap: () => launchUrl(Uri.https("docs.cakewallet.com")),
                        trailingIconPath: "assets/new-ui/link_arrow.svg",
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        trailingIconSize: 10),
                    ListItemRegularRow(
                      keyValue: "donate-xmr",
                      label: "${S.of(context).donation} XMR",
                      iconPath: "assets/new-ui/crypto_full_icons/monero.svg",
                      leadingIconSize: 28,
                      onTap: () => _showDonationSheet(context),
                      trailingIconPath: "assets/new-ui/link_arrow.svg",
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      trailingIconSize: 10,
                    ),
                  ],
                  "2": [
                    ListItemRegularRow(
                        keyValue: "gh",
                        label: "GitHub",
                        onTap: () => launchUrl(Uri.https("github.com", "cake-tech")),
                        trailingIconPath: "assets/new-ui/link_arrow.svg",
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        trailingIconSize: 10),
                    ListItemRegularRow(
                        keyValue: "twitter",
                        label: "X (Twitter)",
                        onTap: () => launchUrl(Uri.https("twitter.com", "cakewallet")),
                        trailingIconPath: "assets/new-ui/link_arrow.svg",
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        trailingIconSize: 10),
                    ListItemRegularRow(
                        keyValue: "tg",
                        label: "Telegram",
                        onTap: () => launchUrl(Uri.https("t.me", "cakewallet")),
                        trailingIconPath: "assets/new-ui/link_arrow.svg",
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        trailingIconSize: 10)
                  ]
                })
              ],
            )
          ])),
    );
  }
}

class _DonationSheet extends StatelessWidget {
  const _DonationSheet({required this.onSend});

  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 20,
        children: [
          Text(
            "${S.of(context).donation} XMR",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Semantics(
            image: true,
            label: "${S.of(context).donation} XMR QR",
            child: Container(
              width: 248,
              height: 248,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  qr.QrImageView(
                    data: xmrWalletDonationUri,
                    version: qr.QrVersions.auto,
                    errorCorrectionLevel: qr.QrErrorCorrectLevel.M,
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const CakeImageWidget(
                      imageUrl: "assets/new-ui/crypto_full_icons/monero.svg",
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: SelectableText(
              xmrWalletDonationAddress,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFamily: 'monospace',
                    height: 1.45,
                  ),
            ),
          ),
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: CopyWrapper(
                  data: const ClipboardData(text: xmrWalletDonationAddress),
                  controlBuilder: (context, copied, onCopy) => NewPrimaryButton(
                    onPressed: onCopy!,
                    text: copied ? S.of(context).copied : S.of(context).copy_address,
                    color: colors.surfaceContainerHighest,
                    textColor: colors.primary,
                    image: Icon(
                      copied ? Icons.check_rounded : Icons.copy_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: NewPrimaryButton(
                  onPressed: onSend,
                  text: S.of(context).send,
                  color: colors.primary,
                  textColor: colors.onPrimary,
                  image: Icon(
                    Icons.send_rounded,
                    color: colors.onPrimary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
