import 'package:cloud_firestore/cloud_firestore.dart';

/// /donation_drives/{drive_id} — PRD-exact schema.
class DriveModel {
  final String driveId;
  final DateTime createdAt;
  final String urgencyMode; // always "PROACTIVE"
  final String triggerSkuId;
  final String triggerCategoryId;
  final double runwayAtCreationDays;
  final List<Map<String, dynamic>> targetItems;
  final Map<String, dynamic> dropOffPoint; // { name, lat, lng }
  final int driveWindowDays;
  final DateTime expiresAt;
  final String status; // "ACTIVE" | "FULFILLED" | "EXPIRED"
  final String geminiDescription;
  final DateTime? fulfilledAt;

  const DriveModel({
    required this.driveId,
    required this.createdAt,
    required this.urgencyMode,
    required this.triggerSkuId,
    required this.triggerCategoryId,
    required this.runwayAtCreationDays,
    required this.targetItems,
    required this.dropOffPoint,
    required this.driveWindowDays,
    required this.expiresAt,
    required this.status,
    required this.geminiDescription,
    this.fulfilledAt,
  });

  factory DriveModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return DriveModel(
      driveId: d['drive_id'] as String,
      createdAt: (d['created_at'] as Timestamp).toDate(),
      urgencyMode: d['urgency_mode'] as String,
      triggerSkuId: d['trigger_sku_id'] as String,
      triggerCategoryId: d['trigger_category_id'] as String,
      runwayAtCreationDays: (d['runway_at_creation_days'] as num).toDouble(),
      targetItems: List<Map<String, dynamic>>.from(
        (d['target_items'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
      ),
      dropOffPoint: Map<String, dynamic>.from(d['drop_off_point'] as Map),
      driveWindowDays: (d['drive_window_days'] as num).toInt(),
      expiresAt: (d['expires_at'] as Timestamp).toDate(),
      status: d['status'] as String,
      geminiDescription: d['gemini_description'] as String,
      fulfilledAt: d['fulfilled_at'] != null
          ? (d['fulfilled_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'drive_id': driveId,
    'created_at': Timestamp.fromDate(createdAt),
    'urgency_mode': urgencyMode,
    'trigger_sku_id': triggerSkuId,
    'trigger_category_id': triggerCategoryId,
    'runway_at_creation_days': runwayAtCreationDays,
    'target_items': targetItems,
    'drop_off_point': dropOffPoint,
    'drive_window_days': driveWindowDays,
    'expires_at': Timestamp.fromDate(expiresAt),
    'status': status,
    'gemini_description': geminiDescription,
    'fulfilled_at': fulfilledAt != null ? Timestamp.fromDate(fulfilledAt!) : null,
  };
}
