import 'package:flutter/material.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';

class PersonInfoCard extends StatelessWidget {
  final Person person;
  final Widget avatar;
  final int? conversationCount;

  const PersonInfoCard({
    super.key,
    required this.person,
    required this.avatar,
    this.conversationCount,
  });

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _date(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  bool get _followUpDue {
    final d = person.followUpDate;
    if (d == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !DateTime(d.year, d.month, d.day).isAfter(today);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final rows = <Widget>[];
    void add(IconData icon, String label, String? value,
        {bool highlight = false}) {
      if (value == null || value.trim().isEmpty) return;
      rows.add(_InfoRow(
        icon: icon,
        label: label,
        value: value,
        highlight: highlight,
      ));
    }

    add(Icons.place_outlined, 'Where we met', person.metAt);
    // NEW FIELDS (a): date met and partner go here
    add(Icons.phone_outlined, 'Phone', person.phoneno);
    // NEW FIELDS (b): birthday goes here
    add(
      Icons.event_available_outlined,
      'Next follow-up',
      person.followUpDate == null ? null : _date(person.followUpDate!),
      highlight: _followUpDue,
    );
    add(Icons.history, 'Added', _date(person.createdAt));
    if (conversationCount != null) {
      add(Icons.forum_outlined, 'Conversations', '$conversationCount');
    }

    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: avatar),
            const SizedBox(height: 12),
            Text(
              person.firstname,
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (rows.isNotEmpty) const Divider(height: 28),
            ...rows,
            // NEW FIELDS (c): the intro block goes here
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: text.labelMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: text.bodyLarge?.copyWith(
                    fontWeight: highlight ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
          ),
          if (highlight)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.wheat,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Due',
                style: TextStyle(
                  color: AppColors.indigoDeep,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}