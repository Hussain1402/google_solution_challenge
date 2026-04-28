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
import 'stock_update_screen.dart';

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
                return Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kOutlineVariant),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: const BoxDecoration(
                          color: kSurfaceContainerLow,
                          border: Border(bottom: BorderSide(color: kOutlineVariant)),
                        ),
                        child: Row(
                          children: [
                            const Text('INVENTORY ITEMS', style: TextStyle(color: kBlue, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                            const Spacer(),
                            Text('${items.length} ITEMS', style: TextStyle(color: kMidGray, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: items.length,
                          separatorBuilder: (_, i) => const Divider(height: 1, color: kOutlineVariant, thickness: 0.5),
                          itemBuilder: (_, i) => _SkuTile(sku: items[i]),
                        ),
                      ),
                    ],
                  ),
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
              color: Colors.white, borderRadius: BorderRadius.circular(8))),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(children: [
        _chip('CRITICAL', summary[RunwayStatus.critical] ?? 0, runwayColor(RunwayStatus.critical), RunwayStatus.critical),
        const SizedBox(width: 8),
        _chip('WARNING', summary[RunwayStatus.warning] ?? 0, runwayColor(RunwayStatus.warning), RunwayStatus.warning),
        const SizedBox(width: 8),
        _chip('MONITOR', summary[RunwayStatus.monitor] ?? 0, runwayColor(RunwayStatus.monitor), RunwayStatus.monitor),
        const SizedBox(width: 8),
        _chip('SAFE', summary[RunwayStatus.safe] ?? 0, runwayColor(RunwayStatus.safe), RunwayStatus.safe),
      ]),
    );
  }

  Widget _chip(String label, int count, Color baseColor, RunwayStatus status) {
    final isActive = activeFilter == status;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(runwayFilterProvider.notifier).toggle(status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isActive ? baseColor : kOutlineVariant, width: isActive ? 2 : 1),
            boxShadow: [
              if (!isActive) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
              if (isActive) BoxShadow(color: baseColor.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: kMidGray, letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: baseColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      status == RunwayStatus.critical ? Icons.report :
                      status == RunwayStatus.safe ? Icons.verified : Icons.history,
                      size: 12, color: baseColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('$count', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kOnSurface)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkuTile extends ConsumerWidget {
  final dynamic sku;
  const _SkuTile({required this.sku});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    final isStaffOrAdmin = userProfile.value?.role == 'staff' || userProfile.value?.role == 'admin';

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => context.go('/ledger/${sku.skuId}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: kSurfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: CategoryIcon(categoryId: sku.categoryId),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sku.skuName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kOnSurface)),
                const SizedBox(height: 4),
                Text('${sku.skuId.length > 8 ? sku.skuId.substring(0, 8).toUpperCase() : sku.skuId.toUpperCase()} • ${sku.currentStock} ${sku.unit} • ${sku.categoryName}',
                    style: const TextStyle(fontSize: 11, color: kMidGray, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
              ],
            )),
            if (isStaffOrAdmin) ...[
              _StockActionButton(
                icon: Icons.add_circle_outline,
                color: kGreen,
                tooltip: 'Stock In',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StockUpdateScreen(skuId: sku.skuId, eventType: 'STOCK_IN'),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _StockActionButton(
                icon: Icons.remove_circle_outline,
                color: kAmber,
                tooltip: 'Stock Out',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StockUpdateScreen(skuId: sku.skuId, eventType: 'STOCK_OUT'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            RunwayBadge(daysOfRunway: sku.daysOfRunway),
          ]),
        ),
      ),
    );
  }
}

class _StockActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _StockActionButton({required this.icon, required this.color, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: color),
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
