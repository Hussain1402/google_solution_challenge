import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

/// Runway status enum matching PRD thresholds exactly.
enum RunwayStatus { safe, monitor, warning, critical }

/// PRD formula — do not alter.
double calculateRunway(int currentStock, int reservedStock, double avgDailyConsumption) {
  if (avgDailyConsumption <= 0) return 999.0;
  return (currentStock - reservedStock) / avgDailyConsumption;
}

/// Map days-of-runway to the PRD status.
RunwayStatus getRunwayStatus(double daysOfRunway) {
  if (daysOfRunway < 7) return RunwayStatus.critical;
  if (daysOfRunway < 15) return RunwayStatus.warning;
  if (daysOfRunway <= 30) return RunwayStatus.monitor;
  return RunwayStatus.safe;
}

/// PRD-mandated label text.
String runwayStatusLabel(RunwayStatus status) {
  switch (status) {
    case RunwayStatus.safe:     return 'SAFE';
    case RunwayStatus.monitor:  return 'MONITOR';
    case RunwayStatus.warning:  return 'WARNING';
    case RunwayStatus.critical: return 'CRITICAL';
  }
}

/// Background colour for the runway badge.
Color runwayBgColor(RunwayStatus status) {
  switch (status) {
    case RunwayStatus.safe:     return kGreen;
    case RunwayStatus.monitor:  return kAmber;
    case RunwayStatus.warning:  return kAmber;
    case RunwayStatus.critical: return kRed;
  }
}

/// Foreground / text colour for the runway badge.
Color runwayFgColor(RunwayStatus status) {
  switch (status) {
    case RunwayStatus.safe:     return Colors.white;
    case RunwayStatus.monitor:  return Colors.black;
    case RunwayStatus.warning:  return Colors.black;
    case RunwayStatus.critical: return Colors.white;
  }
}
