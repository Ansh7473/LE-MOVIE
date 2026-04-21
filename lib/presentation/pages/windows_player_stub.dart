// lib/presentation/pages/windows_player_stub.dart
import 'package:flutter/material.dart';
import '../../data/models/stream_model.dart';

class WindowsPlayer extends StatelessWidget {
  final StreamModel stream;
  const WindowsPlayer({super.key, required this.stream});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Windows player not supported on this platform.',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
