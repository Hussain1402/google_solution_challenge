import 'package:flutter/material.dart';
import '../../shared/utils/runway_calculator.dart';

/// Coloured badge/chip showing runway status — PRD mandates this on every
/// inventory item, never plain text.
class RunwayBadge extends StatelessWidget {
  final double daysOfRunway;

  const RunwayBadge({super.key, required this.daysOfRunway});

  IconData _getIcon(RunwayStatus status) {
    switch (status) {
      case RunwayStatus.critical: return Icons.report;
      case RunwayStatus.warning: return Icons.history;
      case RunwayStatus.monitor: return Icons.history;
      case RunwayStatus.safe: return Icons.verified;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = getRunwayStatus(daysOfRunway);
    final label = runwayStatusLabel(status);
    final baseColor = runwayColor(status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.1),
        border: Border.all(color: baseColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(status), size: 14, color: baseColor),
          const SizedBox(width: 8),
          Text(
            '${daysOfRunway.toStringAsFixed(0)} DAYS RUNWAY',
            style: TextStyle(
              color: baseColor,
              fontSize: 12,
              fontWeight: FontWeight.w900, // Black
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
