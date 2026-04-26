import 'package:cloud_firestore/cloud_firestore.dart';

/// /inventory_log/{event_id} — PRD-exact schema.
class InventoryLogModel {
  final String eventId;
  final String skuId;
  final String eventType; // "STOCK_IN" | "STOCK_OUT"
  final int quantityDelta;
  final int stockAfter;
  final String performedBy; // uid
  final DateTime timestamp;
  final String? notes;

  const InventoryLogModel({
    required this.eventId,
    required this.skuId,
    required this.eventType,
    required this.quantityDelta,
    required this.stockAfter,
    required this.performedBy,
    required this.timestamp,
    this.notes,
  });

  factory InventoryLogModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return InventoryLogModel(
      eventId: d['event_id'] as String,
      skuId: d['sku_id'] as String,
      eventType: d['event_type'] as String,
      quantityDelta: (d['quantity_delta'] as num).toInt(),
      stockAfter: (d['stock_after'] as num).toInt(),
      performedBy: d['performed_by'] as String,
      timestamp: (d['timestamp'] as Timestamp).toDate(),
      notes: d['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'event_id': eventId,
    'sku_id': skuId,
    'event_type': eventType,
    'quantity_delta': quantityDelta,
    'stock_after': stockAfter,
    'performed_by': performedBy,
    'timestamp': Timestamp.fromDate(timestamp),
    'notes': notes,
  };
}
