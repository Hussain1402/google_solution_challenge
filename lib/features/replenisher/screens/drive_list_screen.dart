import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/drive_model.dart';
import '../../../shared/widgets/app_drawer.dart';

final activeDrivesProvider = StreamProvider<List<DriveModel>>((ref) {
  return FirestoreService().streamActiveDrives();
});

class DriveListScreen extends ConsumerWidget {
  const DriveListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drivesAsync = ref.watch(activeDrivesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Drives'),
      ),
      drawer: const AppDrawer(),
      body: drivesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
        data: (drives) {
          if (drives.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: drives.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, index) {
              final drive = drives[index];
              return _DriveCard(drive: drive);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.volunteer_activism_outlined, size: 80, color: kLightGray),
          SizedBox(height: 16),
          Text(
            'All resources are secure!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kGray),
          ),
          SizedBox(height: 8),
          Text(
            'No proactive donation drives are active right now.',
            style: TextStyle(color: kMidGray),
          ),
        ],
      ),
    );
  }
}

class _DriveCard extends StatelessWidget {
  final DriveModel drive;

  const _DriveCard({required this.drive});

  @override
  Widget build(BuildContext context) {
    final target = drive.targetItems.first;
    final progress = target['qty_pledged'] / target['qty_needed'];
    final progressClamped = progress > 1.0 ? 1.0 : progress;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kOutlineVariant),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/drives/${drive.driveId}', extra: drive),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: kOutlineVariant, width: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kSurfaceContainerLow,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: kOutlineVariant, width: 0.5),
                        ),
                        child: const Text(
                          'PROACTIVE DRIVE',
                          style: TextStyle(color: kBlue, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.timer_outlined, size: 14, color: kWarningText),
                      const SizedBox(width: 4),
                      Text(
                        'Ends in ${drive.expiresAt.difference(DateTime.now()).inDays} days',
                        style: const TextStyle(fontSize: 12, color: kWarningText, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${target['sku_id'].toString().replaceAll('_', ' ').toUpperCase()} CAMPAIGN',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kOnSurface, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    drive.geminiDescription,
                    style: const TextStyle(fontSize: 13, color: kMidGray, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.inventory_2, size: 14, color: kTeal),
                          const SizedBox(width: 6),
                          Text(
                            '${target['qty_pledged']} / ${target['qty_needed']} Pledged',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: kTeal, fontSize: 13),
                          ),
                        ],
                      ),
                      Text(
                        '${(progressClamped * 100).toInt()}%',
                        style: const TextStyle(color: kMidGray, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progressClamped,
                    backgroundColor: kSurfaceContainerLow,
                    color: kTeal,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
