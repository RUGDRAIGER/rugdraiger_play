import 'package:flutter/material.dart';
import '../screens/player/player_screen.dart';

void openFullPlayer(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (_, animation, __) => const PlayerScreen(),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 300),
    ),
  );
}
