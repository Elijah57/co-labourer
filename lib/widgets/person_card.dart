import 'package:flutter/material.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import 'person_avatar.dart';

class PersonCard extends StatelessWidget {
  final Person person;
  final String fullName;
  final bool isDue;
  final VoidCallback onTap;

  const PersonCard({
    super.key,
    required this.person,
    required this.fullName,
    required this.isDue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final followUp = person.followUpDate;
    final location = person.metAt?.trim();
    final hasLocation = location != null && location.isNotEmpty;

    final subtitleSpans = <InlineSpan>[];
    if (hasLocation) {
      subtitleSpans.add(TextSpan(text: location));
    }
    if (followUp != null) {
      if (subtitleSpans.isNotEmpty) {
        subtitleSpans.add(const TextSpan(text: '  •  '));
      }
      subtitleSpans.add(
        TextSpan(
          text: 'Follow-up ${formatDayMonth(followUp)}',
          style: TextStyle(
            fontWeight: isDue ? FontWeight.w700 : FontWeight.w500,
            color: isDue ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
      );
    }
    if (subtitleSpans.isEmpty) {
      subtitleSpans.add(const TextSpan(text: 'No details added yet'));
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              PersonAvatar(photoPath: person.photoPath, radius: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fullName,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        style: theme.textTheme.bodySmall,
                        children: subtitleSpans,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isDue) ...[
                const SizedBox(width: 10),
                Tooltip(
                  message: 'Follow-up due',
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.wheat,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      size: 18,
                      color: AppColors.indigoDeep,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
