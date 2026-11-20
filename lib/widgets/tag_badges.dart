import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Small read-only pills: an optional "Active" badge followed by tag names.
class TagBadges extends StatelessWidget {
  final bool isActive;
  final List<String> tags;
  final WrapAlignment alignment;

  const TagBadges({
    super.key,
    required this.isActive,
    required this.tags,
    this.alignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive && tags.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelSmall;

    Widget pill(String label, {required bool active}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: active ? AppColors.wheat : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: active ? null : Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        label,
        style: style?.copyWith(
          color: active ? AppColors.indigoDeep : scheme.onSurfaceVariant,
          fontWeight: active ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      alignment: alignment,
      children: [
        if (isActive) pill('Active', active: true),
        for (final tag in tags) pill(tag, active: false),
      ],
    );
  }
}
