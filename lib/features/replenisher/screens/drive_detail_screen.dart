import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/models/drive_model.dart';

class DriveDetailScreen extends StatelessWidget {
  final DriveModel drive;

  const DriveDetailScreen({super.key, required this.drive});

  @override
  Widget build(BuildContext context) {
    final target = drive.targetItems.first;
    final progress = target['qty_pledged'] / target['qty_needed'];
    final progressClamped = progress > 1.0 ? 1.0 : progress;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drive Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kLightBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'PROACTIVE REPLENISHMENT',
                style: TextStyle(color: kBlue, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Help us restock before scarcity hits.',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kGray),
            ),
            const SizedBox(height: 16),
            Text(
              drive.geminiDescription,
              style: const TextStyle(fontSize: 16, color: kMidGray, height: 1.5),
            ),
            const SizedBox(height: 32),
            
            // Progress Section
            const Text('Goal Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kGray)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${target['qty_pledged']} Pledged',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: kTeal, fontSize: 16),
                ),
                Text(
                  'Goal: ${target['qty_needed']}',
                  style: const TextStyle(color: kMidGray),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progressClamped,
              backgroundColor: kLightGray,
              color: kTeal,
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            
            const SizedBox(height: 32),
            // Drop-off Info
            const Text('Drop-off Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kGray)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: kLightGray),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: kBlue, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drive.dropOffPoint['name'] ?? 'ReliefHub',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Text(
                          'Open 9 AM - 6 PM Daily',
                          style: TextStyle(color: kMidGray),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () => context.push('/drives/${drive.driveId}/pledge', extra: drive),
            style: FilledButton.styleFrom(
              backgroundColor: kBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Pledge a Donation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
