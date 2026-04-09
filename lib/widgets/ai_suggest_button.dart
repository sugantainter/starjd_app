import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AiSuggestButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final String label;
  final bool isSmall;

  const AiSuggestButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.label = 'Suggest with AI',
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: isLoading ? null : () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 10 : 16,
          vertical: isSmall ? 6 : 10,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLoading 
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : [const Color(0xFFE63946), const Color(0xFFFF6B6B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isLoading ? [] : [
            BoxShadow(
              color: const Color(0xFFE63946).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Text(
                '✨',
                style: TextStyle(fontSize: isSmall ? 12 : 14),
              ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmall ? 11 : 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ).animate(target: isLoading ? 1 : 0).shimmer(
        duration: 1.seconds,
        color: Colors.white24,
      ),
    );
  }
}
