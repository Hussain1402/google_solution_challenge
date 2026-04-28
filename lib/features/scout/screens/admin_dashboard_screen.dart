import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/theme/colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/sector_model.dart';
import '../../../shared/widgets/app_drawer.dart';

// Provider to stream all sectors sorted by zone status and risk
final riskLogProvider = StreamProvider<List<SectorModel>>((ref) {
  return FirestoreService().streamSectors().map((sectors) {
    final list = List<SectorModel>.from(sectors);
    // Sort logic: SCARCITY first, then NEUTRAL, then ABUNDANCE
    list.sort((a, b) {
      int score(String status) {
        if (status == 'SCARCITY') return 0;
        if (status == 'NEUTRAL') return 1;
        return 2;
      }
      return score(a.zoneStatus).compareTo(score(b.zoneStatus));
    });
    return list;
  });
});

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isLoading = false;

  Future<void> _triggerScoutAgent() async {
    setState(() => _isLoading = true);
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable(
        'manualScoutTrigger',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 300)),
      );
      final result = await callable.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scout Agent executed successfully! Risk scores updated.'),
            backgroundColor: kGreen,
          ),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: kRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: kRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskLogAsync = ref.watch(riskLogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Scout (Admin)'),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildHeroSection(),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'AI Risk Log',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kGray),
              ),
            ),
          ),
          Expanded(
            child: riskLogAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error loading log: $err')),
              data: (sectors) {
                if (sectors.isEmpty) {
                  return const Center(child: Text('No sectors available.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: sectors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final sector = sectors[index];
                    return _SectorRiskCard(sector: sector);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: kLightBlue,
      ),
      child: Column(
        children: [
          const Icon(Icons.analytics_outlined, size: 64, color: kBlue),
          const SizedBox(height: 16),
          const Text(
            'Vertex AI Scout Engine',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kBlue),
          ),
          const SizedBox(height: 8),
          const Text(
            'Analyzes real-time inventory velocity and sector demographics to predict resource scarcity.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kGray),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _triggerScoutAgent,
              icon: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: Text(_isLoading ? 'Analyzing...' : 'Run Scout Agent'),
              style: FilledButton.styleFrom(
                backgroundColor: kBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectorRiskCard extends StatelessWidget {
  final SectorModel sector;
  
  const _SectorRiskCard({required this.sector});

  Color _getStatusBgColor(String status) {
    if (status == 'SCARCITY') return kLightRed;
    if (status == 'ABUNDANCE') return kLightGreen;
    return kLightGray;
  }

  Color _getStatusTextColor(String status) {
    if (status == 'SCARCITY') return kRed;
    if (status == 'ABUNDANCE') return kGreen;
    return kMidGray;
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'HIGH': return kRed;
      case 'MEDIUM': return kAmber;
      case 'LOW': return kGreen;
      default: return kMidGray;
    }
  }

  String _formatCategory(String key) {
    final map = {
      'CAT_01': 'Basic Necessities',
      'CAT_02': 'Operational Tools',
      'CAT_03': 'Household & Structural',
      'CAT_04': 'Medical Goods',
      'CAT_05': 'Hygiene Goods',
    };
    return map[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final highRisks = sector.riskScores.entries.where((e) => e.value == 'HIGH').toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kBlue, Color(0xFF1E3A8A)], 
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -40,
            bottom: -40,
            child: Icon(Icons.inventory_2, size: 200, color: Colors.white.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 14, color: kLightBlue),
                    const SizedBox(width: 8),
                    Text(
                      'AI SCOUT LOG - ${sector.sectorId}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kLightBlue, letterSpacing: 0.5),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        sector.zoneStatus,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  highRisks.isNotEmpty 
                      ? 'Urgent Supply Gap Detected in ${sector.label}'
                      : 'Operations Normal in ${sector.label}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                if (highRisks.isNotEmpty) ...[
                  Text(
                    'High depletion rate in ${highRisks.map((e) => _formatCategory(e.key)).join(', ')} suggests critical scarcity. Recommend immediate rerouting from central hub.',
                    style: TextStyle(fontSize: 14, color: Colors.blue.shade100),
                  ),
                ] else ...[
                  Text(
                    'No critical supply gaps detected. Current inventory levels are sufficient for projected needs.',
                    style: TextStyle(fontSize: 14, color: Colors.blue.shade100),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: kBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        elevation: 0,
                      ),
                      child: const Text('Apply Recommendation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
