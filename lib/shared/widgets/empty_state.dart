import 'package:flutter/material.dart';

/// A centered placeholder for empty lists/screens: an optional muted icon, a
/// title (the first line of [message]) and a muted subtitle (remaining lines).
class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {this.icon, super.key});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = message.split('\n');
    final subtitle =
        lines.length > 1 ? lines.sublist(1).join('\n').trim() : null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 56,
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 18),
            ],
            Text(
              lines.first,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
