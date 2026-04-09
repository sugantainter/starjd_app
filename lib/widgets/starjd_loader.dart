import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StarJDLoader extends StatelessWidget {
  final String? message;
  const StarJDLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glowing rings
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.primaryColor.withOpacity(0.1),
                    width: 2,
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.5, 1.5),
                duration: 1500.ms,
                curve: Curves.easeOut,
              )
              .fadeOut(duration: 1500.ms),
              
              // Inner spinning gradient border
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.primaryColor,
                    width: 3,
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 2000.ms),

              // Small logo or icon in center
              Image.asset(
                'assets/images/logo.png',
                width: 30,
                height: 30,
                color: isDark ? Colors.white.withOpacity(0.5) : null,
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.1, 1.1),
                duration: 1000.ms,
                curve: Curves.easeInOut,
              ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 24),
            Text(
              message!,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ).animate().fadeIn(delay: 400.ms).moveY(begin: 10, end: 0),
          ],
        ],
      ),
    );
  }
}
