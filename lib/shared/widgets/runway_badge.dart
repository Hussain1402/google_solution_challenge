import 'package:flutter/material.dart';
import '../../shared/utils/runway_calculator.dart';

/// Coloured badge/chip showing runway status — PRD mandates this on every
/// inventory item, never plain text.
class RunwayBadge extends StatelessWidget {
  final double daysOfRunway;

  const RunwayBadge({super.key, required this.daysOfRunway});

  @override
  Widget build(BuildContext context) {
    final status = getRunwayStatus(daysOfRunway);
    final label = runwayStatusLabel(status);
    final bg = runwayBgColor(status);
    final fg = runwayFgColor(status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label • ${daysOfRunway.toStringAsFixed(0)}d',
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
