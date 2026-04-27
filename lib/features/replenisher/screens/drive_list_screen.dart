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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: kLightGray),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/drives/${drive.driveId}', extra: drive),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              color: kLightBlue,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: kBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PROACTIVE',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.timer_outlined, size: 16, color: kBlue),
                      const SizedBox(width: 4),
                      Text(
                        'Ends in ${drive.expiresAt.difference(DateTime.now()).inDays} days',
                        style: const TextStyle(fontSize: 12, color: kBlue, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Item: ${target['sku_id']}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kBlue),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drive.geminiDescription,
                    style: const TextStyle(fontSize: 14, color: kGray),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${target['qty_pledged']} Pledged',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: kTeal),
                      ),
                      Text(
                        '${(progressClamped * 100).toInt()}%',
                        style: const TextStyle(color: kMidGray),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progressClamped,
                    backgroundColor: kLightGray,
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
