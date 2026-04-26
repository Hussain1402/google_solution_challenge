import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/sku_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../shared/utils/runway_calculator.dart';

/// Stream all inventory items in real-time.
final inventoryStreamProvider = StreamProvider<List<SkuModel>>((ref) {
  return FirestoreService().streamInventory();
});

/// Currently selected filter (null = show all).
class RunwayFilterNotifier extends Notifier<RunwayStatus?> {
  @override
  RunwayStatus? build() => null;
  void set(RunwayStatus? status) => state = status;
  void clear() => state = null;
  void toggle(RunwayStatus status) => state = state == status ? null : status;
}

final runwayFilterProvider =
    NotifierProvider<RunwayFilterNotifier, RunwayStatus?>(RunwayFilterNotifier.new);

/// Filtered inventory based on the selected runway status.
final filteredInventoryProvider = Provider<AsyncValue<List<SkuModel>>>((ref) {
  final inventoryAsync = ref.watch(inventoryStreamProvider);
  final filter = ref.watch(runwayFilterProvider);

  return inventoryAsync.whenData((items) {
    if (filter == null) return items;
    return items
        .where((sku) => getRunwayStatus(sku.daysOfRunway) == filter)
        .toList();
  });
});

/// Summary counts for admin dashboard row.
final inventorySummaryProvider = Provider<Map<RunwayStatus, int>>((ref) {
  final inventoryAsync = ref.watch(inventoryStreamProvider);
  final items = inventoryAsync.when(
    data: (list) => list,
    loading: () => <SkuModel>[],
    error: (e, st) => <SkuModel>[],
  );
  return {
    RunwayStatus.critical: items.where((s) => getRunwayStatus(s.daysOfRunway) == RunwayStatus.critical).length,
    RunwayStatus.warning: items.where((s) => getRunwayStatus(s.daysOfRunway) == RunwayStatus.warning).length,
    RunwayStatus.monitor: items.where((s) => getRunwayStatus(s.daysOfRunway) == RunwayStatus.monitor).length,
    RunwayStatus.safe: items.where((s) => getRunwayStatus(s.daysOfRunway) == RunwayStatus.safe).length,
  };
});
