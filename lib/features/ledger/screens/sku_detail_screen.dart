import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/colors.dart';
import '../../../core/models/sku_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../shared/utils/runway_calculator.dart';
import '../../../shared/widgets/runway_badge.dart';
import '../../../shared/widgets/category_icon.dart';
import 'stock_update_screen.dart';

/// Provider that fetches a single SKU by ID.
final skuDetailProvider = FutureProvider.family<SkuModel?, String>((ref, skuId) {
  return FirestoreService().getSku(skuId);
});

class SkuDetailScreen extends ConsumerWidget {
  final String skuId;
  const SkuDetailScreen({super.key, required this.skuId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skuAsync = ref.watch(skuDetailProvider(skuId));

    return Scaffold(
      appBar: AppBar(title: const Text('SKU Detail')),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'stock_in',
            backgroundColor: kGreen,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StockUpdateScreen(skuId: skuId, eventType: 'STOCK_IN'),
              ),
            ).then((_) => ref.invalidate(skuDetailProvider(skuId))),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.small(
            heroTag: 'stock_out',
            backgroundColor: kAmber,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StockUpdateScreen(skuId: skuId, eventType: 'STOCK_OUT'),
              ),
            ).then((_) => ref.invalidate(skuDetailProvider(skuId))),
            child: const Icon(Icons.remove, color: Colors.white),
          ),
        ],
      ),
      body: skuAsync.when(
        loading: () => _buildShimmer(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sku) {
          if (sku == null) {
            return Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 56, color: kMidGray),
                const SizedBox(height: 12),
                Text('SKU not found', style: TextStyle(color: kMidGray, fontSize: 16)),
              ],
            ));
          }
          return _SkuDetailBody(sku: sku);
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: kLightGray,
      highlightColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: List.generate(5, (_) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(height: 48, decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(10))),
        ))),
      ),
    );
  }
}

class _SkuDetailBody extends StatelessWidget {
  final SkuModel sku;
  const _SkuDetailBody({required this.sku});

  @override
  Widget build(BuildContext context) {
    final status = getRunwayStatus(sku.daysOfRunway);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          CategoryIcon(categoryId: sku.categoryId, size: 48),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sku.skuName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kGray)),
              const SizedBox(height: 4),
              Text(sku.categoryName, style: TextStyle(fontSize: 14, color: kMidGray)),
            ],
          )),
          RunwayBadge(daysOfRunway: sku.daysOfRunway),
        ]),
        const SizedBox(height: 24),

        // Stock info cards
        Row(children: [
          _InfoCard('Current Stock', '${sku.currentStock} ${sku.unit}', kLightBlue, kBlue),
          const SizedBox(width: 12),
          _InfoCard('Reserved', '${sku.reservedStock} ${sku.unit}', kLightTeal, kTeal),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _InfoCard('Avg Daily Use', sku.avgDailyConsumption.toStringAsFixed(1), kLightAmb, kAmber),
          const SizedBox(width: 12),
          _InfoCard('Reorder At', '${sku.reorderThreshold} ${sku.unit}', kLightGray, kGray),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _InfoCard('Runway', '${sku.daysOfRunway.toStringAsFixed(1)} days',
              runwayBgColor(status), runwayFgColor(status)),
          const SizedBox(width: 12),
          _InfoCard('Location', sku.locationInStorehouse, kLightGray, kGray),
        ]),
        const SizedBox(height: 24),

        // Metadata
        _MetaRow('SKU ID', sku.skuId),
        _MetaRow('Category ID', sku.categoryId),
        _MetaRow('Last Updated', _formatDate(sku.lastUpdated)),
        _MetaRow('Updated By', sku.lastUpdatedBy),
      ]),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final Color bg;
  final Color fg;
  const _InfoCard(this.label, this.value, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fg)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.7))),
      ]),
    ));
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 120, child: Text(label, style: TextStyle(fontSize: 13, color: kMidGray))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kGray))),
      ]),
    );
  }
}
