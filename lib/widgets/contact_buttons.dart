import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactButtons extends StatelessWidget {
  final String phoneNo;
  const ContactButtons({super.key, required this.phoneNo});

  String get _dialable => phoneNo.replaceAll(RegExp(r'[^0-9+]'), '');

  String? get _whatsAppDigits {
    final p = _dialable;
    if (p.startsWith('+')) return p.substring(1);
    if (p.startsWith('00')) return p.substring(2);
    return null;
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the app')),
      );
    }
  }

  void _whatsApp(BuildContext context) {
    final digits = _whatsAppDigits;
    if (digits == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'WhatsApp needs the country code. Edit the number to start with +',
          ),
        ),
      );
      return;
    }
    _open(context, Uri.parse('https://wa.me/$digits'));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () =>
                _open(context, Uri(scheme: 'tel', path: _dialable)),
            icon: const Icon(Icons.call),
            label: const Text('Call'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () => _whatsApp(context),
            icon: const Icon(Icons.chat),
            label: const Text('WhatsApp'),
          ),
        ),
      ],
    );
  }
}