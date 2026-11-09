import 'package:flutter/material.dart';
import '../models/interaction.dart';
import '../utils/date_format.dart';
import 'voice_visualizer.dart';

class InteractionCard extends StatelessWidget {
  final Interaction interaction;
  final VoidCallback onTap;
  final VoidCallback onPlay;
  final bool isPlaying;

  const InteractionCard({
    super.key,
    required this.interaction,
    required this.onTap,
    required this.onPlay,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isAudio = interaction.audioPath != null;
    final note = interaction.note?.trim();
    final hasNote = note != null && note.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isAudio) ...[
                IconButton(
                  onPressed: onPlay,
                  tooltip: isPlaying ? 'Stop audio' : 'Play audio',
                  icon: Icon(
                    isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.surfaceContainerHighest,
                    foregroundColor: scheme.primary,
                    side: BorderSide(color: scheme.outlineVariant),
                    shape: const CircleBorder(),
                    minimumSize: const Size(48, 48),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formatDayMonth(interaction.createdAt),
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasNote ? note : 'Audio note',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: hasNote
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                        fontStyle: hasNote ? null : FontStyle.italic,
                      ),
                    ),
                    if (isPlaying)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: VoiceVisualizer(
                          active: true,
                          width: 80,
                          height: 22,
                          barCount: 16,
                          color: scheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
