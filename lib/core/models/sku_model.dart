import 'package:cloud_firestore/cloud_firestore.dart';

/// /inventory/{sku_id} — PRD-exact schema.
class SkuModel {
  final String skuId;
  final String categoryId;
  final String categoryName;
  final String skuName;
  final String unit;
  final int currentStock;
  final int reservedStock;
  final int reorderThreshold;
  final double avgDailyConsumption;
  final double daysOfRunway;
  final DateTime lastUpdated;
  final String lastUpdatedBy;
  final String locationInStorehouse;

  const SkuModel({
    required this.skuId,
    required this.categoryId,
    required this.categoryName,
    required this.skuName,
    required this.unit,
    required this.currentStock,
    required this.reservedStock,
    required this.reorderThreshold,
    required this.avgDailyConsumption,
    required this.daysOfRunway,
    required this.lastUpdated,
    required this.lastUpdatedBy,
    required this.locationInStorehouse,
  });

  factory SkuModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return SkuModel(
      skuId: d['sku_id'] as String,
      categoryId: d['category_id'] as String,
      categoryName: d['category_name'] as String,
      skuName: d['sku_name'] as String,
      unit: d['unit'] as String,
      currentStock: (d['current_stock'] as num).toInt(),
      reservedStock: (d['reserved_stock'] as num).toInt(),
      reorderThreshold: (d['reorder_threshold'] as num).toInt(),
      avgDailyConsumption: (d['avg_daily_consumption'] as num).toDouble(),
      daysOfRunway: (d['days_of_runway'] as num).toDouble(),
      lastUpdated: (d['last_updated'] as Timestamp).toDate(),
      lastUpdatedBy: d['last_updated_by'] as String,
      locationInStorehouse: d['location_in_storehouse'] as String,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'sku_id': skuId,
    'category_id': categoryId,
    'category_name': categoryName,
    'sku_name': skuName,
    'unit': unit,
    'current_stock': currentStock,
    'reserved_stock': reservedStock,
    'reorder_threshold': reorderThreshold,
    'avg_daily_consumption': avgDailyConsumption,
    'days_of_runway': daysOfRunway,
    'last_updated': Timestamp.fromDate(lastUpdated),
    'last_updated_by': lastUpdatedBy,
    'location_in_storehouse': locationInStorehouse,
  };
}
