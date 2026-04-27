import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../../../core/models/drive_model.dart';
import '../../auth/providers/auth_provider.dart';

class PledgeScreen extends ConsumerStatefulWidget {
  final DriveModel drive;

  const PledgeScreen({super.key, required this.drive});

  @override
  ConsumerState<PledgeScreen> createState() => _PledgeScreenState();
}

class _PledgeScreenState extends ConsumerState<PledgeScreen> {
  int _quantity = 1;
  bool _isSubmitting = false;

  Future<void> _submitPledge() async {
    setState(() => _isSubmitting = true);
    
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw Exception('User not logged in');

      final db = FirebaseFirestore.instance;
      
      // Update drive pledged qty (optimistic simple update for demo)
      final driveRef = db.collection('donation_drives').doc(widget.drive.driveId);
      
      await db.runTransaction((transaction) async {
        final snapshot = await transaction.get(driveRef);
        if (!snapshot.exists) throw Exception('Drive not found');
        
        final data = snapshot.data()!;
        final targets = List<Map<String, dynamic>>.from(data['target_items']);
        
        // Update first target item
        if (targets.isNotEmpty) {
          targets[0]['qty_pledged'] = (targets[0]['qty_pledged'] as int) + _quantity;
        }

        transaction.update(driveRef, {'target_items': targets});
        
        // Also add to user's donation history
        final userRef = db.collection('users').doc(user.uid);
        transaction.update(userRef, {
          'donation_history': FieldValue.arrayUnion([widget.drive.driveId])
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pledge successful! Thank you.'), backgroundColor: kGreen),
        );
        context.pop(); // return to detail
        context.pop(); // return to list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pledge Items')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How many items can you pledge?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kGray),
            ),
            const SizedBox(height: 32),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    icon: const Icon(Icons.remove_circle_outline, size: 40, color: kBlue),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    '$_quantity',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: kGray),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    onPressed: () => setState(() => _quantity++),
                    icon: const Icon(Icons.add_circle_outline, size: 40, color: kBlue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'By pledging, you commit to dropping off these items at the designated location within the next 48 hours.',
              style: TextStyle(color: kMidGray, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submitPledge,
                style: FilledButton.styleFrom(
                  backgroundColor: kBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirm Pledge', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
