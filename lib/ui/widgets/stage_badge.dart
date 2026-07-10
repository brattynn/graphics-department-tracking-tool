import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class StageBadge extends StatelessWidget {
  final String stage;

  const StageBadge({super.key, required this.stage});

  Color _color(BuildContext context) {
    switch (stage) {
      case Stage.proofing:
        return Colors.blueGrey;
      case Stage.productionInstallation:
        return Colors.orange.shade700;
      case Stage.qc:
        return Colors.purple.shade600;
      case Stage.complete:
        return Colors.green.shade700;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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
