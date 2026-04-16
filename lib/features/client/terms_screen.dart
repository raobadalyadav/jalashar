import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Title('Terms of Service'),
          _SubTitle('Last updated: April 2026'),
          SizedBox(height: 16),
          _Section(
            '1. Acceptance of Terms',
            'By accessing or using Jalaram Events, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the app.',
          ),
          _Section(
            '2. Description of Service',
            'Jalaram Events is a platform connecting clients with event service providers (vendors). We facilitate bookings and payments but are not a party to the service agreement between clients and vendors.',
          ),
          _Section(
            '3. User Accounts',
            '• You must be 18 years or older to create an account\n'
            '• You are responsible for maintaining the confidentiality of your login credentials\n'
            '• You must provide accurate and complete information\n'
            '• One person may not create multiple accounts',
          ),
          _Section(
            '4. Booking & Payments',
            '• Bookings are confirmed upon successful 30% advance payment\n'
            '• Payments are processed by Razorpay under their terms\n'
            '• Balance payment is due as agreed with the vendor\n'
            '• Jalaram Events charges a 10% platform fee on completed bookings',
          ),
          _Section(
            '5. Cancellation & Refunds',
            '• Cancellations more than 7 days before the event: 80% refund of advance\n'
            '• Cancellations 3-7 days before: 50% refund of advance\n'
            '• Cancellations within 72 hours: No refund\n'
            '• Vendor cancellations: Full refund plus compensation credit',
          ),
          _Section(
            '6. Vendor Obligations',
            'Vendors must:\n'
            '• Provide accurate service descriptions and pricing\n'
            '• Respond to booking requests within 24 hours\n'
            '• Complete services as described and agreed\n'
            '• Maintain professional standards\n'
            '• Have valid documentation as required by law',
          ),
          _Section(
            '7. Prohibited Conduct',
            '• Circumventing the platform to avoid fees\n'
            '• Posting false reviews or misleading information\n'
            '• Harassment or abusive behaviour toward other users\n'
            '• Using the platform for illegal activities\n'
            '• Attempting to access other users\' data',
          ),
          _Section(
            '8. Intellectual Property',
            'The Jalaram Events name, logo, and all platform content are owned by Jalaram Events Pvt. Ltd. Users grant us a license to use content they upload (portfolio photos, reviews) for platform operation.',
          ),
          _Section(
            '9. Limitation of Liability',
            'Jalaram Events is not liable for: vendor service quality, event outcomes, force majeure events, or indirect/consequential damages. Our liability is limited to the platform fee collected for the relevant booking.',
          ),
          _Section(
            '10. Governing Law',
            'These terms are governed by the laws of India. Disputes shall be subject to the exclusive jurisdiction of courts in Ahmedabad, Gujarat.',
          ),
          _Section(
            '11. Contact',
            'For terms-related queries:\n'
            'Email: legal@jalaram.events\n'
            'Address: Jalaram Events Pvt. Ltd., Ahmedabad, Gujarat 380001',
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800, color: AppColors.deepMaroon));
  }
}

class _SubTitle extends StatelessWidget {
  const _SubTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(color: AppColors.slate, fontSize: 12));
  }
}

class _Section extends StatelessWidget {
  const _Section(this.heading, this.body);
  final String heading, body;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(height: 1.6)),
        ],
      ),
    );
  }
}
