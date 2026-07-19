import 'package:flutter/material.dart';
import 'package:openlifts/features/home/application/welcome_back.dart';

/// A returning-lifter prompt: after a layoff, offer to ease back in with
/// lighter weights. The deload amount is pre-filled from the time away.
///
/// Pure (no providers/DB) so it is widget-testable directly with a fixed
/// [WelcomeBack] and callbacks.
class WelcomeBackCard extends StatefulWidget {
  const WelcomeBackCard({
    required this.suggestion,
    required this.onApply,
    required this.onDismiss,
    super.key,
  });

  final WelcomeBack suggestion;
  final void Function(int percent) onApply;
  final VoidCallback onDismiss;

  @override
  State<WelcomeBackCard> createState() => _WelcomeBackCardState();
}

class _WelcomeBackCardState extends State<WelcomeBackCard> {
  late int _percent = widget.suggestion.suggestedPercent;

  // Latch on the first tap so a double-tap can't fire a second (compounding)
  // deload before the parent tears the card down (only after the action ends).
  bool _submitted = false;

  void _apply(int percent) {
    if (_submitted) return;
    setState(() => _submitted = true);
    widget.onApply(percent);
  }

  void _dismiss() {
    if (_submitted) return;
    setState(() => _submitted = true);
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final weeks = (widget.suggestion.daysAway / 7).round();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.waving_hand_outlined,
                  size: 18,
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Welcome back',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "It's been about $weeks weeks. Ease back in with lighter weights "
              'to rebuild form and avoid soreness.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Deload', style: theme.textTheme.bodyMedium),
                const Spacer(),
                IconButton.filledTonal(
                  visualDensity: VisualDensity.compact,
                  onPressed: _submitted || _percent <= 0
                      ? null
                      : () => setState(() => _percent -= 5),
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    '$_percent%',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton.filledTonal(
                  visualDensity: VisualDensity.compact,
                  onPressed: _submitted || _percent >= 50
                      ? null
                      : () => setState(() => _percent += 5),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitted ? null : _dismiss,
                    child: const Text('Keep weights'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _submitted
                        ? null
                        : () => _percent <= 0 ? _dismiss() : _apply(_percent),
                    child: const Text('Apply deload'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
