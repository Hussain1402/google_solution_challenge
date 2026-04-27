import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/models/sector_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../shared/widgets/app_drawer.dart';

// Provider to stream all 25 sectors for the map
final sectorsProvider = StreamProvider<List<SectorModel>>((ref) {
  return FirestoreService().streamSectors();
});

class GridMapScreen extends ConsumerStatefulWidget {
  const GridMapScreen({super.key});

  @override
  ConsumerState<GridMapScreen> createState() => _GridMapScreenState();
}

class _GridMapScreenState extends ConsumerState<GridMapScreen> {
  GoogleMapController? _mapController;

  // Center of the 5x5 grid (Pimpri-Chinchwad hub)
  static const LatLng _hubLocation = LatLng(18.6298, 73.8553);

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Color _getZoneFillColor(String zoneStatus) {
    switch (zoneStatus) {
      case 'SCARCITY':
        return kRed.withValues(alpha: 0.40);
      case 'NEUTRAL':
        return kGray.withValues(alpha: 0.25);
      case 'ABUNDANCE':
        return kGreen.withValues(alpha: 0.40);
      default:
        return Colors.transparent;
    }
  }

  Color _getZoneStrokeColor(String zoneStatus) {
    switch (zoneStatus) {
      case 'SCARCITY':
        return kRed.withValues(alpha: 0.8);
      case 'NEUTRAL':
        return kMidGray.withValues(alpha: 0.5);
      case 'ABUNDANCE':
        return kGreen.withValues(alpha: 0.8);
      default:
        return Colors.white;
    }
  }

  Color _getStatusTextColor(String status) {
    if (status == 'SCARCITY') return kRed;
    if (status == 'ABUNDANCE') return kGreen;
    return kMidGray;
  }

  Color _getStatusBgColor(String status) {
    if (status == 'SCARCITY') return kLightRed;
    if (status == 'ABUNDANCE') return kLightGreen;
    return kLightGray;
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'HIGH':
        return kRed;
      case 'MEDIUM':
        return kAmber;
      case 'LOW':
        return kGreen;
      default:
        return kMidGray;
    }
  }

  Color _getRiskBgColor(String risk) {
    switch (risk) {
      case 'HIGH':
        return kLightRed;
      case 'MEDIUM':
        return kLightAmb;
      case 'LOW':
        return kLightGreen;
      default:
        return kLightGray;
    }
  }

  Set<Polygon> _buildPolygons(List<SectorModel> sectors) {
    return sectors.map((sector) {
      // Map polygon points
      final points = sector.polygonPoints.map((p) => LatLng(p['lat']!, p['lng']!)).toList();

      return Polygon(
        polygonId: PolygonId(sector.sectorId),
        points: points,
        fillColor: _getZoneFillColor(sector.zoneStatus),
        strokeColor: _getZoneStrokeColor(sector.zoneStatus),
        strokeWidth: 2,
        consumeTapEvents: true,
        onTap: () {
          _showSectorDetails(sector);
        },
      );
    }).toSet();
  }

  Set<Marker> _buildMarkers(List<SectorModel> sectors) {
    final markers = <Marker>{};

    // Hub marker
    final criticalCount = sectors.where((s) => s.zoneStatus == 'SCARCITY').length;
    markers.add(
      Marker(
        markerId: const MarkerId('hub'),
        position: _hubLocation,
        infoWindow: InfoWindow(
          title: 'ReliefHub Demo Centre',
          snippet: '$criticalCount SCARCITY sectors active',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    return markers;
  }

  void _showSectorDetails(SectorModel sector) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.25,
        maxChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: kMidGray.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sector header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kLightBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(sector.sectorId,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBlue)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(sector.label,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kGray)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Zone status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusBgColor(sector.zoneStatus),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      sector.zoneStatus == 'SCARCITY'
                          ? Icons.warning_rounded
                          : sector.zoneStatus == 'ABUNDANCE'
                              ? Icons.check_circle
                              : Icons.remove_circle_outline,
                      color: _getStatusTextColor(sector.zoneStatus),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(sector.zoneStatus,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _getStatusTextColor(sector.zoneStatus))),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  _statChip(Icons.people, '${sector.populationEstimate}', 'Population'),
                  const SizedBox(width: 12),
                  _statChip(Icons.person, '${sector.registeredBeneficiaries}', 'Beneficiaries'),
                  const SizedBox(width: 12),
                  _statChip(Icons.volunteer_activism, '${sector.registeredDonors}', 'Donors'),
                ],
              ),
              const SizedBox(height: 20),

              // Risk scores per category
              const Text('Risk Scores by Category',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kGray)),
              const SizedBox(height: 10),
              ...sector.riskScores.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(_formatCategoryName(entry.key),
                              style: const TextStyle(fontSize: 13, color: kGray)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getRiskBgColor(entry.value),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(entry.value,
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700, color: _getRiskColor(entry.value))),
                        ),
                      ],
                    ),
                  )),

              // Active drive
              if (sector.activeDriveId != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kLightAmb,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.campaign, color: kAmber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Active Donation Drive',
                                style: TextStyle(fontWeight: FontWeight.w600, color: kAmber, fontSize: 13)),
                            Text(sector.activeDriveId!,
                                style: const TextStyle(color: kGray, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kLightGray,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: kMidGray),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kGray)),
            Text(label, style: const TextStyle(fontSize: 10, color: kMidGray)),
          ],
        ),
      ),
    );
  }

  String _formatCategoryName(String key) {
    // CAT_01 → Basic Necessities, etc.
    final mapping = {
      'CAT_01': 'Basic Necessities',
      'CAT_02': 'Operational Tools',
      'CAT_03': 'Household & Structural',
      'CAT_04': 'Medical Goods',
      'CAT_05': 'Hygiene Goods',
    };
    return mapping[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final sectorsAsync = ref.watch(sectorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Grid'),
      ),
      drawer: const AppDrawer(),
      body: sectorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: kRed),
                const SizedBox(height: 12),
                Text('Error loading grid: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: kGray)),
              ],
            ),
          ),
        ),
        data: (sectors) {
          // Count zones for summary
          final scarcityCount = sectors.where((s) => s.zoneStatus == 'SCARCITY').length;
          final neutralCount = sectors.where((s) => s.zoneStatus == 'NEUTRAL').length;
          final abundanceCount = sectors.where((s) => s.zoneStatus == 'ABUNDANCE').length;

          return Stack(
            children: [
              // Google Map with sector polygons
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _hubLocation,
                  zoom: 11.5,
                ),
                onMapCreated: (controller) => _mapController = controller,
                polygons: _buildPolygons(sectors),
                markers: _buildMarkers(sectors),
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false,
              ),

              // Floating legend card (PRD requirement)
              Positioned(
                top: 12,
                right: 12,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Zone Legend',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kGray)),
                        const SizedBox(height: 8),
                        _legendRow(kRed, 'Scarcity', scarcityCount),
                        const SizedBox(height: 6),
                        _legendRow(kMidGray, 'Neutral', neutralCount),
                        const SizedBox(height: 6),
                        _legendRow(kGreen, 'Abundance', abundanceCount),
                      ],
                    ),
                  ),
                ),
              ),

              // Sector count summary pill at bottom
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text(
                        '${sectors.length} Sectors  •  $scarcityCount Scarcity  •  $neutralCount Neutral  •  $abundanceCount Abundance',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kGray),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _legendRow(Color color, String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.5),
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text('$label ($count)',
            style: const TextStyle(fontSize: 12, color: kGray)),
      ],
    );
  }
}
