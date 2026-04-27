import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../auth/providers/auth_provider.dart';

class DonationHistoryScreen extends ConsumerWidget {
  const DonationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final userName = userProfileAsync.value?.displayName ?? 'Donor';

    // Dummy data for donation history
    final dummyHistory = [
      {
        'user': userName,
        'driveId': 'DRIVE-001',
        'category': 'Basic Necessities',
        'date': '2025-10-12',
      },
      {
        'user': userName,
        'driveId': 'DRIVE-002',
        'category': 'Medical Supplies',
        'date': '2025-09-05',
      },
      {
        'user': userName,
        'driveId': 'DRIVE-003',
        'category': 'Education Supplies',
        'date': '2025-08-22',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation History'),
      ),
      drawer: const AppDrawer(),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: dummyHistory.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = dummyHistory[index];
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const CircleAvatar(
                backgroundColor: kLightBlue,
                child: Icon(Icons.volunteer_activism, color: kBlue),
              ),
              title: Text(
                '${item['category']}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Drive ID: ${item['driveId']}'),
                  Text('Date: ${item['date']}'),
                ],
              ),
              trailing: const Icon(Icons.check_circle, color: kGreen),
            ),
          );
        },
      ),
    );
  }
}
