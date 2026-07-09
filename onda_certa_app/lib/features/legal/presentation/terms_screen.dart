import 'package:flutter/material.dart';
import '../../../core/l10n/l10n.dart';
import 'legal_screen.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LegalScreen(
      title: l10n.termsOfService,
      sections: [
        LegalSection(heading: l10n.legalLastUpdated, body: l10n.termsIntroBody),
        LegalSection(heading: l10n.termsSection1Heading, body: l10n.termsSection1Body),
        LegalSection(heading: l10n.termsSection2Heading, body: l10n.termsSection2Body),
        LegalSection(heading: l10n.termsSection3Heading, body: l10n.termsSection3Body),
        LegalSection(heading: l10n.termsSection4Heading, body: l10n.termsSection4Body),
        LegalSection(heading: l10n.termsSection5Heading, body: l10n.termsSection5Body),
        LegalSection(heading: l10n.termsSection6Heading, body: l10n.termsSection6Body),
        LegalSection(heading: l10n.termsSection7Heading, body: l10n.termsSection7Body),
        LegalSection(heading: l10n.termsSection8Heading, body: l10n.termsSection8Body),
        LegalSection(heading: l10n.termsSection9Heading, body: l10n.termsSection9Body),
        LegalSection(heading: l10n.termsSection10Heading, body: l10n.termsSection10Body),
      ],
    );
  }
}
