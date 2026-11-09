import 'package:flutter/material.dart';
import 'voice_visualizer.dart';

Future<bool?> showRecordingDialog(
  BuildContext context, {
  required Stream<double> levels,
}) {
  final scheme = Theme.of(context).colorScheme;
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Text('Recording...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VoiceVisualizer(
              active: true,
              levelStream: levels,
              width: 180,
              height: 56,
              barCount: 18,
              color: scheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Speak now',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Stop & save'),
          ),
        ],
      );
    },
  );
}
