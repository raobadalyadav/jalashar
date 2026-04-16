import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Title('Privacy Policy'),
          _SubTitle('Last updated: April 2026'),
          SizedBox(height: 16),
          _Section(
            'Information We Collect',
            'We collect information you provide when creating an account, making bookings, or communicating with vendors. This includes your name, email address, phone number, location, and payment details processed securely via Razorpay.',
          ),
          _Section(
            'How We Use Your Information',
            '• To process bookings and facilitate vendor connections\n'
            '• To send booking confirmations and event reminders\n'
            '• To improve our services and personalise your experience\n'
            '• To comply with legal obligations\n'
            '• To detect and prevent fraud',
          ),
          _Section(
            'Information Sharing',
            'We share your contact details with vendors only when you confirm a booking. We do not sell your personal data to third parties. Payment information is handled exclusively by Razorpay under their privacy policy.',
          ),
          _Section(
            'Data Storage & Security',
            'Your data is stored on Supabase servers with industry-standard encryption (AES-256). All data transmissions use TLS 1.3. We retain your data for as long as your account is active or as required by law.',
          ),
          _Section(
            'Your Rights',
            'You have the right to:\n'
            '• Access, correct, or delete your personal data\n'
            '• Withdraw consent at any time\n'
            '• Request data portability\n'
            '• Lodge a complaint with a supervisory authority\n\n'
            'To exercise these rights, contact us at privacy@jalaram.events',
          ),
          _Section(
            'Cookies & Analytics',
            'We use essential cookies for authentication. We may use analytics tools to understand app usage patterns. No advertising cookies are used.',
          ),
          _Section(
            'Children\'s Privacy',
            'Jalaram Events is not directed to children under 18. We do not knowingly collect personal information from minors.',
          ),
          _Section(
            'Changes to This Policy',
            'We may update this policy periodically. We will notify you of significant changes via email or in-app notification.',
          ),
          _Section(
            'Contact Us',
            'For privacy-related queries:\n'
            'Email: privacy@jalaram.events\n'
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
