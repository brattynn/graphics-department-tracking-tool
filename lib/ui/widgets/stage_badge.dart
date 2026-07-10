import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class StageBadge extends StatelessWidget {
  final String stage;

  const StageBadge({super.key, required this.stage});

  Color _color(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (stage) {
      case Stage.proofing:
        return isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700;
      case Stage.productionInstallation:
        return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
      case Stage.qc:
        return isDark ? Colors.purple.shade200 : Colors.purple.shade600;
      case Stage.complete:
        return isDark ? Colors.green.shade300 : Colors.green.shade700;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.4 : 0.35)),
      ),
      child: Text(
        stage,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
