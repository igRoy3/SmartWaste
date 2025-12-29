import 'dart:math';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class WaveformVisualizer extends StatefulWidget {
  const WaveformVisualizer({super.key});

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  final int _barCount = 40;
  late List<double> _barHeights;

  @override
  void initState() {
    super.initState();
    _barHeights = List.generate(_barCount, (_) => _random.nextDouble() * 0.5 + 0.2);
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(() {
        setState(() {
          for (int i = 0; i < _barCount; i++) {
            _barHeights[i] = _random.nextDouble() * 0.7 + 0.15;
          }
        });
      });
    
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_barCount, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 50),
            width: 4,
            height: _barHeights[index] * 80,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.primary,
                  AppColors.accent,
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
