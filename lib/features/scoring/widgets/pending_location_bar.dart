import 'package:flutter/material.dart';

const confirmLocationText = '确认落点';
const skipLocationText = '跳过落点';
const undoText = '撤销';

class PendingLocationBar extends StatelessWidget {
  const PendingLocationBar({
    required this.onConfirm,
    required this.onSkip,
    required this.onUndo,
    super.key,
  });

  final VoidCallback onConfirm;
  final VoidCallback onSkip;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              key: const Key('confirm-location'),
              onPressed: onConfirm,
              icon: const Icon(Icons.check),
              label: const Text(confirmLocationText),
            ),
            OutlinedButton(
              onPressed: onSkip,
              child: const Text(skipLocationText),
            ),
            TextButton.icon(
              onPressed: onUndo,
              icon: const Icon(Icons.undo),
              label: const Text(undoText),
            ),
          ],
        ),
      ),
    );
  }
}
