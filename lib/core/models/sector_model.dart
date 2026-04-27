import 'package:cloud_firestore/cloud_firestore.dart';

/// /sectors/{sector_id} — PRD-exact schema.
class SectorModel {
  final String sectorId;
  final String label;
  final double centerLat;
  final double centerLng;
  final List<Map<String, double>> polygonPoints; // [{lat, lng}, ...]
  final String zoneStatus; // "SCARCITY" | "NEUTRAL" | "ABUNDANCE"
  final Map<String, String> riskScores; // { CAT_01: "HIGH"|"MEDIUM"|"LOW", ... }
  final int populationEstimate;
  final int registeredBeneficiaries;
  final int registeredDonors;
  final DateTime lastScoutRun;
  final String? activeDriveId;

  const SectorModel({
    required this.sectorId,
    required this.label,
    required this.centerLat,
    required this.centerLng,
    required this.polygonPoints,
    required this.zoneStatus,
    required this.riskScores,
    required this.populationEstimate,
    required this.registeredBeneficiaries,
    required this.registeredDonors,
    required this.lastScoutRun,
    this.activeDriveId,
  });

  factory SectorModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    
    // Parse polygon points from Firestore array
    final rawPoints = d['polygon_points'] as List<dynamic>? ?? [];
    final parsedPoints = rawPoints.map((point) {
      final p = point as Map<String, dynamic>;
      return {
        'lat': (p['lat'] as num).toDouble(),
        'lng': (p['lng'] as num).toDouble(),
      };
    }).toList();

    return SectorModel(
      sectorId: d['sector_id'] as String,
      label: d['label'] as String,
      centerLat: (d['center_lat'] as num).toDouble(),
      centerLng: (d['center_lng'] as num).toDouble(),
      polygonPoints: parsedPoints,
      zoneStatus: d['zone_status'] as String,
      riskScores: Map<String, String>.from(d['risk_scores'] as Map),
      populationEstimate: (d['population_estimate'] as num).toInt(),
      registeredBeneficiaries: (d['registered_beneficiaries'] as num).toInt(),
      registeredDonors: (d['registered_donors'] as num).toInt(),
      lastScoutRun: (d['last_scout_run'] as Timestamp).toDate(),
      activeDriveId: d['active_drive_id'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'sector_id': sectorId,
    'label': label,
    'center_lat': centerLat,
    'center_lng': centerLng,
    'polygon_points': polygonPoints,
    'zone_status': zoneStatus,
    'risk_scores': riskScores,
    'population_estimate': populationEstimate,
    'registered_beneficiaries': registeredBeneficiaries,
    'registered_donors': registeredDonors,
    'last_scout_run': Timestamp.fromDate(lastScoutRun),
    'active_drive_id': activeDriveId,
  };
}
