import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/utils/runway_calculator.dart';
import '../../../shared/widgets/runway_badge.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/inventory_provider.dart';

class InventoryListScreen extends ConsumerWidget {
  const InventoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(filteredInventoryProvider);
    final summary = ref.watch(inventorySummaryProvider);
    final activeFilter = ref.watch(runwayFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _SummaryRow(summary: summary, activeFilter: activeFilter, ref: ref),
          if (activeFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Text('Filtered: ${runwayStatusLabel(activeFilter)}',
                    style: TextStyle(fontSize: 13, color: kMidGray)),
                const Spacer(),
                TextButton(
                  onPressed: () => ref.read(runwayFilterProvider.notifier).clear(),
                  child: const Text('Clear'),
                ),
              ]),
            ),
          const Divider(height: 1),
          Expanded(
            child: inventoryAsync.when(
              loading: () => _buildShimmer(),
              error: (e, _) => _ErrorState(error: '$e'),
              data: (items) {
                if (items.isEmpty) return _EmptyState(activeFilter: activeFilter);
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _SkuTile(sku: items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: kLightGray,
      highlightColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(height: 72, decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12))),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final Map<RunwayStatus, int> summary;
  final RunwayStatus? activeFilter;
  final WidgetRef ref;
  const _SummaryRow({required this.summary, required this.activeFilter, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(children: [
        _chip('CRITICAL', summary[RunwayStatus.critical]!, kLightRed, kRed, RunwayStatus.critical),
        const SizedBox(width: 8),
        _chip('WARNING', summary[RunwayStatus.warning]!, kWarningBg, kWarningText, RunwayStatus.warning),
        const SizedBox(width: 8),
        _chip('MONITOR', summary[RunwayStatus.monitor]!, kLightAmb, kAmber, RunwayStatus.monitor),
        const SizedBox(width: 8),
        _chip('SAFE', summary[RunwayStatus.safe]!, kLightGreen, kGreen, RunwayStatus.safe),
      ]),
    );
  }

  Widget _chip(String label, int count, Color bg, Color fg, RunwayStatus status) {
    final isActive = activeFilter == status;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(runwayFilterProvider.notifier).toggle(status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? fg : bg,
            borderRadius: BorderRadius.circular(10),
            border: isActive ? Border.all(color: fg, width: 2) : null,
          ),
          child: Column(children: [
            Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : fg)),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                color: isActive ? Colors.white70 : fg, letterSpacing: 0.5)),
          ]),
        ),
      ),
    );
  }
}

class _SkuTile extends StatelessWidget {
  final dynamic sku;
  const _SkuTile({required this.sku});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/ledger/${sku.skuId}'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kLightGray),
          ),
          child: Row(children: [
            CategoryIcon(categoryId: sku.categoryId),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sku.skuName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kGray)),
                const SizedBox(height: 3),
                Text('${sku.currentStock} ${sku.unit} • ${sku.categoryName}',
                    style: TextStyle(fontSize: 12, color: kMidGray)),
              ],
            )),
            RunwayBadge(daysOfRunway: sku.daysOfRunway),
          ]),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final RunwayStatus? activeFilter;
  const _EmptyState({this.activeFilter});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.inventory_2_outlined, size: 64, color: kLightGray),
      const SizedBox(height: 12),
      Text(activeFilter != null
          ? 'No items with ${runwayStatusLabel(activeFilter!)} status'
          : 'No inventory items yet',
          style: TextStyle(fontSize: 15, color: kMidGray)),
    ]));
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.error_outline, size: 48, color: kMidGray),
      const SizedBox(height: 12),
      Text('Failed to load inventory', style: TextStyle(color: kMidGray)),
      Text(error, style: TextStyle(color: kMidGray, fontSize: 12)),
    ]));
  }
}
