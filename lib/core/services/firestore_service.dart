import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sku_model.dart';
import '../models/sector_model.dart';
import '../models/drive_model.dart';
import '../models/user_model.dart';
import '../models/inventory_log_model.dart';

/// Centralised Firestore access — all reads/writes go through here.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ───────────────────── INVENTORY ─────────────────────

  /// Stream all inventory SKUs (real-time).
  Stream<List<SkuModel>> streamInventory() {
    return _db
        .collection('inventory')
        .orderBy('days_of_runway', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => SkuModel.fromFirestore(d)).toList());
  }

  /// Get a single SKU by ID.
  Future<SkuModel?> getSku(String skuId) async {
    final doc = await _db.collection('inventory').doc(skuId).get();
    if (!doc.exists) return null;
    return SkuModel.fromFirestore(doc);
  }

  /// Update stock (used for stock-in / stock-out).
  Future<void> updateStock({
    required String skuId,
    required int newStock,
    required String updatedBy,
  }) async {
    await _db.collection('inventory').doc(skuId).update({
      'current_stock': newStock,
      'last_updated': FieldValue.serverTimestamp(),
      'last_updated_by': updatedBy,
    });
  }

  // ───────────────────── INVENTORY LOG ─────────────────────

  /// Write an inventory log event.
  Future<void> addInventoryLog(InventoryLogModel log) async {
    await _db.collection('inventory_log').doc(log.eventId).set(log.toFirestore());
  }

  /// Stream log events for a given SKU, newest first.
  Stream<List<InventoryLogModel>> streamLogsForSku(String skuId) {
    return _db
        .collection('inventory_log')
        .where('sku_id', isEqualTo: skuId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => InventoryLogModel.fromFirestore(d)).toList());
  }

  // ───────────────────── SECTORS ─────────────────────

  /// Stream all 25 sectors.
  Stream<List<SectorModel>> streamSectors() {
    return _db.collection('sectors').snapshots().map(
          (snap) => snap.docs.map((d) => SectorModel.fromFirestore(d)).toList(),
        );
  }

  // ───────────────────── DONATION DRIVES ─────────────────────

  /// Stream active drives sorted by ascending runway (most urgent first).
  Stream<List<DriveModel>> streamActiveDrives() {
    return _db
        .collection('donation_drives')
        .where('status', isEqualTo: 'ACTIVE')
        .orderBy('runway_at_creation_days', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => DriveModel.fromFirestore(d)).toList());
  }

  /// Get a single drive.
  Future<DriveModel?> getDrive(String driveId) async {
    final doc = await _db.collection('donation_drives').doc(driveId).get();
    if (!doc.exists) return null;
    return DriveModel.fromFirestore(doc);
  }

  // ───────────────────── USERS ─────────────────────

  /// Get a user document.
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Create or overwrite user document.
  Future<void> setUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toFirestore());
  }

  /// Update FCM token (admin only).
  Future<void> updateFcmToken(String uid, String token) async {
    await _db.collection('users').doc(uid).update({'fcm_token': token});
  }
}
