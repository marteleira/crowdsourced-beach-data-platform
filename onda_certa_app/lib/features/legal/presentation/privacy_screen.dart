import 'package:flutter/material.dart';
import '../../../core/l10n/l10n.dart';
import 'legal_screen.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LegalScreen(
      title: l10n.privacyPolicy,
      sections: [
        LegalSection(heading: l10n.legalLastUpdated, body: l10n.privacyIntroBody),
        LegalSection(heading: l10n.privacySection1Heading, body: l10n.privacySection1Body),
        LegalSection(heading: l10n.privacySection2Heading, body: l10n.privacySection2Body),
        LegalSection(heading: l10n.privacySection3Heading, body: l10n.privacySection3Body),
        LegalSection(heading: l10n.privacySection4Heading, body: l10n.privacySection4Body),
        LegalSection(heading: l10n.privacySection5Heading, body: l10n.privacySection5Body),
        LegalSection(heading: l10n.privacySection6Heading, body: l10n.privacySection6Body),
        LegalSection(heading: l10n.privacySection7Heading, body: l10n.privacySection7Body),
        LegalSection(heading: l10n.privacySection8Heading, body: l10n.privacySection8Body),
      ],
    );
  }
}
