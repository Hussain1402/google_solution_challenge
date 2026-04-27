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

    return Card(
      elevation: 0,
      color: const Color(0xFF1E1E1E), // Terminal-like background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF333333), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '> ${sector.sectorId} - ${sector.label}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.greenAccent,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(sector.zoneStatus),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    sector.zoneStatus,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStatusTextColor(sector.zoneStatus),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (highRisks.isNotEmpty) ...[
              const Text('HIGH_RISK_CATEGORIES_DETECTED:', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.white70)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: highRisks.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kLightRed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 14, color: kRed),
                        const SizedBox(width: 4),
                        Text(
                          _formatCategory(entry.key),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kRed),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              const Text('SYS.OK: No high risk categories detected.', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.greenAccent)),
            ],
            const SizedBox(height: 12),
            Text(
              '[LAST_ASSESSED: ${sector.lastScoutRun.toLocal().toString().split('.')[0]}]',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
