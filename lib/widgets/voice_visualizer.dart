import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class VoiceVisualizer extends StatefulWidget {
  final bool active;
  final Stream<double>? levelStream;
  final double width;
  final double height;
  final int barCount;
  final Color? color;

  const VoiceVisualizer({
    super.key,
    this.active = false,
    this.levelStream,
    this.width = 72,
    this.height = 28,
    this.barCount = 12,
    this.color,
  });

  @override
  State<VoiceVisualizer> createState() => _VoiceVisualizerState();
}

class _VoiceVisualizerState extends State<VoiceVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  StreamSubscription<double>? _levelSub;
  double _level = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.active) _controller.repeat();
    _subscribeToLevels();
  }

  @override
  void didUpdateWidget(VoiceVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.value = 0;
      }
    }
    if (widget.levelStream != oldWidget.levelStream) {
      _subscribeToLevels();
    }
  }

  void _subscribeToLevels() {
    _levelSub?.cancel();
    _levelSub = widget.levelStream?.listen((value) {
      if (!mounted) return;
      setState(() => _level = value.clamp(0.0, 1.0).toDouble());
    });
  }

  @override
  void dispose() {
    _levelSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  double _factorFor(int index) {
    if (!widget.active) return 0.12;
    final t = _controller.value;
    if (widget.levelStream != null) {
      final pulse =
          0.5 + 0.5 * math.sin(t * math.pi * 4 + index * 0.9);
      return (0.12 + _level * 0.55 + pulse * 0.33)
          .clamp(0.12, 1.0)
          .toDouble();
    }
    final wave = 0.5 + 0.5 * math.sin(t * math.pi * 4 + index * 0.8);
    final secondary = 0.5 + 0.5 * math.sin(t * math.pi * 2 + index * 0.35);
    return (0.2 + wave * 0.5 + secondary * 0.3)
        .clamp(0.15, 1.0)
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final count = math.max(1, widget.barCount);
    final gap = count > 1 ? 3.0 : 0.0;
    final barWidth =
        math.max(2.0, (widget.width - gap * (count - 1)) / count).toDouble();

    return Semantics(
      label: widget.active ? 'Voice activity' : 'Voice idle',
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(count, (index) {
                final barHeight =
                    math.max(3.0, widget.height * _factorFor(index)).toDouble();
                return Container(
                  width: barWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: color.withValues(
                      alpha: widget.active ? 0.9 : 0.35,
                    ),
                    borderRadius: BorderRadius.circular(barWidth / 2),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
