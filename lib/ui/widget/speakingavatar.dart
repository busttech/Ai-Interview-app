import 'package:flutter/material.dart';

class SpeakingAvatar extends StatelessWidget {
  final bool isSpeaking;

  const SpeakingAvatar({super.key, required this.isSpeaking});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 700),
        width: isSpeaking ? 160 : 120,
        height: isSpeaking ? 160 : 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
          boxShadow:
              isSpeaking
                  ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      spreadRadius: 10,
                      blurRadius: 20,
                    ),
                  ]
                  : [],
        ),
        child: ClipOval(
          child: Image.asset('assests/girl_avatar.webp', fit: BoxFit.cover),
        ),
      ),
    );
  }
}
